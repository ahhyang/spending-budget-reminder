import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models.dart';
import '../../providers/data_providers.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final budgets = ref.watch(budgetsProvider);
    final snaps = ref.watch(budgetSnapshotsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.budget)),
      body: budgets.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: StashColors.mint),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: BudgetPeriod.values.map((period) {
              Budget? b;
              for (final x in list) {
                if (x.period == period) {
                  b = x;
                  break;
                }
              }
              BudgetSnapshot? snap;
              for (final x in snaps.valueOrNull ?? <BudgetSnapshot>[]) {
                if (x.period == period) {
                  snap = x;
                  break;
                }
              }
              final label = switch (period) {
                BudgetPeriod.day => s.daily,
                BudgetPeriod.week => s.weekly,
                BudgetPeriod.month => s.monthly,
              };
              return Card(
                child: ListTile(
                  title: Text(label),
                  subtitle: snap == null
                      ? null
                      : Text(
                          '${s.spent}: ${snap.spent.toStringAsFixed(2)}'
                          '${snap.isOver ? ' · ${s.overBudget}' : ''}',
                          style: TextStyle(
                            color: snap.isOver
                                ? StashColors.coral
                                : StashColors.textMuted,
                          ),
                        ),
                  trailing: Text(
                    b == null ? '—' : 'RM ${b.amount.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () => _edit(context, ref, s, period, b?.amount ?? 0),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    AppStrings s,
    BudgetPeriod period,
    double current,
  ) async {
    final ctrl = TextEditingController(text: current.toStringAsFixed(0));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: StashColors.surface,
        title: Text(s.setBudgets),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: s.amount, prefixText: 'RM '),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.save),
          ),
        ],
      ),
    );
    final amount = double.tryParse(ctrl.text);
    if (ok != true || amount == null || amount < 0) return;
    final db = ref.read(databaseProvider);
    final now = DateTime.now().toUtc().toIso8601String();
    await db.upsertBudget(
      Budget(
        id: 'budget_${period.name}',
        period: period,
        amount: amount,
        updatedAt: now,
      ),
    );
    bumpData(ref);
  }
}
