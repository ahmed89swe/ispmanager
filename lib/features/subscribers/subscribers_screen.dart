import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _exportDebtsReport(BuildContext context, AppUser user) async {
    final subs =
        ref.read(subscribersStreamProvider(user.adminUid)).valueOrNull ?? [];
    if (subs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد مشتركين لتصدير التقرير')),
      );
      return;
    }
    final loc = Localizations.localeOf(context).languageCode;
    try {
      await PdfReportService().previewSubscribersDebtReport(
        subscribers: subs,
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
    final canAdd = user.can(Permission.addSubscriber);
    final theme = Theme.of(context);

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
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.4),
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

          // Stream-driven content: Filter Chips & Modern Subscriber Cards
          Expanded(
            child: subs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (list) {
                _syncDueDebts(user, list);

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
                                Widget buildSubscriberItem(Subscriber subscriber) {
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l = AppLocalizations.of(context);
    final loc = Localizations.localeOf(context).languageCode;

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
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasDebt
              ? const Color(0xFFE53935).withValues(alpha: 0.25)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                          backgroundColor: statusColor.withValues(alpha: 0.12),
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
                                color: isDark
                                    ? theme.colorScheme.surface
                                    : Colors.white,
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
                        if (user.can(Permission.editSubscriber))
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
                        if (user.can(Permission.editSubscriber))
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
        generatedBy:
            by.displayName.isNotEmpty ? by.displayName : (by.email ?? 'ISP Manager'),
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
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      child: DefaultTabController(
        length: 2,
        child: SizedBox(
          width: size.width * .94,
          height: size.height * .86,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        subscriber.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (by.can(Permission.editSubscriber))
                      Row(
                        children: [
                          Icon(subscriber.autoRenew
                              ? Icons.autorenew
                              : Icons.sync_disabled),
                          const SizedBox(width: 4),
                          Text(l.t('autoRenew')),
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
                    if (by.can(Permission.recordSubscriberPayment))
                      IconButton(
                        tooltip: l.t('payAdvanceSubscription'),
                        icon: const Icon(Icons.event_repeat_rounded,
                            color: Color(0xFF1976D2)),
                        onPressed: () =>
                            AdvanceSubscriptionSheet.show(context, subscriber),
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
              ),
              if (subscriber.prepaidCycles > 0)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
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
                                content: Text(
                                    l.t('confirmCancelAdvancePayment')),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: Text(l.no),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
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
              const SizedBox(height: 16),
              DropdownButtonFormField<MoneyStorage>(
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
                ],
                onChanged: (v) {
                  if (v != null) setState(() => selectedDestination = v);
                },
              ),
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
                    '${isPartial ? ' • ${l.paid}: ${CurrencyFormatter.format(debt.paidAmount, debt.currency, locale: loc)}' : ''}',
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final loc = Localizations.localeOf(context).languageCode;
    final canManage = by.isAdmin || by.can(Permission.editSubscriber);
    if (debts.isEmpty) return Center(child: Text(l.noData));
    return ListView.separated(
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
            '${l.paid}: ${debt.paidAt == null ? '-' : DateFormatter.dateTime(debt.paidAt!, locale: loc)}',
          ),
          isThreeLine: true,
          trailing: canManage
              ? PopupMenuButton<String>(
                  tooltip: 'خيارات الاشتراك',
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
                      _SubscriberDebtsTab._confirmAndDeleteDebt(
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
                )
              : null,
        );
      },
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
  late DateTime _from =
      widget.existingDebt?.periodStart ?? DateTime.now();
  late DateTime _to = widget.existingDebt?.periodEnd ??
      DateFormatter.addDays(_from, 30);
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
        paidAt: widget.existingDebt?.paidAt,
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
      );
      if (widget.existing == null) {
        if (_initialPaymentMode == 'paid') {
          await repo.addWithInitialSubscription(
            widget.by,
            subscriber,
            isPaid: true,
            receivedIn: _initialReceivedIn,
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
                      subtitle: 'تسجيل المبلغ كـ دَين على المشترك دون التأثير على الصندوق',
                      icon: Icons.receipt_outlined,
                      activeColor: Colors.orange,
                    ),
                    if (_initialPaymentMode == 'paid') ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<MoneyStorage>(
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
