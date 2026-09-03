import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models.dart';
import '../../providers/data_providers.dart';
import 'goal_detail_screen.dart';
import 'goal_form_sheet.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final goals = ref.watch(goalsProvider(false));

    return Scaffold(
      appBar: AppBar(
        title: Text(s.goals),
        actions: [
          IconButton(
            onPressed: () => showGoalFormSheet(context, ref),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: goals.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: StashColors.mint),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.emptyGoals,
                    style: const TextStyle(color: StashColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => showGoalFormSheet(context, ref),
                    child: Text(s.newGoal),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final g = list[i];
              return InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GoalDetailScreen(goalId: g.id),
                  ),
                ),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: StashColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: StashColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              g.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            _typeLabel(s, g.type),
                            style: const TextStyle(
                              color: StashColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      if (g.showPercent) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: g.percent,
                            minHeight: 8,
                            backgroundColor: StashColors.surfaceHigh,
                            color: StashColors.mint,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${(g.percent * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(color: StashColors.mint),
                        ),
                      ],
                      if (g.showSaved || g.showTarget) ...[
                        const SizedBox(height: 8),
                        Text(
                          [
                            if (g.showSaved) formatMoney(g.savedAmount),
                            if (g.showSaved && g.showTarget) ' / ',
                            if (g.showTarget) formatMoney(g.targetAmount),
                          ].join(),
                          style: const TextStyle(color: StashColors.textMuted),
                        ),
                      ],
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

String _typeLabel(AppStrings s, GoalType t) => switch (t) {
      GoalType.travel => s.travel,
      GoalType.emergency => s.emergency,
      GoalType.downPayment => s.downPayment,
      GoalType.custom => s.custom,
    };
