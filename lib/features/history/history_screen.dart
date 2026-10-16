import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l.search,
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
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
              return ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final ev = filtered[i];
                  final canUndo = user.isAdmin && _isUndoable(ev);
                  final isBusy = _busyEventIds.contains(ev.id);
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(ev.actorName.isNotEmpty
                          ? ev.actorName[0].toUpperCase()
                          : '?'),
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
                            ? IconButton(
                                tooltip: l.t('undoEdit'),
                                icon: const Icon(Icons.undo),
                                onPressed: () => _undo(context, ref, user, ev),
                              )
                            : null,
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
    if (event.targetId == null || event.action.startsWith('history.')) {
      return false;
    }
    if (!_isSupportedUndoTarget(event)) return false;
    if (_undoDeletesCurrent(event)) return event.after != null;
    return event.before != null;
  }

  bool _undoDeletesCurrent(HistoryEvent event) {
    final action = event.action;
    return action.endsWith('.add') || action.endsWith('.create');
  }

  bool _isSupportedUndoTarget(HistoryEvent event) {
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.t('undoEdit')),
        content: Text(l.t('confirmUndoEdit')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
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
