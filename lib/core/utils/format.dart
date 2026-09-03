import 'package:intl/intl.dart';

final myrFormat = NumberFormat.currency(
  locale: 'en_MY',
  symbol: 'RM ',
  decimalDigits: 2,
);

String formatMoney(num value) => myrFormat.format(value);

String shortDate(DateTime d) => DateFormat('dd MMM yyyy').format(d);

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseIsoDate(String s) => DateTime.parse(s);

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime startOfWeek(DateTime d) {
  final day = dateOnly(d);
  return day.subtract(Duration(days: day.weekday - 1));
}

DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

DateTime endOfMonth(DateTime d) => DateTime(d.year, d.month + 1, 0);

DateTime endOfWeek(DateTime d) => startOfWeek(d).add(const Duration(days: 6));

DateTime startOfLastWeek(DateTime d) =>
    startOfWeek(d).subtract(const Duration(days: 7));

String yearMonth(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

DateTime parseYearMonth(String ym) {
  final parts = ym.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
}

String monthYearLabel(DateTime d, {required bool isZh}) {
  if (isZh) {
    return '${d.year}年${d.month}月';
  }
  return DateFormat('MMM yyyy').format(d);
}

String monthShortLabel(DateTime d, {required bool isZh}) {
  if (isZh) return '${d.month}月';
  return DateFormat('MMM').format(d);
}

String longDateLabel(DateTime d, {required bool isZh}) {
  if (isZh) {
    return '${d.year}年${d.month}月${d.day}日';
  }
  return DateFormat('EEEE, d MMM yyyy').format(d);
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
