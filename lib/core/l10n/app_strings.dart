import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_provider.dart';

class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  bool get isZh => locale.languageCode == 'zh';

  static AppStrings of(BuildContext context, WidgetRef ref) {
    final code = ref.watch(localeProvider);
    return AppStrings(Locale(code));
  }

  String get appName => 'Stash';
  String get home => isZh ? '首页' : 'Home';
  String get activity => isZh ? '流水' : 'Activity';
  String get goals => isZh ? '目标' : 'Goals';
  String get bills => isZh ? '账单' : 'Bills';
  String get settings => isZh ? '设置' : 'Settings';
  String get reports => isZh ? '报表' : 'Reports';
  String get add => isZh ? '记一笔' : 'Add';
  String get expense => isZh ? '支出' : 'Expense';
  String get income => isZh ? '收入' : 'Income';
  String get amount => isZh ? '金额' : 'Amount';
  String get date => isZh ? '日期' : 'Date';
  String get category => isZh ? '分类' : 'Category';
  String get account => isZh ? '账户' : 'Account';
  String get save => isZh ? '保存' : 'Save';
  String get cancel => isZh ? '取消' : 'Cancel';
  String get delete => isZh ? '删除' : 'Delete';
  String get edit => isZh ? '编辑' : 'Edit';
  String get budget => isZh ? '预算' : 'Budget';
  String get daily => isZh ? '日' : 'Day';
  String get weekly => isZh ? '周' : 'Week';
  String get monthly => isZh ? '月' : 'Month';
  String get remaining => isZh ? '剩余' : 'Left';
  String get spent => isZh ? '已花' : 'Spent';
  String get overBudget => isZh ? '已超预算' : 'Over budget';
  String get assets => isZh ? '资产' : 'Assets';
  String get balance => isZh ? '余额' : 'Balance';
  String get totalBalance => isZh ? '总余额' : 'Total balance';
  String get savingsProgress => isZh ? '储蓄进度' : 'Savings progress';
  String get pendingBills => isZh ? '待付账单' : 'Due bills';
  String get noPendingBills => isZh ? '暂无待付账单' : 'No pending bills';
  String get markPaid => isZh ? '标记已付' : 'Mark paid';
  String get paid => isZh ? '已付' : 'Paid';
  String get pending => isZh ? '待付' : 'Pending';
  String get addToCalendar => isZh ? '写入日历' : 'Add to calendar';
  String get newGoal => isZh ? '新目标' : 'New goal';
  String get newBill => isZh ? '新账单' : 'New bill';
  String get newAccount => isZh ? '新账户' : 'New account';
  String get targetAmount => isZh ? '目标金额' : 'Target';
  String get savedAmount => isZh ? '已存' : 'Saved';
  String get deadline => isZh ? '截止日期' : 'Deadline';
  String get deposit => isZh ? '存入' : 'Deposit';
  String get archive => isZh ? '归档' : 'Archive';
  String get archived => isZh ? '已归档' : 'Archived';
  String get active => isZh ? '进行中' : 'Active';
  String get displayFields => isZh ? '显示字段' : 'Display fields';
  String get monthlySuggest => isZh ? '建议月存' : 'Monthly suggest';
  String get note => isZh ? '备注' : 'Note';
  String get language => isZh ? '语言' : 'Language';
  String get chinese => isZh ? '中文' : 'Chinese';
  String get english => isZh ? 'English' : 'English';
  String get categories => isZh ? '分类管理' : 'Categories';
  String get templates => isZh ? '固定收支' : 'Templates';
  String get privacy => isZh ? '隐私说明' : 'Privacy';
  String get privacyBody => isZh
      ? 'Stash 将数据保存在本机。通知监听仅用于解析付款金额，不会上传交易。银行 API 仍为后续版本预留。'
      : 'Stash stores data on this device. Notification access is only used to parse payment amounts locally. Bank APIs remain a later option.';
  String get about => isZh ? '关于' : 'About';
  String get aboutBody => isZh
      ? 'Stash — 预算、储蓄目标与账单，专为 MYR 设计。'
      : 'Stash — budgets, savings goals, and bills for MYR.';
  String get thisMonth => isZh ? '本月' : 'This month';
  String get vsLastMonth => isZh ? '与上月对比' : 'vs last month';
  String get byCategory => isZh ? '分类占比' : 'By category';
  String get trend => isZh ? '趋势' : 'Trend';
  String get noData => isZh ? '暂无数据' : 'No data yet';
  String get quickAdd => isZh ? '快速记账' : 'Quick add';
  String get applyTemplate => isZh ? '套用模板' : 'Apply';
  String get createTemplate => isZh ? '新建模板' : 'New template';
  String get name => isZh ? '名称' : 'Name';
  String get type => isZh ? '类型' : 'Type';
  String get travel => isZh ? '旅行' : 'Travel';
  String get emergency => isZh ? '紧急金' : 'Emergency';
  String get downPayment => isZh ? '房屋首付' : 'Down payment';
  String get custom => isZh ? '自定义' : 'Custom';
  String get bindGoal => isZh ? '绑定目标' : 'Bind goal';
  String get unbound => isZh ? '未绑定' : 'Unbound';
  String get goalBound => isZh ? '已有账户绑定此目标' : 'Goal already bound to an account';
  String get required => isZh ? '必填' : 'Required';
  String get saved => isZh ? '已保存' : 'Saved';
  String get emptyActivity => isZh ? '还没有流水，点 + 记一笔' : 'No activity yet. Tap + to add.';
  String get emptyGoals => isZh ? '创建第一个储蓄目标' : 'Create your first savings goal';
  String get emptyBills => isZh ? '添加物业管理费等账单' : 'Add maintenance fees and other bills';
  String get emptyAccounts => isZh ? '添加一个账户开始' : 'Add an account to start';
  String get setBudgets => isZh ? '设置预算' : 'Set budgets';
  String get manageAccounts => isZh ? '管理账户' : 'Accounts';
  String get viewReports => isZh ? '查看报表' : 'View reports';
  String get cycleMonthly => isZh ? '每月' : 'Monthly';
  String get cycleQuarterly => isZh ? '每季' : 'Quarterly';
  String get cycleYearly => isZh ? '每年' : 'Yearly';
  String get cycleOnce => isZh ? '一次' : 'Once';
  String get nextDue => isZh ? '下次日期' : 'Next due';
  String get calendarAdded => isZh ? '已加入日历' : 'Added to calendar';
  String get all => isZh ? '全部' : 'All';
  String get bankImport => isZh ? '银行导入' : 'Bank import';
  String get autoListen => isZh ? '自动监听通知' : 'Listen to notifications';
  String get autoListenHint => isZh
      ? '开启通知访问后，Stash 会尝试解析丰隆 / TnG 等付款通知，放入待确认列表。'
      : 'After enabling notification access, Stash parses HLB / TnG payment alerts into a review queue.';
  String get enableListen => isZh ? '开启监听' : 'Enable listener';
  String get listeningOn => isZh ? '监听中' : 'Listening';
  String get permissionOn => isZh ? '已授权' : 'Permission on';
  String get permissionOff => isZh ? '未授权' : 'Permission off';
  String get pasteSms => isZh ? '粘贴短信 / 通知' : 'Paste SMS / notice';
  String get pasteSmsHint => isZh
      ? '例如：Your HLB account was debited RM25.00 at GRAB on 03/09/2026'
      : 'e.g. Your HLB account was debited RM25.00 at GRAB on 03/09/2026';
  String get parseAndQueue => isZh ? '解析并加入待确认' : 'Parse & queue';
  String get parseFailed => isZh ? '无法解析金额，请检查文本' : 'Could not parse amount';
  String get importQueued => isZh ? '已加入待确认' : 'Queued for review';
  String get pendingReview => isZh ? '待确认' : 'Pending review';
  String get noPendingImports => isZh ? '暂无待确认交易' : 'No pending imports';
  String get confirmImport => isZh ? '确认入账' : 'Confirm';
  String get dismiss => isZh ? '忽略' : 'Dismiss';
  String get pendingImportsBadge => isZh ? '待导入' : 'To import';
  String get paidThisMonth => isZh ? '本月已付' : 'Paid this month';
  String get unpaidThisMonth => isZh ? '本月未付' : 'Unpaid this month';
  String get tapToCheck => isZh ? '点进查看月份' : 'Tap to check months';
  String get monthsPaid => isZh ? '已付月份' : 'Months paid';
  String get markThisMonth => isZh ? '标记本月已付' : 'Mark this month paid';
  String get unmarkMonth => isZh ? '取消本月' : 'Undo this month';
  String get spending => isZh ? '支出' : 'Spending';
  String get today => isZh ? '今天' : 'Today';
  String get thisWeek => isZh ? '本周' : 'This week';
  String get lastWeek => isZh ? '上周' : 'Last week';
  String get lastMonth => isZh ? '上月' : 'Last month';
  String get vsLastWeek => isZh ? '对比上周' : 'vs last week';
  String get moreThan => isZh ? '多了' : 'more';
  String get lessThan => isZh ? '少了' : 'less';
  String get sameAs => isZh ? '持平' : 'same';
  String get totalSpend => isZh ? '总支出' : 'Total spend';
  String get swipeOrTapMonth => isZh ? '左右滑或点柱看各月' : 'Swipe or tap a bar';
}

final stringsProvider = Provider<AppStrings>((ref) {
  final code = ref.watch(localeProvider);
  return AppStrings(Locale(code));
});
