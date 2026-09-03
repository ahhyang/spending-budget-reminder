class Account {
  Account({
    required this.id,
    required this.name,
    required this.balance,
    this.goalId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final double balance;
  final String? goalId;
  final String createdAt;
  final String updatedAt;

  Account copyWith({
    String? name,
    double? balance,
    String? goalId,
    bool clearGoalId = false,
    String? updatedAt,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      goalId: clearGoalId ? null : (goalId ?? this.goalId),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'balance': balance,
        'goal_id': goalId,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory Account.fromMap(Map<String, Object?> m) => Account(
        id: m['id'] as String,
        name: m['name'] as String,
        balance: (m['balance'] as num).toDouble(),
        goalId: m['goal_id'] as String?,
        createdAt: m['created_at'] as String,
        updatedAt: m['updated_at'] as String,
      );
}

enum GoalType { travel, emergency, downPayment, custom }

enum GoalStatus { active, archived }

class Goal {
  Goal({
    required this.id,
    required this.name,
    required this.type,
    required this.targetAmount,
    required this.savedAmount,
    this.deadline,
    this.note,
    this.showTarget = true,
    this.showSaved = true,
    this.showDeadline = true,
    this.showMonthlySuggest = false,
    this.showPercent = true,
    this.showNote = false,
    this.status = GoalStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final GoalType type;
  final double targetAmount;
  final double savedAmount;
  final String? deadline;
  final String? note;
  final bool showTarget;
  final bool showSaved;
  final bool showDeadline;
  final bool showMonthlySuggest;
  final bool showPercent;
  final bool showNote;
  final GoalStatus status;
  final String createdAt;
  final String updatedAt;

  double get percent =>
      targetAmount <= 0 ? 0 : (savedAmount / targetAmount).clamp(0, 1);

  double? get monthlySuggest {
    if (deadline == null || targetAmount <= savedAmount) return null;
    final due = DateTime.tryParse(deadline!);
    if (due == null) return null;
    final now = DateTime.now();
    final months = (due.year - now.year) * 12 + due.month - now.month;
    if (months <= 0) return targetAmount - savedAmount;
    return (targetAmount - savedAmount) / months;
  }

  Goal copyWith({
    String? name,
    GoalType? type,
    double? targetAmount,
    double? savedAmount,
    String? deadline,
    String? note,
    bool? showTarget,
    bool? showSaved,
    bool? showDeadline,
    bool? showMonthlySuggest,
    bool? showPercent,
    bool? showNote,
    GoalStatus? status,
    String? updatedAt,
  }) {
    return Goal(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      deadline: deadline ?? this.deadline,
      note: note ?? this.note,
      showTarget: showTarget ?? this.showTarget,
      showSaved: showSaved ?? this.showSaved,
      showDeadline: showDeadline ?? this.showDeadline,
      showMonthlySuggest: showMonthlySuggest ?? this.showMonthlySuggest,
      showPercent: showPercent ?? this.showPercent,
      showNote: showNote ?? this.showNote,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'target_amount': targetAmount,
        'saved_amount': savedAmount,
        'deadline': deadline,
        'note': note,
        'show_target': showTarget ? 1 : 0,
        'show_saved': showSaved ? 1 : 0,
        'show_deadline': showDeadline ? 1 : 0,
        'show_monthly_suggest': showMonthlySuggest ? 1 : 0,
        'show_percent': showPercent ? 1 : 0,
        'show_note': showNote ? 1 : 0,
        'status': status.name,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory Goal.fromMap(Map<String, Object?> m) => Goal(
        id: m['id'] as String,
        name: m['name'] as String,
        type: GoalType.values.byName(m['type'] as String),
        targetAmount: (m['target_amount'] as num).toDouble(),
        savedAmount: (m['saved_amount'] as num).toDouble(),
        deadline: m['deadline'] as String?,
        note: m['note'] as String?,
        showTarget: (m['show_target'] as int) == 1,
        showSaved: (m['show_saved'] as int) == 1,
        showDeadline: (m['show_deadline'] as int) == 1,
        showMonthlySuggest: (m['show_monthly_suggest'] as int) == 1,
        showPercent: (m['show_percent'] as int) == 1,
        showNote: (m['show_note'] as int) == 1,
        status: GoalStatus.values.byName(m['status'] as String),
        createdAt: m['created_at'] as String,
        updatedAt: m['updated_at'] as String,
      );
}

enum TxType { expense, income, goalDeposit }

class Category {
  Category({
    required this.id,
    required this.nameEn,
    required this.nameZh,
    required this.kind,
    this.isSystem = false,
  });

  final String id;
  final String nameEn;
  final String nameZh;
  final TxType kind; // expense or income only
  final bool isSystem;

  String label(bool isZh) => isZh ? nameZh : nameEn;

  Map<String, Object?> toMap() => {
        'id': id,
        'name_en': nameEn,
        'name_zh': nameZh,
        'kind': kind.name,
        'is_system': isSystem ? 1 : 0,
      };

  factory Category.fromMap(Map<String, Object?> m) => Category(
        id: m['id'] as String,
        nameEn: m['name_en'] as String,
        nameZh: m['name_zh'] as String,
        kind: TxType.values.byName(m['kind'] as String),
        isSystem: (m['is_system'] as int) == 1,
      );
}

class MoneyTx {
  MoneyTx({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    this.categoryId,
    this.accountId,
    this.goalId,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final TxType type;
  final double amount;
  final String date;
  final String? categoryId;
  final String? accountId;
  final String? goalId;
  final String? note;
  final String createdAt;
  final String updatedAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'date': date,
        'category_id': categoryId,
        'account_id': accountId,
        'goal_id': goalId,
        'note': note,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory MoneyTx.fromMap(Map<String, Object?> m) => MoneyTx(
        id: m['id'] as String,
        type: TxType.values.byName(m['type'] as String),
        amount: (m['amount'] as num).toDouble(),
        date: m['date'] as String,
        categoryId: m['category_id'] as String?,
        accountId: m['account_id'] as String?,
        goalId: m['goal_id'] as String?,
        note: m['note'] as String?,
        createdAt: m['created_at'] as String,
        updatedAt: m['updated_at'] as String,
      );
}

enum BudgetPeriod { day, week, month }

class Budget {
  Budget({
    required this.id,
    required this.period,
    required this.amount,
    required this.updatedAt,
  });

  final String id;
  final BudgetPeriod period;
  final double amount;
  final String updatedAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'period': period.name,
        'amount': amount,
        'updated_at': updatedAt,
      };

  factory Budget.fromMap(Map<String, Object?> m) => Budget(
        id: m['id'] as String,
        period: BudgetPeriod.values.byName(m['period'] as String),
        amount: (m['amount'] as num).toDouble(),
        updatedAt: m['updated_at'] as String,
      );
}

enum BillCycle { monthly, quarterly, yearly, once }

enum BillStatus { pending, paid }

class Bill {
  Bill({
    required this.id,
    required this.name,
    required this.amount,
    required this.nextDue,
    required this.cycle,
    required this.status,
    this.addToCalendar = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final double amount;
  final String nextDue;
  final BillCycle cycle;
  final BillStatus status;
  final bool addToCalendar;
  final String createdAt;
  final String updatedAt;

  Bill copyWith({
    String? name,
    double? amount,
    String? nextDue,
    BillCycle? cycle,
    BillStatus? status,
    bool? addToCalendar,
    String? updatedAt,
  }) {
    return Bill(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      nextDue: nextDue ?? this.nextDue,
      cycle: cycle ?? this.cycle,
      status: status ?? this.status,
      addToCalendar: addToCalendar ?? this.addToCalendar,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'amount': amount,
        'next_due': nextDue,
        'cycle': cycle.name,
        'status': status.name,
        'add_to_calendar': addToCalendar ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory Bill.fromMap(Map<String, Object?> m) => Bill(
        id: m['id'] as String,
        name: m['name'] as String,
        amount: (m['amount'] as num).toDouble(),
        nextDue: m['next_due'] as String,
        cycle: BillCycle.values.byName(m['cycle'] as String),
        status: BillStatus.values.byName(m['status'] as String),
        addToCalendar: (m['add_to_calendar'] as int) == 1,
        createdAt: m['created_at'] as String,
        updatedAt: m['updated_at'] as String,
      );
}

class BillPayment {
  BillPayment({
    required this.id,
    required this.billId,
    required this.yearMonth,
    required this.paidOn,
    required this.amount,
  });

  final String id;
  final String billId;
  /// YYYY-MM
  final String yearMonth;
  final String paidOn;
  final double amount;

  Map<String, Object?> toMap() => {
        'id': id,
        'bill_id': billId,
        'year_month': yearMonth,
        'paid_on': paidOn,
        'amount': amount,
      };

  factory BillPayment.fromMap(Map<String, Object?> m) => BillPayment(
        id: m['id'] as String,
        billId: m['bill_id'] as String,
        yearMonth: m['year_month'] as String,
        paidOn: m['paid_on'] as String,
        amount: (m['amount'] as num).toDouble(),
      );
}

class RecurringTemplate {
  RecurringTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    this.categoryId,
    this.accountId,
    this.dayOfMonth,
    required this.createdAt,
  });

  final String id;
  final String name;
  final TxType type;
  final double amount;
  final String? categoryId;
  final String? accountId;
  final int? dayOfMonth;
  final String createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'amount': amount,
        'category_id': categoryId,
        'account_id': accountId,
        'day_of_month': dayOfMonth,
        'created_at': createdAt,
      };

  factory RecurringTemplate.fromMap(Map<String, Object?> m) =>
      RecurringTemplate(
        id: m['id'] as String,
        name: m['name'] as String,
        type: TxType.values.byName(m['type'] as String),
        amount: (m['amount'] as num).toDouble(),
        categoryId: m['category_id'] as String?,
        accountId: m['account_id'] as String?,
        dayOfMonth: m['day_of_month'] as int?,
        createdAt: m['created_at'] as String,
      );
}

enum PendingStatus { pending, accepted, dismissed }

class PendingImport {
  PendingImport({
    required this.id,
    required this.rawText,
    required this.source,
    required this.amount,
    required this.type,
    this.merchant,
    required this.txDate,
    this.categoryId,
    this.accountId,
    this.status = PendingStatus.pending,
    required this.createdAt,
  });

  final String id;
  final String rawText;
  final String source;
  final double amount;
  final TxType type;
  final String? merchant;
  final String txDate;
  final String? categoryId;
  final String? accountId;
  final PendingStatus status;
  final String createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'raw_text': rawText,
        'source': source,
        'amount': amount,
        'type': type.name,
        'merchant': merchant,
        'tx_date': txDate,
        'category_id': categoryId,
        'account_id': accountId,
        'status': status.name,
        'created_at': createdAt,
      };

  factory PendingImport.fromMap(Map<String, Object?> m) => PendingImport(
        id: m['id'] as String,
        rawText: m['raw_text'] as String,
        source: m['source'] as String,
        amount: (m['amount'] as num).toDouble(),
        type: TxType.values.byName(m['type'] as String),
        merchant: m['merchant'] as String?,
        txDate: m['tx_date'] as String,
        categoryId: m['category_id'] as String?,
        accountId: m['account_id'] as String?,
        status: PendingStatus.values.byName(m['status'] as String),
        createdAt: m['created_at'] as String,
      );

  PendingImport copyWith({
    String? categoryId,
    String? accountId,
    PendingStatus? status,
    TxType? type,
  }) {
    return PendingImport(
      id: id,
      rawText: rawText,
      source: source,
      amount: amount,
      type: type ?? this.type,
      merchant: merchant,
      txDate: txDate,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
