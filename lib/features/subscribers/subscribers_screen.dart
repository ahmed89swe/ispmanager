import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_theme.dart';
import '../../core/constants.dart';
import '../../core/models/models.dart';
import '../../core/services/pdf_report_service.dart';
import '../../core/utils/formatters.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_repository.dart';
import '../payments/advance_subscription_sheet.dart';
import '../payments/record_payment_sheet.dart';
import '../suppliers/suppliers_repository.dart';
import 'subscribers_repository.dart';

class SubscribersScreen extends ConsumerStatefulWidget {
  const SubscribersScreen({super.key});

  @override
  ConsumerState<SubscribersScreen> createState() => _SubscribersScreenState();
}

enum SubscriberFilterType { all, active, debts, overdue, inactive }

class _SubscribersScreenState extends ConsumerState<SubscribersScreen> {
  final _syncedSubscribers = <String>{};
  final _searchController = TextEditingController();
  String _query = '';
  SubscriberFilterType _filterType = SubscriberFilterType.all;
  String? _selectedSupplierId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _exportDebtsReport(BuildContext context, AppUser user) async {
    final allSubs =
        ref.read(subscribersStreamProvider(user.adminUid)).valueOrNull ?? [];
    final suppliers =
        ref.read(suppliersStreamProvider(user.adminUid)).valueOrNull ?? [];
    final selectedSupplierName = _selectedSupplierId == null
        ? null
        : suppliers
            .where((sp) => sp.id == _selectedSupplierId)
            .map((sp) => sp.name)
            .firstOrNull;
    final subs = _selectedSupplierId == null
        ? allSubs
        : allSubs
            .where((s) =>
                s.supplierId == _selectedSupplierId ||
                (selectedSupplierName != null &&
                    s.supplierName == selectedSupplierName))
            .toList();
    if (subs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد مشتركين لتصدير التقرير')),
      );
      return;
    }
    final loc = Localizations.localeOf(context).languageCode;
    try {
      final repo = ref.read(subscribersRepositoryProvider);
      final indebted = subs.where((s) => s.balance > 0).toList();
      final debtLists = await Future.wait(
        indebted.map((s) => repo.getDebts(user.adminUid, s.id)),
      );
      final allDebts = debtLists.expand((d) => d).toList();
      await PdfReportService().previewSubscribersDebtReport(
        subscribers: subs,
        allDebts: allDebts,
        generatedBy: user.displayName.isNotEmpty
            ? user.displayName
            : (user.email ?? 'ISP Manager'),
        locale: loc,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تصدير تقرير الديون: $e')),
      );
    }
  }

  Future<void> _exportSubscriberStatement(
    BuildContext context,
    AppUser user,
    Subscriber subscriber,
  ) async {
    final loc = Localizations.localeOf(context).languageCode;
    try {
      final repo = ref.read(subscribersRepositoryProvider);
      final debts = await repo.getDebts(user.adminUid, subscriber.id);
      final payments = await repo.getPayments(user.adminUid, subscriber.id);
      await PdfReportService().previewSubscriberStatement(
        subscriber: subscriber,
        debts: debts,
        payments: payments,
        generatedBy: user.displayName.isNotEmpty
            ? user.displayName
            : (user.email ?? 'ISP Manager'),
        locale: loc,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تصدير كشف الحساب: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentAppUserProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();
    final subs = ref.watch(subscribersStreamProvider(user.adminUid));
    final suppliers =
        ref.watch(suppliersStreamProvider(user.adminUid)).valueOrNull ?? [];
    final canAdd = user.can(Permission.addSubscriber);
    final theme = Theme.of(context);

    // Ensure _selectedSupplierId is still valid
    final validSupplierId = suppliers.any((sp) => sp.id == _selectedSupplierId)
        ? _selectedSupplierId
        : null;
    final selectedSupplierName = validSupplierId == null
        ? null
        : suppliers
            .where((sp) => sp.id == validSupplierId)
            .map((sp) => sp.name)
            .firstOrNull;

    return Scaffold(
      body: Column(
        children: [
          // Modern Search Bar & Debts PDF Export Button
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.cardBorderColor(context),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search,
                            color: theme.colorScheme.primary),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        hintText: l.search,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                      onChanged: (v) =>
                          setState(() => _query = v.trim().toLowerCase()),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'تصدير تقرير ديون المشتركين (PDF)',
                  icon: const Icon(Icons.picture_as_pdf_rounded,
                      color: Colors.redAccent),
                  onPressed: () => _exportDebtsReport(context, user),
                ),
                if (canAdd) ...[
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => _showForm(context, ref, user),
                    icon: const Icon(Icons.person_add_alt_1, size: 20),
                    label: Text(l.addSubscriber),
                  ),
                ],
              ],
            ),
          ),

          // Supplier Filter Bar
          if (suppliers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 4),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: validSupplierId != null
                        ? theme.colorScheme.primary
                        : AppTheme.cardBorderColor(context),
                    width: validSupplierId != null ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.hub_outlined,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${l.t('filterBySupplier')}:',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: validSupplierId,
                          isExpanded: true,
                          isDense: false,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                l.t('allSuppliers'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            ...suppliers.map(
                              (sp) => DropdownMenuItem<String?>(
                                value: sp.id,
                                child: Text(
                                  sp.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedSupplierId = val),
                        ),
                      ),
                    ),
                    if (validSupplierId != null)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: l.all,
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () =>
                            setState(() => _selectedSupplierId = null),
                      ),
                  ],
                ),
              ),
            ),

          // Stream-driven content: Filter Chips & Modern Subscriber Cards
          Expanded(
            child: subs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (rawList) {
                _syncDueDebts(user, rawList);

                final list = validSupplierId == null
                    ? rawList
                    : rawList
                        .where((s) =>
                            s.supplierId == validSupplierId ||
                            (selectedSupplierName != null &&
                                s.supplierName == selectedSupplierName))
                        .toList();

                // Counters for chips
                final totalCount = list.length;
                final activeCount = list
                    .where((s) => s.status == SubscriberStatus.active)
                    .length;
                final debtsCount = list.where((s) => s.balance > 0).length;
                final overdueCount = list
                    .where((s) =>
                        s.status == SubscriberStatus.overdue ||
                        s.subscriptionEndsAt.isBefore(DateTime.now()))
                    .length;
                final inactiveCount = list
                    .where((s) => s.status == SubscriberStatus.inactive)
                    .length;

                final filtered = list
                    .where((s) {
                      switch (_filterType) {
                        case SubscriberFilterType.all:
                          return true;
                        case SubscriberFilterType.active:
                          return s.status == SubscriberStatus.active;
                        case SubscriberFilterType.debts:
                          return s.balance > 0;
                        case SubscriberFilterType.overdue:
                          return s.status == SubscriberStatus.overdue ||
                              s.subscriptionEndsAt.isBefore(DateTime.now());
                        case SubscriberFilterType.inactive:
                          return s.status == SubscriberStatus.inactive;
                      }
                    })
                    .where((s) =>
                        _query.isEmpty ||
                        s.name.toLowerCase().contains(_query) ||
                        (s.phone ?? '').contains(_query) ||
                        (s.supplierName ?? '').toLowerCase().contains(_query) ||
                        (s.packageName ?? s.planName ?? '')
                            .toLowerCase()
                            .contains(_query))
                    .toList();

                return Column(
                  children: [
                    // Horizontal Filter Chips Bar
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: l.all,
                            count: totalCount,
                            selected: _filterType == SubscriberFilterType.all,
                            onTap: () => setState(
                                () => _filterType = SubscriberFilterType.all),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: l.t('active'),
                            count: activeCount,
                            selected:
                                _filterType == SubscriberFilterType.active,
                            color: const Color(0xFF00A86B),
                            onTap: () => setState(() =>
                                _filterType = SubscriberFilterType.active),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: l.debts,
                            count: debtsCount,
                            selected: _filterType == SubscriberFilterType.debts,
                            color: const Color(0xFFE53935),
                            onTap: () => setState(
                                () => _filterType = SubscriberFilterType.debts),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: l.t('overdue'),
                            count: overdueCount,
                            selected:
                                _filterType == SubscriberFilterType.overdue,
                            color: Colors.orange,
                            onTap: () => setState(() =>
                                _filterType = SubscriberFilterType.overdue),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: l.t('inactive'),
                            count: inactiveCount,
                            selected:
                                _filterType == SubscriberFilterType.inactive,
                            color: Colors.grey,
                            onTap: () => setState(() =>
                                _filterType = SubscriberFilterType.inactive),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Subscribers List / Grid
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off,
                                      size: 48,
                                      color: theme.colorScheme.outline),
                                  const SizedBox(height: 8),
                                  Text(l.noData,
                                      style: theme.textTheme.bodyLarge),
                                ],
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth >= 840;
                                Widget buildSubscriberItem(
                                    Subscriber subscriber) {
                                  return _ModernSubscriberCard(
                                    subscriber: subscriber,
                                    user: user,
                                    onTap: () => showDialog(
                                      context: context,
                                      builder: (_) => SubscriberDetailsDialog(
                                        subscriber: subscriber,
                                        by: user,
                                      ),
                                    ),
                                    onExportPdf: () =>
                                        _exportSubscriberStatement(
                                            context, user, subscriber),
                                    onPay: () async {
                                      await showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        builder: (_) => RecordPaymentSheet(
                                            subscriber: subscriber),
                                      );
                                    },
                                    onPayAdvance: () =>
                                        AdvanceSubscriptionSheet.show(
                                            context, subscriber),
                                    onToggleAutoRenew: () async {
                                      await ref
                                          .read(subscribersRepositoryProvider)
                                          .setAutoRenew(user, subscriber,
                                              !subscriber.autoRenew);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(subscriber.autoRenew
                                              ? l.t('autoRenewDisabled')
                                              : l.t('autoRenewEnabled')),
                                        ),
                                      );
                                    },
                                    onShiftAutoRenew: () =>
                                        ShiftAutoRenewalDialog.show(
                                            context, user, subscriber),
                                    onEdit: () => _showForm(context, ref, user,
                                        existing: subscriber),
                                    onDelete: () async {
                                      final ok = await _confirm(context, l);
                                      if (ok == true) {
                                        await ref
                                            .read(subscribersRepositoryProvider)
                                            .delete(user, subscriber);
                                      }
                                    },
                                  )
                                      .animate()
                                      .fadeIn(duration: 200.ms)
                                      .slideY(begin: 0.04, end: 0);
                                }

                                if (isWide) {
                                  final rows = (filtered.length + 1) ~/ 2;
                                  return ListView.builder(
                                    padding: const EdgeInsets.only(
                                        top: 4, bottom: 100),
                                    itemCount: rows,
                                    itemBuilder: (_, rowIdx) {
                                      final first = filtered[rowIdx * 2];
                                      final secondIdx = rowIdx * 2 + 1;
                                      final second = secondIdx < filtered.length
                                          ? filtered[secondIdx]
                                          : null;
                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                              child:
                                                  buildSubscriberItem(first)),
                                          Expanded(
                                            child: second != null
                                                ? buildSubscriberItem(second)
                                                : const SizedBox.shrink(),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }

                                return ListView.builder(
                                  padding: const EdgeInsets.only(
                                      top: 4, bottom: 100),
                                  itemCount: filtered.length,
                                  itemBuilder: (_, i) =>
                                      buildSubscriberItem(filtered[i]),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _syncDueDebts(AppUser user, List<Subscriber> subscribers) {
    if (!user.can(Permission.recordSubscriberPayment) &&
        !user.can(Permission.editSubscriber)) {
      return;
    }
    final due = subscribers.where((subscriber) {
      return !_syncedSubscribers.contains(subscriber.id) &&
          !subscriber.subscriptionEndsAt.isAfter(DateTime.now());
    }).toList();
    if (due.isEmpty) return;
    for (final subscriber in due) {
      _syncedSubscribers.add(subscriber.id);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = ref.read(subscribersRepositoryProvider);
      for (final subscriber in due) {
        repo.syncDueDebts(user, subscriber).catchError((_) {});
      }
    });
  }

  Future<bool?> _confirm(BuildContext ctx, AppLocalizations l) =>
      showDialog<bool>(
        context: ctx,
        builder: (dialogContext) => AlertDialog(
          content: Text(l.confirmDelete),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l.no)),
            FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l.yes)),
          ],
        ),
      );

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final activeColor = color ?? theme.colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? activeColor
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? activeColor : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? activeColor
                    : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showForm(BuildContext ctx, WidgetRef ref, AppUser by,
      {Subscriber? existing}) async {
    if (existing == null && !by.can(Permission.addSubscriber)) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('ليس لديك صلاحية إضافة مشترك')),
      );
      return;
    }
    if (existing != null && !by.can(Permission.editSubscriber)) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('ليس لديك صلاحية تعديل بيانات المشترك')),
      );
      return;
    }
    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) => SubscriberFormSheet(by: by, existing: existing),
    );
  }
}

