import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/format.dart';
import 'models.dart';

const _uuid = Uuid();

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'stash.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await _createV1(db);
        await _createPendingImports(db);
        await _createBillPayments(db);
        await _seed(db);
        await _seedMaintenanceBill(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createPendingImports(db);
          await _seedMaintenanceBill(db);
        }
        if (oldVersion < 3) {
          await _createBillPayments(db);
        }
      },
    );
  }

  Future<void> _createV1(Database db) async {
        await db.execute('''
CREATE TABLE accounts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  balance REAL NOT NULL DEFAULT 0,
  goal_id TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)''');
        await db.execute('''
CREATE TABLE goals (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  target_amount REAL NOT NULL,
  saved_amount REAL NOT NULL DEFAULT 0,
  deadline TEXT,
  note TEXT,
  show_target INTEGER DEFAULT 1,
  show_saved INTEGER DEFAULT 1,
  show_deadline INTEGER DEFAULT 1,
  show_monthly_suggest INTEGER DEFAULT 0,
  show_percent INTEGER DEFAULT 1,
  show_note INTEGER DEFAULT 0,
  status TEXT DEFAULT 'active',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)''');
        await db.execute('''
CREATE TABLE categories (
  id TEXT PRIMARY KEY,
  name_en TEXT NOT NULL,
  name_zh TEXT NOT NULL,
  kind TEXT NOT NULL,
  is_system INTEGER DEFAULT 0
)''');
        await db.execute('''
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  amount REAL NOT NULL,
  date TEXT NOT NULL,
  category_id TEXT,
  account_id TEXT,
  goal_id TEXT,
  note TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)''');
        await db.execute('''
CREATE TABLE budgets (
  id TEXT PRIMARY KEY,
  period TEXT NOT NULL UNIQUE,
  amount REAL NOT NULL,
  updated_at TEXT NOT NULL
)''');
        await db.execute('''
CREATE TABLE bills (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  amount REAL NOT NULL,
  next_due TEXT NOT NULL,
  cycle TEXT NOT NULL,
  status TEXT NOT NULL,
  add_to_calendar INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)''');
        await db.execute('''
CREATE TABLE recurring_templates (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  amount REAL NOT NULL,
  category_id TEXT,
  account_id TEXT,
  day_of_month INTEGER,
  created_at TEXT NOT NULL
)''');
  }

  Future<void> _createPendingImports(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS pending_imports (
  id TEXT PRIMARY KEY,
  raw_text TEXT NOT NULL,
  source TEXT NOT NULL,
  amount REAL NOT NULL,
  type TEXT NOT NULL,
  merchant TEXT,
  tx_date TEXT NOT NULL,
  category_id TEXT,
  account_id TEXT,
  status TEXT NOT NULL,
  created_at TEXT NOT NULL
)''');
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_pending_raw ON pending_imports(raw_text)',
    );
  }

  Future<void> _createBillPayments(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS bill_payments (
  id TEXT PRIMARY KEY,
  bill_id TEXT NOT NULL,
  year_month TEXT NOT NULL,
  paid_on TEXT NOT NULL,
  amount REAL NOT NULL
)''');
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_bill_month ON bill_payments(bill_id, year_month)',
    );
  }

  Future<void> _seedMaintenanceBill(Database db) async {
    final existing = await db.query(
      'bills',
      where: 'id = ?',
      whereArgs: ['bill_maintenance'],
    );
    if (existing.isNotEmpty) return;
    final now = DateTime.now();
    final next = DateTime(now.year, now.month + 1, 1);
    final ts = now.toUtc().toIso8601String();
    await db.insert('bills', {
      'id': 'bill_maintenance',
      'name': 'Maintenance fee',
      'amount': 150,
      'next_due':
          '${next.year.toString().padLeft(4, '0')}-${next.month.toString().padLeft(2, '0')}-01',
      'cycle': BillCycle.monthly.name,
      'status': BillStatus.pending.name,
      'add_to_calendar': 0,
      'created_at': ts,
      'updated_at': ts,
    });
  }

  Future<void> _seed(Database db) async {
    final now = DateTime.now().toUtc().toIso8601String();

    Future<void> cat(String id, String en, String zh, TxType kind) async {
      await db.insert('categories', {
        'id': id,
        'name_en': en,
        'name_zh': zh,
        'kind': kind.name,
        'is_system': 1,
      });
    }

    await cat('c_food', 'Food', '餐饮', TxType.expense);
    await cat('c_transport', 'Transport', '交通', TxType.expense);
    await cat('c_shopping', 'Shopping', '购物', TxType.expense);
    await cat('c_bills', 'Bills', '账单', TxType.expense);
    await cat('c_other_exp', 'Other', '其他', TxType.expense);
    await cat('c_salary', 'Salary', '工资', TxType.income);
    await cat('c_bonus', 'Bonus', '奖金', TxType.income);
    await cat('c_other_inc', 'Other', '其他', TxType.income);

    await db.insert('accounts', {
      'id': 'acc_main',
      'name': 'Hong Leong',
      'balance': 0,
      'goal_id': null,
      'created_at': now,
      'updated_at': now,
    });

    for (final period in BudgetPeriod.values) {
      await db.insert('budgets', {
        'id': 'budget_${period.name}',
        'period': period.name,
        'amount': period == BudgetPeriod.month
            ? 2000
            : period == BudgetPeriod.week
                ? 500
                : 70,
        'updated_at': now,
      });
    }
  }

  String newId() => _uuid.v4();

  // —— Accounts ——
  Future<List<Account>> getAccounts() async {
    final db = await database;
    final rows = await db.query('accounts', orderBy: 'name ASC');
    return rows.map(Account.fromMap).toList();
  }

  Future<void> upsertAccount(Account a) async {
    final db = await database;
    await db.insert(
      'accounts',
      a.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAccount(String id) async {
    final db = await database;
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  Future<Account?> accountByGoal(String goalId) async {
    final db = await database;
    final rows = await db.query(
      'accounts',
      where: 'goal_id = ?',
      whereArgs: [goalId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Account.fromMap(rows.first);
  }

  // —— Goals ——
  Future<List<Goal>> getGoals({bool includeArchived = false}) async {
    final db = await database;
    final rows = includeArchived
        ? await db.query('goals', orderBy: 'created_at DESC')
        : await db.query(
            'goals',
            where: 'status = ?',
            whereArgs: [GoalStatus.active.name],
            orderBy: 'created_at DESC',
          );
    return rows.map(Goal.fromMap).toList();
  }

  Future<Goal?> getGoal(String id) async {
    final db = await database;
    final rows = await db.query('goals', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Goal.fromMap(rows.first);
  }

  Future<void> upsertGoal(Goal g) async {
    final db = await database;
    await db.insert(
      'goals',
      g.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteGoal(String id) async {
    final db = await database;
    await db.update(
      'accounts',
      {'goal_id': null},
      where: 'goal_id = ?',
      whereArgs: [id],
    );
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  // —— Categories ——
  Future<List<Category>> getCategories({TxType? kind}) async {
    final db = await database;
    final rows = kind == null
        ? await db.query('categories', orderBy: 'name_en ASC')
        : await db.query(
            'categories',
            where: 'kind = ?',
            whereArgs: [kind.name],
            orderBy: 'name_en ASC',
          );
    return rows.map(Category.fromMap).toList();
  }

  Future<void> upsertCategory(Category c) async {
    final db = await database;
    await db.insert(
      'categories',
      c.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete(
      'categories',
      where: 'id = ? AND is_system = 0',
      whereArgs: [id],
    );
  }

  // —— Transactions ——
  Future<List<MoneyTx>> getTransactions({int? limit}) async {
    final db = await database;
    final rows = await db.query(
      'transactions',
      orderBy: 'date DESC, created_at DESC',
      limit: limit,
    );
    return rows.map(MoneyTx.fromMap).toList();
  }

  Future<void> insertTransaction(MoneyTx tx) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('transactions', tx.toMap());
      if (tx.accountId != null) {
        // expense & goalDeposit reduce liquid balance; income increases it
        final delta = tx.type == TxType.income ? tx.amount : -tx.amount;
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ?, updated_at = ? WHERE id = ?',
          [delta, tx.updatedAt, tx.accountId],
        );
      }
      if (tx.type == TxType.goalDeposit && tx.goalId != null) {
        await txn.rawUpdate(
          'UPDATE goals SET saved_amount = saved_amount + ?, updated_at = ? WHERE id = ?',
          [tx.amount, tx.updatedAt, tx.goalId],
        );
      }
    });
  }

  Future<void> deleteTransaction(MoneyTx tx) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('transactions', where: 'id = ?', whereArgs: [tx.id]);
      if (tx.accountId != null) {
        final delta = tx.type == TxType.income ? -tx.amount : tx.amount;
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ?, updated_at = ? WHERE id = ?',
          [delta, DateTime.now().toUtc().toIso8601String(), tx.accountId],
        );
      }
      if (tx.type == TxType.goalDeposit && tx.goalId != null) {
        await txn.rawUpdate(
          'UPDATE goals SET saved_amount = saved_amount - ?, updated_at = ? WHERE id = ?',
          [
            tx.amount,
            DateTime.now().toUtc().toIso8601String(),
            tx.goalId,
          ],
        );
      }
    });
  }

  Future<double> sumExpensesBetween(String from, String to) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
SELECT COALESCE(SUM(amount), 0) AS total FROM transactions
WHERE type = ? AND date >= ? AND date <= ?
''',
      [TxType.expense.name, from, to],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<double> sumIncomeBetween(String from, String to) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
SELECT COALESCE(SUM(amount), 0) AS total FROM transactions
WHERE type = ? AND date >= ? AND date <= ?
''',
      [TxType.income.name, from, to],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<List<Map<String, Object?>>> expenseByCategory(
    String from,
    String to,
  ) async {
    final db = await database;
    return db.rawQuery(
      '''
SELECT category_id, COALESCE(SUM(amount), 0) AS total
FROM transactions
WHERE type = ? AND date >= ? AND date <= ?
GROUP BY category_id
ORDER BY total DESC
''',
      [TxType.expense.name, from, to],
    );
  }

  Future<List<Map<String, Object?>>> dailyExpenseTrend(
    String from,
    String to,
  ) async {
    final db = await database;
    return db.rawQuery(
      '''
SELECT date, COALESCE(SUM(amount), 0) AS total
FROM transactions
WHERE type = ? AND date >= ? AND date <= ?
GROUP BY date
ORDER BY date ASC
''',
      [TxType.expense.name, from, to],
    );
  }

  // —— Budgets ——
  Future<List<Budget>> getBudgets() async {
    final db = await database;
    final rows = await db.query('budgets');
    return rows.map(Budget.fromMap).toList();
  }

  Future<void> upsertBudget(Budget b) async {
    final db = await database;
    await db.insert(
      'budgets',
      b.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // —— Bills ——
  Future<List<Bill>> getBills() async {
    final db = await database;
    final rows = await db.query('bills', orderBy: 'next_due ASC');
    return rows.map(Bill.fromMap).toList();
  }

  Future<void> upsertBill(Bill b) async {
    final db = await database;
    await db.insert(
      'bills',
      b.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteBill(String id) async {
    final db = await database;
    await db.delete('bill_payments', where: 'bill_id = ?', whereArgs: [id]);
    await db.delete('bills', where: 'id = ?', whereArgs: [id]);
  }

  Future<Bill?> getBill(String id) async {
    final db = await database;
    final rows = await db.query('bills', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Bill.fromMap(rows.first);
  }

  Future<List<BillPayment>> getBillPayments(String billId) async {
    final db = await database;
    final rows = await db.query(
      'bill_payments',
      where: 'bill_id = ?',
      whereArgs: [billId],
      orderBy: 'year_month DESC',
    );
    return rows.map(BillPayment.fromMap).toList();
  }

  Future<Set<String>> paidMonthsForBill(String billId) async {
    final list = await getBillPayments(billId);
    return {for (final p in list) p.yearMonth};
  }

  Future<Set<String>> paidMonthsThisMonth(String yearMonth) async {
    final db = await database;
    final rows = await db.query(
      'bill_payments',
      columns: ['bill_id'],
      where: 'year_month = ?',
      whereArgs: [yearMonth],
    );
    return {for (final r in rows) r['bill_id'] as String};
  }

  Future<void> markBillMonthPaid({
    required Bill bill,
    required String yearMonth,
    String? paidOn,
  }) async {
    final db = await database;
    try {
      await db.insert('bill_payments', {
        'id': newId(),
        'bill_id': bill.id,
        'year_month': yearMonth,
        'paid_on': paidOn ?? isoDate(DateTime.now()),
        'amount': bill.amount,
      });
    } on DatabaseException catch (e) {
      if (!e.isUniqueConstraintError()) rethrow;
    }
  }

  Future<void> unmarkBillMonth(String billId, String yearMonth) async {
    final db = await database;
    await db.delete(
      'bill_payments',
      where: 'bill_id = ? AND year_month = ?',
      whereArgs: [billId, yearMonth],
    );
  }

  // —— Templates ——
  Future<List<RecurringTemplate>> getTemplates() async {
    final db = await database;
    final rows = await db.query('recurring_templates', orderBy: 'name ASC');
    return rows.map(RecurringTemplate.fromMap).toList();
  }

  Future<void> upsertTemplate(RecurringTemplate t) async {
    final db = await database;
    await db.insert(
      'recurring_templates',
      t.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteTemplate(String id) async {
    final db = await database;
    await db.delete('recurring_templates', where: 'id = ?', whereArgs: [id]);
  }

  // —— Pending imports (Phase 2) ——
  Future<List<PendingImport>> getPendingImports() async {
    final db = await database;
    final rows = await db.query(
      'pending_imports',
      where: 'status = ?',
      whereArgs: [PendingStatus.pending.name],
      orderBy: 'created_at DESC',
    );
    return rows.map(PendingImport.fromMap).toList();
  }

  Future<int> countPendingImports() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM pending_imports WHERE status = ?',
      [PendingStatus.pending.name],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  /// Returns true if inserted, false if duplicate raw text.
  Future<bool> insertPendingImport(PendingImport item) async {
    final db = await database;
    try {
      await db.insert('pending_imports', item.toMap());
      return true;
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) return false;
      rethrow;
    }
  }

  Future<void> updatePendingImport(PendingImport item) async {
    final db = await database;
    await db.update(
      'pending_imports',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> acceptPendingImport(
    PendingImport item, {
    required String? accountId,
    required String? categoryId,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await insertTransaction(
      MoneyTx(
        id: newId(),
        type: item.type,
        amount: item.amount,
        date: item.txDate,
        categoryId: categoryId ?? item.categoryId,
        accountId: accountId ?? item.accountId,
        note: item.merchant,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await updatePendingImport(
      item.copyWith(
        status: PendingStatus.accepted,
        accountId: accountId ?? item.accountId,
        categoryId: categoryId ?? item.categoryId,
      ),
    );
  }

  Future<void> dismissPendingImport(PendingImport item) async {
    await updatePendingImport(item.copyWith(status: PendingStatus.dismissed));
  }
}
