import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/firebase_service.dart';
import '../../core/models/models.dart';
import '../../core/services/cashbox_service.dart';
import '../../core/utils/firestore_helpers.dart';
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

  static bool isSubscriptionPaymentAction(String action) =>
      action == 'payment.record' ||
      action == 'subscriber.debt.pay' ||
      action == 'subscriber.advance_payment';

  Future<void> undoEdit(AppUser by, HistoryEvent event) async {
    final db = _db;
    if (db == null || !by.isAdmin) return;
    if (isSubscriptionPaymentAction(event.action)) {
      await _undoSubscriptionPayment(by, event);
      return;
    }
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

  Future<void> _undoSubscriptionPayment(AppUser by, HistoryEvent event) async {
    final db = _db!;
    final adminRef = db.collection('admins').doc(by.adminUid);
    final after = event.after ?? const <String, dynamic>{};
    final before = event.before ?? const <String, dynamic>{};

    final subscriberId = (after['subscriberId'] ??
        before['subscriberId'] ??
        (before['debt'] is Map
            ? (before['debt'] as Map)['subscriberId']
            : null) ??
        (event.targetType == 'subscriber' ? event.targetId : null)) as String?;

    if (subscriberId == null || subscriberId.isEmpty) {
      throw StateError('This subscription payment cannot be undone.');
    }

    final subRef = adminRef.collection('subscribers').doc(subscriberId);
    final subSnap = await subRef.get().timeout(HistoryLogger.operationTimeout);
    if (!subSnap.exists) {
      throw StateError('Subscriber no longer exists.');
    }
    final subData = subSnap.data() ?? const <String, dynamic>{};
    final subscriberName = (after['subscriberName'] ??
        before['subscriberName'] ??
        subData['name'] ??
        '') as String;

    final amount = ((after['amount'] ??
            (before['debt'] is Map
                ? (before['debt'] as Map)['amount']
                : null) ??
            0) as num)
        .toDouble();
    if (amount <= 0) {
      throw StateError('Invalid payment amount.');
    }

    final currencyCode = (after['currency'] ??
        (before['debt'] is Map ? (before['debt'] as Map)['currency'] : null) ??
        subData['currency'] ??
        'IQD') as String?;
    final currency = AppCurrency.fromCode(currencyCode ?? 'IQD');

    var receivedIn =
        enumFromName(MoneyStorage.values, after['receivedIn'] as String?) ??
            MoneyStorage.cashbox;
    var collectorUid = (after['recordedBy'] as String?)?.isNotEmpty == true
        ? (after['recordedBy'] as String)
        : event.actorUid;

    String? paymentId = (after['paymentId'] ??
        (event.targetType == 'payment' ? event.targetId : null)) as String?;

    DocumentReference<Map<String, dynamic>>? matchedPayRef;
    if (paymentId != null && paymentId.isNotEmpty) {
      matchedPayRef = subRef.collection('payments').doc(paymentId);
      final paySnap =
          await matchedPayRef.get().timeout(HistoryLogger.operationTimeout);
      if (paySnap.exists) {
        final p = Payment.fromDoc(paySnap);
        receivedIn = p.receivedIn;
        if (p.recordedBy.isNotEmpty) collectorUid = p.recordedBy;
      }
    } else {
      final paymentsSnap = await subRef
          .collection('payments')
          .orderBy('recordedAt', descending: true)
          .limit(25)
          .get()
          .timeout(HistoryLogger.operationTimeout);
      for (final pDoc in paymentsSnap.docs) {
        final p = Payment.fromDoc(pDoc);
        final diffSec = p.recordedAt.difference(event.ts).inSeconds.abs();
        if (p.amount == amount && p.currency == currency && diffSec <= 120) {
          matchedPayRef = pDoc.reference;
          paymentId = pDoc.id;
          receivedIn = p.receivedIn;
          if (p.recordedBy.isNotEmpty) collectorUid = p.recordedBy;
          break;
        }
      }
    }

    final batch = db.batch();
    if (matchedPayRef != null) {
      batch.delete(matchedPayRef);
    }

    if (event.action == 'subscriber.advance_payment') {
      final cycles = ((after['cycles'] as num?)?.toInt()) ?? 1;
      final currentPrepaid = ((subData['prepaidCycles'] as num?)?.toInt()) ?? 0;
      final nextPrepaid = (currentPrepaid - cycles).clamp(0, 999);
      batch.update(subRef, {'prepaidCycles': nextPrepaid});
    } else if (event.action == 'subscriber.debt.pay') {
      final debtId = (after['debtId'] ?? event.targetId) as String?;
      if (debtId != null && debtId.isNotEmpty) {
        final debtRef = subRef.collection('debts').doc(debtId);
        final debtBefore = before['debt'] is Map
            ? Map<String, dynamic>.from(before['debt'] as Map)
            : null;
        batch.update(debtRef, {
          'status': debtBefore?['status'] ?? SubscriptionDebtStatus.unpaid.name,
          'paidAmount': debtBefore?['paidAmount'] ?? 0,
          'paidAt': debtBefore?['paidAt'],
          'paidBy': debtBefore?['paidBy'],
        });
      }
      final currentBalance = (subData['balance'] ?? 0) as num;
      final nextBalance = currentBalance + amount;
      batch.update(subRef, {
        'balance': nextBalance,
        'status': nextBalance > 0
            ? SubscriberStatus.overdue.name
            : SubscriberStatus.active.name,
      });
    } else if (event.action == 'payment.record') {
      if (before['debts'] is List && (before['debts'] as List).isNotEmpty) {
        for (final item in (before['debts'] as List)) {
          if (item is! Map) continue;
          final m = Map<String, dynamic>.from(item);
          final dId = m['id'] as String?;
          if (dId == null || dId.isEmpty) continue;
          batch.update(subRef.collection('debts').doc(dId), {
            'paidAmount': m['paidAmount'] ?? 0,
            'status': m['status'] ?? SubscriptionDebtStatus.unpaid.name,
            'paidAt': m['paidAt'],
            'paidBy': m['paidBy'],
          });
        }
      } else {
        // Fallback for older payment.record events: reverse paid amounts from newest to oldest
        final debtsSnap = await subRef
            .collection('debts')
            .orderBy('periodStart', descending: true)
            .get()
            .timeout(HistoryLogger.operationTimeout);
        num remainingToReverse = amount;
        for (final doc in debtsSnap.docs) {
          if (remainingToReverse <= 0) break;
          final d = doc.data();
          final paidAmt = (d['paidAmount'] ?? 0) as num;
          if (paidAmt <= 0) continue;
          final deduct =
              remainingToReverse >= paidAmt ? paidAmt : remainingToReverse;
          final newPaid = paidAmt - deduct;
          remainingToReverse -= deduct;
          batch.update(doc.reference, {
            'paidAmount': newPaid,
            'status': newPaid <= 0
                ? SubscriptionDebtStatus.unpaid.name
                : SubscriptionDebtStatus.partiallyPaid.name,
            if (newPaid <= 0) 'paidAt': null,
            if (newPaid <= 0) 'paidBy': null,
          });
        }
      }
      final currentBalance = (subData['balance'] ?? 0) as num;
      final nextBalance = currentBalance + amount;
      batch.update(subRef, {
        'balance': nextBalance,
        'status': nextBalance > 0
            ? SubscriberStatus.overdue.name
            : SubscriberStatus.active.name,
      });
    }

    CashboxService.reverseSubscriptionPayment(
      batch: batch,
      db: db,
      actor: by,
      adminUid: by.adminUid,
      amount: amount,
      currency: currency,
      receivedIn: receivedIn,
      collectorUid: collectorUid,
      subscriberId: subscriberId,
      subscriberName: subscriberName,
      paymentId: paymentId,
      note: 'التراجع عن تسديد اشتراك من السجل: ${event.summary}',
    );

    if (event.id.isNotEmpty) {
      batch.delete(adminRef.collection('history').doc(event.id));
    }

    final historyRef = _logger.newEventRef(by);
    batch.set(
      historyRef,
      _logger.eventData(
        actor: by,
        action: 'history.undo',
        targetType: event.targetType,
        targetId: event.targetId,
        summary: 'التراجع عن تسديد اشتراك: ${event.summary}',
        before: event.after,
      ),
    );

    await batch.commit().timeout(HistoryLogger.operationTimeout);
  }

  bool _isUndoable(HistoryEvent event) {
    if (event.action.startsWith('history.')) return false;
    if (isSubscriptionPaymentAction(event.action)) {
      return event.after != null || event.before != null;
    }
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
