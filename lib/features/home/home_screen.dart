import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../providers/data_providers.dart';
import '../bills/bill_detail_screen.dart';
import '../import/import_inbox_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final bills = ref.watch(billsProvider);
    final paidIds = ref.watch(paidBillIdsThisMonthProvider);
    final spend = ref.watch(spendCompareProvider);
    final pendingCount = ref.watch(pendingImportCountProvider);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.appName),
        actions: [
          if ((pendingCount.valueOrNull ?? 0) > 0)
            IconButton(
              tooltip: s.pendingImportsBadge,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ImportInboxScreen()),
              ),
              icon: Badge(
                label: Text('${pendingCount.valueOrNull}'),
                child: const Icon(Icons.inbox_outlined),
              ),
            ),
          IconButton(
            tooltip: s.reports,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReportsScreen()),
            ),
            icon: const Icon(Icons.insights_outlined),
          ),
          IconButton(
            tooltip: s.settings,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: StashColors.mint,
        onRefresh: () async => bumpData(ref),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            Text(
              longDateLabel(now, isZh: s.isZh),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              monthYearLabel(now, isZh: s.isZh),
              style: const TextStyle(color: StashColors.textMuted),
            ),
            const SizedBox(height: 16),

            Text(s.bills, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            bills.when(
              loading: () => const _LoadingBox(),
              error: (e, _) => Text('$e'),
              data: (list) {
                if (list.isEmpty) {
                  return _Panel(
                    child: Text(
                      s.emptyBills,
                      style: const TextStyle(color: StashColors.textMuted),
                    ),
                  );
                }
                final paid = paidIds.valueOrNull ?? {};
                return Column(
                  children: list.map((b) {
                    final done = paid.contains(b.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: StashColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BillDetailScreen(billId: b.id),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: done
                                    ? StashColors.mint.withValues(alpha: 0.45)
                                    : StashColors.amber.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  done
                                      ? Icons.check_circle
                                      : Icons.receipt_long_outlined,
                                  color: done
                                      ? StashColors.mint
                                      : StashColors.amber,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        b.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        done
                                            ? '${s.paidThisMonth} · ${s.tapToCheck}'
                                            : '${s.unpaidThisMonth} · ${s.tapToCheck}',
                                        style: const TextStyle(
                                          color: StashColors.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  formatMoney(b.amount),
                                  style: TextStyle(
                                    color: done
                                        ? StashColors.mint
                                        : StashColors.amber,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 18),

            Text(s.totalSpend, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ref.watch(monthlySpendSeriesProvider).when(
              loading: () => const _LoadingBox(),
              error: (e, _) => Text('$e'),
              data: (months) => _MonthlySpendCard(months: months, s: s),
            ),
            const SizedBox(height: 18),

            Text(s.spending, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            spend.when(
              loading: () => const _LoadingBox(),
              error: (e, _) => Text('$e'),
              data: (d) => _SpendBlock(d: d, s: s),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlySpendCard extends StatefulWidget {
  const _MonthlySpendCard({required this.months, required this.s});
  final List<MonthSpend> months;
  final AppStrings s;

  @override
  State<_MonthlySpendCard> createState() => _MonthlySpendCardState();
}

class _MonthlySpendCardState extends State<_MonthlySpendCard> {
  late int _index;
  late final PageController _page;

  @override
  void initState() {
    super.initState();
    _index = widget.months.isEmpty ? 0 : widget.months.length - 1;
    _page = PageController(initialPage: _index);
  }

  @override
  void didUpdateWidget(covariant _MonthlySpendCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.months.length != oldWidget.months.length &&
        widget.months.isNotEmpty) {
      _index = widget.months.length - 1;
    }
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i < 0 || i >= widget.months.length) return;
    setState(() => _index = i);
    if (_page.hasClients) {
      _page.animateToPage(
        i,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final months = widget.months;
    final s = widget.s;
    if (months.isEmpty) {
      return _Panel(
        child: Text(s.noData, style: const TextStyle(color: StashColors.textMuted)),
      );
    }
    final maxY = months.fold<double>(0, (m, e) => e.amount > m ? e.amount : m);
    final chartMax = maxY <= 0 ? 100.0 : maxY * 1.2;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.swipeOrTapMonth,
            style: const TextStyle(color: StashColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 88,
            child: PageView.builder(
              controller: _page,
              itemCount: months.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final m = months[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monthYearLabel(m.month, isZh: s.isZh),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatMoney(m.amount),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: StashColors.mint,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _index > 0 ? () => _select(_index - 1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(months.length, (i) {
                    final on = i == _index;
                    return Container(
                      width: on ? 16 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: on ? StashColors.mint : StashColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
              IconButton(
                onPressed: _index < months.length - 1
                    ? () => _select(_index + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: chartMax,
                minY: 0,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions) return;
                    final i = response?.spot?.touchedBarGroupIndex;
                    if (i != null) _select(i);
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final m = months[group.x.toInt()];
                      return BarTooltipItem(
                        '${monthShortLabel(m.month, isZh: s.isZh)}\n${formatMoney(m.amount)}',
                        const TextStyle(
                          color: StashColors.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= months.length) {
                          return const SizedBox.shrink();
                        }
                        final on = i == _index;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            monthShortLabel(months[i].month, isZh: s.isZh),
                            style: TextStyle(
                              fontSize: 11,
                              color: on ? StashColors.mint : StashColors.textMuted,
                              fontWeight: on ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: StashColors.border,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (var i = 0; i < months.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: months[i].amount <= 0 ? 0.01 : months[i].amount,
                          width: 18,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          color: i == _index
                              ? StashColors.mint
                              : StashColors.mintDim,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendBlock extends StatelessWidget {
  const _SpendBlock({required this.d, required this.s});
  final SpendCompare d;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.today, style: const TextStyle(color: StashColors.textMuted)),
              const SizedBox(height: 4),
              Text(
                longDateLabel(d.now, isZh: s.isZh),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                formatMoney(d.todaySpent),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _CompareCard(
          title: s.thisWeek,
          range:
              '${shortDate(d.weekStart)} – ${shortDate(d.weekEnd)}',
          amount: d.thisWeek,
          compareLabel: s.lastWeek,
          compareRange:
              '${shortDate(d.lastWeekStart)} – ${shortDate(d.lastWeekEnd)}',
          compareAmount: d.lastWeek,
          delta: d.weekDelta,
          s: s,
        ),
        const SizedBox(height: 10),
        _CompareCard(
          title: s.thisMonth,
          range: monthYearLabel(d.monthStart, isZh: s.isZh),
          amount: d.thisMonth,
          compareLabel: s.lastMonth,
          compareRange: monthYearLabel(d.lastMonthStart, isZh: s.isZh),
          compareAmount: d.lastMonth,
          delta: d.monthDelta,
          s: s,
        ),
      ],
    );
  }
}

class _CompareCard extends StatelessWidget {
  const _CompareCard({
    required this.title,
    required this.range,
    required this.amount,
    required this.compareLabel,
    required this.compareRange,
    required this.compareAmount,
    required this.delta,
    required this.s,
  });

  final String title;
  final String range;
  final double amount;
  final String compareLabel;
  final String compareRange;
  final double compareAmount;
  final double delta;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final up = delta > 0.005;
    final down = delta < -0.005;
    final color = up
        ? StashColors.coral
        : down
            ? StashColors.mint
            : StashColors.textMuted;
    final word = up
        ? s.moreThan
        : down
            ? s.lessThan
            : s.sameAs;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(range, style: const TextStyle(color: StashColors.textMuted, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            formatMoney(amount),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      compareLabel,
                      style: const TextStyle(color: StashColors.textMuted),
                    ),
                    Text(
                      compareRange,
                      style: const TextStyle(
                        color: StashColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatMoney(compareAmount),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${formatMoney(delta.abs())} $word',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
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

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: CircularProgressIndicator(color: StashColors.mint),
      ),
    );
  }
}
