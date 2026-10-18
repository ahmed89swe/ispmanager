import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/models/models.dart';
import '../../core/utils/formatters.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/providers/preferences_providers.dart';
import '../auth/auth_repository.dart';
import '../employees/employees_repository.dart';
import 'cashbox_repository.dart';

enum _LedgerFilterType { all, income, expense, settlement }

class CashboxScreen extends ConsumerStatefulWidget {
  const CashboxScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  final int initialTabIndex;

  @override
  ConsumerState<CashboxScreen> createState() => _CashboxScreenState();
}

class _CashboxScreenState extends ConsumerState<CashboxScreen> {
  AppCurrency? _selectedCurrencyFilter;
  _LedgerFilterType _selectedFilterType = _LedgerFilterType.all;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentAppUserProvider).valueOrNull;
    if (user == null) {
      return Scaffold(body: Center(child: Text(l.pleaseSignIn)));
    }
    final loc = Localizations.localeOf(context).languageCode;
    final defaultCurrency = ref.watch(currencyProvider);
    final cashboxAsync = ref.watch(cashboxStreamProvider(user.adminUid));
    final ledgerAsync = ref.watch(cashboxLedgerStreamProvider(user.adminUid));

    if (user.isAdmin) {
      return DefaultTabController(
        length: 2,
        initialIndex: widget.initialTabIndex.clamp(0, 1),
        child: Scaffold(
          appBar: AppBar(
            title: Text(l.t('cashboxLedger')),
            bottom: TabBar(
              tabs: [
                Tab(
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  text: l.t('generalCashbox'),
                ),
                Tab(
                  icon: const Icon(Icons.people_alt_outlined),
                  text: l.t('staffDebtsAndAccounts'),
                ),
              ],
            ),
          ),
          body: cashboxAsync.when(
            skipLoadingOnReload: true,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _buildErrorState(context, l, user, e),
            data: (cashbox) => TabBarView(
              children: [
                _buildAdminGeneralCashboxTab(
                  context,
                  l,
                  loc,
                  user,
                  cashbox,
                  defaultCurrency,
                  ledgerAsync,
                ),
                _buildAdminStaffDebtsTab(
                  context,
                  l,
                  loc,
                  user,
                  cashbox,
                  defaultCurrency,
                  ledgerAsync,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Employee dedicated view: My Cashbox Account
    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('myCashboxAccount')),
      ),
      body: cashboxAsync.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildErrorState(context, l, user, e),
        data: (cashbox) => _buildEmployeePersonalView(
          context,
          l,
          loc,
          user,
          cashbox,
          defaultCurrency,
          ledgerAsync,
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    AppLocalizations l,
    AppUser user,
    Object error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 56, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(
              l.errorOccurred,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                ref.invalidate(cashboxStreamProvider(user.adminUid));
                ref.invalidate(cashboxLedgerStreamProvider(user.adminUid));
              },
              icon: const Icon(Icons.refresh),
              label: Text(l.retry),
            ),
          ],
        ),
      ),
    );
  }

  // Admin Tab 1: General Cashbox & Full Ledger
  Widget _buildAdminGeneralCashboxTab(
    BuildContext context,
    AppLocalizations l,
    String loc,
    AppUser user,
    CashboxSnapshot cashbox,
    AppCurrency defaultCurrency,
    AsyncValue<List<CashboxLedgerEntry>> ledgerAsync,
  ) {
    final iqdBalance = cashbox.balanceFor(AppCurrency.iqd);
    final usdBalance = cashbox.balanceFor(AppCurrency.usd);
    final iqdStaffDebt = cashbox.totalStaffDebtToCashbox(AppCurrency.iqd);
    final usdStaffDebt = cashbox.totalStaffDebtToCashbox(AppCurrency.usd);
    final iqdBoxDebt = cashbox.totalCashboxDebtToStaff(AppCurrency.iqd);
    final usdBoxDebt = cashbox.totalCashboxDebtToStaff(AppCurrency.usd);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(cashboxStreamProvider(user.adminUid));
        ref.invalidate(cashboxLedgerStreamProvider(user.adminUid));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBalancesSection(
            context,
            l,
            loc,
            iqdBalance,
            usdBalance,
            iqdStaffDebt,
            usdStaffDebt,
            iqdBoxDebt,
            usdBoxDebt,
          ),
          const SizedBox(height: 16),
          _buildActionButtons(context, l, user, cashbox, defaultCurrency),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.t('ledger'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              _buildFiltersRow(l),
            ],
          ),
          const SizedBox(height: 12),
          ledgerAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Center(child: Text('$err')),
            ),
            data: (entries) {
              final filtered = _filterEntries(entries);
              if (filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text(l.noData)),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, idx) =>
                    _buildLedgerTile(ctx, l, loc, filtered[idx]),
              );
            },
          ),
        ],
      ),
    );
  }

  // Admin Tab 2: Staff Accounts & Debts List
  Widget _buildAdminStaffDebtsTab(
    BuildContext context,
    AppLocalizations l,
    String loc,
    AppUser user,
    CashboxSnapshot cashbox,
    AppCurrency defaultCurrency,
    AsyncValue<List<CashboxLedgerEntry>> ledgerAsync,
  ) {
    final employeesAsync = ref.watch(employeesStreamProvider(user.adminUid));
    final iqdStaffDebt = cashbox.totalStaffDebtToCashbox(AppCurrency.iqd);
    final usdStaffDebt = cashbox.totalStaffDebtToCashbox(AppCurrency.usd);
    final iqdBoxDebt = cashbox.totalCashboxDebtToStaff(AppCurrency.iqd);
    final usdBoxDebt = cashbox.totalCashboxDebtToStaff(AppCurrency.usd);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(cashboxStreamProvider(user.adminUid));
        ref.invalidate(cashboxLedgerStreamProvider(user.adminUid));
        ref.invalidate(employeesStreamProvider(user.adminUid));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStaffDebtsOverviewHeader(
            context,
            l,
            loc,
            iqdStaffDebt,
            usdStaffDebt,
            iqdBoxDebt,
            usdBoxDebt,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.t('staffDebtsAndAccounts'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _showSettleDebtDialog(
                  context,
                  l,
                  user,
                  cashbox,
                  defaultCurrency,
                ),
                icon: const Icon(Icons.sync_alt, size: 16),
                label: Text(
                  l.t('settleStaffDebt'),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          employeesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Center(child: Text('$err')),
            data: (employees) {
              if (employees.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text(l.noData)),
                );
              }
              final ledger = ledgerAsync.valueOrNull ?? [];
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: employees.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, idx) => _buildEmployeeDebtCard(
                  ctx,
                  l,
                  loc,
                  user,
                  employees[idx],
                  cashbox,
                  defaultCurrency,
                  ledger,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStaffDebtsOverviewHeader(
    BuildContext context,
    AppLocalizations l,
    String loc,
    num iqdStaffDebt,
    num usdStaffDebt,
    num iqdBoxDebt,
    num usdBoxDebt,
  ) {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 1,
            color: Colors.orange.withAlpha(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.orange.withAlpha(80)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.arrow_upward_rounded,
                          size: 16, color: Colors.orange.shade800),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l.t('totalStaffDebt'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.format(iqdStaffDebt, AppCurrency.iqd,
                        locale: loc),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(usdStaffDebt, AppCurrency.usd,
                        locale: loc),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            elevation: 1,
            color: Colors.blue.withAlpha(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.blue.withAlpha(80)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.arrow_downward_rounded,
                          size: 16, color: Colors.blue.shade800),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l.t('totalCashboxDebt'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.format(iqdBoxDebt, AppCurrency.iqd,
                        locale: loc),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(usdBoxDebt, AppCurrency.usd,
                        locale: loc),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeDebtCard(
    BuildContext context,
    AppLocalizations l,
    String loc,
    AppUser adminUser,
    Employee employee,
    CashboxSnapshot cashbox,
    AppCurrency defaultCurrency,
    List<CashboxLedgerEntry> ledger,
  ) {
    final theme = Theme.of(context);
    final iqdOwedToBox =
        cashbox.staffDebtToCashboxForUid(employee.uid, AppCurrency.iqd);
    final usdOwedToBox =
        cashbox.staffDebtToCashboxForUid(employee.uid, AppCurrency.usd);
    final iqdOwedByBox =
        cashbox.cashboxDebtToStaffForUid(employee.uid, AppCurrency.iqd);
    final usdOwedByBox =
        cashbox.cashboxDebtToStaffForUid(employee.uid, AppCurrency.usd);

    final hasDebtToBox = iqdOwedToBox > 0 || usdOwedToBox > 0;
    final hasCreditByBox = iqdOwedByBox > 0 || usdOwedByBox > 0;
    final isBalanced = !hasDebtToBox && !hasCreditByBox;

    final empEntries = ledger.where((e) {
      return e.actorUid == employee.uid || e.subscriberId == employee.uid;
    }).toList();

    num pocketSpentIqd = 0;
    num pocketSpentUsd = 0;
    num custodyCollectedIqd = 0;
    num custodyCollectedUsd = 0;

    for (final e in empEntries) {
      if (e.isPaidFromPersonal) {
        if (e.currency == AppCurrency.iqd) {
          pocketSpentIqd += e.amount;
        } else {
          pocketSpentUsd += e.amount;
        }
      }
      if (e.isCustodyPayment) {
        if (e.currency == AppCurrency.iqd) {
          custodyCollectedIqd += e.amount;
        } else {
          custodyCollectedUsd += e.amount;
        }
      }
    }

    final subtitle = employee.username.isNotEmpty
        ? employee.username
        : (employee.email.isNotEmpty ? employee.email : '');

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: hasDebtToBox
              ? Colors.orange.shade300.withAlpha(120)
              : (hasCreditByBox
                  ? Colors.blue.shade300.withAlpha(120)
                  : theme.colorScheme.outlineVariant.withAlpha(80)),
          width: hasDebtToBox || hasCreditByBox ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: hasDebtToBox
                      ? Colors.orange.withAlpha(30)
                      : (hasCreditByBox
                          ? Colors.blue.withAlpha(30)
                          : theme.colorScheme.primaryContainer),
                  foregroundColor: hasDebtToBox
                      ? Colors.orange.shade800
                      : (hasCreditByBox
                          ? Colors.blue.shade800
                          : theme.colorScheme.onPrimaryContainer),
                  child: Text(
                    employee.displayName.isNotEmpty
                        ? employee.displayName.substring(0, 1).toUpperCase()
                        : 'E',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasDebtToBox
                        ? Colors.orange.withAlpha(25)
                        : (hasCreditByBox
                            ? Colors.blue.withAlpha(25)
                            : Colors.green.withAlpha(25)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    hasDebtToBox
                        ? l.t('staffOwesCashbox')
                        : (hasCreditByBox
                            ? l.t('staffOwedByCashbox')
                            : l.t('balancedAccount')),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: hasDebtToBox
                          ? Colors.orange.shade800
                          : (hasCreditByBox
                              ? Colors.blue.shade800
                              : Colors.green.shade800),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 14,
                              color: hasDebtToBox
                                  ? Colors.orange.shade800
                                  : theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                l.t('staffOwesCashbox'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: hasDebtToBox
                                      ? Colors.orange.shade800
                                      : theme.colorScheme.outline,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(
                              iqdOwedToBox, AppCurrency.iqd,
                              locale: loc),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: hasDebtToBox
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: hasDebtToBox
                                ? Colors.orange.shade900
                                : theme.colorScheme.outline,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(
                              usdOwedToBox, AppCurrency.usd,
                              locale: loc),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: hasDebtToBox
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: hasDebtToBox
                                ? Colors.orange.shade800
                                : theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 44,
                    color: theme.dividerColor.withAlpha(80),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.arrow_downward_rounded,
                              size: 14,
                              color: hasCreditByBox
                                  ? Colors.blue.shade800
                                  : theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                l.t('staffOwedByCashbox'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: hasCreditByBox
                                      ? Colors.blue.shade800
                                      : theme.colorScheme.outline,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(
                              iqdOwedByBox, AppCurrency.iqd,
                              locale: loc),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: hasCreditByBox
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: hasCreditByBox
                                ? Colors.blue.shade900
                                : theme.colorScheme.outline,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(
                              usdOwedByBox, AppCurrency.usd,
                              locale: loc),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: hasCreditByBox
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: hasCreditByBox
                                ? Colors.blue.shade800
                                : theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (pocketSpentIqd > 0 ||
                pocketSpentUsd > 0 ||
                custodyCollectedIqd > 0 ||
                custodyCollectedUsd > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.surfaceContainerHighest.withAlpha(90),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withAlpha(70),
                  ),
                ),
                child: Row(
                  children: [
                    if (pocketSpentIqd > 0 || pocketSpentUsd > 0)
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.person_pin_outlined,
                                size: 14, color: Colors.blue.shade800),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'صرف من الجيب: ${pocketSpentIqd > 0 ? CurrencyFormatter.format(pocketSpentIqd, AppCurrency.iqd, locale: loc) : CurrencyFormatter.format(pocketSpentUsd, AppCurrency.usd, locale: loc)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if ((pocketSpentIqd > 0 || pocketSpentUsd > 0) &&
                        (custodyCollectedIqd > 0 || custodyCollectedUsd > 0))
                      Container(
                        width: 1,
                        height: 18,
                        color: theme.dividerColor.withAlpha(80),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                    if (custodyCollectedIqd > 0 || custodyCollectedUsd > 0)
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 14, color: Colors.amber.shade900),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'قُبض بالعهدة: ${custodyCollectedIqd > 0 ? CurrencyFormatter.format(custodyCollectedIqd, AppCurrency.iqd, locale: loc) : CurrencyFormatter.format(custodyCollectedUsd, AppCurrency.usd, locale: loc)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber.shade900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    _showEmployeeAccountStatementSheet(
                      context,
                      l,
                      loc,
                      adminUser,
                      employee,
                      cashbox,
                      defaultCurrency,
                      empEntries,
                    );
                  },
                  icon: const Icon(Icons.receipt_long_outlined, size: 16),
                  label: const Text(
                    'كشف الحساب والتفاصيل',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                  ),
                ),
                if (hasDebtToBox || isBalanced)
                  FilledButton.tonalIcon(
                    onPressed: () {
                      final curr = iqdOwedToBox > 0
                          ? AppCurrency.iqd
                          : (usdOwedToBox > 0
                              ? AppCurrency.usd
                              : defaultCurrency);
                      final amt = iqdOwedToBox > 0
                          ? iqdOwedToBox
                          : (usdOwedToBox > 0 ? usdOwedToBox : null);
                      _showSettleDebtDialog(
                        context,
                        l,
                        adminUser,
                        cashbox,
                        defaultCurrency,
                        initialEmployeeUid: employee.uid,
                        initialEmployeeName: employee.displayName,
                        initialDirection: StaffSettlementDirection.toCashbox,
                        initialAmount: amt,
                        initialCurrency: curr,
                      );
                    },
                    icon: const Icon(Icons.input_rounded, size: 16),
                    label: Text(
                      l.t('payToCashbox'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.teal.withAlpha(25),
                      foregroundColor: Colors.teal.shade800,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                  ),
                if (hasCreditByBox || isBalanced)
                  FilledButton.tonalIcon(
                    onPressed: () {
                      final curr = iqdOwedByBox > 0
                          ? AppCurrency.iqd
                          : (usdOwedByBox > 0
                              ? AppCurrency.usd
                              : defaultCurrency);
                      final amt = iqdOwedByBox > 0
                          ? iqdOwedByBox
                          : (usdOwedByBox > 0 ? usdOwedByBox : null);
                      _showSettleDebtDialog(
                        context,
                        l,
                        adminUser,
                        cashbox,
                        defaultCurrency,
                        initialEmployeeUid: employee.uid,
                        initialEmployeeName: employee.displayName,
                        initialDirection: StaffSettlementDirection.fromCashbox,
                        initialAmount: amt,
                        initialCurrency: curr,
                      );
                    },
                    icon: const Icon(Icons.output_rounded, size: 16),
                    label: Text(
                      l.t('claimReimbursement'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blue.withAlpha(25),
                      foregroundColor: Colors.blue.shade800,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Employee View: My Cashbox Account & Personal History
  Widget _buildEmployeePersonalView(
    BuildContext context,
    AppLocalizations l,
    String loc,
    AppUser user,
    CashboxSnapshot cashbox,
    AppCurrency defaultCurrency,
    AsyncValue<List<CashboxLedgerEntry>> ledgerAsync,
  ) {
    final iqdOwedToBox =
        cashbox.staffDebtToCashboxForUid(user.uid, AppCurrency.iqd);
    final usdOwedToBox =
        cashbox.staffDebtToCashboxForUid(user.uid, AppCurrency.usd);
    final iqdOwedByBox =
        cashbox.cashboxDebtToStaffForUid(user.uid, AppCurrency.iqd);
    final usdOwedByBox =
        cashbox.cashboxDebtToStaffForUid(user.uid, AppCurrency.usd);

    final netIqd = cashbox.netStaffDebtForUid(user.uid, AppCurrency.iqd);
    final netUsd = cashbox.netStaffDebtForUid(user.uid, AppCurrency.usd);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(cashboxStreamProvider(user.adminUid));
        ref.invalidate(cashboxLedgerStreamProvider(user.adminUid));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _BalanceCard(
                  title: '${l.t('generalCashbox')} (IQD)',
                  amount: cashbox.balanceFor(AppCurrency.iqd),
                  currency: AppCurrency.iqd,
                  color: Colors.teal,
                  icon: Icons.account_balance_wallet,
                  locale: loc,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BalanceCard(
                  title: '${l.t('generalCashbox')} (USD)',
                  amount: cashbox.balanceFor(AppCurrency.usd),
                  currency: AppCurrency.usd,
                  color: Colors.green,
                  icon: Icons.attach_money,
                  locale: loc,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildEmployeeHeroAccountCard(
            context,
            l,
            loc,
            user,
            cashbox,
            defaultCurrency,
            iqdOwedToBox,
            usdOwedToBox,
            iqdOwedByBox,
            usdOwedByBox,
            netIqd,
            netUsd,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.t('ledger'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              _buildFiltersRow(l),
            ],
          ),
          const SizedBox(height: 12),
          ledgerAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Center(child: Text('$err')),
            ),
            data: (entries) {
              final myEntries = entries.where((e) {
                return e.actorUid == user.uid || e.subscriberId == user.uid;
              }).toList();
              final filtered = _filterEntries(myEntries);
              if (filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text(l.noData)),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, idx) =>
                    _buildLedgerTile(ctx, l, loc, filtered[idx]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeHeroAccountCard(
    BuildContext context,
    AppLocalizations l,
    String loc,
    AppUser user,
    CashboxSnapshot cashbox,
    AppCurrency defaultCurrency,
    num iqdOwedToBox,
    num usdOwedToBox,
    num iqdOwedByBox,
    num usdOwedByBox,
    num netIqd,
    num netUsd,
  ) {
    final hasDebt = iqdOwedToBox > 0 || usdOwedToBox > 0;
    final hasCredit = iqdOwedByBox > 0 || usdOwedByBox > 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F2B48),
            Color(0xFF1B4965),
            Color(0xFF1E555C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2B48).withAlpha(80),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withAlpha(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l.t('myCashboxAccount'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(18),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: hasDebt
                                ? Colors.amberAccent.withAlpha(140)
                                : Colors.white.withAlpha(25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.arrow_upward_rounded,
                                    size: 14, color: Colors.amberAccent),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    l.t('owedToCashbox'),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                CurrencyFormatter.format(
                                  iqdOwedToBox,
                                  AppCurrency.iqd,
                                  locale: loc,
                                ),
                                style: TextStyle(
                                  color: hasDebt
                                      ? Colors.amberAccent
                                      : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                CurrencyFormatter.format(
                                  usdOwedToBox,
                                  AppCurrency.usd,
                                  locale: loc,
                                ),
                                style: TextStyle(
                                  color: hasDebt
                                      ? Colors.amberAccent
                                      : Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(18),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: hasCredit
                                ? Colors.lightBlueAccent.withAlpha(140)
                                : Colors.white.withAlpha(25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.arrow_downward_rounded,
                                    size: 14, color: Colors.lightBlueAccent),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    l.t('owedByCashbox'),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                CurrencyFormatter.format(
                                  iqdOwedByBox,
                                  AppCurrency.iqd,
                                  locale: loc,
                                ),
                                style: TextStyle(
                                  color: hasCredit
                                      ? Colors.lightBlueAccent
                                      : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                CurrencyFormatter.format(
                                  usdOwedByBox,
                                  AppCurrency.usd,
                                  locale: loc,
                                ),
                                style: TextStyle(
                                  color: hasCredit
                                      ? Colors.lightBlueAccent
                                      : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        netIqd > 0 || netUsd > 0
                            ? Icons.info_outline
                            : (netIqd < 0 || netUsd < 0
                                ? Icons.check_circle_outline
                                : Icons.done_all),
                        size: 16,
                        color: netIqd > 0 || netUsd > 0
                            ? Colors.amberAccent
                            : (netIqd < 0 || netUsd < 0
                                ? Colors.lightBlueAccent
                                : Colors.greenAccent),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          netIqd > 0 || netUsd > 0
                              ? '${l.t('staffNetYouOwe')}: ${CurrencyFormatter.format(netIqd > 0 ? netIqd : netUsd, netIqd > 0 ? AppCurrency.iqd : AppCurrency.usd, locale: loc)}'
                              : (netIqd < 0 || netUsd < 0
                                  ? '${l.t('staffNetBoxOwes')}: ${CurrencyFormatter.format((netIqd < 0 ? -netIqd : -netUsd), netIqd < 0 ? AppCurrency.iqd : AppCurrency.usd, locale: loc)}'
                                  : l.t('allStaffBalanced')),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          final curr = iqdOwedToBox > 0
                              ? AppCurrency.iqd
                              : (usdOwedToBox > 0
                                  ? AppCurrency.usd
                                  : defaultCurrency);
                          final amt = iqdOwedToBox > 0
                              ? iqdOwedToBox
                              : (usdOwedToBox > 0 ? usdOwedToBox : null);
                          _showSettleDebtDialog(
                            context,
                            l,
                            user,
                            cashbox,
                            defaultCurrency,
                            initialEmployeeUid: user.uid,
                            initialEmployeeName: user.displayName,
                            initialDirection:
                                StaffSettlementDirection.toCashbox,
                            initialAmount: amt,
                            initialCurrency: curr,
                            lockEmployee: true,
                          );
                        },
                        icon: const Icon(Icons.input_rounded, size: 16),
                        label: Text(l.t('payToCashbox')),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.tealAccent.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () {
                          final curr = iqdOwedByBox > 0
                              ? AppCurrency.iqd
                              : (usdOwedByBox > 0
                                  ? AppCurrency.usd
                                  : defaultCurrency);
                          final amt = iqdOwedByBox > 0
                              ? iqdOwedByBox
                              : (usdOwedByBox > 0 ? usdOwedByBox : null);
                          _showClaimReimbursementRequestDialog(
                            context,
                            l,
                            user,
                            cashbox,
                            defaultCurrency,
                            initialAmount: amt,
                            initialCurrency: curr,
                          );
                        },
                        icon: const Icon(Icons.output_rounded, size: 16),
                        label: Text(l.t('claimReimbursement')),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white.withAlpha(45),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalancesSection(
    BuildContext context,
    AppLocalizations l,
    String loc,
    num iqdBalance,
    num usdBalance,
    num iqdStaffDebt,
    num usdStaffDebt,
    num iqdBoxDebt,
    num usdBoxDebt,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _BalanceCard(
                title: '${l.t('cashboxBalance')} (IQD)',
                amount: iqdBalance,
                currency: AppCurrency.iqd,
                color: Colors.teal,
                icon: Icons.account_balance_wallet,
                locale: loc,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BalanceCard(
                title: '${l.t('cashboxBalance')} (USD)',
                amount: usdBalance,
                currency: AppCurrency.usd,
                color: Colors.green,
                icon: Icons.attach_money,
                locale: loc,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Card(
                elevation: 1,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.arrow_upward,
                              size: 16, color: Colors.orange.shade800),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              l.t('totalStaffDebt'),
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${CurrencyFormatter.format(iqdStaffDebt, AppCurrency.iqd, locale: loc)}'
                        '\n${CurrencyFormatter.format(usdStaffDebt, AppCurrency.usd, locale: loc)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                elevation: 1,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.arrow_downward,
                              size: 16, color: Colors.blue.shade800),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              l.t('totalCashboxDebt'),
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${CurrencyFormatter.format(iqdBoxDebt, AppCurrency.iqd, locale: loc)}'
                        '\n${CurrencyFormatter.format(usdBoxDebt, AppCurrency.usd, locale: loc)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    AppLocalizations l,
    AppUser user,
    CashboxSnapshot cashbox,
    AppCurrency defaultCurrency,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      children: [
        FilledButton.tonalIcon(
          onPressed: () => _showDirectAdjustmentDialog(
            context,
            l,
            user,
            cashbox,
            isDeposit: true,
            defaultCurrency: defaultCurrency,
          ),
          icon: const Icon(Icons.add_circle_outline, color: Colors.green),
          label: Text(l.t('directDeposit')),
        ),
        FilledButton.tonalIcon(
          onPressed: () => _showDirectAdjustmentDialog(
            context,
            l,
            user,
            cashbox,
            isDeposit: false,
            defaultCurrency: defaultCurrency,
          ),
          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
          label: Text(l.t('directWithdrawal')),
        ),
        FilledButton.tonalIcon(
          onPressed: () => _showSettleDebtDialog(
            context,
            l,
            user,
            cashbox,
            defaultCurrency,
          ),
          icon: const Icon(Icons.sync_alt, color: Colors.blue),
          label: Text(l.t('settleStaffDebt')),
        ),
      ],
    );
  }

  Widget _buildFiltersRow(AppLocalizations l) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButton<AppCurrency?>(
          value: _selectedCurrencyFilter,
          underline: const SizedBox.shrink(),
          isDense: true,
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(l.t('allCurrencies'),
                  style: const TextStyle(fontSize: 12)),
            ),
            ...AppCurrency.values.map(
              (c) => DropdownMenuItem(
                value: c,
                child: Text(c.code, style: const TextStyle(fontSize: 12)),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _selectedCurrencyFilter = v),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<_LedgerFilterType>(
          icon: const Icon(Icons.filter_list, size: 20),
          tooltip: l.filter,
          initialValue: _selectedFilterType,
          onSelected: (t) => setState(() => _selectedFilterType = t),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: _LedgerFilterType.all,
              child: Text(l.t('allOperations')),
            ),
            PopupMenuItem(
              value: _LedgerFilterType.income,
              child: Text(l.t('income')),
            ),
            PopupMenuItem(
              value: _LedgerFilterType.expense,
              child: Text(l.t('withdrawal')),
            ),
            PopupMenuItem(
              value: _LedgerFilterType.settlement,
              child: Text(l.t('settlement')),
            ),
          ],
        ),
      ],
    );
  }

  List<CashboxLedgerEntry> _filterEntries(List<CashboxLedgerEntry> list) {
    return list.where((e) {
      if (_selectedCurrencyFilter != null &&
          e.currency != _selectedCurrencyFilter) {
        return false;
      }
      switch (_selectedFilterType) {
        case _LedgerFilterType.all:
          return true;
        case _LedgerFilterType.income:
          return e.isDirectCashIncrease || e.kind == 'manualDeposit';
        case _LedgerFilterType.expense:
          return e.isDirectCashDecrease ||
              e.kind == 'manualWithdrawal' ||
              e.kind == 'supplierPayment' ||
              e.kind == 'supplierRecharge' ||
              e.kind == 'expense' ||
              e.kind == 'withdrawal';
        case _LedgerFilterType.settlement:
          return e.isSettlement;
      }
    }).toList();
  }

  Widget _buildLedgerTile(
    BuildContext context,
    AppLocalizations l,
    String loc,
    CashboxLedgerEntry entry,
  ) {
    final isIncrease = entry.isDirectCashIncrease;
    final isDecrease = entry.isDirectCashDecrease;
    final isSettlement = entry.isSettlement;

    Color badgeColor;
    IconData icon;
    String sign = '';

    if (isSettlement) {
      badgeColor = Colors.teal;
      icon = Icons.sync_alt;
      sign = entry.kind == 'staffSettlement' ? '+' : '-';
    } else if (entry.isPaidFromPersonal) {
      badgeColor = Colors.blue.shade700;
      icon = Icons.person_pin_outlined;
      sign = '';
    } else if (entry.isCustodyPayment) {
      badgeColor = Colors.amber.shade900;
      icon = Icons.inventory_2_outlined;
      sign = '';
    } else if (isIncrease) {
      badgeColor = Colors.green;
      icon = Icons.arrow_downward;
      sign = '+';
    } else if (isDecrease) {
      badgeColor = Colors.red;
      icon = Icons.arrow_upward;
      sign = '-';
    } else {
      badgeColor = Colors.orange;
      icon = Icons.account_balance_wallet_outlined;
    }

    String title = _entryTitle(entry, l);
    String subtitle = '${DateFormatter.dateTime(entry.createdAt, locale: loc)}'
        ' • ${entry.actorName.isEmpty ? l.employee : entry.actorName}';
    if (entry.isPaidFromPersonal) {
      subtitle += ' • (من جيب الموظف)';
    } else if (entry.isCustodyPayment) {
      subtitle += ' • (بالعهدة)';
    } else if (entry.isPaidFromCashbox) {
      subtitle += ' • (من الصندوق)';
    }
    if (entry.note != null && entry.note!.isNotEmpty) {
      subtitle += '\n${entry.note}';
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: badgeColor.withAlpha(30),
        foregroundColor: badgeColor,
        child: Icon(icon, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      isThreeLine: entry.note != null && entry.note!.isNotEmpty,
      trailing: Text(
        '$sign${CurrencyFormatter.format(entry.amount, entry.currency, locale: loc)}',
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  String _entryTitle(CashboxLedgerEntry entry, AppLocalizations l) {
    switch (entry.kind) {
      case 'subscriptionPayment':
        return '${l.t('payment')}: ${entry.subscriberName ?? '-'}';
      case 'expense':
        return '${l.t('expense')}: ${entry.reason ?? '-'}';
      case 'withdrawal':
        return '${l.t('withdrawal')}: ${entry.reason ?? '-'}';
      case 'supplierPayment':
        return '${l.t('supplierPayment')}: ${entry.supplierName ?? '-'}';
      case 'supplierRecharge':
        return 'تعبئة رصيد مجهز: ${entry.supplierName ?? '-'}';
      case 'staffSettlement':
        return '${l.t('staffSettlement')}: ${entry.subscriberName ?? '-'}';
      case 'staffReimbursement':
        return '${l.t('staffReimbursement')}: ${entry.subscriberName ?? '-'}';
      case 'manualDeposit':
        return '${l.t('manualDeposit')}: ${entry.reason ?? '-'}';
      case 'manualWithdrawal':
        return '${l.t('manualWithdrawal')}: ${entry.reason ?? '-'}';
      default:
        return entry.kind;
    }
  }

  void _showDirectAdjustmentDialog(
    BuildContext context,
    AppLocalizations l,
    AppUser user,
    CashboxSnapshot cashbox, {
    required bool isDeposit,
    required AppCurrency defaultCurrency,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DirectAdjustmentSheet(
        user: user,
        cashbox: cashbox,
        isDeposit: isDeposit,
        defaultCurrency: defaultCurrency,
      ),
    );
  }

  void _showSettleDebtDialog(
    BuildContext context,
    AppLocalizations l,
    AppUser user,
    CashboxSnapshot cashbox,
    AppCurrency defaultCurrency, {
    String? initialEmployeeUid,
    String? initialEmployeeName,
    StaffSettlementDirection? initialDirection,
    num? initialAmount,
    AppCurrency? initialCurrency,
    bool lockEmployee = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SettleStaffDebtSheet(
        user: user,
        cashbox: cashbox,
        defaultCurrency: defaultCurrency,
        initialEmployeeUid: initialEmployeeUid,
        initialEmployeeName: initialEmployeeName,
        initialDirection: initialDirection,
        initialAmount: initialAmount,
        initialCurrency: initialCurrency,
        lockEmployee: lockEmployee,
      ),
    );
  }

  void _showClaimReimbursementRequestDialog(
    BuildContext context,
    AppLocalizations l,
    AppUser user,
    CashboxSnapshot cashbox,
    AppCurrency defaultCurrency, {
    num? initialAmount,
    AppCurrency? initialCurrency,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ClaimReimbursementRequestSheet(
        user: user,
        cashbox: cashbox,
        defaultCurrency: defaultCurrency,
        initialAmount: initialAmount,
        initialCurrency: initialCurrency,
      ),
    );
  }

  void _showEmployeeAccountStatementSheet(
    BuildContext context,
    AppLocalizations l,
    String loc,
    AppUser adminUser,
    Employee employee,
    CashboxSnapshot cashbox,
    AppCurrency defaultCurrency,
    List<CashboxLedgerEntry> entries,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EmployeeAccountStatementSheet(
        adminUser: adminUser,
        employee: employee,
        cashbox: cashbox,
        defaultCurrency: defaultCurrency,
        entries: entries,
        loc: loc,
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.title,
    required this.amount,
    required this.currency,
    required this.color,
    required this.icon,
    required this.locale,
  });

  final String title;
  final num amount;
  final AppCurrency currency;
  final MaterialColor color;
  final IconData icon;
  final String locale;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.shade50, color.shade100.withAlpha(120)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color.shade900,
                  ),
                ),
                Icon(icon, size: 20, color: color.shade700),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              CurrencyFormatter.format(amount, currency, locale: locale),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectAdjustmentSheet extends ConsumerStatefulWidget {
  const _DirectAdjustmentSheet({
    required this.user,
    required this.cashbox,
    required this.isDeposit,
    required this.defaultCurrency,
  });

  final AppUser user;
  final CashboxSnapshot cashbox;
  final bool isDeposit;
  final AppCurrency defaultCurrency;

  @override
  ConsumerState<_DirectAdjustmentSheet> createState() =>
      _DirectAdjustmentSheetState();
}

class _DirectAdjustmentSheetState
    extends ConsumerState<_DirectAdjustmentSheet> {
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  final _note = TextEditingController();
  late AppCurrency _currency = widget.defaultCurrency;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final amount = num.tryParse(_amount.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invalidAmount)),
      );
      return;
    }
    if (_reason.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.fieldRequired)),
      );
      return;
    }

    if (!widget.isDeposit) {
      final currentBalance = widget.cashbox.balanceFor(_currency);
      if (amount > currentBalance) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l.t('insufficientCashboxBalance')),
            content: Text(
              '${l.t('insufficientCashboxBalance')}. هل تريد المتابعة وسحب المبلغ ليصبح الرصيد سالباً؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.no),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.yes),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }
    }

    setState(() => _busy = true);
    try {
      await ref.read(cashboxRepositoryProvider).directAdjustment(
            widget.user,
            amount: amount,
            currency: _currency,
            isDeposit: widget.isDeposit,
            reason: _reason.text.trim(),
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.saved)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isDeposit ? l.t('directDeposit') : l.t('directWithdrawal'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              decoration: InputDecoration(labelText: l.amount),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<AppCurrency>(
              value: _currency,
              decoration: InputDecoration(labelText: l.currency),
              items: AppCurrency.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.code)))
                  .toList(),
              onChanged: (v) => setState(() => _currency = v ?? _currency),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reason,
              decoration: InputDecoration(
                labelText: widget.isDeposit ? 'السبب / مصدر الإيداع' : l.reason,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              decoration: InputDecoration(labelText: l.note),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l.save),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ClaimReimbursementRequestSheet extends ConsumerStatefulWidget {
  const _ClaimReimbursementRequestSheet({
    required this.user,
    required this.cashbox,
    required this.defaultCurrency,
    this.initialAmount,
    this.initialCurrency,
  });

  final AppUser user;
  final CashboxSnapshot cashbox;
  final AppCurrency defaultCurrency;
  final num? initialAmount;
  final AppCurrency? initialCurrency;

  @override
  ConsumerState<_ClaimReimbursementRequestSheet> createState() =>
      _ClaimReimbursementRequestSheetState();
}

class _ClaimReimbursementRequestSheetState
    extends ConsumerState<_ClaimReimbursementRequestSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late AppCurrency _currency;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _currency = widget.initialCurrency ?? widget.defaultCurrency;
    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _amount.text = widget.initialAmount.toString();
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final amount = num.tryParse(_amount.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invalidAmount)),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(cashboxRepositoryProvider).requestReimbursement(
            widget.user,
            amount: amount,
            currency: _currency,
            note: _note.text.trim(),
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.teal,
            content: Text(
              'تم إرسال طلب صرف المستحقات إلى المدير العام بنجاح. سيتم خصمها من الصندوق عند الموافقة.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final loc = Localizations.localeOf(context).languageCode;

    final iqdDue = widget.cashbox
        .cashboxDebtToStaffForUid(widget.user.uid, AppCurrency.iqd);
    final usdDue = widget.cashbox
        .cashboxDebtToStaffForUid(widget.user.uid, AppCurrency.usd);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                'طلب صرف مستحقات من الصندوق',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withAlpha(70)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'مستحقاتك (${l.t('owedByCashbox')}):',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'IQD: ${CurrencyFormatter.format(iqdDue, AppCurrency.iqd, locale: loc)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'USD: ${CurrencyFormatter.format(usdDue, AppCurrency.usd, locale: loc)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withAlpha(80)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ملاحظة: هذا الطلب يتطلب موافقة المدير العام قبل خصم المبلغ من الصندوق وتسوية حسابك.',
                      style: TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l.amount,
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<AppCurrency>(
                    value: _currency,
                    decoration: const InputDecoration(labelText: 'العملة'),
                    items: AppCurrency.values
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.code),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _currency = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _note,
              decoration: InputDecoration(
                labelText: '${l.note} (اختياري)',
                hintText: 'سبب أو تفاصيل الصرف…',
                prefixIcon: const Icon(Icons.note_alt_outlined),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_busy ? 'جارِ الإرسال...' : 'إرسال الطلب للمدير'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SettleStaffDebtSheet extends ConsumerStatefulWidget {
  const _SettleStaffDebtSheet({
    required this.user,
    required this.cashbox,
    required this.defaultCurrency,
    this.initialEmployeeUid,
    this.initialEmployeeName,
    this.initialDirection,
    this.initialAmount,
    this.initialCurrency,
    this.lockEmployee = false,
  });

  final AppUser user;
  final CashboxSnapshot cashbox;
  final AppCurrency defaultCurrency;
  final String? initialEmployeeUid;
  final String? initialEmployeeName;
  final StaffSettlementDirection? initialDirection;
  final num? initialAmount;
  final AppCurrency? initialCurrency;
  final bool lockEmployee;

  @override
  ConsumerState<_SettleStaffDebtSheet> createState() =>
      _SettleStaffDebtSheetState();
}

class _SettleStaffDebtSheetState extends ConsumerState<_SettleStaffDebtSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  Employee? _selectedEmployee;
  late StaffSettlementDirection _direction;
  late AppCurrency _currency;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (!widget.user.isAdmin) {
      _direction = StaffSettlementDirection.toCashbox;
    } else {
      _direction =
          widget.initialDirection ?? StaffSettlementDirection.toCashbox;
    }
    _currency = widget.initialCurrency ?? widget.defaultCurrency;
    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _amount.text = widget.initialAmount.toString();
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final targetUid = _selectedEmployee?.uid ?? widget.initialEmployeeUid;
    final targetName = _selectedEmployee?.displayName ??
        widget.initialEmployeeName ??
        (widget.lockEmployee ? widget.user.displayName : null);

    if (targetUid == null || targetName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.t('selectEmployee'))),
      );
      return;
    }
    final amount = num.tryParse(_amount.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invalidAmount)),
      );
      return;
    }

    if (!widget.user.isAdmin &&
        _direction == StaffSettlementDirection.fromCashbox) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا يمكن سحب المستحقات مباشرة. يرجى تقديم طلب صرف إلى المدير العام للموافقة عليه.',
          ),
        ),
      );
      return;
    }

    if (_direction == StaffSettlementDirection.fromCashbox) {
      final currentBalance = widget.cashbox.balanceFor(_currency);
      if (amount > currentBalance) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l.t('insufficientCashboxBalance')),
            content: Text(
              '${l.t('insufficientCashboxBalance')}. هل تريد المتابعة وصرف المبلغ للموظف ليصبح رصيد الصندوق سالباً؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.no),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.yes),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }
    }

    setState(() => _busy = true);
    try {
      await ref.read(cashboxRepositoryProvider).settleStaffDebt(
            widget.user,
            staffUid: targetUid,
            staffName: targetName,
            amount: amount,
            currency: _currency,
            direction: _direction,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (mounted) {
        ref.invalidate(cashboxStreamProvider(widget.user.adminUid));
        ref.invalidate(cashboxLedgerStreamProvider(widget.user.adminUid));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _direction == StaffSettlementDirection.toCashbox
                  ? 'تم تسديد عهدة الموظف وإيداعها في الصندوق بنجاح'
                  : 'تم صرف المستحقات للموظف من الصندوق بنجاح',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final employees =
        ref.watch(employeesStreamProvider(widget.user.adminUid)).valueOrNull ??
            [];

    if (_selectedEmployee == null && widget.initialEmployeeUid != null) {
      for (final e in employees) {
        if (e.uid == widget.initialEmployeeUid) {
          _selectedEmployee = e;
          break;
        }
      }
    }

    final targetName = _selectedEmployee?.displayName ??
        widget.initialEmployeeName ??
        (widget.lockEmployee ? widget.user.displayName : '');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                l.t('settleStaffDebt'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.lockEmployee || (!widget.user.isAdmin))
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${l.employee}: $targetName',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.lock_outline,
                        size: 16, color: Colors.grey),
                  ],
                ),
              )
            else
              DropdownButtonFormField<Employee>(
                value: _selectedEmployee,
                decoration: InputDecoration(labelText: l.t('selectEmployee')),
                items: employees
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.displayName),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedEmployee = v),
              ),
            const SizedBox(height: 10),
            if (widget.user.isAdmin)
              DropdownButtonFormField<StaffSettlementDirection>(
                value: _direction,
                decoration:
                    InputDecoration(labelText: l.t('settlementDirection')),
                items: [
                  DropdownMenuItem(
                    value: StaffSettlementDirection.toCashbox,
                    child: Text(l.t('handoverToCashbox')),
                  ),
                  DropdownMenuItem(
                    value: StaffSettlementDirection.fromCashbox,
                    child: Text(l.t('reimburseFromCashbox')),
                  ),
                ],
                onChanged: (v) => setState(() => _direction = v ?? _direction),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.teal.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.input_rounded,
                        size: 20, color: Colors.teal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.t('handoverToCashbox'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _direction == StaffSettlementDirection.toCashbox
                    ? Colors.teal.withAlpha(20)
                    : Colors.blue.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _direction == StaffSettlementDirection.toCashbox
                      ? Colors.teal.withAlpha(80)
                      : Colors.blue.withAlpha(80),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _direction == StaffSettlementDirection.toCashbox
                        ? Icons.input_rounded
                        : Icons.output_rounded,
                    size: 18,
                    color: _direction == StaffSettlementDirection.toCashbox
                        ? Colors.teal.shade800
                        : Colors.blue.shade800,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _direction == StaffSettlementDirection.toCashbox
                          ? l.t('handoverExplanation')
                          : l.t('reimburseExplanation'),
                      style: TextStyle(
                        fontSize: 12,
                        color: _direction == StaffSettlementDirection.toCashbox
                            ? Colors.teal.shade900
                            : Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amount,
              decoration: InputDecoration(labelText: l.amount),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<AppCurrency>(
              value: _currency,
              decoration: InputDecoration(labelText: l.currency),
              items: AppCurrency.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.code)))
                  .toList(),
              onChanged: (v) => setState(() => _currency = v ?? _currency),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _note,
              decoration: InputDecoration(labelText: l.note),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l.save),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _EmployeeAccountStatementSheet extends StatefulWidget {
  const _EmployeeAccountStatementSheet({
    required this.adminUser,
    required this.employee,
    required this.cashbox,
    required this.defaultCurrency,
    required this.entries,
    required this.loc,
  });

  final AppUser adminUser;
  final Employee employee;
  final CashboxSnapshot cashbox;
  final AppCurrency defaultCurrency;
  final List<CashboxLedgerEntry> entries;
  final String loc;

  @override
  State<_EmployeeAccountStatementSheet> createState() =>
      _EmployeeAccountStatementSheetState();
}

class _EmployeeAccountStatementSheetState
    extends State<_EmployeeAccountStatementSheet> {
  AppCurrency? _currencyFilter;
  String _typeFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    final iqdOwedToBox = widget.cashbox
        .staffDebtToCashboxForUid(widget.employee.uid, AppCurrency.iqd);
    final usdOwedToBox = widget.cashbox
        .staffDebtToCashboxForUid(widget.employee.uid, AppCurrency.usd);
    final iqdOwedByBox = widget.cashbox
        .cashboxDebtToStaffForUid(widget.employee.uid, AppCurrency.iqd);
    final usdOwedByBox = widget.cashbox
        .cashboxDebtToStaffForUid(widget.employee.uid, AppCurrency.usd);

    final hasDebtToBox = iqdOwedToBox > 0 || usdOwedToBox > 0;
    final hasCreditByBox = iqdOwedByBox > 0 || usdOwedByBox > 0;

    num pocketSpentIqd = 0;
    num pocketSpentUsd = 0;
    num custodyCollectedIqd = 0;
    num custodyCollectedUsd = 0;
    num settledToBoxIqd = 0;
    num settledToBoxUsd = 0;
    num reimbursedFromBoxIqd = 0;
    num reimbursedFromBoxUsd = 0;

    for (final e in widget.entries) {
      if (e.isPaidFromPersonal) {
        if (e.currency == AppCurrency.iqd) {
          pocketSpentIqd += e.amount;
        } else {
          pocketSpentUsd += e.amount;
        }
      }
      if (e.isCustodyPayment) {
        if (e.currency == AppCurrency.iqd) {
          custodyCollectedIqd += e.amount;
        } else {
          custodyCollectedUsd += e.amount;
        }
      }
      if (e.kind == 'staffSettlement') {
        if (e.currency == AppCurrency.iqd) {
          settledToBoxIqd += e.amount;
        } else {
          settledToBoxUsd += e.amount;
        }
      }
      if (e.kind == 'staffReimbursement') {
        if (e.currency == AppCurrency.iqd) {
          reimbursedFromBoxIqd += e.amount;
        } else {
          reimbursedFromBoxUsd += e.amount;
        }
      }
    }

    final filtered = widget.entries.where((e) {
      if (_currencyFilter != null && e.currency != _currencyFilter) {
        return false;
      }
      switch (_typeFilter) {
        case 'pocket':
          return e.isPaidFromPersonal;
        case 'custody':
          return e.isCustodyPayment;
        case 'settlement':
          return e.isSettlement;
        default:
          return true;
      }
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  child: const Icon(Icons.receipt_long_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'كشف حساب: ${widget.employee.displayName}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.employee.username.isNotEmpty
                            ? widget.employee.username
                            : widget.employee.email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(height: 20),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primaryContainer.withAlpha(120),
                          theme.colorScheme.surfaceContainerHighest,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withAlpha(100),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'الرصيد والذمة الحالية',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: hasDebtToBox
                                    ? Colors.orange.withAlpha(30)
                                    : (hasCreditByBox
                                        ? Colors.blue.withAlpha(30)
                                        : Colors.green.withAlpha(30)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                hasDebtToBox
                                    ? l.t('staffOwesCashbox')
                                    : (hasCreditByBox
                                        ? l.t('staffOwedByCashbox')
                                        : l.t('balancedAccount')),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: hasDebtToBox
                                      ? Colors.orange.shade800
                                      : (hasCreditByBox
                                          ? Colors.blue.shade800
                                          : Colors.green.shade800),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withAlpha(20),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.orange.withAlpha(60)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ما بعهدته للصندوق',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyFormatter.format(
                                          iqdOwedToBox, AppCurrency.iqd,
                                          locale: widget.loc),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade900,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(
                                          usdOwedToBox, AppCurrency.usd,
                                          locale: widget.loc),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withAlpha(20),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.blue.withAlpha(60)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'مستحقاته بذمة الصندوق',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyFormatter.format(
                                          iqdOwedByBox, AppCurrency.iqd,
                                          locale: widget.loc),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(
                                          usdOwedByBox, AppCurrency.usd,
                                          locale: widget.loc),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'ملخص إجمالي الحركات التاريخية للموظف',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          title: 'مقبوض بالعهدة',
                          subtitle: 'اشتراكات نقدية',
                          iqdAmount: custodyCollectedIqd,
                          usdAmount: custodyCollectedUsd,
                          color: Colors.amber,
                          icon: Icons.inventory_2_outlined,
                          loc: widget.loc,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatBox(
                          title: 'مصروف من الجيب',
                          subtitle: 'مجهزين ونثريات',
                          iqdAmount: pocketSpentIqd,
                          usdAmount: pocketSpentUsd,
                          color: Colors.blue,
                          icon: Icons.person_pin_outlined,
                          loc: widget.loc,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          title: 'مسلّم للصندوق',
                          subtitle: 'تسويات عهدة سابقة',
                          iqdAmount: settledToBoxIqd,
                          usdAmount: settledToBoxUsd,
                          color: Colors.teal,
                          icon: Icons.input_rounded,
                          loc: widget.loc,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatBox(
                          title: 'مسترد من الصندوق',
                          subtitle: 'تعويضات مصروفة',
                          iqdAmount: reimbursedFromBoxIqd,
                          usdAmount: reimbursedFromBoxUsd,
                          color: Colors.indigo,
                          icon: Icons.output_rounded,
                          loc: widget.loc,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          selected: _typeFilter == 'all',
                          label: const Text('جميع العمليات'),
                          onSelected: (_) =>
                              setState(() => _typeFilter = 'all'),
                        ),
                        const SizedBox(width: 6),
                        FilterChip(
                          selected: _typeFilter == 'pocket',
                          label: const Text('من الجيب الشخصي'),
                          avatar: const Icon(Icons.person_pin_outlined, size: 16),
                          onSelected: (_) =>
                              setState(() => _typeFilter = 'pocket'),
                        ),
                        const SizedBox(width: 6),
                        FilterChip(
                          selected: _typeFilter == 'custody',
                          label: const Text('مقبوض بالعهدة'),
                          avatar: const Icon(Icons.inventory_2_outlined, size: 16),
                          onSelected: (_) =>
                              setState(() => _typeFilter = 'custody'),
                        ),
                        const SizedBox(width: 6),
                        FilterChip(
                          selected: _typeFilter == 'settlement',
                          label: const Text('تسويات الصندوق'),
                          avatar: const Icon(Icons.sync_alt, size: 16),
                          onSelected: (_) =>
                              setState(() => _typeFilter = 'settlement'),
                        ),
                        const SizedBox(width: 10),
                        DropdownButton<AppCurrency?>(
                          value: _currencyFilter,
                          isDense: true,
                          underline: const SizedBox.shrink(),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(l.t('allCurrencies'),
                                  style: const TextStyle(fontSize: 12)),
                            ),
                            ...AppCurrency.values.map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.code,
                                    style: const TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _currencyFilter = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'العمليات (${filtered.length})',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'لا توجد عمليات تطابق هذا الفلتر',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, idx) {
                        final entry = filtered[idx];
                        return _buildStatementEntryTile(entry, theme, l);
                      },
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant.withAlpha(80),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        final curr = iqdOwedToBox > 0
                            ? AppCurrency.iqd
                            : (usdOwedToBox > 0
                                ? AppCurrency.usd
                                : widget.defaultCurrency);
                        final amt = iqdOwedToBox > 0
                            ? iqdOwedToBox
                            : (usdOwedToBox > 0 ? usdOwedToBox : null);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (_) => _SettleStaffDebtSheet(
                            user: widget.adminUser,
                            cashbox: widget.cashbox,
                            defaultCurrency: widget.defaultCurrency,
                            initialEmployeeUid: widget.employee.uid,
                            initialEmployeeName: widget.employee.displayName,
                            initialDirection:
                                StaffSettlementDirection.toCashbox,
                            initialAmount: amt,
                            initialCurrency: curr,
                          ),
                        );
                      },
                      icon: const Icon(Icons.input_rounded, size: 16),
                      label: const Text('تسديد العهدة للصندوق',
                          style: TextStyle(fontSize: 12)),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal.withAlpha(30),
                        foregroundColor: Colors.teal.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        final curr = iqdOwedByBox > 0
                            ? AppCurrency.iqd
                            : (usdOwedByBox > 0
                                ? AppCurrency.usd
                                : widget.defaultCurrency);
                        final amt = iqdOwedByBox > 0
                            ? iqdOwedByBox
                            : (usdOwedByBox > 0 ? usdOwedByBox : null);
                        if (!widget.adminUser.isAdmin) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                            shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            builder: (_) => _ClaimReimbursementRequestSheet(
                              user: widget.adminUser,
                              cashbox: widget.cashbox,
                              defaultCurrency: widget.defaultCurrency,
                              initialAmount: amt,
                              initialCurrency: curr,
                            ),
                          );
                        } else {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                            shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            builder: (_) => _SettleStaffDebtSheet(
                              user: widget.adminUser,
                              cashbox: widget.cashbox,
                              defaultCurrency: widget.defaultCurrency,
                              initialEmployeeUid: widget.employee.uid,
                              initialEmployeeName: widget.employee.displayName,
                              initialDirection:
                                  StaffSettlementDirection.fromCashbox,
                              initialAmount: amt,
                              initialCurrency: curr,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.output_rounded, size: 16),
                      label: const Text('صرف تعويض من الصندوق',
                          style: TextStyle(fontSize: 12)),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue.withAlpha(30),
                        foregroundColor: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatementEntryTile(
    CashboxLedgerEntry entry,
    ThemeData theme,
    AppLocalizations l,
  ) {
    Color badgeColor;
    IconData icon;
    String actionLabel;

    if (entry.kind == 'staffSettlement') {
      badgeColor = Colors.teal;
      icon = Icons.input_rounded;
      actionLabel = 'تسليم عهدة للصندوق';
    } else if (entry.kind == 'staffReimbursement') {
      badgeColor = Colors.blue;
      icon = Icons.output_rounded;
      actionLabel = 'صرف تعويض من الصندوق';
    } else if (entry.isPaidFromPersonal) {
      badgeColor = Colors.blue.shade700;
      icon = Icons.person_pin_outlined;
      actionLabel = entry.kind == 'supplierRecharge'
          ? 'تعبئة رصيد مجهز من الجيب'
          : (entry.kind == 'supplierPayment'
              ? 'دفع لمجهز من الجيب'
              : 'مصروف من الجيب');
    } else if (entry.isCustodyPayment) {
      badgeColor = Colors.amber.shade900;
      icon = Icons.inventory_2_outlined;
      actionLabel = 'اشتراك مقبوض بالعهدة';
    } else if (entry.isDirectCashIncrease) {
      badgeColor = Colors.green;
      icon = Icons.arrow_downward;
      actionLabel = entry.kind;
    } else {
      badgeColor = Colors.red;
      icon = Icons.arrow_upward;
      actionLabel = entry.kind;
    }

    String subtitle = DateFormatter.dateTime(entry.createdAt, locale: widget.loc);
    if (entry.supplierName != null && entry.supplierName!.isNotEmpty) {
      subtitle += ' • المجهز: ${entry.supplierName}';
    } else if (entry.subscriberName != null && entry.subscriberName!.isNotEmpty) {
      subtitle += ' • المشترك: ${entry.subscriberName}';
    } else if (entry.reason != null && entry.reason!.isNotEmpty) {
      subtitle += ' • ${entry.reason}';
    }

    if (entry.note != null && entry.note!.isNotEmpty) {
      subtitle += '\nملاحظة: ${entry.note}';
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: badgeColor.withAlpha(25),
        foregroundColor: badgeColor,
        child: Icon(icon, size: 18),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              actionLabel,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            CurrencyFormatter.format(entry.amount, entry.currency,
                locale: widget.loc),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: badgeColor,
            ),
          ),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
      ),
      isThreeLine: entry.note != null && entry.note!.isNotEmpty,
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.title,
    required this.subtitle,
    required this.iqdAmount,
    required this.usdAmount,
    required this.color,
    required this.icon,
    required this.loc,
  });

  final String title;
  final String subtitle;
  final num iqdAmount;
  final num usdAmount;
  final MaterialColor color;
  final IconData icon;
  final String loc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color.shade800),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color.shade900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(iqdAmount, AppCurrency.iqd, locale: loc),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color.shade900,
            ),
          ),
          Text(
            CurrencyFormatter.format(usdAmount, AppCurrency.usd, locale: loc),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
