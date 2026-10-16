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
}
