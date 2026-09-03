import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

import '../core/utils/format.dart';
import 'app_database.dart';
import 'bank_parser.dart';
import 'models.dart';

/// Listens for HLB / TnG / bank notifications and queues pending imports.
class BankNotificationWatcher {
  BankNotificationWatcher._();
  static final BankNotificationWatcher instance = BankNotificationWatcher._();

  StreamSubscription<ServiceNotificationEvent>? _sub;
  bool _running = false;

  static const watchedPackages = {
    'com.hongleongconnect.mobile',
    'com.hlb',
    'my.com.tngdigital.ewallet',
    'com.tngdigital.ewallet',
    'com.android.mms',
    'com.google.android.apps.messaging',
    'com.samsung.android.messaging',
  };

  bool get isRunning => _running;

  Future<bool> hasPermission() async {
    if (kIsWeb || (!kIsWeb && !Platform.isAndroid)) return false;
    try {
      return await NotificationListenerService.isPermissionGranted();
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      return await NotificationListenerService.requestPermission();
    } catch (_) {
      return false;
    }
  }

  Future<void> start() async {
    if (_running || !Platform.isAndroid) return;
    final ok = await hasPermission();
    if (!ok) return;

    await _sub?.cancel();
    _sub = NotificationListenerService.notificationsStream.listen(_onEvent);
    _running = true;
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _running = false;
  }

  Future<void> _onEvent(ServiceNotificationEvent event) async {
    if (event.hasRemoved) return;
    final pkg = event.packageName.toLowerCase();
    final text = '${event.title}\n${event.content}'.trim();
    if (text.isEmpty) return;

    final interesting = watchedPackages.any(pkg.contains) ||
        BankTxParser.detectSource(text, packageOrTitle: pkg) !=
            BankSource.unknown;
    if (!interesting) return;

    final parsed = BankTxParser.parse(text, packageOrTitle: pkg);
    if (parsed == null) return;

    final db = AppDatabase.instance;
    final accounts = await db.getAccounts();
    final accountId = accounts.isNotEmpty ? accounts.first.id : null;
    final now = DateTime.now().toUtc().toIso8601String();

    await db.insertPendingImport(
      PendingImport(
        id: db.newId(),
        rawText: text,
        source: parsed.source.name,
        amount: parsed.amount,
        type: parsed.type,
        merchant: parsed.merchant,
        txDate: isoDate(parsed.date ?? DateTime.now()),
        categoryId: parsed.suggestedCategoryId,
        accountId: accountId,
        status: PendingStatus.pending,
        createdAt: now,
      ),
    );
  }

  /// Manual path: paste SMS / notification text.
  Future<PendingImport?> importFromPaste(String raw) async {
    final parsed = BankTxParser.parse(raw);
    if (parsed == null) return null;
    final db = AppDatabase.instance;
    final accounts = await db.getAccounts();
    final accountId = accounts.isNotEmpty ? accounts.first.id : null;
    final now = DateTime.now().toUtc().toIso8601String();
    final item = PendingImport(
      id: db.newId(),
      rawText: raw.trim(),
      source: parsed.source.name,
      amount: parsed.amount,
      type: parsed.type,
      merchant: parsed.merchant,
      txDate: isoDate(parsed.date ?? DateTime.now()),
      categoryId: parsed.suggestedCategoryId,
      accountId: accountId,
      status: PendingStatus.pending,
      createdAt: now,
    );
    final inserted = await db.insertPendingImport(item);
    return inserted ? item : null;
  }
}
