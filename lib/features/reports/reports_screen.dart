import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models.dart';
import '../../providers/data_providers.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.reports)),
      body: FutureBuilder<_ReportData>(
        future: _load(ref),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: StashColors.mint),
            );
          }
          final d = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.thisMonth,
                        style: const TextStyle(color: StashColors.textMuted)),
                    const SizedBox(height: 6),
                    Text(
                      formatMoney(d.monthSpent),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${s.vsLastMonth}: ${formatMoney(d.lastMonthSpent)}'
                      ' (${d.deltaLabel})',
                      style: TextStyle(
                        color: d.monthSpent > d.lastMonthSpent
                            ? StashColors.coral
                            : StashColors.mint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(s.byCategory, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _panel(
                child: d.byCat.isEmpty
                    ? Text(s.noData,
                        style: const TextStyle(color: StashColors.textMuted))
                    : SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 36,
                            sections: [
                              for (var i = 0; i < d.byCat.length; i++)
                                PieChartSectionData(
                                  value: d.byCat[i].total,
                                  title: d.byCat[i].label,
                                  radius: 50,
                                  color: _colors[i % _colors.length],
                                  titleStyle: const TextStyle(
                                    fontSize: 10,
                                    color: StashColors.text,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 14),
              Text(s.trend, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _panel(
                child: d.trend.isEmpty
                    ? Text(s.noData,
                        style: const TextStyle(color: StashColors.textMuted))
                    : SizedBox(
                        height: 180,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  for (var i = 0; i < d.trend.length; i++)
                                    FlSpot(i.toDouble(), d.trend[i]),
                                ],
                                isCurved: true,
                                color: StashColors.mint,
                                barWidth: 3,
                                dotData: const FlDotData(show: false),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 14),
              Text(s.savingsProgress,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _panel(
                child: d.goals.isEmpty
                    ? Text(s.noData,
                        style: const TextStyle(color: StashColors.textMuted))
                    : Column(
                        children: d.goals.map((g) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(child: Text(g.name)),
                                Text(
                                  '${(g.percent * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(color: StashColors.mint),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<_ReportData> _load(WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final now = DateTime.now();
    final from = isoDate(startOfMonth(now));
    final to = isoDate(now);
    final lastStart = startOfMonth(DateTime(now.year, now.month - 1, 1));
    final lastEnd = endOfMonth(lastStart);
    final monthSpent = await db.sumExpensesBetween(from, to);
    final lastMonthSpent =
        await db.sumExpensesBetween(isoDate(lastStart), isoDate(lastEnd));
    final cats = await db.getCategories(kind: TxType.expense);
    final catMap = {for (final c in cats) c.id: c};
    final s = ref.read(stringsProvider);
    final raw = await db.expenseByCategory(from, to);
    final byCat = raw
        .where((r) => (r['total'] as num) > 0)
        .map((r) {
          final id = r['category_id'] as String?;
          final label = id != null
              ? (catMap[id]?.label(s.isZh) ?? '?')
              : '?';
          return _CatSlice(label: label, total: (r['total'] as num).toDouble());
        })
        .toList();
    final trendRaw = await db.dailyExpenseTrend(from, to);
    final trend =
        trendRaw.map((r) => (r['total'] as num).toDouble()).toList();
    final goals = await db.getGoals();
    final delta = monthSpent - lastMonthSpent;
    final deltaLabel = '${delta >= 0 ? '+' : ''}${formatMoney(delta)}';
    return _ReportData(
      monthSpent: monthSpent,
      lastMonthSpent: lastMonthSpent,
      deltaLabel: deltaLabel,
      byCat: byCat,
      trend: trend,
      goals: goals,
    );
  }

  Widget _panel({required Widget child}) {
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

const _colors = [
  StashColors.mint,
  StashColors.amber,
  StashColors.coral,
  Color(0xFF6C8CFF),
  Color(0xFFB07CFF),
  Color(0xFF4ECDC4),
];

class _CatSlice {
  _CatSlice({required this.label, required this.total});
  final String label;
  final double total;
}

class _ReportData {
  _ReportData({
    required this.monthSpent,
    required this.lastMonthSpent,
    required this.deltaLabel,
    required this.byCat,
    required this.trend,
    required this.goals,
  });

  final double monthSpent;
  final double lastMonthSpent;
  final String deltaLabel;
  final List<_CatSlice> byCat;
  final List<double> trend;
  final List<Goal> goals;
}
