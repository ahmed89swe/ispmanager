import 'package:intl/intl.dart';

import '../constants.dart';

class CurrencyFormatter {
  static String format(num amount, AppCurrency currency,
      {String locale = 'ar'}) {
    final symbol = currency.symbol;
    final formatter = NumberFormat.decimalPattern(locale);
    final formatted = formatter.format(amount);
    return currency == AppCurrency.usd
        ? '$symbol$formatted'
        : '$formatted $symbol';
  }
}

class DateFormatter {
  static String date(DateTime dt, {String locale = 'ar'}) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  static String dateTime(DateTime dt, {String locale = 'ar'}) =>
      '${date(dt, locale: locale)} ${DateFormat.jm(locale).format(dt)}';
  static String time(DateTime dt, {String locale = 'ar'}) =>
      DateFormat.jm(locale).format(dt);
  static String monthLabel(DateTime dt, {String locale = 'ar'}) =>
      '${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  /// Adds an exact number of calendar days (e.g. 30 days), taking into account
  /// months with 28, 29, 30, or 31 days and avoiding DST hour-shift bugs.
  static DateTime addDays(DateTime dt, int days) => DateTime(
        dt.year,
        dt.month,
        dt.day + days,
        dt.hour,
        dt.minute,
        dt.second,
        dt.millisecond,
        dt.microsecond,
      );

  /// Returns the exact number of calendar days remaining from [from] to [to].
  static int calendarDaysBetween(DateTime from, DateTime to) {
    final startUtc = DateTime.utc(from.year, from.month, from.day);
    final endUtc = DateTime.utc(to.year, to.month, to.day);
    return endUtc.difference(startUtc).inDays;
  }

  static int daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  /// Returns the next occurrence of [dayOfMonth] (1..31) that is at least 1 day
  /// after [fromDate].
  static DateTime nextUpcomingMonthlyDay(DateTime fromDate, int dayOfMonth) {
    final targetDay = dayOfMonth.clamp(1, 31);
    final thisMonthMax = daysInMonth(fromDate.year, fromDate.month);
    final sameMonth = DateTime(
      fromDate.year,
      fromDate.month,
      targetDay.clamp(1, thisMonthMax),
      fromDate.hour,
      fromDate.minute,
      fromDate.second,
    );
    if (calendarDaysBetween(fromDate, sameMonth) >= 1) {
      return sameMonth;
    }
    final nextYear =
        fromDate.month == 12 ? fromDate.year + 1 : fromDate.year;
    final nextMonth = fromDate.month == 12 ? 1 : fromDate.month + 1;
    final nextMonthMax = daysInMonth(nextYear, nextMonth);
    return DateTime(
      nextYear,
      nextMonth,
      targetDay.clamp(1, nextMonthMax),
      fromDate.hour,
      fromDate.minute,
      fromDate.second,
    );
  }

  /// Advances one monthly cycle from [periodStart] to the fixed [dayOfMonth].
  static DateTime nextMonthlyCycleEnd(DateTime periodStart, int dayOfMonth) {
    final targetDay = dayOfMonth.clamp(1, 31);
    final thisMonthMax = daysInMonth(periodStart.year, periodStart.month);
    final sameMonth = DateTime(
      periodStart.year,
      periodStart.month,
      targetDay.clamp(1, thisMonthMax),
      periodStart.hour,
      periodStart.minute,
      periodStart.second,
    );
    if (calendarDaysBetween(periodStart, sameMonth) >= 15) {
      return sameMonth;
    }
    final nextYear =
        periodStart.month == 12 ? periodStart.year + 1 : periodStart.year;
    final nextMonth = periodStart.month == 12 ? 1 : periodStart.month + 1;
    final nextMonthMax = daysInMonth(nextYear, nextMonth);
    return DateTime(
      nextYear,
      nextMonth,
      targetDay.clamp(1, nextMonthMax),
      periodStart.hour,
      periodStart.minute,
      periodStart.second,
    );
  }

  static DateTime addRenewalCycle(
    DateTime periodStart, {
    required AutoRenewMode mode,
    int intervalDays = 30,
    int? dayOfMonth,
  }) {
    if (mode == AutoRenewMode.fixedMonthlyDay) {
      return nextMonthlyCycleEnd(
        periodStart,
        (dayOfMonth ?? periodStart.day).clamp(1, 31),
      );
    }
    return addDays(periodStart, intervalDays > 0 ? intervalDays : 30);
  }
}
