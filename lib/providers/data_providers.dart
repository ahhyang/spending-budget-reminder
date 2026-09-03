import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/format.dart';
import '../data/app_database.dart';
import '../data/models.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

final dataRevisionProvider = StateProvider<int>((ref) => 0);

void bumpData(WidgetRef ref) {
  ref.read(dataRevisionProvider.notifier).state++;
}

final accountsProvider = FutureProvider<List<Account>>((ref) async {
  ref.watch(dataRevisionProvider);
  return ref.read(databaseProvider).getAccounts();
});

final goalsProvider = FutureProvider.family<List<Goal>, bool>((ref, archived) async {
  ref.watch(dataRevisionProvider);
  return ref.read(databaseProvider).getGoals(includeArchived: archived);
});

final categoriesProvider =
    FutureProvider.family<List<Category>, TxType?>((ref, kind) async {
  ref.watch(dataRevisionProvider);
  return ref.read(databaseProvider).getCategories(kind: kind);
});

final transactionsProvider = FutureProvider<List<MoneyTx>>((ref) async {
  ref.watch(dataRevisionProvider);
  return ref.read(databaseProvider).getTransactions();
});

final budgetsProvider = FutureProvider<List<Budget>>((ref) async {
  ref.watch(dataRevisionProvider);
  return ref.read(databaseProvider).getBudgets();
});

final billsProvider = FutureProvider<List<Bill>>((ref) async {
  ref.watch(dataRevisionProvider);
  return ref.read(databaseProvider).getBills();
});

final templatesProvider = FutureProvider<List<RecurringTemplate>>((ref) async {
  ref.watch(dataRevisionProvider);
  return ref.read(databaseProvider).getTemplates();
});

final pendingImportsProvider = FutureProvider<List<PendingImport>>((ref) async {
  ref.watch(dataRevisionProvider);
  return ref.read(databaseProvider).getPendingImports();
});

final pendingImportCountProvider = FutureProvider<int>((ref) async {
  ref.watch(dataRevisionProvider);
  return ref.read(databaseProvider).countPendingImports();
});

class BudgetSnapshot {
  BudgetSnapshot({
    required this.period,
    required this.limit,
    required this.spent,
  });

  final BudgetPeriod period;
  final double limit;
  final double spent;

  double get remaining => limit - spent;
  bool get isOver => spent > limit && limit > 0;
  double get progress => limit <= 0 ? 0 : (spent / limit).clamp(0, 1.5);
}

final budgetSnapshotsProvider = FutureProvider<List<BudgetSnapshot>>((ref) async {
  ref.watch(dataRevisionProvider);
  final db = ref.read(databaseProvider);
  final budgets = await db.getBudgets();
  final now = DateTime.now();
  final results = <BudgetSnapshot>[];

  for (final b in budgets) {
    late String from;
    late String to;
    switch (b.period) {
      case BudgetPeriod.day:
        from = to = isoDate(now);
      case BudgetPeriod.week:
        from = isoDate(startOfWeek(now));
        to = isoDate(now);
      case BudgetPeriod.month:
        from = isoDate(startOfMonth(now));
        to = isoDate(now);
    }
    final spent = await db.sumExpensesBetween(from, to);
    results.add(BudgetSnapshot(period: b.period, limit: b.amount, spent: spent));
  }
  return results;
});

final totalBalanceProvider = Provider<AsyncValue<double>>((ref) {
  return ref.watch(accountsProvider).whenData(
        (list) => list.fold<double>(0, (s, a) => s + a.balance),
      );
});

class SpendCompare {
  SpendCompare({
    required this.now,
    required this.todaySpent,
    required this.thisWeek,
    required this.lastWeek,
    required this.thisMonth,
    required this.lastMonth,
    required this.weekStart,
    required this.weekEnd,
    required this.lastWeekStart,
    required this.lastWeekEnd,
    required this.monthStart,
    required this.lastMonthStart,
    required this.lastMonthEnd,
  });

  final DateTime now;
  final double todaySpent;
  final double thisWeek;
  final double lastWeek;
  final double thisMonth;
  final double lastMonth;
  final DateTime weekStart;
  final DateTime weekEnd;
  final DateTime lastWeekStart;
  final DateTime lastWeekEnd;
  final DateTime monthStart;
  final DateTime lastMonthStart;
  final DateTime lastMonthEnd;

  double get weekDelta => thisWeek - lastWeek;
  double get monthDelta => thisMonth - lastMonth;
}

class MonthSpend {
  MonthSpend({required this.month, required this.amount});
  final DateTime month;
  final double amount;
}

final monthlySpendSeriesProvider = FutureProvider<List<MonthSpend>>((ref) async {
  ref.watch(dataRevisionProvider);
  final db = ref.read(databaseProvider);
  final now = DateTime.now();
  const count = 6;
  final list = <MonthSpend>[];
  for (var i = count - 1; i >= 0; i--) {
    final m = DateTime(now.year, now.month - i, 1);
    final from = isoDate(startOfMonth(m));
    final to = i == 0 ? isoDate(now) : isoDate(endOfMonth(m));
    final amount = await db.sumExpensesBetween(from, to);
    list.add(MonthSpend(month: m, amount: amount));
  }
  return list;
});

final spendCompareProvider = FutureProvider<SpendCompare>((ref) async {
  ref.watch(dataRevisionProvider);
  final db = ref.read(databaseProvider);
  final now = DateTime.now();
  final today = isoDate(now);
  final weekStart = startOfWeek(now);
  final weekEnd = endOfWeek(now);
  final lastWeekStart = startOfLastWeek(now);
  final lastWeekEnd = lastWeekStart.add(const Duration(days: 6));
  final monthStart = startOfMonth(now);
  final lastMonthStart = startOfMonth(DateTime(now.year, now.month - 1, 1));
  final lastMonthEnd = endOfMonth(lastMonthStart);

  return SpendCompare(
    now: now,
    todaySpent: await db.sumExpensesBetween(today, today),
    thisWeek: await db.sumExpensesBetween(isoDate(weekStart), isoDate(now)),
    lastWeek: await db.sumExpensesBetween(
      isoDate(lastWeekStart),
      isoDate(lastWeekEnd),
    ),
    thisMonth: await db.sumExpensesBetween(isoDate(monthStart), isoDate(now)),
    lastMonth: await db.sumExpensesBetween(
      isoDate(lastMonthStart),
      isoDate(lastMonthEnd),
    ),
    weekStart: weekStart,
    weekEnd: weekEnd,
    lastWeekStart: lastWeekStart,
    lastWeekEnd: lastWeekEnd,
    monthStart: monthStart,
    lastMonthStart: lastMonthStart,
    lastMonthEnd: lastMonthEnd,
  );
});

final paidBillIdsThisMonthProvider = FutureProvider<Set<String>>((ref) async {
  ref.watch(dataRevisionProvider);
  return ref.read(databaseProvider).paidMonthsThisMonth(yearMonth(DateTime.now()));
});

final billPaymentsProvider =
    FutureProvider.family<List<BillPayment>, String>((ref, billId) async {
  ref.watch(dataRevisionProvider);
  return ref.read(databaseProvider).getBillPayments(billId);
});
