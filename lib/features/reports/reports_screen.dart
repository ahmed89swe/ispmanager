import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/models/models.dart';
import '../../core/services/pdf_report_service.dart';
import '../../core/utils/formatters.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/providers/preferences_providers.dart';
import '../auth/auth_repository.dart';
import '../employees/employees_repository.dart';
import '../expenses/expenses_repository.dart';
import '../payments/payments_repository.dart';
import '../subscribers/subscribers_repository.dart';
import '../suppliers/suppliers_repository.dart';

enum ReportType { financial, revenue, expenses, supplierPayments, debts, subscriber }

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  late DateTime _to = DateTime.now();
  ReportType _type = ReportType.financial;
  Subscriber? _selectedSubscriber;
  AppCurrency? _selectedCurrency;

  String _typeLabel(ReportType t, AppLocalizations l) {
    switch (t) {
      case ReportType.financial:
        return l.t('reportFinancial');
      case ReportType.revenue:
        return l.t('reportRevenue');
      case ReportType.expenses:
        return l.t('reportExpenses');
      case ReportType.supplierPayments:
        return l.t('reportSupplierPayments');
      case ReportType.debts:
        return 'ديون المشتركين';
      case ReportType.subscriber:
        return l.t('reportSubscriber');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentAppUserProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();
    final loc = Localizations.localeOf(context).languageCode;
    final AppCurrency currency =
        _selectedCurrency ?? ref.watch(currencyProvider);
    final expensesAsync = ref.watch(expensesStreamProvider(user.adminUid));
    final paymentsStream =
        ref.watch(paymentsRepositoryProvider).watchAll(user.adminUid);
    final supplierTransactionsStream = ref
        .watch(suppliersRepositoryProvider)
        .watchBalanceTransactions(user.adminUid);
    final debtsStream =
        ref.watch(subscribersRepositoryProvider).watchAllDebts(user.adminUid);
    final subscribers =
        ref.watch(subscribersStreamProvider(user.adminUid)).valueOrNull ?? [];
    final employees =
        ref.watch(employeesStreamProvider(user.adminUid)).valueOrNull ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildControls(context, l, loc, subscribers, currency),
        const SizedBox(height: 12),
        StreamBuilder<List<Payment>>(
          stream: paymentsStream,
          builder: (_, paymentSnap) {
            return StreamBuilder<List<SupplierBalanceTransaction>>(
              stream: supplierTransactionsStream,
              builder: (_, supplierSnap) {
                return StreamBuilder<List<SubscriberDebt>>(
                  stream: debtsStream,
                  builder: (_, debtSnap) {
                    final payments = paymentSnap.data ?? [];
                    final supplierTransactions = supplierSnap.data ?? [];
                    final debts = debtSnap.data ?? [];
                    final expenses = expensesAsync.valueOrNull ?? [];
                    return _buildBody(
                      context,
                      l,
                      loc,
                      currency,
                      user,
                      payments,
                      expenses,
                      supplierTransactions,
                      debts,
                      subscribers,
                      employees,
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context, AppLocalizations l, String loc,
      List<Subscriber> subscribers, AppCurrency currency) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ReportType>(
                    value: _type,
                    decoration: InputDecoration(
                      labelText: l.t('reportType'),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: ReportType.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(_typeLabel(t, l)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _type = v;
                          if (v != ReportType.subscriber) {
                            _selectedSubscriber = null;
                          }
                        });
                      }
                    },
                  ),
                ),
                if (_type != ReportType.subscriber) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 105,
                    child: DropdownButtonFormField<AppCurrency>(
                      value: currency,
                      decoration: InputDecoration(
                        labelText: l.currency,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: AppCurrency.values
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.code),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _selectedCurrency = v);
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
            if (_type == ReportType.subscriber) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<Subscriber>(
                value: _selectedSubscriber,
                decoration: InputDecoration(
                  labelText: l.t('subscriber'),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: subscribers
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.name),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedSubscriber = v),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickFrom(context),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                        '${l.from}: ${DateFormatter.date(_from, locale: loc)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTo(context),
                    icon: const Icon(Icons.event),
                    label: Text(
                        '${l.to}: ${DateFormatter.date(_to, locale: loc)}'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l,
    String loc,
    AppCurrency currency,
    AppUser user,
    List<Payment> payments,
    List<Expense> expenses,
    List<SupplierBalanceTransaction> supplierTransactions,
    List<SubscriberDebt> debts,
    List<Subscriber> subscribers,
    List<Employee> employees,
  ) {
    final nameByUid = <String, String>{
      user.uid: user.displayName,
      for (final e in employees) e.uid: e.displayName,
    };

    Widget actionsRow(VoidCallback onExport) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onExport,
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(l.exportPdf),
              ),
            ),
          ],
        ),
      );
    }

    switch (_type) {
      case ReportType.financial:
        final summary = _buildSummary(
          payments: payments,
          expenses: expenses,
          supplierTransactions: supplierTransactions,
          debts: debts,
          currency: currency,
        );
        return Column(
          children: [
            _kpi(l.totalRevenue, summary.revenue, currency, loc, Colors.green,
                Icons.trending_up),
            _kpi(l.totalExpenses, summary.expenses, currency, loc, Colors.red,
                Icons.receipt_long),
            _kpi(l.totalWithdrawals, summary.withdrawals, currency, loc,
                Colors.deepOrange, Icons.wallet),
            _kpi(l.totalSupplierPayments, summary.supplierPayments, currency,
                loc, Colors.indigo, Icons.payments),
            _kpi(l.totalRecharges, summary.recharges, currency, loc,
                Colors.teal, Icons.add_card),
            _kpi(l.subscriptionProfit, summary.subscriptionProfit, currency,
                loc, Colors.blue, Icons.stacked_line_chart),
            _kpi(
              l.netProfit,
              summary.netProfit,
              currency,
              loc,
              summary.netProfit >= 0 ? Colors.blue : Colors.orange,
              Icons.bar_chart,
            ),
            actionsRow(() => _exportFinancial(
                  l: l,
                  loc: loc,
                  currency: currency,
                  user: user,
                  summary: summary,
                  payments: payments,
                  expenses: expenses,
                  supplierTransactions: supplierTransactions,
                  nameByUid: nameByUid,
                  subscribers: subscribers,
                )),
          ],
        );
      case ReportType.revenue:
        final list = payments
            .where((p) => p.currency == currency && _inRange(p.recordedAt))
            .toList()
          ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
        final total = list.fold<num>(0, (s, p) => s + p.amount);
        return Column(
          children: [
            _previewListCard(
              title: l.t('reportRevenue'),
              countLabel:
                  '${list.length} ${l.t('records')} · ${CurrencyFormatter.format(total, currency, locale: loc)}',
              icon: Icons.trending_up,
              color: Colors.green,
            ),
            actionsRow(() => _exportRevenue(
                l, loc, currency, user, list, subscribers, nameByUid)),
          ],
        );
      case ReportType.expenses:
        final list = expenses
            .where((e) => e.currency == currency && _inRange(e.date))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        final total = list.fold<num>(0, (s, e) => s + e.amount);
        return Column(
          children: [
            _previewListCard(
              title: l.t('reportExpenses'),
              countLabel:
                  '${list.length} ${l.t('records')} · ${CurrencyFormatter.format(total, currency, locale: loc)}',
              icon: Icons.receipt_long,
              color: Colors.red,
            ),
            actionsRow(
                () => _exportExpenses(l, loc, currency, user, list, nameByUid)),
          ],
        );
      case ReportType.supplierPayments:
        final list = supplierTransactions
            .where((t) => t.currency == currency && _inRange(t.date))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        final total = list.fold<num>(0, (s, t) => s + t.amount);
        return Column(
          children: [
            _previewListCard(
              title: l.t('reportSupplierPayments'),
              countLabel:
                  '${list.length} ${l.t('records')} · ${CurrencyFormatter.format(total, currency, locale: loc)}',
              icon: Icons.payments,
              color: Colors.indigo,
            ),
            actionsRow(() => _exportSupplierTransactions(
                l, loc, currency, user, list, nameByUid)),
          ],
        );
      case ReportType.debts:
        final indebted = subscribers.where((s) => s.balance > 0).toList()
          ..sort((a, b) => b.balance.compareTo(a.balance));
        final totalDebt = indebted
            .where((s) => s.currency == currency)
            .fold<num>(0, (sum, s) => sum + s.balance);
        return Column(
          children: [
            _previewListCard(
              title: 'ديون المشتركين',
              countLabel:
                  '${indebted.length} مشتركين بذمتهم ديون · إجمالي: ${CurrencyFormatter.format(totalDebt, currency, locale: loc)}',
              icon: Icons.money_off_rounded,
              color: Colors.redAccent,
            ),
            actionsRow(() => PdfReportService().previewSubscribersDebtReport(
                  subscribers: subscribers,
                  allDebts: debts,
                  generatedBy: user.displayName.isNotEmpty
                      ? user.displayName
                      : (user.email ?? 'ISP Manager'),
                  locale: loc,
                )),
          ],
        );
      case ReportType.subscriber:
        if (_selectedSubscriber == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(l.t('selectSubscriberFirst')),
              ),
            ),
          );
        }
        final sub = _selectedSubscriber!;
        final subDebts = debts.where((d) => d.subscriberId == sub.id).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final subPayments = payments
            .where((p) => p.subscriberId == sub.id)
            .toList()
          ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
        return Column(
          children: [
            _subscriberHeaderCard(sub, sub.currency, loc, l),
            _previewListCard(
              title: l.t('subscriptions'),
              countLabel:
                  '${subDebts.length} ${l.t('records')} · ${l.paid}: ${subDebts.where((d) => d.isPaid).length}',
              icon: Icons.subscriptions,
              color: Colors.blue,
            ),
            _previewListCard(
              title: l.payments,
              countLabel:
                  '${subPayments.length} ${l.t('records')} · ${CurrencyFormatter.format(subPayments.fold<num>(0, (s, p) => s + p.amount), sub.currency, locale: loc)}',
              icon: Icons.payment,
              color: Colors.teal,
            ),
            actionsRow(() => _exportSubscriber(
                l, loc, sub.currency, user, sub, subDebts, subPayments, nameByUid)),
          ],
        );
    }
  }

  Widget _subscriberHeaderCard(
      Subscriber sub, AppCurrency currency, String loc, AppLocalizations l) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sub.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            if (sub.phone != null) Text(sub.phone!),
            if (sub.packageName != null || sub.planName != null)
              Text(sub.packageName ?? sub.planName ?? ''),
            const SizedBox(height: 4),
            Text(
                '${l.balance}: ${CurrencyFormatter.format(sub.balance, currency, locale: loc)}'),
            Text(
                '${l.t('subscriptionEnd')}: ${DateFormatter.date(sub.subscriptionEndsAt, locale: loc)}'),
          ],
        ),
      ),
    );
  }

  Widget _previewListCard({
    required String title,
    required String countLabel,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .2),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(countLabel),
      ),
    );
  }

  // --- Export builders ------------------------------------------------------

  String _supplierTxTypeLabel(
      SupplierBalanceTransactionType type, AppLocalizations l) {
    switch (type) {
      case SupplierBalanceTransactionType.recharge:
        return l.t('recharge');
      case SupplierBalanceTransactionType.payment:
        return l.t('supplierPayment');
    }
  }

  Future<List<Supplier>> _supplierNames(AppUser user) async {
    return ref.read(suppliersStreamProvider(user.adminUid)).valueOrNull ??
        const [];
  }

  Future<void> _exportFinancial({
    required AppLocalizations l,
    required String loc,
    required AppCurrency currency,
    required AppUser user,
    required _ReportSummary summary,
    required List<Payment> payments,
    required List<Expense> expenses,
    required List<SupplierBalanceTransaction> supplierTransactions,
    required Map<String, String> nameByUid,
    required List<Subscriber> subscribers,
  }) async {
    String fmt(num n) => CurrencyFormatter.format(n, currency, locale: loc);
    final subName = {for (final s in subscribers) s.id: s.name};
    final rows = <List<String>>[];
    for (final p in payments
        .where((p) => p.currency == currency && _inRange(p.recordedAt))) {
      rows.add([
        DateFormatter.date(p.recordedAt, locale: loc),
        l.t('payment'),
        subName[p.subscriberId] ?? p.subscriberId,
        fmt(p.amount),
        nameByUid[p.recordedBy] ?? p.recordedBy,
      ]);
    }
    for (final e
        in expenses.where((e) => e.currency == currency && _inRange(e.date))) {
      rows.add([
        DateFormatter.date(e.date, locale: loc),
        e.type == ExpenseEntryType.withdrawal ? l.withdrawal : l.expense,
        e.reason,
        '- ${fmt(e.amount)}',
        nameByUid[e.recordedBy] ?? e.recordedByName ?? e.recordedBy,
      ]);
    }
    final supplierName = {
      for (final s in await _supplierNames(user)) s.id: s.name
    };
    for (final t in supplierTransactions
        .where((t) => t.currency == currency && _inRange(t.date))) {
      rows.add([
        DateFormatter.date(t.date, locale: loc),
        _supplierTxTypeLabel(t.type, l),
        supplierName[t.supplierId] ?? t.supplierId,
        '- ${fmt(t.amount)}',
        nameByUid[t.recordedBy] ?? t.recordedBy,
      ]);
    }
    rows.sort((a, b) => b[0].compareTo(a[0]));

    await PdfReportService().preview(PdfReportData(
      title: l.t('reportFinancial'),
      subtitle:
          'ISP Manager · ${DateFormatter.date(_from, locale: loc)} → ${DateFormatter.date(_to, locale: loc)}',
      from: _from,
      to: _to,
      generatedBy: user.displayName,
      currency: currency,
      locale: loc,
      kpis: [
        PdfKpi(l.totalRevenue, fmt(summary.revenue)),
        PdfKpi(l.totalExpenses, fmt(summary.expenses)),
        PdfKpi(l.totalWithdrawals, fmt(summary.withdrawals)),
        PdfKpi(l.totalSupplierPayments, fmt(summary.supplierPayments)),
        PdfKpi(l.totalRecharges, fmt(summary.recharges)),
        PdfKpi(l.subscriptionProfit, fmt(summary.subscriptionProfit)),
        PdfKpi(l.netProfit, fmt(summary.netProfit), highlight: true),
      ],
      tableHeaders: [
        l.date,
        l.type,
        l.t('description'),
        l.amount,
        l.by,
      ],
      tableRows: rows,
    ));
  }

  Future<void> _exportRevenue(
    AppLocalizations l,
    String loc,
    AppCurrency currency,
    AppUser user,
    List<Payment> payments,
    List<Subscriber> subscribers,
    Map<String, String> nameByUid,
  ) async {
    final subName = {for (final s in subscribers) s.id: s.name};
    final total = payments.fold<num>(0, (s, p) => s + p.amount);
    final rows = payments
        .map((p) => [
              DateFormatter.dateTime(p.recordedAt, locale: loc),
              subName[p.subscriberId] ?? p.subscriberId,
              CurrencyFormatter.format(p.amount, currency, locale: loc),
              p.method ?? '-',
              nameByUid[p.recordedBy] ?? p.recordedBy,
              p.note ?? '',
            ])
        .toList();

    await PdfReportService().preview(PdfReportData(
      title: l.t('reportRevenue'),
      from: _from,
      to: _to,
      generatedBy: user.displayName,
      currency: currency,
      locale: loc,
      kpis: [
        PdfKpi(l.t('paymentsCount'), '${payments.length}'),
        PdfKpi(l.total, CurrencyFormatter.format(total, currency, locale: loc),
            highlight: true),
      ],
      tableHeaders: [
        l.date,
        l.t('subscriber'),
        l.amount,
        l.method,
        l.by,
        l.t('notes'),
      ],
      tableRows: rows,
    ));
  }

  Future<void> _exportExpenses(
    AppLocalizations l,
    String loc,
    AppCurrency currency,
    AppUser user,
    List<Expense> expenses,
    Map<String, String> nameByUid,
  ) async {
    final total = expenses.fold<num>(0, (s, e) => s + e.amount);
    final byCat = <String, num>{};
    for (final e in expenses) {
      byCat[e.category.name] = (byCat[e.category.name] ?? 0) + e.amount;
    }
    final rows = expenses
        .map((e) => [
              DateFormatter.dateTime(e.date, locale: loc),
              e.type == ExpenseEntryType.withdrawal ? l.withdrawal : l.expense,
              e.category.name,
              e.reason,
              CurrencyFormatter.format(e.amount, currency, locale: loc),
              nameByUid[e.recordedBy] ?? e.recordedByName ?? e.recordedBy,
            ])
        .toList();

    await PdfReportService().preview(PdfReportData(
      title: l.t('reportExpenses'),
      from: _from,
      to: _to,
      generatedBy: user.displayName,
      currency: currency,
      locale: loc,
      kpis: [
        PdfKpi(l.t('operationsCount'), '${expenses.length}'),
        PdfKpi(l.total, CurrencyFormatter.format(total, currency, locale: loc),
            highlight: true),
        ...byCat.entries.map((e) => PdfKpi(
            e.key, CurrencyFormatter.format(e.value, currency, locale: loc))),
      ],
      tableHeaders: [
        l.date,
        l.type,
        l.category,
        l.reason,
        l.amount,
        l.by,
      ],
      tableRows: rows,
    ));
  }

  Future<void> _exportSupplierTransactions(
    AppLocalizations l,
    String loc,
    AppCurrency currency,
    AppUser user,
    List<SupplierBalanceTransaction> txs,
    Map<String, String> nameByUid,
  ) async {
    final total = txs.fold<num>(0, (s, t) => s + t.amount);
    final supplierName = {
      for (final s in await _supplierNames(user)) s.id: s.name
    };
    final rows = txs
        .map((t) => [
              DateFormatter.dateTime(t.date, locale: loc),
              supplierName[t.supplierId] ?? t.supplierId,
              _supplierTxTypeLabel(t.type, l),
              CurrencyFormatter.format(t.amount, currency, locale: loc),
              nameByUid[t.recordedBy] ?? t.recordedBy,
              t.note ?? '',
            ])
        .toList();

    await PdfReportService().preview(PdfReportData(
      title: l.t('reportSupplierPayments'),
      from: _from,
      to: _to,
      generatedBy: user.displayName,
      currency: currency,
      locale: loc,
      kpis: [
        PdfKpi(l.t('operationsCount'), '${txs.length}'),
        PdfKpi(l.total, CurrencyFormatter.format(total, currency, locale: loc),
            highlight: true),
      ],
      tableHeaders: [
        l.date,
        l.t('supplier'),
        l.type,
        l.amount,
        l.by,
        l.t('notes'),
      ],
      tableRows: rows,
    ));
  }

  Future<void> _exportSubscriber(
    AppLocalizations l,
    String loc,
    AppCurrency currency,
    AppUser user,
    Subscriber sub,
    List<SubscriberDebt> debts,
    List<Payment> payments,
    Map<String, String> nameByUid,
  ) async {
    final filteredDebts = debts.where((d) => _inRange(d.createdAt)).toList();
    final filteredPayments =
        payments.where((p) => _inRange(p.recordedAt)).toList();

    await PdfReportService().previewSubscriberStatement(
      subscriber: sub,
      debts: filteredDebts.isNotEmpty ? filteredDebts : debts,
      payments: filteredPayments.isNotEmpty ? filteredPayments : payments,
      generatedBy: user.displayName.isNotEmpty
          ? user.displayName
          : (user.email ?? 'ISP Manager'),
      locale: loc,
    );
  }

  // --- Summary helpers ------------------------------------------------------

  _ReportSummary _buildSummary({
    required List<Payment> payments,
    required List<Expense> expenses,
    required List<SupplierBalanceTransaction> supplierTransactions,
    required List<SubscriberDebt> debts,
    required AppCurrency currency,
  }) {
    final revenue = payments
        .where((p) => p.currency == currency && _inRange(p.recordedAt))
        .fold<num>(0, (s, p) => s + p.amount);
    final expenseTotal = expenses
        .where((e) =>
            e.currency == currency &&
            e.type == ExpenseEntryType.expense &&
            _inRange(e.date))
        .fold<num>(0, (s, e) => s + e.amount);
    final withdrawals = expenses
        .where((e) =>
            e.currency == currency &&
            e.type == ExpenseEntryType.withdrawal &&
            _inRange(e.date))
        .fold<num>(0, (s, e) => s + e.amount);
    final supplierPayments = supplierTransactions
        .where((t) =>
            t.currency == currency &&
            t.type == SupplierBalanceTransactionType.payment &&
            _inRange(t.date))
        .fold<num>(0, (s, t) => s + t.amount);
    final recharges = supplierTransactions
        .where((t) =>
            t.currency == currency &&
            t.type == SupplierBalanceTransactionType.recharge &&
            _inRange(t.date))
        .fold<num>(0, (s, t) => s + t.amount);
    final subscriptionProfit = debts
        .where((d) =>
            d.currency == currency &&
            d.isPaid &&
            d.paidAt != null &&
            _inRange(d.paidAt!))
        .fold<num>(0, (s, d) => s + d.profit);
    return _ReportSummary(
      revenue: revenue,
      expenses: expenseTotal,
      withdrawals: withdrawals,
      supplierPayments: supplierPayments,
      recharges: recharges,
      subscriptionProfit: subscriptionProfit,
      netProfit: subscriptionProfit - expenseTotal - withdrawals,
    );
  }

  bool _inRange(DateTime date) {
    final from = DateTime(_from.year, _from.month, _from.day);
    final to = DateTime(_to.year, _to.month, _to.day, 23, 59, 59);
    return !date.isBefore(from) && !date.isAfter(to);
  }

  Future<void> _pickFrom(BuildContext context) async {
    final d = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _from = d);
  }

  Future<void> _pickTo(BuildContext context) async {
    final d = await showDatePicker(
      context: context,
      initialDate: _to,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _to = d);
  }

  Widget _kpi(String label, num value, AppCurrency currency, String loc,
      Color color, IconData icon) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .2),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        trailing: Text(
          CurrencyFormatter.format(value, currency, locale: loc),
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}

class _ReportSummary {
  const _ReportSummary({
    required this.revenue,
    required this.expenses,
    required this.withdrawals,
    required this.supplierPayments,
    required this.recharges,
    required this.subscriptionProfit,
    required this.netProfit,
  });

  final num revenue;
  final num expenses;
  final num withdrawals;
  final num supplierPayments;
  final num recharges;
  final num subscriptionProfit;
  final num netProfit;
}
