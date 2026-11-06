import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_theme.dart';
import '../../core/constants.dart';

class AppPreferences {
  AppPreferences(this._prefs);
  final SharedPreferences _prefs;

  static const _kThemeMode = 'themeMode';
  static const _kWebColorTheme = 'webColorTheme';
  static const _kWebNotificationsEnabled = 'webNotificationsEnabled';
  static const _kLocale = 'locale';
  static const _kCurrency = 'currency';
  static const _kDefaultAutoRenewMode = 'defaultAutoRenewMode';
  static const _kDefaultAutoRenewDays = 'defaultAutoRenewDays';
  static const _kDefaultAutoRenewDayOfMonth = 'defaultAutoRenewDayOfMonth';

  ThemeMode get themeMode {
    final v = _prefs.getString(_kThemeMode);
    return ThemeMode.values
        .firstWhere((m) => m.name == v, orElse: () => ThemeMode.system);
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _prefs.setString(_kThemeMode, mode.name);

  AppColorTheme get webColorTheme {
    final v = _prefs.getString(_kWebColorTheme);
    return AppColorTheme.values
        .firstWhere((t) => t.name == v, orElse: () => AppColorTheme.deepBlue);
  }

  Future<void> setWebColorTheme(AppColorTheme theme) =>
      _prefs.setString(_kWebColorTheme, theme.name);

  bool get webNotificationsEnabled =>
      _prefs.getBool(_kWebNotificationsEnabled) ?? true;

  Future<void> setWebNotificationsEnabled(bool enabled) =>
      _prefs.setBool(_kWebNotificationsEnabled, enabled);

  Locale get locale {
    final v = _prefs.getString(_kLocale) ?? 'ar';
    return Locale(v);
  }

  Future<void> setLocale(Locale locale) =>
      _prefs.setString(_kLocale, locale.languageCode);

  AppCurrency get currency {
    final v = _prefs.getString(_kCurrency);
    return AppCurrency.fromCode(v ?? 'IQD');
  }

  Future<void> setCurrency(AppCurrency currency) =>
      _prefs.setString(_kCurrency, currency.code);

  AutoRenewMode get defaultAutoRenewMode {
    final v = _prefs.getString(_kDefaultAutoRenewMode);
    return AutoRenewMode.values.firstWhere(
      (m) => m.name == v,
      orElse: () => AutoRenewMode.fixedIntervalDays,
    );
  }

  Future<void> setDefaultAutoRenewMode(AutoRenewMode mode) =>
      _prefs.setString(_kDefaultAutoRenewMode, mode.name);

  int get defaultAutoRenewDays =>
      (_prefs.getInt(_kDefaultAutoRenewDays) ?? 30).clamp(1, 365);

  Future<void> setDefaultAutoRenewDays(int days) =>
      _prefs.setInt(_kDefaultAutoRenewDays, days.clamp(1, 365));

  int get defaultAutoRenewDayOfMonth =>
      (_prefs.getInt(_kDefaultAutoRenewDayOfMonth) ?? 1).clamp(1, 31);

  Future<void> setDefaultAutoRenewDayOfMonth(int day) =>
      _prefs.setInt(_kDefaultAutoRenewDayOfMonth, day.clamp(1, 31));
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in main()');
});

final appPreferencesProvider = Provider<AppPreferences>((ref) {
  return AppPreferences(ref.watch(sharedPreferencesProvider));
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_prefs.themeMode);
  final AppPreferences _prefs;
  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _prefs.setThemeMode(mode);
  }
}

class WebColorThemeNotifier extends StateNotifier<AppColorTheme> {
  WebColorThemeNotifier(this._prefs) : super(_prefs.webColorTheme);
  final AppPreferences _prefs;
  Future<void> set(AppColorTheme theme) async {
    state = theme;
    await _prefs.setWebColorTheme(theme);
  }
}

class WebNotificationsEnabledNotifier extends StateNotifier<bool> {
  WebNotificationsEnabledNotifier(this._prefs)
      : super(_prefs.webNotificationsEnabled);
  final AppPreferences _prefs;
  Future<void> set(bool enabled) async {
    state = enabled;
    await _prefs.setWebNotificationsEnabled(enabled);
  }
}

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this._prefs) : super(_prefs.locale);
  final AppPreferences _prefs;
  Future<void> set(Locale locale) async {
    state = locale;
    await _prefs.setLocale(locale);
  }
}

class CurrencyNotifier extends StateNotifier<AppCurrency> {
  CurrencyNotifier(this._prefs) : super(_prefs.currency);
  final AppPreferences _prefs;
  Future<void> set(AppCurrency currency) async {
    state = currency;
    await _prefs.setCurrency(currency);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
    (ref) => ThemeModeNotifier(ref.watch(appPreferencesProvider)));
final webColorThemeProvider =
    StateNotifierProvider<WebColorThemeNotifier, AppColorTheme>(
        (ref) => WebColorThemeNotifier(ref.watch(appPreferencesProvider)));
final webNotificationsEnabledProvider =
    StateNotifierProvider<WebNotificationsEnabledNotifier, bool>((ref) =>
        WebNotificationsEnabledNotifier(ref.watch(appPreferencesProvider)));
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
    (ref) => LocaleNotifier(ref.watch(appPreferencesProvider)));
final currencyProvider = StateNotifierProvider<CurrencyNotifier, AppCurrency>(
    (ref) => CurrencyNotifier(ref.watch(appPreferencesProvider)));

class DefaultAutoRenewModeNotifier extends StateNotifier<AutoRenewMode> {
  DefaultAutoRenewModeNotifier(this._prefs)
      : super(_prefs.defaultAutoRenewMode);
  final AppPreferences _prefs;
  Future<void> set(AutoRenewMode mode) async {
    state = mode;
    await _prefs.setDefaultAutoRenewMode(mode);
  }
}

class DefaultAutoRenewDaysNotifier extends StateNotifier<int> {
  DefaultAutoRenewDaysNotifier(this._prefs)
      : super(_prefs.defaultAutoRenewDays);
  final AppPreferences _prefs;
  Future<void> set(int days) async {
    final clamped = days.clamp(1, 365);
    state = clamped;
    await _prefs.setDefaultAutoRenewDays(clamped);
  }
}

class DefaultAutoRenewDayOfMonthNotifier extends StateNotifier<int> {
  DefaultAutoRenewDayOfMonthNotifier(this._prefs)
      : super(_prefs.defaultAutoRenewDayOfMonth);
  final AppPreferences _prefs;
  Future<void> set(int day) async {
    final clamped = day.clamp(1, 31);
    state = clamped;
    await _prefs.setDefaultAutoRenewDayOfMonth(clamped);
  }
}

final defaultAutoRenewModeProvider =
    StateNotifierProvider<DefaultAutoRenewModeNotifier, AutoRenewMode>((ref) =>
        DefaultAutoRenewModeNotifier(ref.watch(appPreferencesProvider)));
final defaultAutoRenewDaysProvider =
    StateNotifierProvider<DefaultAutoRenewDaysNotifier, int>((ref) =>
        DefaultAutoRenewDaysNotifier(ref.watch(appPreferencesProvider)));
final defaultAutoRenewDayOfMonthProvider =
    StateNotifierProvider<DefaultAutoRenewDayOfMonthNotifier, int>((ref) =>
        DefaultAutoRenewDayOfMonthNotifier(ref.watch(appPreferencesProvider)));
