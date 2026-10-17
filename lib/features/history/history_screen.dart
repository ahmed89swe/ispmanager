import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/utils/formatters.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_repository.dart';
import 'history_repository.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _query = '';
  final Set<String> _busyEventIds = {};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentAppUserProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();
    final stream = ref.watch(historyStreamProvider(user.adminUid));
    final loc = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.cardBorderColor(context)),
            ),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon:
                    Icon(Icons.search, color: theme.colorScheme.primary),
                hintText: l.search,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
        ),
        Expanded(
          child: stream.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (events) {
              final filtered = events
                  .where((e) =>
                      _query.isEmpty ||
                      e.summary.toLowerCase().contains(_query) ||
                      e.actorName.toLowerCase().contains(_query) ||
                      e.action.toLowerCase().contains(_query))
                  .toList();
              if (filtered.isEmpty) return Center(child: Text(l.noData));
              return ListView.builder(
                padding: const EdgeInsets.only(top: 4, bottom: 24),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final ev = filtered[i];
                  final canUndo = user.isAdmin && _isUndoable(ev);
                  final isBusy = _busyEventIds.contains(ev.id);
                  return Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: AppTheme.cardDecoration(context),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.16),
                        foregroundColor: theme.colorScheme.primary,
                        child: Text(
                          ev.actorName.isNotEmpty
                              ? ev.actorName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(ev.summary),
                      subtitle: Text(
                          '${ev.actorName} • ${ev.action} • ${DateFormatter.dateTime(ev.ts, locale: loc)}'),
                      isThreeLine: true,
                      trailing: isBusy
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : canUndo
                              ? HistoryRepository.isSubscriptionPaymentAction(
                                      ev.action)
                                  ? TextButton.icon(
                                      onPressed: () =>
                                          _undo(context, ref, user, ev),
                                      icon: const Icon(Icons.undo_rounded,
                                          size: 18, color: Colors.orange),
                                      label: Text(
                                        l.locale.languageCode == 'ar'
                                            ? 'تراجع عن التسديد'
                                            : 'Undo Payment',
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  : IconButton(
                                      tooltip: l.t('undoEdit'),
                                      icon: const Icon(Icons.undo),
                                      onPressed: () =>
                                          _undo(context, ref, user, ev),
                                    )
                              : null,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  bool _isUndoable(HistoryEvent event) {
    if (event.action.startsWith('history.')) {
      return false;
    }
    if (HistoryRepository.isSubscriptionPaymentAction(event.action)) {
      return event.after != null || event.before != null;
    }
    if (event.targetId == null) return false;
    if (!_isSupportedUndoTarget(event)) return false;
    if (_undoDeletesCurrent(event)) return event.after != null;
    return event.before != null;
  }

  bool _undoDeletesCurrent(HistoryEvent event) {
    final action = event.action;
    return action.endsWith('.add') || action.endsWith('.create');
  }

  bool _isSupportedUndoTarget(HistoryEvent event) {
    if (HistoryRepository.isSubscriptionPaymentAction(event.action)) {
      return true;
    }
    switch (event.targetType) {
      case 'subscriber':
      case 'supplier':
      case 'expense':
      case 'employee':
        return true;
      case 'expenseDeleteRequest':
        return event.action == 'expense.delete.approve' &&
            _expenseIdFromDeleteRequestEvent(event) != null;
      case 'package':
        final data = event.before ?? event.after;
        final supplierId = data?['supplierId'] as String?;
        return supplierId != null && supplierId.isNotEmpty;
    }
    return false;
  }

  String? _expenseIdFromDeleteRequestEvent(HistoryEvent event) {
    final after = event.after;
    final before = event.before;
    return (after?['expenseId'] ?? before?['expenseId']) as String?;
  }

  Future<void> _undo(BuildContext context, WidgetRef ref, AppUser user,
      HistoryEvent event) async {
    final l = AppLocalizations.of(context);
    final isPaymentUndo =
        HistoryRepository.isSubscriptionPaymentAction(event.action);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isPaymentUndo
              ? (l.locale.languageCode == 'ar'
                  ? 'التراجع عن تسديد الاشتراك'
                  : 'Undo Subscription Payment')
              : l.t('undoEdit'),
        ),
        content: Text(
          isPaymentUndo
              ? (l.locale.languageCode == 'ar'
                  ? 'هل أنت متأكد من التراجع عن عملية التسديد هذه؟\nسيتم إرجاع الاشتراك كغير مسدد، وإعادة المبلغ إلى ذمة المشترك، وخصمه من الصندوق.'
                  : 'Are you sure you want to undo this subscription payment?\nThe subscription will revert to unpaid, the amount will return to the subscriber balance, and it will be deducted from the cashbox.')
              : l.t('confirmUndoEdit'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: isPaymentUndo
                ? FilledButton.styleFrom(backgroundColor: Colors.orange)
                : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.t('undo')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busyEventIds.add(event.id));
    try {
      await ref.read(historyRepositoryProvider).undoEdit(user, event);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.t('undone'))),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(l, error))),
      );
    } finally {
      if (mounted) setState(() => _busyEventIds.remove(event.id));
    }
  }

  String _errorMessage(AppLocalizations l, Object error) {
    if (error is TimeoutException) return l.t('operationTimedOut');
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') return l.t('permissionDenied');
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) {
        return '${l.errorOccurred}: ${error.code} - $message';
      }
      return '${l.errorOccurred}: ${error.code}';
    }
    return l.t('cannotUndo');
  }
}
