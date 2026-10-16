import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/utils/formatters.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_repository.dart';
import 'notifications_repository.dart';

class NotificationsSheet extends ConsumerWidget {
  const NotificationsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const NotificationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final loc = Localizations.localeOf(context).languageCode;
    final user = ref.watch(currentAppUserProvider).valueOrNull;

    if (user == null) {
      return const SizedBox(height: 100);
    }

    final notifsAsync = ref.watch(notificationsStreamProvider);
    final unreadCount =
        ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;
    final notifsRepo = ref.watch(notificationsRepositoryProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded,
                      size: 22, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    l.t('notifications'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (unreadCount > 0)
                    TextButton.icon(
                      onPressed: () {
                        notifsRepo.markAllAsRead(
                          user.adminUid,
                          user.uid,
                          isAdmin: user.isAdmin,
                        );
                      },
                      icon: const Icon(Icons.done_all, size: 16),
                      label: Text(
                        l.t('markAllRead'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Notifications List
            Expanded(
              child: notifsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 56,
                            color: theme.colorScheme.outline.withAlpha(120),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l.t('noNotifications'),
                            style: TextStyle(
                              color: theme.colorScheme.outline,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (c, idx) {
                      final n = notifications[idx];
                      return _buildNotificationTile(
                        c,
                        theme,
                        n,
                        loc,
                        onTap: () {
                          if (!n.isRead) {
                            notifsRepo.markAsRead(user.adminUid, n.id);
                          }
                        },
                        onDelete: () {
                          notifsRepo.delete(user.adminUid, n.id);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    ThemeData theme,
    AppNotification n,
    String loc, {
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    final iconData = _iconForType(n.type);
    final color = _colorForType(n.type);

    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        color: n.isRead
            ? Colors.transparent
            : theme.colorScheme.primary.withAlpha(14),
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: color.withAlpha(25),
            foregroundColor: color,
            child: Icon(iconData, size: 20),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  n.title,
                  style: TextStyle(
                    fontWeight:
                        n.isRead ? FontWeight.w600 : FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!n.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 3),
              Text(
                n.body,
                style: TextStyle(
                  fontSize: 12,
                  color: n.isRead
                      ? theme.colorScheme.outline
                      : theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                DateFormatter.dateTime(n.createdAt, locale: loc),
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.outline.withAlpha(160),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'chat_message':
        return Icons.chat_bubble_outline_rounded;
      case 'reimbursement_request':
        return Icons.output_rounded;
      case 'reimbursement_approved':
        return Icons.check_circle_outline_rounded;
      case 'reimbursement_rejected':
        return Icons.cancel_outlined;
      case 'supplier_payment':
      case 'supplier_request':
        return Icons.local_shipping_outlined;
      case 'expense_delete':
        return Icons.delete_outline_rounded;
      case 'staff_settlement':
        return Icons.input_rounded;
      case 'payment_recorded':
        return Icons.payments_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'chat_message':
        return Colors.indigo;
      case 'reimbursement_request':
        return Colors.amber.shade800;
      case 'reimbursement_approved':
        return Colors.green;
      case 'reimbursement_rejected':
        return Colors.red;
      case 'supplier_payment':
      case 'supplier_request':
        return Colors.teal;
      case 'expense_delete':
        return Colors.orange;
      case 'staff_settlement':
        return Colors.blue;
      case 'payment_recorded':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

