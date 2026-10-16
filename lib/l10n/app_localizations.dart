import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'strings_ar.dart';
import 'strings_en.dart';

class AppLocalizations {
  AppLocalizations(this.locale, this._strings);
  final Locale locale;
  final Map<String, String> _strings;

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const supportedLocales = <Locale>[Locale('ar'), Locale('en')];

  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    _AppDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  String t(String key) => _strings[key] ?? englishStrings[key] ?? key;

  // Frequently used getters:
  String get appTitle => t('appTitle');
  String get tabAdmin => t('tabAdmin');
  String get tabEmployee => t('tabEmployee');
  String get signInWithGoogle => t('signInWithGoogle');
  String get adminEmail => t('adminEmail');
  String get username => t('username');
  String get password => t('password');
  String get login => t('login');
  String get logout => t('logout');
  String get subscribers => t('subscribers');
  String get payments => t('payments');
  String get suppliers => t('suppliers');
  String get expenses => t('expenses');
  String get employees => t('employees');
  String get reports => t('reports');
  String get history => t('history');
  String get settings => t('settings');
  String get profile => t('profile');
  String get dashboard => t('dashboard');
  String get inbox => t('inbox');
  String get save => t('save');
  String get cancel => t('cancel');
  String get delete => t('delete');
  String get edit => t('edit');
  String get search => t('search');
  String get amount => t('amount');
  String get currency => t('currency');
  String get note => t('note');
  String get date => t('date');
  String get name => t('name');
  String get phone => t('phone');
  String get plan => t('plan');
  String get monthlyFee => t('monthlyFee');
  String get balance => t('balance');
  String get status => t('status');
  String get category => t('category');
  String get reason => t('reason');
  String get permissions => t('permissions');
  String get newSupplier => t('newSupplier');
  String get supplierName => t('supplierName');
  String get packages => t('packages');
  String get purchases => t('purchases');
  String get debts => t('debts');
  String get newPackage => t('newPackage');
  String get newPurchase => t('newPurchase');
  String get requestSupplierPayment => t('requestSupplierPayment');
  String get addExpense => t('addExpense');
  String get newEmployee => t('newEmployee');
  String get language => t('language');
  String get theme => t('theme');
  String get themeSystem => t('themeSystem');
  String get themeLight => t('themeLight');
  String get themeDark => t('themeDark');
  String get defaultCurrency => t('defaultCurrency');
  String get firebaseNotConfigured => t('firebaseNotConfigured');
  String get noData => t('noData');
  String get loading => t('loading');
  String get errorOccurred => t('errorOccurred');
  String get retry => t('retry');
  String get yes => t('yes');
  String get no => t('no');
  String get confirmDelete => t('confirmDelete');
  String get exportPdf => t('exportPdf');
  String get from => t('from');
  String get to => t('to');
  String get employee => t('employee');
  String get admin => t('admin');
  String get all => t('all');
  String get approve => t('approve');
  String get reject => t('reject');
  String get pending => t('pending');
  String get approved => t('approved');
  String get rejected => t('rejected');
  String get changePhoto => t('changePhoto');
  String get removePhoto => t('removePhoto');
  String get displayName => t('displayName');
  String get organization => t('organization');
  String get type => t('type');
  String get price => t('price');
  String get paid => t('paid');
  String get remaining => t('remaining');
  String get qty => t('qty');
  String get total => t('total');
  String get speed => t('speed');
  String get quotaGb => t('quotaGb');
  String get durationDays => t('durationDays');
  String get selectSupplier => t('selectSupplier');
  String get selectPackage => t('selectPackage');
  String get manualEntry => t('manualEntry');
  String get summary => t('summary');
  String get filter => t('filter');
  String get monthly => t('monthly');
  String get yearly => t('yearly');
  String get daily => t('daily');
  String get scopeFinancial => t('scopeFinancial');
  String get scopeEmployee => t('scopeEmployee');
  String get loginFailed => t('loginFailed');
  String get fieldRequired => t('fieldRequired');
  String get invalidAmount => t('invalidAmount');
  String get saved => t('saved');
  String get deleted => t('deleted');
  String get welcome => t('welcome');
  String get pleaseSignIn => t('pleaseSignIn');
  String get totalRevenue => t('totalRevenue');
  String get totalExpenses => t('totalExpenses');
  String get totalWithdrawals => t('totalWithdrawals');
  String get totalSupplierPayments => t('totalSupplierPayments');
  String get totalRecharges => t('totalRecharges');
  String get subscriptionProfit => t('subscriptionProfit');
  String get totalDebts => t('totalDebts');
  String get netProfit => t('netProfit');
  String get subscribersCount => t('subscribersCount');
  String get addNew => t('addNew');
  String get details => t('details');
  String get recordPayment => t('recordPayment');
  String get supplierPaymentRequest => t('supplierPaymentRequest');
  String get addSubscriber => t('addSubscriber');
  String get editSubscriber => t('editSubscriber');
  String get withdrawal => t('withdrawal');
  String get expense => t('expense');
  String get by => t('by');
  String get method => t('method');
}

class _AppDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final map = locale.languageCode == 'ar' ? arabicStrings : englishStrings;
    return AppLocalizations(locale, map);
  }

  @override
  bool shouldReload(_AppDelegate old) => false;
}