class _ModernSubscriberCard extends StatelessWidget {
  const _ModernSubscriberCard({
    required this.subscriber,
    required this.user,
    required this.onTap,
    required this.onExportPdf,
    required this.onPay,
    required this.onPayAdvance,
    required this.onToggleAutoRenew,
    required this.onShiftAutoRenew,
    required this.onEdit,
    required this.onDelete,
  });

  final Subscriber subscriber;
  final AppUser user;
  final VoidCallback onTap;
  final VoidCallback onExportPdf;
  final VoidCallback onPay;
  final VoidCallback onPayAdvance;
  final VoidCallback onToggleAutoRenew;
  final VoidCallback onShiftAutoRenew;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final loc = Localizations.localeOf(context).languageCode;
    final isAr = loc.startsWith('ar');

    final isOverdue = subscriber.status == SubscriberStatus.overdue ||
        subscriber.subscriptionEndsAt.isBefore(DateTime.now());
    final isInactive = subscriber.status == SubscriberStatus.inactive;

    final Color statusColor;
    final String statusLabel;

    if (isInactive) {
      statusColor = Colors.grey;
      statusLabel = l.t('inactive');
    } else if (isOverdue) {
      statusColor = const Color(0xFFE53935);
      statusLabel = l.t('overdue');
    } else {
      statusColor = const Color(0xFF00A86B);
      statusLabel = l.t('active');
    }

