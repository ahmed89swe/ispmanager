import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase_service.dart';
import '../../core/models/models.dart';
import '../auth/auth_repository.dart';

/// Writes a single history event under /admins/{adminUid}/history.
class HistoryLogger {
  HistoryLogger(this._db);
  final FirebaseFirestore? _db;

  static const operationTimeout = Duration(seconds: 20);

  DocumentReference<Map<String, dynamic>> newEventRef(AppUser actor) =>
      _db!.collection('admins').doc(actor.adminUid).collection('history').doc();

  Map<String, dynamic> eventData({
    required AppUser actor,
    required String action,
    required String targetType,
    String? targetId,
    required String summary,
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
  }) =>
      {
        'actor': {
          'uid': actor.uid,
          'displayName': actor.displayName,
          'role': actor.role.name,
          'photoUrl': actor.photoUrl,
        },
        'action': action,
        'targetType': targetType,
        'targetId': targetId,
        'summary': summary,
        'before': before,
        'after': after,
        'ts': FieldValue.serverTimestamp(),
      };

  Future<void> log({
    required AppUser actor,
    required String action,
    required String targetType,
    String? targetId,
    required String summary,
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
  }) async {
    if (_db == null) return;
    await newEventRef(actor)
        .set(eventData(
          actor: actor,
          action: action,
          targetType: targetType,
          targetId: targetId,
          summary: summary,
          before: before,
          after: after,
        ))
        .timeout(operationTimeout);
  }
}

class HistoryRepository {
  HistoryRepository(this._db, this._logger);
  final FirebaseFirestore? _db;
  final HistoryLogger _logger;

  Future<void> undoEdit(AppUser by, HistoryEvent event) async {
    final db = _db;
    if (db == null || !by.isAdmin) return;
    final targetRef = _targetRef(by.adminUid, event);
    if (targetRef == null || !_isUndoable(event)) {
      throw StateError('This history event cannot be undone.');
    }
    final current =
        await targetRef.get().timeout(HistoryLogger.operationTimeout);
    final batch = db.batch();
    final historyRef = _logger.newEventRef(by);

    if (_undoDeletesCurrent(event)) {
      batch.delete(targetRef);
      batch.set(
        historyRef,
        _logger.eventData(
          actor: by,
          action: 'history.undo',
          targetType: event.targetType,
          targetId: event.targetId,
          summary: 'Undid ${event.action}: ${event.summary}',
          before: current.data(),
        ),
      );
      await batch.commit().timeout(HistoryLogger.operationTimeout);
      return;
    }

    final before = event.before;
    if (before == null) {
      throw StateError('This history event cannot be undone.');
    }
    final restored = _restoredData(event, before);
    batch.set(targetRef, restored);
    batch.set(
      historyRef,
      _logger.eventData(
        actor: by,
        action: 'history.undo',
        targetType: event.targetType,
        targetId: event.targetId,
        summary: 'Undid ${event.action}: ${event.summary}',
        before: current.data(),
        after: restored,
      ),
    );
    await batch.commit().timeout(HistoryLogger.operationTimeout);
  }

  bool _isUndoable(HistoryEvent event) {
    if (event.action.startsWith('history.')) return false;
    if (_undoDeletesCurrent(event)) return event.after != null;
    return event.before != null;
  }

  bool _undoDeletesCurrent(HistoryEvent event) {
    final action = event.action;
    return action.endsWith('.add') || action.endsWith('.create');
  }

  Map<String, dynamic> _restoredData(
      HistoryEvent event, Map<String, dynamic> before) {
    final restored = Map<String, dynamic>.from(before);
    if (event.targetType == 'package') restored.remove('supplierId');
    return restored;
  }

  DocumentReference<Map<String, dynamic>>? _targetRef(
      String adminUid, HistoryEvent event) {
    final targetId = event.targetId;
    if (targetId == null || targetId.isEmpty) return null;
    final adminRef = _db!.collection('admins').doc(adminUid);
    switch (event.targetType) {
      case 'subscriber':
        return adminRef.collection('subscribers').doc(targetId);
      case 'supplier':
        return adminRef.collection('suppliers').doc(targetId);
      case 'expense':
        return adminRef.collection('expenses').doc(targetId);
      case 'expenseDeleteRequest':
        if (event.action != 'expense.delete.approve') return null;
        final expenseId = _expenseIdFromDeleteRequestEvent(event);
        if (expenseId == null || expenseId.isEmpty) return null;
        return adminRef.collection('expenses').doc(expenseId);
      case 'package':
        final data = event.before ?? event.after;
        final supplierId = data?['supplierId'] as String?;
        if (supplierId == null || supplierId.isEmpty) return null;
        return adminRef
            .collection('suppliers')
            .doc(supplierId)
            .collection('packages')
            .doc(targetId);
      case 'employee':
        return adminRef.collection('employees').doc(targetId);
    }
    return null;
  }

  String? _expenseIdFromDeleteRequestEvent(HistoryEvent event) {
    final after = event.after;
    final before = event.before;
    return (after?['expenseId'] ?? before?['expenseId']) as String?;
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => HistoryRepository(
    ref.watch(firestoreProvider),
    ref.watch(historyLoggerProvider),
  ),
);

final historyLoggerProvider = Provider<HistoryLogger>(
    (ref) => HistoryLogger(ref.watch(firestoreProvider)));

final historyStreamProvider = StreamProvider.autoDispose
    .family<List<HistoryEvent>, String>((ref, adminUid) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return const Stream.empty();
  final db = ref.watch(firestoreProvider);
  if (db == null) return const Stream.empty();
  return db
      .collection('admins')
      .doc(adminUid)
      .collection('history')
      .orderBy('ts', descending: true)
      .limit(200)
      .snapshots()
      .map((s) => s.docs.map(HistoryEvent.fromDoc).toList());
});
