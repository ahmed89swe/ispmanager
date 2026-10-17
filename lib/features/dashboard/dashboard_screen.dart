import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/models/models.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/utils/formatters.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/providers/preferences_providers.dart';
import '../auth/auth_repository.dart';
import '../expenses/expenses_repository.dart';
import '../expenses/expenses_screen.dart';
import '../finance/cashbox_repository.dart';
import '../finance/cashbox_screen.dart';
import '../payments/payments_repository.dart';
import '../subscribers/subscribers_repository.dart';
import '../subscribers/subscribers_screen.dart';
import '../suppliers/suppliers_repository.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _syncedSubscribers = <String>{};

  void _syncDueDebts(AppUser user, List<Subscriber> subscribers) {
    if (!user.can(Permission.recordSubscriberPayment) &&
        !user.can(Permission.editSubscriber)) {
      return;
    }
    final now = DateTime.now();
    final due = subscribers.where((subscriber) {
      return subscriber.autoRenew &&
          !_syncedSubscribers.contains(subscriber.id) &&
          !subscriber.subscriptionEndsAt.isAfter(now);
    }).toList();
    if (due.isEmpty) return;
    for (final subscriber in due) {
      _syncedSubscribers.add(subscriber.id);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final repo = ref.read(subscribersRepositoryProvider);
      for (final subscriber in due) {
        repo.syncDueDebts(user, subscriber).catchError((_) {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentAppUserProvider).valueOrNull;
    if (user == null) {
      return Center(child: Text(l.pleaseSignIn));
    }
    final currency = ref.watch(currencyProvider);
    final loc = Localizations.localeOf(context).languageCode;
    final subsAsync = ref.watch(subscribersStreamProvider(user.adminUid));
    final expensesAsync = ref.watch(expensesStreamProvider(user.adminUid));
    final suppliersAsync = ref.watch(suppliersStreamProvider(user.adminUid));
    final paymentsStream =
        ref.watch(paymentsRepositoryProvider).watchAll(user.adminUid);
    final cashbox =
        ref.watch(cashboxStreamProvider(user.adminUid)).valueOrNull ??
            CashboxSnapshot.empty();

    final subs = subsAsync.valueOrNull ?? [];
    _syncDueDebts(user, subs);
    final expenses = expensesAsync.valueOrNull ?? [];
    final suppliers = suppliersAsync.valueOrNull ?? [];

    final subsCount = subs.length;
    final activeSubsCount =
        subs.where((s) => s.status == SubscriberStatus.active).length;
    final totalDebts = subs
        .where((s) => s.currency == currency)
        .fold<num>(0, (a, b) => a + b.balance);
    final totalDebtsIqd = subs
        .where((s) => s.currency == AppCurrency.iqd)
        .fold<num>(0, (a, b) => a + b.balance);
    final totalDebtsUsd = subs
        .where((s) => s.currency == AppCurrency.usd)
        .fold<num>(0, (a, b) => a + b.balance);
    final totalExpenses = expenses
        .where((e) =>
            e.currency == currency && e.type == ExpenseEntryType.expense)
        .fold<num>(0, (a, b) => a + b.amount);
    final suppliersCount = suppliers.length;

    final iqdBalance = cashbox.balanceFor(AppCurrency.iqd);
    final usdBalance = cashbox.balanceFor(AppCurrency.usd);
    final totalStaffDebt = cashbox.totalStaffDebtToCashbox(currency);

    return StreamBuilder<List<Payment>>(
      stream: paymentsStream,
      builder: (context, snapshot) {
        final payments = snapshot.data ?? [];

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            final hasRecent = payments.isNotEmpty;

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(cashboxStreamProvider(user.adminUid));
                ref.invalidate(subscribersStreamProvider(user.adminUid));
                ref.invalidate(expensesStreamProvider(user.adminUid));
                ref.invalidate(suppliersStreamProvider(user.adminUid));
              },
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 24 : 16,
                  vertical: isWide ? 20 : 12,
                ),
                children: [
                  _buildHeaderGreeting(context, l, user)
                      .animate()
                      .fadeIn(duration: 300.ms),
                  const SizedBox(height: 14),
                  if (user.isAdmin)
                    _buildHeroLiquidityCard(
                      context,
                      l,
                      loc,
                      iqdBalance,
                      usdBalance,
                      totalDebtsIqd,
                      totalDebtsUsd,
                      totalStaffDebt,
                      currency,
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.05, end: 0)
                  else if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildGeneralCashboxSummaryCard(
                            context,
                            l,
                            loc,
                            iqdBalance,
                            usdBalance,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildEmployeeDashboardCard(
                            context,
                            l,
                            loc,
                            user,
                            cashbox,
                            currency,
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.05, end: 0)
                  else ...[
                    _buildGeneralCashboxSummaryCard(
                      context,
                      l,
                      loc,
                      iqdBalance,
                      usdBalance,
                    )
                        .animate()
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.05, end: 0),
                    const SizedBox(height: 12),
                    _buildEmployeeDashboardCard(
                      context,
                      l,
                      loc,
                      user,
                      cashbox,
                      currency,
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.05, end: 0),
                  ],
                  const SizedBox(height: 16),
                  _buildQuickActions(context, l, user)
                      .animate()
                      .fadeIn(duration: 450.ms, delay: 100.ms),
                  const SizedBox(height: 20),
                  _buildKpiMetricsGrid(
                    context,
                    l,
                    loc,
                    currency,
                    subsCount,
                    activeSubsCount,
                    totalDebts,
                    totalExpenses,
                    suppliersCount,
                  ).animate().fadeIn(duration: 500.ms, delay: 150.ms),
                  const SizedBox(height: 24),
                  if (isWide && hasRecent)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: _buildMonthlyChart(
                            context,
                            payments,
                            expenses,
                            currency,
                            loc,
                            l,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 5,
                          child: _buildRecentActivity(
                            context,
                            l,
                            payments,
                            loc,
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 550.ms, delay: 200.ms)
                  else ...[
                    _buildMonthlyChart(
                      context,
                      payments,
                      expenses,
                      currency,
                      loc,
                      l,
                    ).animate().fadeIn(duration: 550.ms, delay: 200.ms),
                    const SizedBox(height: 24),
                    _buildRecentActivity(context, l, payments, loc)
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 250.ms),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeaderGreeting(
    BuildContext context,
    AppLocalizations l,
    AppUser user,
  ) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';

    return Row(
      children: [
        InkWell(
          onTap: () => context.push('/profile'),
          borderRadius: BorderRadius.circular(22),
          child: AppAvatar(
            photoUrl: user.photoUrl,
            name: user.displayName,
            radius: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      user.displayName.isEmpty ? l.employee : user.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: user.isAdmin
                          ? Colors.indigo.withValues(alpha: 0.15)
                          : Colors.teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.isAdmin ? l.admin : l.employee,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: user.isAdmin ? Colors.indigo : Colors.teal,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                dateStr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroLiquidityCard(
    BuildContext context,
    AppLocalizations l,
    String loc,
    num iqdBalance,
    num usdBalance,
    num totalDebtsIqd,
    num totalDebtsUsd,
    num totalStaffDebt,
    AppCurrency defaultCurrency,
  ) {
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
            color: const Color(0xFF0F2B48).withValues(alpha: 0.35),
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
              backgroundColor: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: CircleAvatar(
              radius: 70,
              backgroundColor: Colors.white.withValues(alpha: 0.03),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
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
                          l.t('cashboxBalance'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CashboxScreen()),
                      ),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l.t('cashboxLedger'),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios,
                                size: 10, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'IQD',
                            style: TextStyle(
                              color: Colors.tealAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              CurrencyFormatter.format(
                                iqdBalance,
                                AppCurrency.iqd,
                                locale: loc,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 38,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'USD',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              CurrencyFormatter.format(
                                usdBalance,
                                AppCurrency.usd,
                                locale: loc,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 14, color: Colors.amberAccent),
                          const SizedBox(width: 6),
                          Text(
                            totalDebtsUsd > 0
                                ? '${l.totalDebts}: ${CurrencyFormatter.format(totalDebtsIqd, AppCurrency.iqd, locale: loc)} • ${CurrencyFormatter.format(totalDebtsUsd, AppCurrency.usd, locale: loc)}'
                                : '${l.totalDebts}: ${CurrencyFormatter.format(totalDebtsIqd, AppCurrency.iqd, locale: loc)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (totalStaffDebt > 0)
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const CashboxScreen(initialTabIndex: 1),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            children: [
                              Text(
                                '${l.t('totalStaffDebt')}: ${CurrencyFormatter.format(totalStaffDebt, defaultCurrency, locale: loc)}',
                                style: const TextStyle(
                                  color: Colors.amberAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_ios,
                                  size: 9, color: Colors.amberAccent),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralCashboxSummaryCard(
    BuildContext context,
    AppLocalizations l,
    String loc,
    num iqdBalance,
    num usdBalance,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F3D3E),
            Color(0xFF104F55),
            Color(0xFF1E555C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F3D3E).withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.savings_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l.t('generalCashbox'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CashboxScreen(),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l.t('details'),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios,
                            size: 9, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'رصيد الدينار (IQD)',
                          style: TextStyle(
                            color: Colors.tealAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            CurrencyFormatter.format(
                              iqdBalance,
                              AppCurrency.iqd,
                              locale: loc,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
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
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'رصيد الدولار (USD)',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            CurrencyFormatter.format(
                              usdBalance,
                              AppCurrency.usd,
                              locale: loc,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
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
    );
  }

  Widget _buildEmployeeDashboardCard(
    BuildContext context,
    AppLocalizations l,
    String loc,
    AppUser user,
    CashboxSnapshot cashbox,
    AppCurrency defaultCurrency,
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
            color: const Color(0xFF0F2B48).withValues(alpha: 0.35),
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
              backgroundColor: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
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
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CashboxScreen(),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l.t('details'),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios,
                                size: 10, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: hasDebt
                                ? Colors.amberAccent.withValues(alpha: 0.4)
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.arrow_upward_rounded,
                                    size: 13, color: Colors.amberAccent),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    l.t('owedToCashbox'),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
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
                                  fontSize: 15,
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
                                  fontSize: 12,
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
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: hasCredit
                                ? Colors.lightBlueAccent.withValues(alpha: 0.4)
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.arrow_downward_rounded,
                                    size: 13, color: Colors.lightBlueAccent),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    l.t('owedByCashbox'),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
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
                                  fontSize: 15,
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        netIqd > 0 || netUsd > 0
                            ? '${l.t('staffNetYouOwe')}: ${CurrencyFormatter.format(netIqd > 0 ? netIqd : netUsd, netIqd > 0 ? AppCurrency.iqd : AppCurrency.usd, locale: loc)}'
                            : (netIqd < 0 || netUsd < 0
                                ? '${l.t('staffNetBoxOwes')}: ${CurrencyFormatter.format((netIqd < 0 ? -netIqd : -netUsd), netIqd < 0 ? AppCurrency.iqd : AppCurrency.usd, locale: loc)}'
                                : l.t('allStaffBalanced')),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CashboxScreen(),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.tealAccent.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l.t('settlement'),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
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

  Widget _buildQuickActions(
    BuildContext context,
    AppLocalizations l,
    AppUser user,
  ) {
    final canAddSubscriber = user.can(Permission.addSubscriber);
    final canAddExpense = user.can(Permission.addExpense);
    final canViewCashbox =
        user.isAdmin || user.can(Permission.recordSubscriberPayment);

    final actions = <Widget>[];

    if (canAddSubscriber) {
      actions.add(
        Expanded(
          child: _QuickActionButton(
            icon: Icons.person_add_rounded,
            label: l.addSubscriber,
            color: Colors.blue,
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => SubscriberFormSheet(by: user),
            ),
          ),
        ),
      );
    }

    if (canAddExpense) {
      if (actions.isNotEmpty) actions.add(const SizedBox(width: 8));
      actions.add(
        Expanded(
          child: _QuickActionButton(
            icon: Icons.receipt_long_rounded,
            label: l.addExpense,
            color: Colors.deepOrange,
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => ExpenseFormSheet(by: user),
            ),
          ),
        ),
      );
    }

    if (canViewCashbox) {
      if (actions.isNotEmpty) actions.add(const SizedBox(width: 8));
      actions.add(
        Expanded(
          child: _QuickActionButton(
            icon: Icons.savings_rounded,
            label: l.t('cashbox'),
            color: Colors.teal,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CashboxScreen()),
            ),
          ),
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(children: actions);
  }

  Widget _buildKpiMetricsGrid(
    BuildContext context,
    AppLocalizations l,
    String loc,
    AppCurrency currency,
    int subsCount,
    int activeSubsCount,
    num totalDebts,
    num totalExpenses,
    int suppliersCount,
  ) {
    final cards = [
      _ModernKpiCard(
        icon: Icons.people_alt_rounded,
        iconColor: Colors.blue.shade700,
        backgroundColor: Colors.blue.shade50.withValues(alpha: 0.6),
        label: l.subscribersCount,
        value: '$subsCount',
        badgeText: '$activeSubsCount ${l.t('active')}',
        badgeColor: Colors.green,
      ),
      _ModernKpiCard(
        icon: Icons.account_balance_wallet_rounded,
        iconColor: Colors.amber.shade800,
        backgroundColor: Colors.amber.shade50.withValues(alpha: 0.6),
        label: l.totalDebts,
        value: CurrencyFormatter.format(totalDebts, currency, locale: loc),
        badgeText: l.t('unpaid'),
        badgeColor: Colors.orange,
      ),
      _ModernKpiCard(
        icon: Icons.receipt_long_rounded,
        iconColor: Colors.red.shade700,
        backgroundColor: Colors.red.shade50.withValues(alpha: 0.6),
        label: l.totalExpenses,
        value: CurrencyFormatter.format(totalExpenses, currency, locale: loc),
        badgeText: l.expenses,
        badgeColor: Colors.red,
      ),
      _ModernKpiCard(
        icon: Icons.local_shipping_rounded,
        iconColor: Colors.indigo.shade700,
        backgroundColor: Colors.indigo.shade50.withValues(alpha: 0.6),
        label: l.suppliers,
        value: '$suppliersCount',
        badgeText: l.t('package'),
        badgeColor: Colors.indigo,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 700 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 138,
          ),
          itemBuilder: (_, index) => cards[index],
        );
      },
    );
  }

  Widget _buildMonthlyChart(
    BuildContext context,
    List<Payment> payments,
    List<Expense> expenses,
    AppCurrency currency,
    String loc,
    AppLocalizations l,
  ) {
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - i, 1))
        .reversed
        .toList();

    List<BarChartGroupData> barGroups = [];
    double maxY = 0;

    for (int i = 0; i < months.length; i++) {
      final m = months[i];
      final nextM = DateTime(m.year, m.month + 1, 1);

      final mPayments = payments
          .where((p) =>
              p.currency == currency &&
              !p.recordedAt.isBefore(m) &&
              p.recordedAt.isBefore(nextM))
          .fold<double>(0.0, (sum, p) => sum + p.amount.toDouble());
      final mExpenses = expenses
          .where((e) =>
              e.currency == currency &&
              !e.date.isBefore(m) &&
              e.date.isBefore(nextM) &&
              e.type == ExpenseEntryType.expense)
          .fold<double>(0.0, (sum, e) => sum + e.amount.toDouble());

      if (mPayments > maxY) maxY = mPayments;
      if (mExpenses > maxY) maxY = mExpenses;

      barGroups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: mPayments,
            color: Colors.teal.shade600,
            width: 11,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          ),
          BarChartRodData(
            toY: mExpenses,
            color: Colors.red.shade400,
            width: 11,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          ),
        ],
      ));
    }

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l.reports,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    _ChartLegend(
                        color: Colors.teal.shade600, text: l.t('income')),
                    const SizedBox(width: 12),
                    _ChartLegend(color: Colors.red.shade400, text: l.expenses),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY <= 0 ? 100 : maxY * 1.15,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.black87,
                      tooltipRoundedRadius: 8,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= months.length) {
                            return const SizedBox.shrink();
                          }
                          final date = months[idx];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '${date.month}/${date.year.toString().substring(2)}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(
    BuildContext context,
    AppLocalizations l,
    List<Payment> payments,
    String loc,
  ) {
    if (payments.isEmpty) return const SizedBox.shrink();
    final recent = payments.toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final top5 = recent.take(5).toList();

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'آخر الدفعات والتحصيلات',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${recent.length} عملية',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: top5.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final p = top5[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade50,
                    foregroundColor: Colors.green.shade700,
                    child: const Icon(Icons.arrow_downward_rounded, size: 18),
                  ),
                  title: Text(
                    p.subscriberId.isEmpty ? l.t('subscriber') : p.subscriberId,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    DateFormatter.dateTime(p.recordedAt, locale: loc),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    '+${CurrencyFormatter.format(p.amount, p.currency, locale: loc)}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final MaterialColor color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: color.withValues(alpha: isDark ? 0.45 : 0.35),
          width: 1.2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor:
                    isDark ? color.withValues(alpha: 0.25) : color.shade100,
                foregroundColor: isDark ? color.shade200 : color.shade800,
                child: Icon(icon, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernKpiCard extends StatelessWidget {
  const _ModernKpiCard({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.label,
    required this.value,
    required this.badgeText,
    required this.badgeColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String label;
  final String value;
  final String badgeText;
  final MaterialColor badgeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: badgeColor.withValues(alpha: isDark ? 0.40 : 0.35),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? badgeColor.withValues(alpha: 0.22)
                        : badgeColor.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isDark ? badgeColor.shade200 : iconColor,
                    size: 20,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? badgeColor.withValues(alpha: 0.25)
                        : badgeColor.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? badgeColor.shade200 : badgeColor.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String text;
  const _ChartLegend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
