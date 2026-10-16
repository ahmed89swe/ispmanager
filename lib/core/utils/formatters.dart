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
      DateFormat.yMMMd(locale).format(dt);
  static String dateTime(DateTime dt, {String locale = 'ar'}) =>
      DateFormat.yMMMd(locale).add_jm().format(dt);
  static String time(DateTime dt, {String locale = 'ar'}) =>
      DateFormat.jm(locale).format(dt);
  static String monthLabel(DateTime dt, {String locale = 'ar'}) =>
      DateFormat.yMMMM(locale).format(dt);

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
}
