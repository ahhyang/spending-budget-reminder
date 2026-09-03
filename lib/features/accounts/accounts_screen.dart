import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models.dart';
import '../../providers/data_providers.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final accounts = ref.watch(accountsProvider);
    final goals = ref.watch(goalsProvider(false));

    return Scaffold(
      appBar: AppBar(
        title: Text(s.manageAccounts),
        actions: [
          IconButton(
            onPressed: () => _editAccount(context, ref),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: accounts.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: StashColors.mint),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(child: Text(s.emptyAccounts));
          }
          final goalMap = {
            for (final g in goals.valueOrNull ?? <Goal>[]) g.id: g,
          };
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final a = list[i];
              final bound = a.goalId != null ? goalMap[a.goalId] : null;
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
                            a.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          formatMoney(a.balance),
                          style: const TextStyle(
                            color: StashColors.mint,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bound == null
                          ? '${s.bindGoal}: ${s.unbound}'
                          : '${s.bindGoal}: ${bound.name}',
                      style: const TextStyle(color: StashColors.textMuted),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => _editAccount(context, ref, existing: a),
                          child: Text(s.edit),
                        ),
                        TextButton(
                          onPressed: () => _bindGoal(context, ref, a, s),
                          child: Text(s.bindGoal),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () async {
                            await ref.read(databaseProvider).deleteAccount(a.id);
                            bumpData(ref);
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: StashColors.coral,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _editAccount(
    BuildContext context,
    WidgetRef ref, {
    Account? existing,
  }) async {
    final s = ref.read(stringsProvider);
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final balCtrl = TextEditingController(
      text: existing != null ? existing.balance.toStringAsFixed(2) : '0',
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: StashColors.surface,
        title: Text(existing == null ? s.newAccount : s.edit),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: s.name),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: balCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: s.balance),
            ),
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
      ),
    );

    final bal = double.tryParse(balCtrl.text);
    if (ok != true || nameCtrl.text.trim().isEmpty || bal == null) return;

    final db = ref.read(databaseProvider);
    final now = DateTime.now().toUtc().toIso8601String();
    await db.upsertAccount(
      Account(
        id: existing?.id ?? db.newId(),
        name: nameCtrl.text.trim(),
        balance: bal,
        goalId: existing?.goalId,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ),
    );
    bumpData(ref);
  }

  Future<void> _bindGoal(
    BuildContext context,
    WidgetRef ref,
    Account account,
    AppStrings s,
  ) async {
    final db = ref.read(databaseProvider);
    final goals = await db.getGoals();
    String? selected = account.goalId;

    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              backgroundColor: StashColors.surface,
              title: Text(s.bindGoal),
              content: DropdownButtonFormField<String?>(
                // ignore: deprecated_member_use
                value: selected,
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(s.unbound),
                  ),
                  ...goals.map(
                    (g) => DropdownMenuItem<String?>(
                      value: g.id,
                      child: Text(g.name),
                    ),
                  ),
                ],
                onChanged: (v) => setLocal(() => selected = v),
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

    if (ok != true) return;

    if (selected != null) {
      final taken = await db.accountByGoal(selected!);
      if (taken != null && taken.id != account.id) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.goalBound)),
          );
        }
        return;
      }
    }

    final now = DateTime.now().toUtc().toIso8601String();
    await db.upsertAccount(
      account.copyWith(
        goalId: selected,
        clearGoalId: selected == null,
        updatedAt: now,
      ),
    );
    bumpData(ref);
  }
}
