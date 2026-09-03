import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models.dart';
import '../../providers/data_providers.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final txs = ref.watch(transactionsProvider);
    final cats = ref.watch(categoriesProvider(null));

    return Scaffold(
      appBar: AppBar(title: Text(s.activity)),
      body: txs.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: StashColors.mint),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Text(
                s.emptyActivity,
                style: const TextStyle(color: StashColors.textMuted),
              ),
            );
          }
          final catMap = {
            for (final c in cats.valueOrNull ?? <Category>[]) c.id: c,
          };
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final tx = list[i];
              final cat = tx.categoryId != null ? catMap[tx.categoryId] : null;
              final isExpense = tx.type == TxType.expense;
              final color =
                  isExpense ? StashColors.expense : StashColors.income;
              final prefix = isExpense ? '−' : '+';
              return Dismissible(
                key: ValueKey(tx.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: StashColors.coral.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(s.delete, style: const TextStyle(color: StashColors.coral)),
                ),
                onDismissed: (_) async {
                  await ref.read(databaseProvider).deleteTransaction(tx);
                  bumpData(ref);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: StashColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: StashColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isExpense
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: color,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat?.label(s.isZh) ??
                                  (tx.type == TxType.goalDeposit
                                      ? s.deposit
                                      : s.custom),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              tx.date,
                              style: const TextStyle(
                                color: StashColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$prefix${formatMoney(tx.amount)}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
