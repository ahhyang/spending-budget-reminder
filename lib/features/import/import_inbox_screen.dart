import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/bank_notification_watcher.dart';
import '../../data/bank_parser.dart';
import '../../data/models.dart';
import '../../providers/data_providers.dart';

class ImportInboxScreen extends ConsumerStatefulWidget {
  const ImportInboxScreen({super.key});

  @override
  ConsumerState<ImportInboxScreen> createState() => _ImportInboxScreenState();
}

class _ImportInboxScreenState extends ConsumerState<ImportInboxScreen> {
  final _pasteCtrl = TextEditingController();
  bool _listening = false;
  bool _hasPerm = false;

  @override
  void initState() {
    super.initState();
    _refreshPerm();
  }

  @override
  void dispose() {
    _pasteCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshPerm() async {
    final watcher = BankNotificationWatcher.instance;
    final has = await watcher.hasPermission();
    if (mounted) {
      setState(() {
        _hasPerm = has;
        _listening = watcher.isRunning;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final pending = ref.watch(pendingImportsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.bankImport)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.autoListen,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  s.autoListenHint,
                  style: const TextStyle(
                    color: StashColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton(
                      onPressed: () async {
                        final watcher = BankNotificationWatcher.instance;
                        if (!_hasPerm) {
                          await watcher.requestPermission();
                          await _refreshPerm();
                        }
                        if (_hasPerm || await watcher.hasPermission()) {
                          await watcher.start();
                          if (mounted) {
                            setState(() {
                              _hasPerm = true;
                              _listening = true;
                            });
                          }
                        }
                      },
                      child: Text(
                        _listening ? s.listeningOn : s.enableListen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _hasPerm ? s.permissionOn : s.permissionOff,
                      style: TextStyle(
                        color: _hasPerm ? StashColors.mint : StashColors.amber,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(s.pasteSms, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _pasteCtrl,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: s.pasteSmsHint,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () async {
              final text = _pasteCtrl.text.trim();
              if (text.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              final item =
                  await BankNotificationWatcher.instance.importFromPaste(text);
              bumpData(ref);
              if (!mounted) return;
              if (item == null) {
                messenger.showSnackBar(
                  SnackBar(content: Text(s.parseFailed)),
                );
              } else {
                _pasteCtrl.clear();
                messenger.showSnackBar(
                  SnackBar(content: Text(s.importQueued)),
                );
              }
            },
            child: Text(s.parseAndQueue),
          ),
          const SizedBox(height: 20),
          Text(s.pendingReview, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          pending.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: StashColors.mint),
            ),
            error: (e, _) => Text('$e'),
            data: (list) {
              if (list.isEmpty) {
                return _card(
                  child: Text(
                    s.noPendingImports,
                    style: const TextStyle(color: StashColors.textMuted),
                  ),
                );
              }
              return Column(
                children: list
                    .map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PendingCard(item: item),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StashColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StashColors.border),
      ),
      child: child,
    );
  }
}

class _PendingCard extends ConsumerWidget {
  const _PendingCard({required this.item});
  final PendingImport item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final cats = ref.watch(categoriesProvider(item.type));
    final accounts = ref.watch(accountsProvider);
    final isExpense = item.type == TxType.expense;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StashColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: StashColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.merchant ?? BankTxParser.sourceLabel(
                    BankSource.values.byName(item.source),
                    isZh: s.isZh,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${isExpense ? '−' : '+'}${formatMoney(item.amount)}',
                style: TextStyle(
                  color: isExpense ? StashColors.expense : StashColors.income,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${item.txDate} · ${BankTxParser.sourceLabel(BankSource.values.byName(item.source), isZh: s.isZh)}',
            style: const TextStyle(color: StashColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            item.rawText,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: StashColors.textMuted),
          ),
          const SizedBox(height: 10),
          cats.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (list) {
              return DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: item.categoryId ??
                    (list.isNotEmpty ? list.first.id : null),
                decoration: InputDecoration(labelText: s.category),
                items: list
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.label(s.isZh)),
                      ),
                    )
                    .toList(),
                onChanged: (v) async {
                  if (v == null) return;
                  await ref
                      .read(databaseProvider)
                      .updatePendingImport(item.copyWith(categoryId: v));
                  bumpData(ref);
                },
              );
            },
          ),
          const SizedBox(height: 8),
          accounts.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (list) {
              if (list.isEmpty) return const SizedBox.shrink();
              return DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: item.accountId ?? list.first.id,
                decoration: InputDecoration(labelText: s.account),
                items: list
                    .map(
                      (a) => DropdownMenuItem(
                        value: a.id,
                        child: Text(a.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) async {
                  if (v == null) return;
                  await ref
                      .read(databaseProvider)
                      .updatePendingImport(item.copyWith(accountId: v));
                  bumpData(ref);
                },
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton(
                onPressed: () async {
                  await ref.read(databaseProvider).acceptPendingImport(
                        item,
                        accountId: item.accountId,
                        categoryId: item.categoryId,
                      );
                  bumpData(ref);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.saved)),
                    );
                  }
                },
                child: Text(s.confirmImport),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () async {
                  await ref.read(databaseProvider).dismissPendingImport(item);
                  bumpData(ref);
                },
                child: Text(s.dismiss),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
