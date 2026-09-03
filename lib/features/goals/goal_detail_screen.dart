import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models.dart';
import '../../providers/data_providers.dart';
import 'goal_form_sheet.dart';

class GoalDetailScreen extends ConsumerStatefulWidget {
  const GoalDetailScreen({super.key, required this.goalId});
  final String goalId;

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final goals = ref.watch(goalsProvider(true));

    return goals.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: StashColors.mint)),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (list) {
        Goal? g;
        for (final x in list) {
          if (x.id == widget.goalId) {
            g = x;
            break;
          }
        }
        if (g == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(s.noData)),
          );
        }
        final goal = g;
        return Scaffold(
          appBar: AppBar(
            title: Text(goal.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () =>
                    showGoalFormSheet(context, ref, existing: goal),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (goal.showPercent) ...[
                Text(
                  '${(goal.percent * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: StashColors.mint,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: goal.percent,
                    minHeight: 12,
                    backgroundColor: StashColors.surfaceHigh,
                    color: StashColors.mint,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (goal.showTarget)
                _row(s.targetAmount, formatMoney(goal.targetAmount)),
              if (goal.showSaved)
                _row(s.savedAmount, formatMoney(goal.savedAmount)),
              if (goal.showDeadline && goal.deadline != null)
                _row(s.deadline, goal.deadline!),
              if (goal.showMonthlySuggest && goal.monthlySuggest != null)
                _row(s.monthlySuggest, formatMoney(goal.monthlySuggest!)),
              if (goal.showNote && goal.note != null) _row(s.note, goal.note!),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _deposit(context, ref, goal, s),
                icon: const Icon(Icons.savings_outlined),
                label: Text(s.deposit),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () async {
                  final db = ref.read(databaseProvider);
                  final now = DateTime.now().toUtc().toIso8601String();
                  await db.upsertGoal(
                    goal.copyWith(
                      status: GoalStatus.archived,
                      updatedAt: now,
                    ),
                  );
                  bumpData(ref);
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: Text(s.archive),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: StashColors.textMuted)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _deposit(
    BuildContext context,
    WidgetRef ref,
    Goal g,
    AppStrings s,
  ) async {
    final ctrl = TextEditingController();
    final accounts = await ref.read(databaseProvider).getAccounts();
    String? accountId = accounts.isNotEmpty ? accounts.first.id : null;

    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              backgroundColor: StashColors.surface,
              title: Text(s.deposit),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: ctrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: s.amount,
                      prefixText: 'RM ',
                    ),
                  ),
                  if (accounts.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: accountId,
                      items: accounts
                          .map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setLocal(() => accountId = v),
                      decoration: InputDecoration(labelText: s.account),
                    ),
                  ],
                ],
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
            );
          },
        );
      },
    );

    final amount = double.tryParse(ctrl.text);
    if (ok != true || amount == null || amount <= 0) return;

    final db = ref.read(databaseProvider);
    final now = DateTime.now().toUtc().toIso8601String();
    await db.insertTransaction(
      MoneyTx(
        id: db.newId(),
        type: TxType.goalDeposit,
        amount: amount,
        date: isoDate(DateTime.now()),
        accountId: accountId,
        goalId: g.id,
        createdAt: now,
        updatedAt: now,
      ),
    );
    bumpData(ref);
  }
}
