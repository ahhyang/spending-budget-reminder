import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/app_database.dart';
import '../../data/models.dart';
import '../../providers/data_providers.dart';

class BillDetailScreen extends ConsumerWidget {
  const BillDetailScreen({super.key, required this.billId});
  final String billId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final bills = ref.watch(billsProvider);
    final payments = ref.watch(billPaymentsProvider(billId));

    return bills.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: StashColors.mint)),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (list) {
        Bill? found;
        for (final item in list) {
          if (item.id == billId) found = item;
        }
        if (found == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(s.noData)),
          );
        }
        final b = found;
        final now = DateTime.now();
        final currentYm = yearMonth(now);
        final paidSet = {
          for (final p in payments.valueOrNull ?? <BillPayment>[]) p.yearMonth,
        };
        final months = <DateTime>[
          for (var i = 0; i < 12; i++) DateTime(now.year, now.month - i, 1),
        ];

        return Scaffold(
          appBar: AppBar(title: Text(b.name)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                formatMoney(b.amount),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: StashColors.amber,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${s.nextDue}: ${b.nextDue}',
                style: const TextStyle(color: StashColors.textMuted),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final db = ref.read(databaseProvider);
                  if (paidSet.contains(currentYm)) {
                    await db.unmarkBillMonth(b.id, currentYm);
                  } else {
                    await db.markBillMonthPaid(bill: b, yearMonth: currentYm);
                    await _advanceDue(db, b);
                  }
                  bumpData(ref);
                },
                child: Text(
                  paidSet.contains(currentYm) ? s.unmarkMonth : s.markThisMonth,
                ),
              ),
              const SizedBox(height: 20),
              Text(s.monthsPaid, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...months.map((m) {
                final ym = yearMonth(m);
                final paid = paidSet.contains(ym);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: StashColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final db = ref.read(databaseProvider);
                        if (paid) {
                          await db.unmarkBillMonth(b.id, ym);
                        } else {
                          await db.markBillMonthPaid(bill: b, yearMonth: ym);
                        }
                        bumpData(ref);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: paid
                                ? StashColors.mint.withValues(alpha: 0.5)
                                : StashColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              paid
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: paid
                                  ? StashColors.mint
                                  : StashColors.textMuted,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                monthYearLabel(m, isZh: s.isZh),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              paid ? s.paid : s.pending,
                              style: TextStyle(
                                color: paid
                                    ? StashColors.mint
                                    : StashColors.amber,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

Future<void> _advanceDue(AppDatabase db, Bill b) async {
  final now = DateTime.now().toUtc().toIso8601String();
  var next = DateTime.parse(b.nextDue);
  switch (b.cycle) {
    case BillCycle.monthly:
      next = DateTime(next.year, next.month + 1, next.day);
    case BillCycle.quarterly:
      next = DateTime(next.year, next.month + 3, next.day);
    case BillCycle.yearly:
      next = DateTime(next.year + 1, next.month, next.day);
    case BillCycle.once:
      await db.upsertBill(b.copyWith(status: BillStatus.paid, updatedAt: now));
      return;
  }
  await db.upsertBill(
    b.copyWith(status: BillStatus.pending, nextDue: isoDate(next), updatedAt: now),
  );
}
