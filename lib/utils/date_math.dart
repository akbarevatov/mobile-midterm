DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days, d.hour, d.minute);

DateTime addMonths(DateTime d, int months) {
  final monthIndex = d.month - 1 + months;
  final year = d.year + (monthIndex / 12).floor();
  final month = monthIndex % 12 + 1;
  final lastDayOfMonth = DateTime(year, month + 1, 0).day;
  final day = d.day > lastDayOfMonth ? lastDayOfMonth : d.day;
  return DateTime(year, month, day, d.hour, d.minute);
}

int daysBetween(DateTime from, DateTime to) =>
    (dateOnly(to).difference(dateOnly(from)).inHours / 24).round();

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime startOfWeek(DateTime d) => addDays(dateOnly(d), -(d.weekday - 1));

DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month);

DateTime withTime(DateTime date, int hour, int minute) =>
    DateTime(date.year, date.month, date.day, hour, minute);
