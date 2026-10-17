enum AppCurrency {
  iqd('IQD', 'د.ع'),
  usd('USD', '\$');

  final String code;
  final String symbol;
  const AppCurrency(this.code, this.symbol);

  static AppCurrency fromCode(String code) => AppCurrency.values
      .firstWhere((c) => c.code == code, orElse: () => AppCurrency.iqd);
}

enum UserRole { admin, employee }

enum Permission {
  recordSubscriberPayment,
  addSubscriber,
  editSubscriber,
  deleteSubscriber,
  notifySupplierPayment,
  addExpense,
  viewSubscribers,
  viewSuppliers,
  viewReports,
  viewHistory,
  manageSuppliers,
  manageSupplierPurchases;

  static Set<Permission> all = Permission.values.toSet();

  static Permission? fromName(String name) {
    for (final p in values) {
      if (p.name == name) return p;
    }
    return null;
  }
}

enum ExpenseCategory { rent, salary, maintenance, utilities, other }

enum ExpenseEntryType { expense, withdrawal }

enum MoneyStorage { cashbox, personal, none }

enum SupplierPackageType { data, time, hybrid }

enum SupplierBalanceTransactionType { recharge, payment }

enum PaymentRequestStatus { pending, approved, rejected }

enum SubscriptionDebtStatus { unpaid, partiallyPaid, paid }

enum SubscriberStatus { active, inactive, overdue }

enum ReportRange { day, month, year, custom }

enum ReportScope { financial, employee }

enum StaffSettlementDirection { toCashbox, fromCashbox }
