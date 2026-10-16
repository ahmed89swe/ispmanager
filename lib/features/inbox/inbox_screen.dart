import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/models/models.dart';
import '../../core/utils/formatters.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_repository.dart';
import '../employees/employees_repository.dart';
import '../expenses/expenses_repository.dart';
import '../finance/cashbox_repository.dart';
import '../suppliers/suppliers_repository.dart';
import 'chat_conversation_screen.dart';
import 'chat_repository.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _requestsFilter = 'all'; // all, pending, approved, rejected

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentAppUserProvider).valueOrNull;
    if (user == null) {
      return Center(child: Text(l.pleaseSignIn));
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                text: l.t('chats'),
              ),
              Tab(
                icon: const Icon(Icons.pending_actions_rounded, size: 20),
                text: l.t('requests'),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatsTab(context, l, user),
          _buildRequestsTab(context, l, user),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: CHATS (المحادثات)
  // ==========================================
  Widget _buildChatsTab(BuildContext context, AppLocalizations l, AppUser user) {
    final theme = Theme.of(context);
    final loc = Localizations.localeOf(context).languageCode;

    if (user.isAdmin) {
      // Admin sees list of all employees
      final employeesAsync = ref.watch(employeesStreamProvider(user.adminUid));
      final threadsAsync = ref.watch(chatThreadsStreamProvider);

      return employeesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (employees) {
          if (employees.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline,
                      size: 54, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  const Text('لا يوجد موظفون مضافون حالياً'),
                ],
              ),
            );
          }

          final threads = threadsAsync.valueOrNull ?? [];
          final threadMap = <String, Map<String, dynamic>>{
            for (final t in threads) '${t['id']}': t,
          };

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: employees.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, idx) {
              final emp = employees[idx];
              final thread = threadMap[emp.uid];
              final lastMsg = thread?['lastMessage'] as String?;
              final lastTime = thread?['lastMessageTime'] != null
                  ? (thread!['lastMessageTime'] as dynamic).toDate() as DateTime
                  : null;

              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatConversationScreen(
                        employeeUid: emp.uid,
                        employeeName: emp.displayName,
                        employeeRole: emp.username.isNotEmpty
                            ? emp.username
                            : l.employee,
                      ),
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  child: Text(
                    emp.displayName.isNotEmpty
                        ? emp.displayName.substring(0, 1).toUpperCase()
                        : 'E',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  emp.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  lastMsg ?? (emp.username.isNotEmpty ? emp.username : 'بدء المحادثة…'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: lastMsg != null
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.outline,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (lastTime != null)
                      Text(
                        DateFormatter.time(lastTime, locale: loc),
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                  ],
                ),
              );
            },
          );
        },
      );
    } else {
      // Employee sees single Management/Manager Chat tile
      final threadAsync = ref.watch(chatThreadStreamProvider(user.uid));

      return threadAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (thread) {
          final lastMsg = thread?['lastMessage'] as String?;
          final lastTime = thread?['lastMessageTime'] != null
              ? (thread!['lastMessageTime'] as dynamic).toDate() as DateTime
              : null;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatConversationScreen(
                            employeeUid: user.uid,
                            employeeName: user.displayName,
                            employeeRole: user.role.name,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.indigo.withAlpha(40),
                            foregroundColor: Colors.indigo,
                            child: const Icon(Icons.admin_panel_settings_rounded,
                                size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      l.t('chatWithManager'),
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (lastTime != null)
                                      Text(
                                        DateFormatter.time(lastTime,
                                            locale: loc),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme.colorScheme.outline,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lastMsg ?? l.t('managerDirectChat'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: lastMsg != null
                                        ? theme.colorScheme.onSurfaceVariant
                                        : theme.colorScheme.outline,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios,
                              size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(90),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_clock_outlined,
                          size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'المحادثة مشفرة ومباشرة مع إدارة المنظومة للاستفسارات وطلبات المتابعة.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  // ==========================================
  // TAB 2: REQUESTS (الطلبات)
  // ==========================================
  Widget _buildRequestsTab(
      BuildContext context, AppLocalizations l, AppUser user) {
    final theme = Theme.of(context);
    final loc = Localizations.localeOf(context).languageCode;

    final reimbursementAsync =
        ref.watch(reimbursementRequestsStreamProvider(user.adminUid));
    final suppliersRepo = ref.watch(suppliersRepositoryProvider);
    final expensesRepo = ref.watch(expensesRepositoryProvider);
    final cashboxRepo = ref.watch(cashboxRepositoryProvider);

    return StreamBuilder<List<SupplierPaymentRequest>>(
      stream: suppliersRepo.watchRequests(user.adminUid),
      builder: (_, supplierSnap) {
        return StreamBuilder<List<ExpenseDeleteRequest>>(
          stream: expensesRepo.watchDeleteRequests(user.adminUid),
          builder: (_, expenseSnap) {
            final reimbursements = reimbursementAsync.valueOrNull ?? [];
            final supplierReqs = supplierSnap.data ?? [];
            final expenseDeleteReqs = expenseSnap.data ?? [];

            final allItems = <_UnifiedRequestItem>[
              for (final r in reimbursements)
                if (user.isAdmin || r.byEmployeeUid == user.uid)
                  _UnifiedRequestItem.reimbursement(r),
              for (final r in supplierReqs)
                if (user.isAdmin || r.byEmployeeUid == user.uid)
                  _UnifiedRequestItem.supplier(r),
              for (final r in expenseDeleteReqs)
                if (user.isAdmin || r.byEmployeeUid == user.uid)
                  _UnifiedRequestItem.expenseDelete(r),
            ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            // Apply filter
            final filtered = allItems.where((item) {
              if (_requestsFilter == 'pending') {
                return item.status == PaymentRequestStatus.pending;
              } else if (_requestsFilter == 'approved') {
                return item.status == PaymentRequestStatus.approved;
              } else if (_requestsFilter == 'rejected') {
                return item.status == PaymentRequestStatus.rejected;
              }
              return true;
            }).toList();

            return Column(
              children: [
                // Filter chips bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      FilterChip(
                        selected: _requestsFilter == 'all',
                        label: Text('${l.all} (${allItems.length})'),
                        onSelected: (_) =>
                            setState(() => _requestsFilter = 'all'),
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        selected: _requestsFilter == 'pending',
                        avatar: const Icon(Icons.schedule, size: 14),
                        label: Text(
                            '${l.pending} (${allItems.where((i) => i.status == PaymentRequestStatus.pending).length})'),
                        onSelected: (_) =>
                            setState(() => _requestsFilter = 'pending'),
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        selected: _requestsFilter == 'approved',
                        avatar: const Icon(Icons.check_circle,
                            size: 14, color: Colors.green),
                        label: Text(
                            '${l.approved} (${allItems.where((i) => i.status == PaymentRequestStatus.approved).length})'),
                        onSelected: (_) =>
                            setState(() => _requestsFilter = 'approved'),
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        selected: _requestsFilter == 'rejected',
                        avatar: const Icon(Icons.cancel,
                            size: 14, color: Colors.red),
                        label: Text(
                            '${l.rejected} (${allItems.where((i) => i.status == PaymentRequestStatus.rejected).length})'),
                        onSelected: (_) =>
                            setState(() => _requestsFilter = 'rejected'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inbox_outlined,
                                  size: 48,
                                  color: theme.colorScheme.outline
                                      .withAlpha(120)),
                              const SizedBox(height: 8),
                              Text(l.noData,
                                  style: TextStyle(
                                      color: theme.colorScheme.outline)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, idx) {
                            final item = filtered[idx];
                            return _buildRequestCard(
                              ctx,
                              theme,
                              l,
                              loc,
                              user,
                              item,
                              cashboxRepo,
                              suppliersRepo,
                              expensesRepo,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l,
    String loc,
    AppUser user,
    _UnifiedRequestItem item,
    CashboxRepository cashboxRepo,
    SuppliersRepository suppliersRepo,
    ExpensesRepository expensesRepo,
  ) {
    Color badgeColor;
    String badgeText;
    switch (item.status) {
      case PaymentRequestStatus.pending:
        badgeColor = Colors.orange;
        badgeText = l.pending;
        break;
      case PaymentRequestStatus.approved:
        badgeColor = Colors.green;
        badgeText = l.approved;
        break;
      case PaymentRequestStatus.rejected:
        badgeColor = Colors.red;
        badgeText = l.rejected;
        break;
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: item.status == PaymentRequestStatus.pending
              ? Colors.orange.withAlpha(70)
              : theme.colorScheme.outlineVariant.withAlpha(60),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: item.typeColor.withAlpha(25),
                  foregroundColor: item.typeColor,
                  child: Icon(item.typeIcon, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.typeTitle(l),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'بواسطة: ${item.byEmployeeName}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.detailsSubtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(item.amount, item.currency,
                        locale: loc),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (item.note != null && item.note!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'ملاحظة: ${item.note}',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormatter.dateTime(item.createdAt, locale: loc),
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.outline,
                  ),
                ),
                if (user.isAdmin &&
                    item.status == PaymentRequestStatus.pending)
                  Row(
                    children: [
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.withAlpha(30),
                          foregroundColor: Colors.green.shade800,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _handleApprove(
                          context,
                          user,
                          item,
                          cashboxRepo,
                          suppliersRepo,
                          expensesRepo,
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check, size: 14),
                            SizedBox(width: 4),
                            Text('قبول', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.withAlpha(30),
                          foregroundColor: Colors.red.shade800,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _handleReject(
                          context,
                          user,
                          item,
                          cashboxRepo,
                          suppliersRepo,
                          expensesRepo,
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.close, size: 14),
                            SizedBox(width: 4),
                            Text('رفض', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApprove(
    BuildContext context,
    AppUser user,
    _UnifiedRequestItem item,
    CashboxRepository cashboxRepo,
    SuppliersRepository suppliersRepo,
    ExpensesRepository expensesRepo,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (item.reimbursement != null) {
        await cashboxRepo.decideReimbursementRequest(
          user,
          item.reimbursement!,
          PaymentRequestStatus.approved,
        );
      } else if (item.supplier != null) {
        await suppliersRepo.decideRequest(
          user,
          item.supplier!,
          PaymentRequestStatus.approved,
        );
      } else if (item.expenseDelete != null) {
        await expensesRepo.decideDeleteRequest(
          user,
          item.expenseDelete!,
          PaymentRequestStatus.approved,
        );
      }
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('تمت الموافقة على الطلب بنجاح'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  Future<void> _handleReject(
    BuildContext context,
    AppUser user,
    _UnifiedRequestItem item,
    CashboxRepository cashboxRepo,
    SuppliersRepository suppliersRepo,
    ExpensesRepository expensesRepo,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (item.reimbursement != null) {
        await cashboxRepo.decideReimbursementRequest(
          user,
          item.reimbursement!,
          PaymentRequestStatus.rejected,
        );
      } else if (item.supplier != null) {
        await suppliersRepo.decideRequest(
          user,
          item.supplier!,
          PaymentRequestStatus.rejected,
        );
      } else if (item.expenseDelete != null) {
        await expensesRepo.decideDeleteRequest(
          user,
          item.expenseDelete!,
          PaymentRequestStatus.rejected,
        );
      }
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('تم رفض الطلب'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }
}

class _UnifiedRequestItem {
  _UnifiedRequestItem.reimbursement(this.reimbursement)
      : supplier = null,
        expenseDelete = null,
        id = reimbursement!.id,
        amount = reimbursement.amount,
        currency = reimbursement.currency,
        byEmployeeUid = reimbursement.byEmployeeUid,
        byEmployeeName = reimbursement.byEmployeeName,
        note = reimbursement.note,
        status = reimbursement.status,
        createdAt = reimbursement.createdAt;

  _UnifiedRequestItem.supplier(this.supplier)
      : reimbursement = null,
        expenseDelete = null,
        id = supplier!.id,
        amount = supplier.amount,
        currency = supplier.currency,
        byEmployeeUid = supplier.byEmployeeUid,
        byEmployeeName = supplier.byEmployeeName,
        note = supplier.note,
        status = supplier.status,
        createdAt = supplier.createdAt;

  _UnifiedRequestItem.expenseDelete(this.expenseDelete)
      : reimbursement = null,
        supplier = null,
        id = expenseDelete!.id,
        amount = expenseDelete.amount,
        currency = expenseDelete.currency,
        byEmployeeUid = expenseDelete.byEmployeeUid,
        byEmployeeName = expenseDelete.byEmployeeName,
        note = expenseDelete.expenseReason,
        status = expenseDelete.status,
        createdAt = expenseDelete.createdAt;

  final StaffReimbursementRequest? reimbursement;
  final SupplierPaymentRequest? supplier;
  final ExpenseDeleteRequest? expenseDelete;

  final String id;
  final num amount;
  final AppCurrency currency;
  final String byEmployeeUid;
  final String byEmployeeName;
  final String? note;
  final PaymentRequestStatus status;
  final DateTime createdAt;

  String typeTitle(AppLocalizations l) {
    if (reimbursement != null) return l.t('reimbursementRequest');
    if (supplier != null) return l.supplierPaymentRequest;
    return l.t('expenseDeleteRequest');
  }

  IconData get typeIcon {
    if (reimbursement != null) return Icons.output_rounded;
    if (supplier != null) return Icons.local_shipping_outlined;
    return Icons.delete_outline;
  }

  Color get typeColor {
    if (reimbursement != null) return Colors.blue;
    if (supplier != null) return Colors.teal;
    return Colors.red;
  }

  String get detailsSubtitle {
    if (reimbursement != null) return 'صرف مستحقات من الصندوق';
    if (supplier != null) return 'تسديد دفعة للمجهز';
    return 'حذف مصروف مسجل';
  }
}