    final hasDebt = subscriber.balance > 0;
    final daysRemaining = DateFormatter.calendarDaysBetween(
      DateTime.now(),
      subscriber.subscriptionEndsAt,
    );
    final daysText = daysRemaining < 0
        ? l.t('overdue')
        : '$daysRemaining ${daysRemaining == 1 ? (loc == 'ar' ? 'يوم' : 'day') : (loc == 'ar' ? 'أيام' : 'days')}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: AppTheme.cardDecoration(
        context,
        borderColor:
            hasDebt ? const Color(0xFFE53935).withValues(alpha: 0.45) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: statusColor.withValues(alpha: 0.16),
                          child: Text(
                            subscriber.name.isNotEmpty
                                ? subscriber.name.substring(0, 1).toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.cardColor(context),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                                  subscriber.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (subscriber.supplierName != null &&
                                  subscriber.supplierName!.isNotEmpty) ...[
                                Icon(Icons.hub_outlined,
                                    size: 13,
                                    color: theme.colorScheme.onSurfaceVariant),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    subscriber.supplierName!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Icon(Icons.wifi,
                                  size: 13,
                                  color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  subscriber.packageName ??
                                      subscriber.planName ??
                                      '-',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (subscriber.phone != null &&
                        subscriber.phone!.trim().isNotEmpty)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.phone_outlined,
                            size: 20, color: Color(0xFF00A86B)),
                        tooltip: subscriber.phone,
                        onPressed: () async {
                          final uri =
                              Uri.parse('tel:${subscriber.phone!.trim()}');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                      ),
                    PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'pay') onPay();
                        if (val == 'payAdvance') onPayAdvance();
                        if (val == 'pdf') onExportPdf();
                        if (val == 'toggleAutoRenew') onToggleAutoRenew();
                        if (val == 'shiftAutoRenew') onShiftAutoRenew();
                        if (val == 'edit') onEdit();
                        if (val == 'delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        if (user.can(Permission.recordSubscriberPayment)) ...[
                          PopupMenuItem(
                            value: 'pay',
                            child: Row(
                              children: [
                                const Icon(Icons.payment,
                                    size: 18, color: Color(0xFF00A86B)),
                                const SizedBox(width: 8),
                                Text(l.recordPayment),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'payAdvance',
                            child: Row(
                              children: [
                                const Icon(Icons.event_repeat_rounded,
                                    size: 18, color: Color(0xFF1976D2)),
                                const SizedBox(width: 8),
                                Text(l.t('payAdvanceSubscription')),
                              ],
                            ),
                          ),
                        ],
                        const PopupMenuItem(
                          value: 'pdf',
                          child: Row(
                            children: [
                              Icon(Icons.picture_as_pdf_outlined,
                                  size: 18, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text('كشف حساب (PDF)'),
                            ],
                          ),
                        ),
                        if (user.can(Permission.editSubscriber)) ...[
                          PopupMenuItem(
                            value: 'toggleAutoRenew',
                            child: Row(
                              children: [
                                Icon(
                                  subscriber.autoRenew
                                      ? Icons.autorenew
                                      : Icons.sync_disabled,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(subscriber.autoRenew
                                    ? l.t('disableAutoRenew')
                                    : l.t('enableAutoRenew')),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'shiftAutoRenew',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_calendar_rounded,
                                    size: 18, color: Colors.deepOrange),
                                const SizedBox(width: 8),
                                Text(isAr
                                    ? 'إزاحة التجديد التلقائي'
                                    : 'Shift Auto-Renewal'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined, size: 18),
                                const SizedBox(width: 8),
                                Text(l.edit),
                              ],
                            ),
                          ),
                        ],
                        if (user.can(Permission.deleteSubscriber))
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline,
                                    size: 18, color: Colors.red),
                                const SizedBox(width: 8),
                                Text(l.delete,
                                    style: const TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                // Row 1: Expiry date and AutoRenew tag
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormatter.date(subscriber.subscriptionEndsAt,
                                locale: loc),
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!isInactive) ...[
                            Text(
                              ' ($daysText)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isOverdue
                                    ? const Color(0xFFE53935)
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (subscriber.autoRenew) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.autorenew,
                              size: 13,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              l.t('autoRenew'),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (subscriber.prepaidCycles > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF1976D2).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color:
                                const Color(0xFF1976D2).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_outlined,
                              size: 13,
                              color: Color(0xFF1976D2),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              subscriber.prepaidCycles == 1
                                  ? l.t('prepaidNextBadge')
                                  : l.t('prepaidCyclesBadge').replaceAll(
                                      '@count', '${subscriber.prepaidCycles}'),
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                // Row 2: Financial Status & Quick Payment Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (hasDebt)
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFE53935).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFE53935)
                                  .withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.money_off,
                                  size: 13, color: Color(0xFFE53935)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${l.debts}: ${CurrencyFormatter.format(subscriber.balance, subscriber.currency, locale: loc)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFE53935),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF00A86B).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline,
                                size: 13, color: Color(0xFF00A86B)),
                            const SizedBox(width: 4),
                            Text(
                              l.paid,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF00A86B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (hasDebt &&
                        user.can(Permission.recordSubscriberPayment)) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: onPay,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF00A86B).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF00A86B)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add,
                                  size: 13, color: Color(0xFF00A86B)),
                              const SizedBox(width: 2),
                              Text(
                                l.recordPayment,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF00A86B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subscriber.lastPaymentAmount != null &&
                    subscriber.lastPaymentAt != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 13,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            isAr
                                ? 'آخر دفعة: ${CurrencyFormatter.format(subscriber.lastPaymentAmount!, subscriber.currency, locale: loc)} • بتاريخ ${DateFormatter.date(subscriber.lastPaymentAt!, locale: loc)}'
                                : 'Last payment: ${CurrencyFormatter.format(subscriber.lastPaymentAmount!, subscriber.currency, locale: loc)} • ${DateFormatter.date(subscriber.lastPaymentAt!, locale: loc)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SubscriberDetailsDialog extends ConsumerWidget {
  const SubscriberDetailsDialog({
    super.key,
    required this.subscriber,
    required this.by,
  });

  final Subscriber subscriber;
  final AppUser by;

  Future<void> _exportStatement(BuildContext context, WidgetRef ref) async {
    final loc = Localizations.localeOf(context).languageCode;
    try {
      final repo = ref.read(subscribersRepositoryProvider);
      final debts = await repo.getDebts(by.adminUid, subscriber.id);
      final payments = await repo.getPayments(by.adminUid, subscriber.id);
      await PdfReportService().previewSubscriberStatement(
        subscriber: subscriber,
        debts: debts,
        payments: payments,
        generatedBy: by.displayName.isNotEmpty
            ? by.displayName
            : (by.email ?? 'ISP Manager'),
        locale: loc,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تصدير كشف الحساب: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final loc = Localizations.localeOf(context).languageCode;
    final isAr = loc.startsWith('ar');
    final size = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      child: DefaultTabController(
        length: 3,
        child: SizedBox(
          width: size.width * .94,
          height: size.height * .86,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subscriber.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (by.can(Permission.recordSubscriberPayment))
                          IconButton(
                            tooltip: l.t('payAdvanceSubscription'),
                            icon: const Icon(Icons.event_repeat_rounded,
                                color: Color(0xFF1976D2)),
                            onPressed: () => AdvanceSubscriptionSheet.show(
                                context, subscriber),
                          ),
                        IconButton(
                          tooltip: 'تصدير كشف حساب المشترك (PDF)',
                          icon: const Icon(Icons.picture_as_pdf_rounded,
                              color: Colors.redAccent),
                          onPressed: () => _exportStatement(context, ref),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    if (by.can(Permission.editSubscriber))
                      Container(
                        margin: const EdgeInsets.only(top: 4, left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.cardBorderColor(context),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              subscriber.autoRenew
                                  ? Icons.autorenew
                                  : Icons.sync_disabled,
                              size: 18,
                              color: subscriber.autoRenew
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    l.t('autoRenew'),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    isAr
                                        ? 'ينتهي: ${DateFormatter.date(subscriber.subscriptionEndsAt, locale: loc)}'
                                        : 'Ends: ${DateFormatter.date(subscriber.subscriptionEndsAt, locale: loc)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                foregroundColor: Colors.deepOrange,
                              ),
                              onPressed: () => ShiftAutoRenewalDialog.show(
                                  context, by, subscriber),
                              icon: const Icon(Icons.edit_calendar_rounded,
                                  size: 16),
                              label: Text(
                                isAr ? 'إزاحة التجديد' : 'Shift Date',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Switch(
                              value: subscriber.autoRenew,
                              onChanged: (v) async {
                                await ref
                                    .read(subscribersRepositoryProvider)
                                    .setAutoRenew(by, subscriber, v);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(v
                                        ? l.t('autoRenewEnabled')
                                        : l.t('autoRenewDisabled')),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    if (subscriber.lastPaymentAmount != null &&
                        subscriber.lastPaymentAt != null)
                      Container(
                        margin: const EdgeInsets.only(top: 6, left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A86B).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                const Color(0xFF00A86B).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.payments_outlined,
                                size: 17, color: Color(0xFF00A86B)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isAr
                                    ? 'آخر دفعة مسددة: ${CurrencyFormatter.format(subscriber.lastPaymentAmount!, subscriber.currency, locale: loc)} • بتاريخ ${DateFormatter.date(subscriber.lastPaymentAt!, locale: loc)}'
                                    : 'Last payment: ${CurrencyFormatter.format(subscriber.lastPaymentAmount!, subscriber.currency, locale: loc)} on ${DateFormatter.date(subscriber.lastPaymentAt!, locale: loc)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF008756),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (subscriber.prepaidCycles > 0)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF1976D2).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: Color(0xFF1976D2), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          subscriber.prepaidCycles == 1
                              ? 'الاشتراك القادم مسدد مقدماً. عند حلول موعد التجديد التلقائي القادم سيُسجل كمسدد تلقائياً بدون إضافة دين.'
                              : 'المشترك لديه (${subscriber.prepaidCycles}) دورات مسددة مقدماً. سيتم تسجيل التجديدات القادمة كمسددة تلقائياً.',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                      ),
                      if (by.can(Permission.recordSubscriberPayment))
                        TextButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(l.t('cancelAdvancePayment')),
                                content:
                                    Text(l.t('confirmCancelAdvancePayment')),
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
                            if (confirm == true) {
                              await ref
                                  .read(subscribersRepositoryProvider)
                                  .cancelAdvancePayment(by, subscriber);
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            }
                          },
                          child: Text(
                            l.t('cancelAdvancePayment'),
                            style: const TextStyle(
                                color: Colors.red, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: StreamBuilder<List<SubscriberDebt>>(
                  stream: ref
                      .watch(subscribersRepositoryProvider)
                      .watchDebts(by.adminUid, subscriber.id),
                  builder: (_, snap) {
                    final debts = snap.data ?? [];
                    final unpaidDebts = debts
                        .where((debt) => !debt.isPaid)
                        .toList(growable: false);
                    final paidDebts = debts
                        .where((debt) => debt.isPaid)
                        .toList(growable: false);
                    final totalDebt = unpaidDebts.fold<num>(
                        0, (total, debt) => total + debt.remaining);
                    return Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.account_balance_wallet),
                          title: Text(l.totalDebts),
                          trailing: Text(
                            CurrencyFormatter.format(
                              totalDebt,
                              subscriber.currency,
                              locale: loc,
                            ),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TabBar(tabs: [
                          Tab(text: l.t('unpaidDebts')),
                          Tab(text: l.t('paidSubscriptions')),
                          Tab(text: isAr ? 'سجل الدفعات' : 'Payments'),
                        ]),
                        Expanded(
                          child: snap.connectionState == ConnectionState.waiting
                              ? const Center(child: CircularProgressIndicator())
                              : TabBarView(
                                  children: [
                                    _SubscriberDebtsTab(
                                      subscriber: subscriber,
                                      by: by,
                                      debts: unpaidDebts,
                                    ),
                                    _PaidSubscriptionsTab(
                                      subscriber: subscriber,
                                      by: by,
                                      debts: paidDebts,
                                    ),
                                    _SubscriberPaymentsTab(
                                      subscriber: subscriber,
                                      by: by,
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriberDebtsTab extends ConsumerWidget {
  const _SubscriberDebtsTab({
    required this.subscriber,
    required this.by,
    required this.debts,
  });

  final Subscriber subscriber;
  final AppUser by;
  final List<SubscriberDebt> debts;

  static Future<void> _confirmAndPayDebt(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    String loc,
    AppUser by,
    Subscriber subscriber,
    SubscriberDebt debt,
  ) async {
    var selectedDestination = MoneyStorage.cashbox;
    var selectedPaidDate = DateTime.now();
    final isAr = loc.startsWith('ar');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l.t('payDebt')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l.amount}: ${CurrencyFormatter.format(debt.remaining, debt.currency, locale: loc)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedPaidDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    final now = DateTime.now();
                    setState(() {
                      selectedPaidDate = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        now.hour,
                        now.minute,
                        now.second,
                      );
                    });
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: isAr ? 'تاريخ التسديد' : 'Payment Date',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    prefixIcon:
                        const Icon(Icons.calendar_today_outlined, size: 18),
                    suffixIcon:
                        const Icon(Icons.edit_calendar_outlined, size: 18),
                  ),
                  child: Text(
                    DateFormatter.date(selectedPaidDate, locale: loc),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<MoneyStorage>(
                isExpanded: true,
                value: selectedDestination,
                decoration: InputDecoration(
                  labelText: l.t('paymentDestination'),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(
                    value: MoneyStorage.cashbox,
                    child: Text(l.t('putInCashbox')),
                  ),
                  DropdownMenuItem(
                    value: MoneyStorage.personal,
                    child: Text(l.t('keptByCollectorDebt')),
                  ),
                  DropdownMenuItem(
                    value: MoneyStorage.none,
                    child: Text(l.t('noCashboxSettlement')),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => selectedDestination = v);
                },
              ),
              if (selectedDestination == MoneyStorage.none) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.amber.shade700.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 16, color: Colors.amber.shade900),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l.t('noCashboxSettlementHint'),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text(l.no),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text(l.t('pay')),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(subscribersRepositoryProvider).markDebtPaid(
            by,
            subscriber,
            debt,
            receivedIn: selectedDestination,
            paidAt: selectedPaidDate,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.saved)),
        );
      }
    }
  }

  static Future<void> _confirmAndDeleteDebt(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    String loc,
    AppUser by,
    Subscriber subscriber,
    SubscriberDebt debt,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(l.t('deleteDebt')),
          ],
        ),
        content: Text(
          '${l.t('confirmDeleteDebt')}\n\n'
          '${l.amount}: ${CurrencyFormatter.format(debt.remaining, debt.currency, locale: loc)}\n'
          '${debt.packageName ?? subscriber.packageName ?? ''}\n\n'
          '${l.t('confirmDeleteDebtMsg')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(subscribersRepositoryProvider).deleteDebt(
            by,
            subscriber,
            debt,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.t('debtDeletedSuccess'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final loc = Localizations.localeOf(context).languageCode;
    final canAddDebt = by.can(Permission.editSubscriber);
    final canPay = by.can(Permission.recordSubscriberPayment);
    return Scaffold(
      body: debts.isEmpty
          ? Center(child: Text(l.noData))
          : ListView.separated(
              padding: const EdgeInsets.only(top: 6, bottom: 88),
              itemCount: debts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final debt = debts[i];
                final isPartial =
                    debt.status == SubscriptionDebtStatus.partiallyPaid;
                return ListTile(
                  leading: Icon(isPartial
                      ? Icons.hourglass_bottom
                      : Icons.pending_actions_outlined),
                  title: Text(
                    '${CurrencyFormatter.format(debt.remaining, debt.currency, locale: loc)}'
                    '${isPartial ? ' / ${CurrencyFormatter.format(debt.amount, debt.currency, locale: loc)}' : ''}',
                  ),
                  subtitle: Text(
                    '${DateFormatter.date(debt.periodStart, locale: loc)} - '
                    '${DateFormatter.date(debt.periodEnd, locale: loc)}\n'
                    '${debt.packageName ?? subscriber.packageName ?? '-'}'
                    '${isPartial ? ' • ${l.paid}: ${CurrencyFormatter.format(debt.paidAmount, debt.currency, locale: loc)}${debt.paidAt != null ? ' (${DateFormatter.date(debt.paidAt!, locale: loc)})' : ''}' : ''}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (canPay)
                        FilledButton(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => _confirmAndPayDebt(
                              context, ref, l, loc, by, subscriber, debt),
                          child: Text(l.t('pay')),
                        ),
                      if (canAddDebt)
                        PopupMenuButton<String>(
                          tooltip: 'خيارات الدين',
                          icon: const Icon(Icons.more_vert, size: 20),
                          onSelected: (action) {
                            if (action == 'edit') {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => AddSubscriberDebtSheet(
                                  subscriber: subscriber,
                                  by: by,
                                  existingDebt: debt,
                                ),
                              );
                            } else if (action == 'delete') {
                              _confirmAndDeleteDebt(
                                  context, ref, l, loc, by, subscriber, debt);
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit_outlined,
                                      size: 18, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(l.t('editDebt')),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline,
                                      size: 18, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text(l.t('deleteDebt')),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: canAddDebt
          ? FloatingActionButton.extended(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => AddSubscriberDebtSheet(
                  subscriber: subscriber,
                  by: by,
                ),
              ),
              icon: const Icon(Icons.add),
              label: Text(l.t('addDebt')),
            )
          : null,
    );
  }
}

class _PaidSubscriptionsTab extends ConsumerWidget {
  const _PaidSubscriptionsTab({
    required this.subscriber,
    required this.by,
    required this.debts,
  });

  final Subscriber subscriber;
  final AppUser by;
  final List<SubscriberDebt> debts;

  static Future<void> _confirmAndUnpayDebt(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    String loc,
    AppUser by,
    Subscriber subscriber,
    SubscriberDebt debt,
  ) async {
    final isAr = loc.startsWith('ar');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.undo_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text(isAr
                ? 'التراجع عن تسديد الاشتراك'
                : 'Undo Subscription Payment'),
          ],
        ),
        content: Text(
          isAr
              ? 'هل تريد التراجع عن تسديد هذا الاشتراك بقيمة ${CurrencyFormatter.format(debt.amount, debt.currency, locale: loc)} للمشترك "${subscriber.name}"؟\n\nسيتم إرجاع الاشتراك إلى غير مسدد وعكس المبلغ من الصندوق.'
              : 'Undo payment of ${CurrencyFormatter.format(debt.amount, debt.currency, locale: loc)} for "${subscriber.name}"?\n\nThe subscription will revert to unpaid and the amount will be reversed from cashbox.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade800),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(isAr ? 'تأكيد التراجع' : 'Undo Payment'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(subscribersRepositoryProvider).unpayDebt(
            by,
            subscriber,
            debt,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'تم التراجع عن تسديد الاشتراك بنجاح'
                  : 'Subscription payment undone successfully',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final loc = Localizations.localeOf(context).languageCode;
    final isAr = loc.startsWith('ar');
    final canManage = by.isAdmin ||
        by.can(Permission.editSubscriber) ||
        by.can(Permission.recordSubscriberPayment);
    if (debts.isEmpty) return Center(child: Text(l.noData));
    return ListView.separated(
      padding: const EdgeInsets.only(top: 6, bottom: 88),
      itemCount: debts.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final debt = debts[i];
        return ListTile(
          leading: const Icon(Icons.check_circle_outline, color: Colors.green),
          title: Text(
            CurrencyFormatter.format(debt.amount, debt.currency, locale: loc),
          ),
          subtitle: Text(
            '${DateFormatter.date(debt.periodStart, locale: loc)} - '
            '${DateFormatter.date(debt.periodEnd, locale: loc)}\n'
            '${l.paid}: ${debt.paidAt == null ? '-' : DateFormatter.date(debt.paidAt!, locale: loc)}',
          ),
          isThreeLine: true,
          trailing: canManage
              ? PopupMenuButton<String>(
                  tooltip: 'خيارات الاشتراك',
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (action) {
                    if (action == 'unpay') {
                      _confirmAndUnpayDebt(
                          context, ref, l, loc, by, subscriber, debt);
                    } else if (action == 'edit') {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => AddSubscriberDebtSheet(
                          subscriber: subscriber,
                          by: by,
                          existingDebt: debt,
                        ),
                      );
                    } else if (action == 'delete') {
                      _SubscriberDebtsTab._confirmAndDeleteDebt(
                          context, ref, l, loc, by, subscriber, debt);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'unpay',
                      child: Row(
                        children: [
                          Icon(Icons.undo_rounded,
                              size: 18, color: Colors.orange.shade800),
                          const SizedBox(width: 8),
                          Text(
                            isAr ? 'التراجع عن التسديد' : 'Undo Payment',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (by.isAdmin || by.can(Permission.editSubscriber)) ...[
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined,
                                size: 18, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(l.t('editDebt')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline,
                                size: 18, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(l.t('deleteDebt')),
                          ],
                        ),
                      ),
                    ],
                  ],
                )
              : null,
        );
      },
    );
  }
}

class _SubscriberPaymentsTab extends ConsumerWidget {
  const _SubscriberPaymentsTab({
    required this.subscriber,
    required this.by,
  });

  final Subscriber subscriber;
  final AppUser by;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final loc = Localizations.localeOf(context).languageCode;
    final isAr = loc.startsWith('ar');
    return StreamBuilder<List<Payment>>(
      stream: ref
          .watch(subscribersRepositoryProvider)
          .watchPayments(by.adminUid, subscriber.id),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final payments = snap.data ?? [];
        if (payments.isEmpty) {
          return Center(child: Text(l.noData));
        }
        return ListView.separated(
          padding: const EdgeInsets.only(top: 6, bottom: 88),
          itemCount: payments.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final p = payments[i];
            final destLabel = switch (p.receivedIn) {
              MoneyStorage.cashbox => l.t('putInCashbox'),
              MoneyStorage.personal => l.t('keptByCollectorDebt'),
              MoneyStorage.none => l.t('noCashboxSettlement'),
            };
            return ListTile(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF00A86B).withValues(alpha: 0.14),
                child: const Icon(Icons.payments_rounded,
                    size: 18, color: Color(0xFF00A86B)),
              ),
              title: Text(
                CurrencyFormatter.format(p.amount, p.currency, locale: loc),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                '${isAr ? 'تاريخ الدفعة' : 'Payment Date'}: ${DateFormatter.date(p.recordedAt, locale: loc)} • $destLabel'
                '${p.note != null && p.note!.isNotEmpty ? '\n${p.note}' : ''}',
              ),
              isThreeLine: p.note != null && p.note!.isNotEmpty,
            );
          },
        );
      },
    );
  }
}

class ShiftAutoRenewalDialog extends ConsumerStatefulWidget {
  const ShiftAutoRenewalDialog({
    super.key,
    required this.by,
    required this.subscriber,
  });

  final AppUser by;
  final Subscriber subscriber;

  static Future<void> show(
    BuildContext context,
    AppUser by,
    Subscriber subscriber,
  ) {
    return showDialog(
      context: context,
      builder: (_) => ShiftAutoRenewalDialog(by: by, subscriber: subscriber),
    );
  }

  @override
  ConsumerState<ShiftAutoRenewalDialog> createState() =>
      _ShiftAutoRenewalDialogState();
}

class _ShiftAutoRenewalDialogState
    extends ConsumerState<ShiftAutoRenewalDialog> {
  SubscriberDebt? _latestDebt;
  late DateTime _baseStart;
  late DateTime _baseEnd;
  late DateTime _newStart;
  late DateTime _newEnd;
  final TextEditingController _daysController =
      TextEditingController(text: '1');
  bool _shiftLatestDebt = true;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _baseEnd = widget.subscriber.subscriptionEndsAt;
    _baseStart = DateFormatter.addDays(_baseEnd, -30);
    _newStart = DateFormatter.addDays(_baseStart, 1);
    _newEnd = DateFormatter.addDays(_baseEnd, 1);
    _loadLatestDebt();
  }

  @override
  void dispose() {
    _daysController.dispose();
    super.dispose();
  }

  Future<void> _loadLatestDebt() async {
    try {
      final debts = await ref
          .read(subscribersRepositoryProvider)
          .getDebts(widget.by.adminUid, widget.subscriber.id);
      if (!mounted) return;
      setState(() {
        _latestDebt = debts.isNotEmpty ? debts.first : null;
        if (_latestDebt != null) {
          _baseStart = _latestDebt!.periodStart;
          _baseEnd = _latestDebt!.periodEnd;
        } else {
          _baseEnd = widget.subscriber.subscriptionEndsAt;
          _baseStart = DateFormatter.addDays(_baseEnd, -30);
        }
        _applyShiftDays(1);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyShiftDays(int days) {
    setState(() {
      _daysController.text = '$days';
      _newStart = DateFormatter.addDays(_baseStart, days);
      _newEnd = DateFormatter.addDays(_baseEnd, days);
    });
  }

  void _activateFromDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final diffDays = DateFormatter.calendarDaysBetween(_baseStart, normalized);
    setState(() {
      _newStart = normalized;
      _newEnd = DateFormatter.addDays(normalized, 30);
      _daysController.text = '$diffDays';
    });
  }

  Future<void> _pickNewStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _newStart,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _activateFromDate(picked);
    }
  }

  Future<void> _pickNewEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _newEnd,
      firstDate: DateFormatter.addDays(_newStart, 1),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _newEnd = picked);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(subscribersRepositoryProvider).shiftAutoRenewal(
            widget.by,
            widget.subscriber,
            newActivationDate: _newStart,
            newSubscriptionEndsAt: _newEnd,
            targetDebtId: _shiftLatestDebt ? _latestDebt?.id : null,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت إزاحة تاريخ التجديد التلقائي بنجاح'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Localizations.localeOf(context).languageCode;
    final isAr = loc.startsWith('ar');
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.edit_calendar_rounded, color: Colors.deepOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isAr ? 'إزاحة التجديد التلقائي' : 'Shift Auto-Renewal',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: _loading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isAr
                        ? 'استخدم هذه الميزة إذا لم يتم تفعيل المشترك (${widget.subscriber.name}) في نفس يوم انتهاء الاشتراك.'
                        : 'Use this if ${widget.subscriber.name} was not activated on the exact expiration day.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? 'الفترة الحالية المسجلة:' : 'Current Period:',
                          style: const TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormatter.date(_baseStart, locale: loc)}  ⬅  ${DateFormatter.date(_baseEnd, locale: loc)}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isAr
                        ? 'إزاحة سريعة (عدد أيام التأخير):'
                        : 'Quick Shift (Days):',
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final d in [1, 2, 3, 5, 7])
                        ActionChip(
                          label: Text(isAr ? '+$d يوم' : '+$d d'),
                          onPressed: () => _applyShiftDays(d),
                        ),
                      ActionChip(
                        avatar: const Icon(Icons.today, size: 16),
                        label: Text(
                            isAr ? 'تفعيل من اليوم' : 'Activate from Today'),
                        onPressed: () => _activateFromDate(DateTime.now()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _daysController,
                    keyboardType:
                        const TextInputType.numberWithOptions(signed: true),
                    decoration: InputDecoration(
                      labelText: isAr
                          ? 'عدد أيام الإزاحة (مثال: 3)'
                          : 'Shift Days (e.g. 3)',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: const Icon(Icons.exposure_plus_1_rounded),
                    ),
                    onChanged: (v) {
                      final parsed = int.tryParse(v.trim());
                      if (parsed != null) {
                        setState(() {
                          _newStart = DateFormatter.addDays(_baseStart, parsed);
                          _newEnd = DateFormatter.addDays(_baseEnd, parsed);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickNewStartDate,
                    icon: const Icon(Icons.play_circle_outline, size: 18),
                    label: Text(
                      isAr
                          ? 'تاريخ التفعيل الفعلي: ${DateFormatter.date(_newStart, locale: loc)}'
                          : 'Activation Date: ${DateFormatter.date(_newStart, locale: loc)}',
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickNewEndDate,
                    icon: const Icon(Icons.event_available_outlined, size: 18),
                    label: Text(
                      isAr
                          ? 'تاريخ الانتهاء الجديد: ${DateFormatter.date(_newEnd, locale: loc)}'
                          : 'New Expiry Date: ${DateFormatter.date(_newEnd, locale: loc)}',
                    ),
                  ),
                  if (_latestDebt != null) ...[
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: _shiftLatestDebt,
                      onChanged: (v) =>
                          setState(() => _shiftLatestDebt = v ?? true),
                      title: Text(
                        isAr
                            ? 'إزاحة فترة الاشتراك الحالية في سجل الديون أيضاً'
                            : 'Also shift current subscription debt period',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(isAr ? 'إلغاء' : 'Cancel'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
          onPressed: _loading || _saving ? null : _save,
          icon: const Icon(Icons.check, size: 18),
          label: Text(isAr ? 'حفظ الإزاحة' : 'Save Shift'),
        ),
      ],
    );
  }
}

class AddSubscriberDebtSheet extends ConsumerStatefulWidget {
  const AddSubscriberDebtSheet({
    super.key,
    required this.subscriber,
    required this.by,
    this.existingDebt,
  });

  final Subscriber subscriber;
  final AppUser by;
  final SubscriberDebt? existingDebt;

  @override
  ConsumerState<AddSubscriberDebtSheet> createState() =>
      _AddSubscriberDebtSheetState();
}

class _AddSubscriberDebtSheetState
    extends ConsumerState<AddSubscriberDebtSheet> {
  late DateTime _from = widget.existingDebt?.periodStart ?? DateTime.now();
  late DateTime _to =
      widget.existingDebt?.periodEnd ?? DateFormatter.addDays(_from, 30);
  late DateTime? _paidAt = widget.existingDebt?.paidAt;
  late final _amount = TextEditingController(
    text: widget.existingDebt != null
        ? widget.existingDebt!.amount.toString()
        : widget.subscriber.monthlyFee.toString(),
  );
  late final _agentCost = TextEditingController(
    text: widget.existingDebt != null
        ? widget.existingDebt!.agentCost.toString()
        : widget.subscriber.packageAgentPrice.toString(),
  );
  late final _note =
      TextEditingController(text: widget.existingDebt?.note ?? '');
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _agentCost.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = num.tryParse(_amount.text) ?? 0;
    if (amount <= 0 || !_to.isAfter(_from)) return;
    setState(() => _busy = true);
    final l = AppLocalizations.of(context);
    try {
      final repo = ref.read(subscribersRepositoryProvider);
      final debt = SubscriberDebt(
        id: widget.existingDebt?.id ?? '',
        subscriberId: widget.subscriber.id,
        supplierId: widget.subscriber.supplierId,
        packageId: widget.subscriber.packageId,
        packageName:
            widget.subscriber.packageName ?? widget.subscriber.planName,
        amount: amount,
        paidAmount: widget.existingDebt?.paidAmount ?? 0,
        agentCost: num.tryParse(_agentCost.text) ?? 0,
        currency: widget.subscriber.currency,
        periodStart: _from,
        periodEnd: _to,
        status: widget.existingDebt?.status ?? SubscriptionDebtStatus.unpaid,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        recordedBy: widget.existingDebt?.recordedBy ?? widget.by.uid,
        createdAt: widget.existingDebt?.createdAt ?? DateTime.now(),
        paidAt: _paidAt,
        paidBy: widget.existingDebt?.paidBy,
      );
      if (widget.existingDebt != null) {
        await repo.updateDebt(
            widget.by, widget.subscriber, widget.existingDebt!, debt);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.t('debtUpdatedSuccess'))),
          );
        }
      } else {
        await repo.addDebt(widget.by, widget.subscriber, debt);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.saved)),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final loc = Localizations.localeOf(context).languageCode;
    final isAr = loc.startsWith('ar');
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
              widget.existingDebt != null ? l.t('editDebt') : l.t('addDebt'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickFrom(context),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      '${l.from}: ${DateFormatter.date(_from, locale: loc)}',
                    ),
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
            if (widget.existingDebt != null &&
                (widget.existingDebt!.isPaid ||
                    widget.existingDebt!.paidAmount > 0)) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _pickPaidAt(context),
                  icon: const Icon(Icons.edit_calendar_outlined),
                  label: Text(
                    '${isAr ? 'تاريخ التسديد' : 'Payment Date'}: '
                    '${DateFormatter.date(_paidAt ?? DateTime.now(), locale: loc)}',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _amount,
              decoration: InputDecoration(labelText: l.t('subscriberPrice')),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _agentCost,
              decoration: InputDecoration(labelText: l.t('agentPrice')),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              decoration: InputDecoration(labelText: l.note),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(l.save),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPaidAt(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _paidAt ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      final now = DateTime.now();
      setState(() {
        _paidAt = DateTime(
          date.year,
          date.month,
          date.day,
          now.hour,
          now.minute,
          now.second,
        );
      });
    }
  }

  Future<void> _pickFrom(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        _from = date;
        if (!_to.isAfter(_from)) {
          _to = DateFormatter.addDays(_from, 30);
        }
      });
    }
  }

  Future<void> _pickTo(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _to,
      firstDate: DateFormatter.addDays(_from, 1),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _to = date);
  }
}

class SubscriberFormSheet extends ConsumerStatefulWidget {
  const SubscriberFormSheet({super.key, required this.by, this.existing});
  final AppUser by;
  final Subscriber? existing;

  @override
  ConsumerState<SubscriberFormSheet> createState() =>
      _SubscriberFormSheetState();
}

class _SubscriberFormSheetState extends ConsumerState<SubscriberFormSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _phone =
      TextEditingController(text: widget.existing?.phone ?? '');
  late final TextEditingController _price = TextEditingController(
      text: widget.existing != null && widget.existing!.monthlyFee > 0
          ? widget.existing!.monthlyFee.toString()
          : '');

  late String? _supplierId = widget.existing?.supplierId;
  late String? _supplierName = widget.existing?.supplierName;
  late String? _packageId = widget.existing?.packageId;
  late String? _packageName =
      widget.existing?.packageName ?? widget.existing?.planName;
  late num _subscriberPrice = widget.existing?.monthlyFee ?? 0;
  late num _agentPrice = widget.existing?.packageAgentPrice ?? 0;
  late AppCurrency _currency = widget.existing?.currency ?? AppCurrency.iqd;
  late DateTime _subscriptionEndsAt = widget.existing?.subscriptionEndsAt ??
      DateFormatter.addDays(DateTime.now(), 30);
  late bool _autoRenew = widget.existing?.autoRenew ?? true;
  // 'paid' = مدفوع نقداً, 'debt' = دين على المشترك, 'none' = بدون أثر مالي (إضافة فقط)
  String _initialPaymentMode = 'none';
  MoneyStorage _initialReceivedIn = MoneyStorage.cashbox;
  DateTime _initialPaidDate = DateTime.now();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (widget.existing == null && !widget.by.can(Permission.addSubscriber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ليس لديك صلاحية إضافة مشترك')),
      );
      return;
    }
    if (widget.existing != null && !widget.by.can(Permission.editSubscriber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ليس لديك صلاحية تعديل بيانات المشترك')),
      );
      return;
    }
    final customPrice = num.tryParse(_price.text.trim());
    if (customPrice != null && customPrice >= 0) {
      _subscriberPrice = customPrice;
    }
    if (_name.text.trim().isEmpty ||
        _supplierId == null ||
        _packageId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.fieldRequired)));
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = ref.read(subscribersRepositoryProvider);
      final num initialBalance;
      final SubscriberStatus initialStatus;
      if (widget.existing != null) {
        initialBalance = widget.existing!.balance;
        initialStatus = widget.existing!.status;
      } else if (_initialPaymentMode == 'debt') {
        initialBalance = _subscriberPrice;
        initialStatus = SubscriberStatus.overdue;
      } else {
        // 'none' or 'paid': initial balance is 0, status is active
        initialBalance = 0;
        initialStatus = SubscriberStatus.active;
      }

      final subscriber = Subscriber(
        id: widget.existing?.id ?? '',
        name: _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        supplierId: _supplierId,
        supplierName: _supplierName,
        packageId: _packageId,
        packageName: _packageName,
        planName: _packageName,
        monthlyFee: _subscriberPrice,
        packageAgentPrice: _agentPrice,
        currency: _currency,
        balance: initialBalance,
        status: initialStatus,
        joinedAt: widget.existing?.joinedAt ?? DateTime.now(),
        subscriptionEndsAt: _subscriptionEndsAt,
        autoRenew: _autoRenew,
        prepaidCycles: widget.existing?.prepaidCycles ?? 0,
        lastPaymentAmount: widget.existing?.lastPaymentAmount,
        lastPaymentAt: widget.existing?.lastPaymentAt,
      );
      if (widget.existing == null) {
        if (_initialPaymentMode == 'paid') {
          await repo.addWithInitialSubscription(
            widget.by,
            subscriber,
            isPaid: true,
            receivedIn: _initialReceivedIn,
            paidAt: _initialPaidDate,
          );
        } else if (_initialPaymentMode == 'debt') {
          await repo.addWithInitialSubscription(
            widget.by,
            subscriber,
            isPaid: false,
            receivedIn: _initialReceivedIn,
          );
        } else {
          // 'none' (بدون أثر مالي): إضافة المشترك فقط بدون أي حركة في الصندوق وبدون أي دين
          await repo.add(widget.by, subscriber);
        }
      } else {
        await repo.update(widget.by, subscriber);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.saved)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final loc = Localizations.localeOf(context).languageCode;
    final suppliers = ref.watch(suppliersStreamProvider(widget.by.adminUid));
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
            Text(widget.existing == null ? l.addSubscriber : l.editSubscriber,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: l.name),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phone,
              decoration: InputDecoration(labelText: l.phone),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            suppliers.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e'),
              data: (items) => DropdownButtonFormField<String>(
                value: items.any((supplier) => supplier.id == _supplierId)
                    ? _supplierId
                    : null,
                decoration: InputDecoration(labelText: l.selectSupplier),
                items: [
                  for (final supplier in items)
                    DropdownMenuItem(
                      value: supplier.id,
                      child: Text(supplier.name),
                    ),
                ],
                onChanged: (value) {
                  final supplier = items
                      .where((item) => item.id == value)
                      .cast<Supplier?>()
                      .firstWhere((_) => true, orElse: () => null);
                  setState(() {
                    _supplierId = supplier?.id;
                    _supplierName = supplier?.name;
                    _packageId = null;
                    _packageName = null;
                    _subscriberPrice = 0;
                    _agentPrice = 0;
                    _price.text = '';
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            if (_supplierId != null)
              StreamBuilder<List<SupplierPackageTemplate>>(
                stream: ref
                    .watch(suppliersRepositoryProvider)
                    .watchPackages(widget.by.adminUid, _supplierId!),
                builder: (_, snap) {
                  final packages = snap.data ?? [];
                  final value =
                      packages.any((package) => package.id == _packageId)
                          ? _packageId
                          : null;
                  return DropdownButtonFormField<String>(
                    value: value,
                    decoration: InputDecoration(labelText: l.selectPackage),
                    items: [
                      for (final package
                          in packages.where((package) => package.active))
                        DropdownMenuItem(
                          value: package.id,
                          child: Text(
                            '${package.name} - ${CurrencyFormatter.format(package.subscriberPrice, package.currency, locale: loc)}',
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      final package = packages
                          .where((item) => item.id == value)
                          .cast<SupplierPackageTemplate?>()
                          .firstWhere((_) => true, orElse: () => null);
                      setState(() {
                        _packageId = package?.id;
                        _packageName = package?.name;
                        _subscriberPrice = package?.subscriberPrice ?? 0;
                        _agentPrice = package?.agentPrice ?? 0;
                        _currency = package?.currency ?? _currency;
                        _price.text = _subscriberPrice > 0
                            ? _subscriberPrice.toString()
                            : '';
                      });
                    },
                  );
                },
              ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l.t('subscriberPrice'),
                prefixIcon: const Icon(Icons.payments_outlined),
                suffixText: _currency.code,
                helperText: 'سعر الاشتراك (يمكنك تعديله يدوياً للمشترك)',
              ),
              onChanged: (v) {
                setState(() {
                  _subscriberPrice = num.tryParse(v.trim()) ?? 0;
                });
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_available_outlined),
              title: Text(l.t('subscriptionEndsAt')),
              trailing: TextButton.icon(
                onPressed: () => _pickEndDate(context),
                icon: const Icon(Icons.calendar_today),
                label:
                    Text(DateFormatter.date(_subscriptionEndsAt, locale: loc)),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary:
                  Icon(_autoRenew ? Icons.autorenew : Icons.sync_disabled),
              title: Text(l.t('autoRenew')),
              value: _autoRenew,
              onChanged: (v) => setState(() => _autoRenew = v),
            ),
            if (widget.existing == null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l.t('initialPaymentOption'),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildPaymentModeTile(
                      mode: 'none',
                      title: l.t('noInitialFinancialEffect'),
                      subtitle: l.t('noInitialFinancialEffectHint'),
                      icon: Icons.person_add_alt_1_outlined,
                      activeColor: Colors.teal,
                    ),
                    const SizedBox(height: 6),
                    _buildPaymentModeTile(
                      mode: 'paid',
                      title: l.t('firstMonthPaid'),
                      subtitle: 'تحصيل المبلغ وإيداعه في الصندوق فوراً',
                      icon: Icons.payments_outlined,
                      activeColor: Colors.green,
                    ),
                    const SizedBox(height: 6),
                    _buildPaymentModeTile(
                      mode: 'debt',
                      title: l.t('firstMonthDebt'),
                      subtitle:
                          'تسجيل المبلغ كـ دَين على المشترك دون التأثير على الصندوق',
                      icon: Icons.receipt_outlined,
                      activeColor: Colors.orange,
                    ),
                    if (_initialPaymentMode == 'paid') ...[
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _initialPaidDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            final now = DateTime.now();
                            setState(() {
                              _initialPaidDate = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                now.hour,
                                now.minute,
                                now.second,
                              );
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: loc.startsWith('ar')
                                ? 'تاريخ التسديد'
                                : 'Payment Date',
                            isDense: true,
                            prefixIcon: const Icon(
                                Icons.calendar_today_outlined,
                                size: 18),
                            suffixIcon: const Icon(
                                Icons.edit_calendar_outlined,
                                size: 18),
                          ),
                          child: Text(
                            DateFormatter.date(_initialPaidDate, locale: loc),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<MoneyStorage>(
                        isExpanded: true,
                        value: _initialReceivedIn,
                        decoration: InputDecoration(
                          labelText: l.t('paymentDestination'),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: MoneyStorage.cashbox,
                            child: Text(l.t('putInCashbox')),
                          ),
                          DropdownMenuItem(
                            value: MoneyStorage.personal,
                            child: Text(l.t('keptByCollectorDebt')),
                          ),
                          DropdownMenuItem(
                            value: MoneyStorage.none,
                            child: Text(l.t('noCashboxSettlement')),
                          ),
                        ],
                        onChanged: (v) => setState(() =>
                            _initialReceivedIn = v ?? MoneyStorage.cashbox),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  child: Text(l.cancel),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _save,
                  child: Text(l.save),
                ),
              ),
            ]),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentModeTile({
    required String mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _initialPaymentMode == mode;
    return InkWell(
      onTap: () => setState(() => _initialPaymentMode = mode),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? activeColor
                : Theme.of(context).dividerColor.withValues(alpha: 0.5),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                isSelected ? Icons.check_circle_rounded : icon,
                size: 20,
                color: isSelected
                    ? activeColor
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 13,
                      color: isSelected ? activeColor : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  Future<void> _pickEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _subscriptionEndsAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _subscriptionEndsAt = picked);
  }
}
