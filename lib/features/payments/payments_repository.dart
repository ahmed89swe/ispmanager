import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase_service.dart';
import '../../core/models/models.dart';
import '../../core/services/cashbox_service.dart';
import '../history/history_repository.dart';
import '../notifications/notifications_repository.dart';

class PaymentsRepository {
  PaymentsRepository(this._db, this._logger, [this._notificationsRepo]);
  final FirebaseFirestore? _db;
  final HistoryLogger _logger;
  final NotificationsRepository? _notificationsRepo;

  Stream<List<Payment>> watchForSubscriber(
      String adminUid, String subscriberId) {
    if (_db == null) return const Stream.empty();
    return _db
        .collection('admins')
        .doc(adminUid)
        .collection('subscribers')
        .doc(subscriberId)
        .collection('payments')
        .orderBy('recordedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Payment.fromDoc).toList());
  }

  Stream<List<Payment>> watchAll(String adminUid) {
    if (_db == null) return const Stream.empty();
    return _db
        .collectionGroup('payments')
        .orderBy('recordedAt', descending: true)
        .limit(500)
        .snapshots()
        .map((s) => s.docs
            .where((d) => d.reference.path.startsWith('admins/$adminUid/'))
            .map(Payment.fromDoc)
            .toList());
  }

  Future<void> record(
      AppUser by, Subscriber subscriber, Payment payment) async {
    if (_db == null) return;
    final db = _db;
    final subRef = db
        .collection('admins')
        .doc(by.adminUid)
        .collection('subscribers')
        .doc(subscriber.id);
    final payRef = subRef.collection('payments').doc();
    final batch = db.batch();
    batch.set(payRef, payment.toMap());
    batch.update(subRef, {'balance': FieldValue.increment(-payment.amount)});
    CashboxService.registerSubscriptionPayment(
      batch: batch,
      db: db,
      actor: by,
      adminUid: by.adminUid,
      payment: payment,
      paymentId: payRef.id,
      subscriberId: subscriber.id,
      subscriberName: subscriber.name,
    );
    await batch.commit();
    await _logger.log(
      actor: by,
      action: 'payment.record',
      targetType: 'payment',
      targetId: payRef.id,
      summary:
          'Recorded payment ${payment.amount} ${payment.currency.code} for ${subscriber.name}',
      after: payment.toMap(),
    );

    if (!by.isAdmin && _notificationsRepo != null) {
      await _notificationsRepo.sendNotification(
        adminUid: by.adminUid,
        recipientUid: 'admin',
        title: 'تسديد اشتراك مشترك',
        body: 'قام الموظف ${by.displayName} بتسجيل دفعة بقيمة ${payment.amount} ${payment.currency.code} للمشترك: ${subscriber.name}',
        type: 'subscriber_payment',
        actor: by,
        targetId: subscriber.id,
        targetType: 'subscriber',
      );
    }
  }
}

final paymentsRepositoryProvider = Provider<PaymentsRepository>(
  (ref) => PaymentsRepository(
    ref.watch(firestoreProvider),
    ref.watch(historyLoggerProvider),
    ref.watch(notificationsRepositoryProvider),
  ),
);
