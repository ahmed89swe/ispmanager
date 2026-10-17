import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/firebase_service.dart';
import '../../core/models/models.dart';
import '../../core/services/cashbox_service.dart';
import '../../core/utils/formatters.dart';
import '../auth/auth_repository.dart';
import '../history/history_repository.dart';
import '../notifications/notifications_repository.dart';

class SubscribersRepository {
  SubscribersRepository(this._db, this._logger, [this._notificationsRepo]);
  final FirebaseFirestore? _db;
  final HistoryLogger _logger;
  final NotificationsRepository? _notificationsRepo;

  CollectionReference<Map<String, dynamic>> _col(String adminUid) =>
      _db!.collection('admins').doc(adminUid).collection('subscribers');

  CollectionReference<Map<String, dynamic>> _debtCol(
          String adminUid, String subscriberId) =>
      _col(adminUid).doc(subscriberId).collection('debts');

  Stream<List<Subscriber>> watchAll(String adminUid) {
    if (_db == null) return const Stream.empty();
    return _col(adminUid).orderBy('name').snapshots().map(
          (s) => s.docs.map(Subscriber.fromDoc).toList(),
        );
  }

  Future<void> add(AppUser by, Subscriber s) async {
    if (_db == null) return;
    final ref = await _col(by.adminUid).add(s.toMap());
    await _logger.log(
      actor: by,
      action: 'subscriber.add',
      targetType: 'subscriber',
      targetId: ref.id,
      summary: 'Added subscriber: ${s.name}',
      after: s.toMap(),
    );

    if (!by.isAdmin && _notificationsRepo != null) {
      await _notificationsRepo.sendNotification(
        adminUid: by.adminUid,
        recipientUid: 'admin',
        title: 'إضافة مشترك جديد',
        body: 'قام الموظف ${by.displayName} بإضافة المشترك: ${s.name}',
        type: 'subscriber_created',
        actor: by,
        targetId: ref.id,
        targetType: 'subscriber',
      );
    }
  }

  Future<void> addWithInitialSubscription(
    AppUser by,
    Subscriber s, {
    required bool isPaid,
    MoneyStorage receivedIn = MoneyStorage.cashbox,
  }) async {
    if (_db == null) return;
    final db = _db;
    final subRef = _col(by.adminUid).doc();
    final subId = subRef.id;

    final now = DateTime.now();
    final periodStart = s.joinedAt;
    final periodEnd = s.subscriptionEndsAt;
    final debtRef =
        _debtCol(by.adminUid, subId).doc(_periodDebtId(periodStart));

    final debt = SubscriberDebt(
      id: debtRef.id,
      subscriberId: subId,
      supplierId: s.supplierId,
      packageId: s.packageId,
      packageName: s.packageName ?? s.planName,
      amount: s.monthlyFee,
      paidAmount: isPaid ? s.monthlyFee : 0,
      agentCost: s.packageAgentPrice,
      currency: s.currency,
      periodStart: periodStart,
      periodEnd: periodEnd,
      status:
          isPaid ? SubscriptionDebtStatus.paid : SubscriptionDebtStatus.unpaid,
      note: isPaid ? 'الاشتراك الأول (مسدد)' : 'الاشتراك الأول (دين)',
      recordedBy: by.uid,
      createdAt: now,
      paidAt: isPaid ? now : null,
      paidBy: isPaid ? by.uid : null,
    );

    final finalSubscriber = s.copyWith(
      id: subId,
      balance: isPaid ? 0 : s.monthlyFee,
      status: isPaid ? SubscriberStatus.active : SubscriberStatus.overdue,
    );

    final batch = db.batch();
    batch.set(subRef, finalSubscriber.toMap());
    batch.set(debtRef, debt.toMap());

    if (isPaid && s.monthlyFee > 0) {
      final payRef = subRef.collection('payments').doc();
      final payment = Payment(
        id: payRef.id,
        subscriberId: subId,
        amount: s.monthlyFee,
        currency: s.currency,
        receivedIn: receivedIn,
        method: 'subscription',
        note: 'سداد الاشتراك الأول عند الإضافة',
        recordedBy: by.uid,
        recordedAt: now,
      );
      batch.set(payRef, payment.toMap());

      CashboxService.registerSubscriptionPayment(
        batch: batch,
        db: db,
        actor: by,
        adminUid: by.adminUid,
        payment: payment,
        paymentId: payRef.id,
        subscriberId: subId,
        subscriberName: s.name,
      );
    }

    await batch.commit();

    await _logger.log(
      actor: by,
      action: 'subscriber.add',
      targetType: 'subscriber',
      targetId: subId,
      summary:
          'Added subscriber: ${s.name} (${isPaid ? "Paid" : "On credit"})',
      after: finalSubscriber.toMap(),
    );

    if (!by.isAdmin && _notificationsRepo != null) {
      await _notificationsRepo.sendNotification(
        adminUid: by.adminUid,
        recipientUid: 'admin',
        title: 'إضافة مشترك جديد',
        body: 'قام الموظف ${by.displayName} بإضافة المشترك: ${s.name} (${isPaid ? "مسدد" : "دين"})',
        type: 'subscriber_created',
        actor: by,
        targetId: subId,
        targetType: 'subscriber',
      );
    }
  }

  Future<void> update(AppUser by, Subscriber s) async {
    if (_db == null) return;
    final ref = _col(by.adminUid).doc(s.id);
    final before = (await ref.get()).data();
    await ref.update(s.toMap());
    await _logger.log(
      actor: by,
      action: 'subscriber.edit',
      targetType: 'subscriber',
      targetId: s.id,
      summary: 'Edited subscriber: ${s.name}',
      before: before,
      after: s.toMap(),
    );

    if (!by.isAdmin && _notificationsRepo != null) {
      await _notificationsRepo.sendNotification(
        adminUid: by.adminUid,
        recipientUid: 'admin',
        title: 'تعديل بيانات مشترك',
        body: 'قام الموظف ${by.displayName} بتعديل بيانات المشترك: ${s.name}',
        type: 'subscriber_updated',
        actor: by,
        targetId: s.id,
        targetType: 'subscriber',
      );
    }
  }

  Future<void> delete(AppUser by, Subscriber s) async {
    if (_db == null) return;
    await _col(by.adminUid).doc(s.id).delete();
    await _logger.log(
      actor: by,
      action: 'subscriber.delete',
      targetType: 'subscriber',
      targetId: s.id,
      summary: 'Deleted subscriber: ${s.name}',
      before: s.toMap(),
    );

    if (!by.isAdmin && _notificationsRepo != null) {
      await _notificationsRepo.sendNotification(
        adminUid: by.adminUid,
        recipientUid: 'admin',
        title: 'حذف مشترك',
        body: 'قام الموظف ${by.displayName} بحذف المشترك: ${s.name}',
        type: 'subscriber_deleted',
        actor: by,
        targetId: s.id,
        targetType: 'subscriber',
      );
    }
  }

  Stream<List<SubscriberDebt>> watchDebts(
      String adminUid, String subscriberId) {
    if (_db == null) return const Stream.empty();
    return _debtCol(adminUid, subscriberId)
        .orderBy('periodEnd', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => SubscriberDebt.fromDoc(d, subscriberId: subscriberId))
            .toList());
  }

  Future<List<SubscriberDebt>> getDebts(
      String adminUid, String subscriberId) async {
    if (_db == null) return [];
    final snap = await _debtCol(adminUid, subscriberId)
        .orderBy('periodEnd', descending: true)
        .get();
    return snap.docs
        .map((d) => SubscriberDebt.fromDoc(d, subscriberId: subscriberId))
        .toList();
  }

  Stream<List<Payment>> watchPayments(String adminUid, String subscriberId) {
    if (_db == null) return const Stream.empty();
    return _col(adminUid)
        .doc(subscriberId)
        .collection('payments')
        .orderBy('recordedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Payment.fromDoc).toList());
  }

  Future<List<Payment>> getPayments(
      String adminUid, String subscriberId) async {
    if (_db == null) return [];
    final snap = await _col(adminUid)
        .doc(subscriberId)
        .collection('payments')
        .orderBy('recordedAt', descending: true)
        .get();
    return snap.docs.map(Payment.fromDoc).toList();
  }

  Stream<List<SubscriberDebt>> watchAllDebts(String adminUid) {
    final db = _db;
    if (db == null) return const Stream.empty();
    return db
        .collectionGroup('debts')
        .limit(1000)
        .snapshots()
        .map((s) {
      final list = s.docs
          .where((d) => d.reference.path.startsWith('admins/$adminUid/'))
          .map(SubscriberDebt.fromDoc)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<List<SubscriberDebt>> getAllDebts(String adminUid) async {
    final db = _db;
    if (db == null) return [];
    try {
      final snap = await db
          .collectionGroup('debts')
          .limit(1000)
          .get();
      final list = snap.docs
          .where((d) => d.reference.path.startsWith('admins/$adminUid/'))
          .map(SubscriberDebt.fromDoc)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      debugPrint('Error getting debts via collectionGroup: $e');
      return [];
    }
  }

  Future<void> addDebt(
      AppUser by, Subscriber subscriber, SubscriberDebt debt) async {
    if (_db == null) return;
    final subRef = _col(by.adminUid).doc(subscriber.id);
    final debtRef = _debtCol(by.adminUid, subscriber.id).doc();
    await _db.runTransaction((tx) async {
      final snap = await tx.get(subRef);
      final currentBalance = (snap.data()?['balance'] ?? 0) as num;
      final currentEnd = snap.data()?['subscriptionEndsAt'];
      final nextEnd = currentEnd == null
          ? debt.periodEnd
          : _maxDate(_dateFromFirestore(currentEnd), debt.periodEnd);
      tx.set(debtRef, debt.toMap());
      tx.update(subRef, {
        'balance': currentBalance + debt.amount,
        'subscriptionEndsAt': Timestamp.fromDate(nextEnd),
        'status': SubscriberStatus.overdue.name,
      });
    });
    await _logger.log(
      actor: by,
      action: 'subscriber.debt.add',
      targetType: 'subscriberDebt',
      targetId: debtRef.id,
      summary:
          'Added debt ${debt.amount} ${debt.currency.code} for ${subscriber.name}',
      after: debt.toMap(),
    );

    if (!by.isAdmin && _notificationsRepo != null) {
      await _notificationsRepo.sendNotification(
        adminUid: by.adminUid,
        recipientUid: 'admin',
        title: 'إضافة دين جديد لمشترك',
        body: 'قام الموظف ${by.displayName} بإضافة دين بقيمة ${debt.amount} ${debt.currency.code} للمشترك: ${subscriber.name}',
        type: 'subscriber_debt_added',
        actor: by,
        targetId: subscriber.id,
        targetType: 'subscriber',
      );
    }
  }

  Future<void> updateDebt(
    AppUser by,
    Subscriber subscriber,
    SubscriberDebt oldDebt,
    SubscriberDebt newDebt,
  ) async {
    if (_db == null) return;
    final subRef = _col(by.adminUid).doc(subscriber.id);
    final debtRef = _debtCol(by.adminUid, subscriber.id).doc(oldDebt.id);

    final oldUnpaid =
        (oldDebt.amount - oldDebt.paidAmount).clamp(0, double.infinity);
    final newUnpaid =
        (newDebt.amount - newDebt.paidAmount).clamp(0, double.infinity);
    final diff = newUnpaid - oldUnpaid;

    await _db.runTransaction((tx) async {
      final snap = await tx.get(subRef);
      if (!snap.exists) return;
      final currentBalance = (snap.data()?['balance'] ?? 0) as num;
      final nextBalance =
          (currentBalance + diff).clamp(0, double.infinity);
      final nextStatus = nextBalance > 0
          ? SubscriberStatus.overdue.name
          : SubscriberStatus.active.name;

      final currentEnd = snap.data()?['subscriptionEndsAt'];
      final nextEnd = currentEnd == null
          ? newDebt.periodEnd
          : _maxDate(_dateFromFirestore(currentEnd), newDebt.periodEnd);

      tx.update(debtRef, {
        'amount': newDebt.amount,
        'agentCost': newDebt.agentCost,
        'periodStart': Timestamp.fromDate(newDebt.periodStart),
        'periodEnd': Timestamp.fromDate(newDebt.periodEnd),
        'note': newDebt.note,
      });

      tx.update(subRef, {
        'balance': nextBalance,
        'subscriptionEndsAt': Timestamp.fromDate(nextEnd),
        'status': nextStatus,
      });
    });

    await _logger.log(
      actor: by,
      action: 'subscriber.debt.update',
      targetType: 'subscriberDebt',
      targetId: oldDebt.id,
      summary:
          'Updated debt from ${oldDebt.amount} to ${newDebt.amount} ${newDebt.currency.code} for ${subscriber.name}',
      before: oldDebt.toMap(),
      after: newDebt.toMap(),
    );

    if (!by.isAdmin && _notificationsRepo != null) {
      await _notificationsRepo.sendNotification(
        adminUid: by.adminUid,
        recipientUid: 'admin',
        title: 'تعديل دين مشترك',
        body:
            'قام الموظف ${by.displayName} بتعديل دين للمشترك: ${subscriber.name}',
        type: 'subscriber_debt_updated',
        actor: by,
        targetId: subscriber.id,
        targetType: 'subscriber',
      );
    }
  }

  Future<void> deleteDebt(
    AppUser by,
    Subscriber subscriber,
    SubscriberDebt debt,
  ) async {
    if (_db == null) return;
    final subRef = _col(by.adminUid).doc(subscriber.id);
    final debtRef = _debtCol(by.adminUid, subscriber.id).doc(debt.id);

    final unpaidPortion =
        (debt.amount - debt.paidAmount).clamp(0, double.infinity);

    // Read remaining debts to properly restore subscriptionEndsAt if this was the latest debt
    final allDebtsSnap = await _debtCol(by.adminUid, subscriber.id).get();
    DateTime? maxPeriodEnd;
    for (final doc in allDebtsSnap.docs) {
      if (doc.id == debt.id) continue;
      final d = doc.data();
      final pEnd = d['periodEnd'];
      if (pEnd != null) {
        final dt = _dateFromFirestore(pEnd);
        if (maxPeriodEnd == null || dt.isAfter(maxPeriodEnd)) {
          maxPeriodEnd = dt;
        }
      }
    }

    await _db.runTransaction((tx) async {
      final snap = await tx.get(subRef);
      if (!snap.exists) return;
      final currentBalance = (snap.data()?['balance'] ?? 0) as num;
      final nextBalance =
          (currentBalance - unpaidPortion).clamp(0, double.infinity);
      final nextStatus = nextBalance > 0
          ? SubscriberStatus.overdue.name
          : SubscriberStatus.active.name;

      final updates = <String, dynamic>{
        'balance': nextBalance,
        'status': nextStatus,
      };
      if (maxPeriodEnd != null) {
        updates['subscriptionEndsAt'] = Timestamp.fromDate(maxPeriodEnd);
      }

      tx.delete(debtRef);
      tx.update(subRef, updates);
    });

    await _logger.log(
      actor: by,
      action: 'subscriber.debt.delete',
      targetType: 'subscriberDebt',
      targetId: debt.id,
      summary:
          'Deleted debt ${debt.amount} ${debt.currency.code} for ${subscriber.name}',
      before: debt.toMap(),
    );

    if (!by.isAdmin && _notificationsRepo != null) {
      await _notificationsRepo.sendNotification(
        adminUid: by.adminUid,
        recipientUid: 'admin',
        title: 'حذف دين مشترك',
        body:
            'قام الموظف ${by.displayName} بحذف دين بقيمة ${debt.amount} ${debt.currency.code} للمشترك: ${subscriber.name}',
        type: 'subscriber_debt_deleted',
        actor: by,
        targetId: subscriber.id,
        targetType: 'subscriber',
      );
    }
  }

  Future<void> markDebtPaid(
      AppUser by, Subscriber subscriber, SubscriberDebt debt,
      {MoneyStorage receivedIn = MoneyStorage.cashbox}) async {
    if (_db == null || debt.isPaid) return;
    final db = _db;
    final subRef = _col(by.adminUid).doc(subscriber.id);
    final debtRef = _debtCol(by.adminUid, subscriber.id).doc(debt.id);
    final paymentRef = subRef.collection('payments').doc();
    final remainingDue = debt.amount - debt.paidAmount;
    final payment = Payment(
      id: paymentRef.id,
      subscriberId: subscriber.id,
      amount: remainingDue,
      currency: debt.currency,
      receivedIn: receivedIn,
      method: 'subscription',
      note: debt.note,
      recordedBy: by.uid,
      recordedAt: DateTime.now(),
    );
    final batch = db.batch();
    batch.set(paymentRef, payment.toMap());
    batch.update(debtRef, {
      'status': SubscriptionDebtStatus.paid.name,
      'paidAmount': debt.amount,
      'paidAt': Timestamp.fromDate(payment.recordedAt),
      'paidBy': by.uid,
    });
    final nextBalance = subscriber.balance - remainingDue;
    batch.update(subRef, {
      'balance': nextBalance,
      'status': nextBalance > 0
          ? SubscriberStatus.overdue.name
          : SubscriberStatus.active.name,
    });
    CashboxService.registerSubscriptionPayment(
      batch: batch,
      db: db,
      actor: by,
      adminUid: by.adminUid,
      payment: payment,
      paymentId: paymentRef.id,
      subscriberId: subscriber.id,
      subscriberName: subscriber.name,
    );
    await batch.commit();
    await _logger.log(
      actor: by,
      action: 'subscriber.debt.pay',
      targetType: 'subscriberDebt',
      targetId: debt.id,
      summary:
          'Paid debt ${debt.amount} ${debt.currency.code} for ${subscriber.name}',
      before: {
        'subscriberId': subscriber.id,
        'subscriberName': subscriber.name,
        'subscriberBalance': subscriber.balance,
        'subscriberStatus': subscriber.status.name,
        'debt': debt.toMap(),
      },
      after: {
        ...payment.toMap(),
        'paymentId': paymentRef.id,
        'debtId': debt.id,
        'subscriberName': subscriber.name,
      },
    );

    if (!by.isAdmin && _notificationsRepo != null) {
      await _notificationsRepo.sendNotification(
        adminUid: by.adminUid,
        recipientUid: 'admin',
        title: 'تسديد دين مشترك',
        body: 'قام الموظف ${by.displayName} بتسديد دين بقيمة $remainingDue ${debt.currency.code} للمشترك: ${subscriber.name}',
        type: 'subscriber_payment',
        actor: by,
        targetId: subscriber.id,
        targetType: 'subscriber',
      );
    }
  }

  /// Reverses a paid subscription debt, restoring the debt to unpaid,
  /// adding the amount back to the subscriber's balance, deleting the
  /// corresponding payment record, and reversing the cashbox entry.
  Future<void> unpayDebt(
    AppUser by,
    Subscriber subscriber,
    SubscriberDebt debt,
  ) async {
    if (_db == null || !debt.isPaid) return;
    final db = _db;
    final subRef = _col(by.adminUid).doc(subscriber.id);
    final debtRef = _debtCol(by.adminUid, subscriber.id).doc(debt.id);
    final refundAmount = debt.paidAmount > 0 ? debt.paidAmount : debt.amount;

    // Try to find the matching payment document to determine receivedIn & collector
    MoneyStorage receivedIn = MoneyStorage.cashbox;
    String collectorUid = debt.paidBy ?? by.uid;
    DocumentReference<Map<String, dynamic>>? matchedPayRef;

    final paymentsSnap = await subRef
        .collection('payments')
        .orderBy('recordedAt', descending: true)
        .limit(25)
        .get();
    for (final pDoc in paymentsSnap.docs) {
      final p = Payment.fromDoc(pDoc);
      final timeDiff = debt.paidAt != null
          ? p.recordedAt.difference(debt.paidAt!).inSeconds.abs()
          : 999999;
      if ((p.amount == refundAmount || timeDiff <= 15) &&
          p.currency == debt.currency) {
        receivedIn = p.receivedIn;
        if (p.recordedBy.isNotEmpty) collectorUid = p.recordedBy;
        matchedPayRef = pDoc.reference;
        break;
      }
    }

    final batch = db.batch();
    if (matchedPayRef != null) {
      batch.delete(matchedPayRef);
    }
    batch.update(debtRef, {
      'status': SubscriptionDebtStatus.unpaid.name,
      'paidAmount': 0,
      'paidAt': null,
      'paidBy': null,
    });
    final nextBalance = subscriber.balance + refundAmount;
    batch.update(subRef, {
      'balance': nextBalance,
      'status': nextBalance > 0
          ? SubscriberStatus.overdue.name
          : SubscriberStatus.active.name,
    });
    CashboxService.reverseSubscriptionPayment(
      batch: batch,
      db: db,
      actor: by,
      adminUid: by.adminUid,
      amount: refundAmount,
      currency: debt.currency,
      receivedIn: receivedIn,
      collectorUid: collectorUid,
      subscriberId: subscriber.id,
      subscriberName: subscriber.name,
      paymentId: matchedPayRef?.id,
      note: 'التراجع عن تسديد اشتراك المشترك ${subscriber.name}',
    );
    await batch.commit();

    await _logger.log(
      actor: by,
      action: 'subscriber.debt.unpay',
      targetType: 'subscriberDebt',
      targetId: debt.id,
      summary:
          'التراجع عن تسديد اشتراك بقيمة $refundAmount ${debt.currency.code} للمشترك ${subscriber.name}',
      before: debt.toMap(),
    );
  }

  Future<void> syncDueDebts(AppUser by, Subscriber subscriber) async {
    if (_db == null || subscriber.id.isEmpty) return;
    if (!subscriber.autoRenew) return;
    final now = DateTime.now();
    if (subscriber.subscriptionEndsAt.isAfter(now)) return;

    var periodStart = subscriber.subscriptionEndsAt;
    var periodEnd = DateFormatter.addDays(periodStart, 30);
    var added = 0;
    num addedBalance = 0;
    var remainingPrepaid = subscriber.prepaidCycles;
    final batch = _db.batch();

    while (!periodStart.isAfter(now) && added < 36) {
      final debtRef =
          _debtCol(by.adminUid, subscriber.id).doc(_periodDebtId(periodStart));
      final exists = await debtRef.get();
      if (!exists.exists) {
        final isPrepaid = remainingPrepaid > 0;
        final debt = SubscriberDebt(
          id: debtRef.id,
          subscriberId: subscriber.id,
          supplierId: subscriber.supplierId,
          packageId: subscriber.packageId,
          packageName: subscriber.packageName ?? subscriber.planName,
          amount: subscriber.monthlyFee,
          paidAmount: isPrepaid ? subscriber.monthlyFee : 0,
          agentCost: subscriber.packageAgentPrice,
          currency: subscriber.currency,
          periodStart: periodStart,
          periodEnd: periodEnd,
          status: isPrepaid
              ? SubscriptionDebtStatus.paid
              : SubscriptionDebtStatus.unpaid,
          note: isPrepaid ? 'تجديد تلقائي (مسدد مقدماً)' : null,
          recordedBy: by.uid,
          createdAt: now,
          paidAt: isPrepaid ? now : null,
          paidBy: isPrepaid ? by.uid : null,
        );
        batch.set(debtRef, debt.toMap());
        if (isPrepaid) {
          remainingPrepaid--;
        } else {
          addedBalance += debt.amount;
        }
      }
      added++;
      periodStart = periodEnd;
      periodEnd = DateFormatter.addDays(periodStart, 30);
    }

    final updates = <String, dynamic>{
      'subscriptionEndsAt': Timestamp.fromDate(periodStart),
      'prepaidCycles': remainingPrepaid,
    };
    if (addedBalance > 0) {
      updates['balance'] = FieldValue.increment(addedBalance);
      updates['status'] = SubscriberStatus.overdue.name;
    }
    batch.update(_col(by.adminUid).doc(subscriber.id), updates);
    await batch.commit();
  }

  /// Toggle auto-renew flag. When enabling, immediately add a 30-day debt
  /// starting from "now" (activation date) if the subscription is already
  /// expired or about to expire. The catch-up sync continues from there.
  Future<void> setAutoRenew(
      AppUser by, Subscriber subscriber, bool enabled) async {
    if (_db == null) return;
    final subRef = _col(by.adminUid).doc(subscriber.id);
    await subRef.update({'autoRenew': enabled});
    await _logger.log(
      actor: by,
      action: enabled
          ? 'subscriber.autoRenew.enable'
          : 'subscriber.autoRenew.disable',
      targetType: 'subscriber',
      targetId: subscriber.id,
      summary: enabled
          ? 'Enabled auto-renew for ${subscriber.name}'
          : 'Disabled auto-renew for ${subscriber.name}',
    );
    if (!enabled) return;

    // On activation, ensure there is at least one 30-day debt starting now.
    final now = DateTime.now();
    final activationStart = subscriber.subscriptionEndsAt.isAfter(now)
        ? subscriber.subscriptionEndsAt
        : now;
    final activationEnd = DateFormatter.addDays(activationStart, 30);
    final debtRef = _debtCol(by.adminUid, subscriber.id)
        .doc(_periodDebtId(activationStart));
    final exists = await debtRef.get();
    if (!exists.exists) {
      final isPrepaid = subscriber.prepaidCycles > 0;
      final debt = SubscriberDebt(
        id: debtRef.id,
        subscriberId: subscriber.id,
        supplierId: subscriber.supplierId,
        packageId: subscriber.packageId,
        packageName: subscriber.packageName ?? subscriber.planName,
        amount: subscriber.monthlyFee,
        paidAmount: isPrepaid ? subscriber.monthlyFee : 0,
        agentCost: subscriber.packageAgentPrice,
        currency: subscriber.currency,
        periodStart: activationStart,
        periodEnd: activationEnd,
        status: isPrepaid
            ? SubscriptionDebtStatus.paid
            : SubscriptionDebtStatus.unpaid,
        note: isPrepaid ? 'تجديد تلقائي (مسدد مقدماً)' : null,
        recordedBy: by.uid,
        createdAt: now,
        paidAt: isPrepaid ? now : null,
        paidBy: isPrepaid ? by.uid : null,
      );
      await _db.runTransaction((tx) async {
        final snap = await tx.get(subRef);
        final currentBalance = (snap.data()?['balance'] ?? 0) as num;
        final currentPrepaid =
            ((snap.data()?['prepaidCycles'] as num?)?.toInt()) ?? 0;
        tx.set(debtRef, debt.toMap());
        final subUpdates = <String, dynamic>{
          'subscriptionEndsAt': Timestamp.fromDate(activationEnd),
        };
        if (isPrepaid) {
          subUpdates['prepaidCycles'] = (currentPrepaid - 1).clamp(0, 999);
        } else {
          subUpdates['balance'] = currentBalance + debt.amount;
          subUpdates['status'] = SubscriberStatus.overdue.name;
        }
        tx.update(subRef, subUpdates);
      });
    }
    // Continue catching up from there.
    await syncDueDebts(by, subscriber.copyWith(autoRenew: true));
  }

  /// Records an advance subscription payment for upcoming cycle(s).
  /// Registers cash in cashbox immediately and increments `prepaidCycles`
  /// so that upon next auto-renewal, the period debt is automatically marked
  /// paid without adding debt to subscriber balance.
  Future<void> recordAdvanceSubscriptionPayment(
    AppUser by,
    Subscriber subscriber, {
    required num amount,
    required MoneyStorage receivedIn,
    int cycles = 1,
    String? note,
  }) async {
    if (_db == null) return;
    final db = _db;
    final subRef = _col(by.adminUid).doc(subscriber.id);
    final payRef = subRef.collection('payments').doc();
    final now = DateTime.now();

    final payment = Payment(
      id: payRef.id,
      subscriberId: subscriber.id,
      amount: amount,
      currency: subscriber.currency,
      receivedIn: receivedIn,
      method: 'advance_subscription',
      note: note ?? 'تسديد اشتراك قادم مقدماً ($cycles دورة)',
      recordedBy: by.uid,
      recordedAt: now,
    );

    final batch = db.batch();
    batch.set(payRef, payment.toMap());

    final nextPrepaid = subscriber.prepaidCycles + cycles;
    batch.update(subRef, {
      'prepaidCycles': nextPrepaid,
    });

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
      action: 'subscriber.advance_payment',
      targetType: 'subscriber',
      targetId: subscriber.id,
      summary:
          'تسديد اشتراك قادم مقدماً ($cycles دورة) بقيمة $amount ${subscriber.currency.code} للمشترك ${subscriber.name}',
      before: {
        'subscriberId': subscriber.id,
        'subscriberName': subscriber.name,
        'prepaidCycles': subscriber.prepaidCycles,
      },
      after: {
        ...payment.toMap(),
        'paymentId': payRef.id,
        'amount': amount,
        'cycles': cycles,
        'prepaidCycles': nextPrepaid,
        'subscriberName': subscriber.name,
      },
    );

    if (!by.isAdmin && _notificationsRepo != null) {
      await _notificationsRepo.sendNotification(
        adminUid: by.adminUid,
        recipientUid: 'admin',
        title: 'تسديد اشتراك قادم مقدماً',
        body:
            'قام الموظف ${by.displayName} بتسجيل تسديد اشتراك قادم مقدماً للمشترك: ${subscriber.name} بقيمة $amount ${subscriber.currency.code}',
        type: 'subscriber_advance_payment',
        actor: by,
        targetId: subscriber.id,
        targetType: 'subscriber',
      );
    }
  }

  /// Cancels a prepaid cycle if entered by mistake.
  Future<void> cancelAdvancePayment(
    AppUser by,
    Subscriber subscriber, {
    int cyclesToCancel = 1,
  }) async {
    if (_db == null || subscriber.prepaidCycles <= 0) return;
    final subRef = _col(by.adminUid).doc(subscriber.id);
    final newCount = (subscriber.prepaidCycles - cyclesToCancel).clamp(0, 999);
    await subRef.update({'prepaidCycles': newCount});
    await _logger.log(
      actor: by,
      action: 'subscriber.advance_payment.cancel',
      targetType: 'subscriber',
      targetId: subscriber.id,
      summary: 'إلغاء تسديد مسبق لدورة اشتراك قادمة للمشترك ${subscriber.name}',
      before: {'prepaidCycles': subscriber.prepaidCycles},
      after: {'prepaidCycles': newCount},
    );
  }

  /// Record a payment and distribute the amount across unpaid/partial debts
  /// in FIFO order (oldest first). Updates each debt's paidAmount/status and
  /// the subscriber's balance.
  Future<void> recordPaymentAndDistribute(
      AppUser by, Subscriber subscriber, Payment payment) async {
    if (_db == null) return;
    final db = _db;
    final subRef = _col(by.adminUid).doc(subscriber.id);
    final payRef = subRef.collection('payments').doc();

    // Read open debts oldest first (outside the transaction; batched write).
    final debtsSnap = await _debtCol(by.adminUid, subscriber.id)
        .where('status', whereIn: [
          SubscriptionDebtStatus.unpaid.name,
          SubscriptionDebtStatus.partiallyPaid.name,
        ])
        .orderBy('periodStart')
        .get();

    final paymentToWrite = Payment(
      id: payRef.id,
      subscriberId: subscriber.id,
      amount: payment.amount,
      currency: payment.currency,
      receivedIn: payment.receivedIn,
      method: payment.method,
      note: payment.note,
      recordedBy: payment.recordedBy,
      recordedAt: payment.recordedAt,
    );

    final batch = db.batch();
    batch.set(payRef, paymentToWrite.toMap());

    num remaining = payment.amount;
    final coveredDebtIds = <String>[];
    final affectedDebtsBefore = <Map<String, dynamic>>[];
    for (final doc in debtsSnap.docs) {
      if (remaining <= 0) break;
      final d = doc.data();
      final amount = (d['amount'] ?? 0) as num;
      final alreadyPaid = (d['paidAmount'] ?? 0) as num;
      final due = amount - alreadyPaid;
      if (due <= 0) continue;
      affectedDebtsBefore.add({
        'id': doc.id,
        'paidAmount': alreadyPaid,
        'status': d['status'] ?? SubscriptionDebtStatus.unpaid.name,
        'paidAt': d['paidAt'],
        'paidBy': d['paidBy'],
      });
      if (remaining >= due) {
        batch.update(doc.reference, {
          'paidAmount': amount,
          'status': SubscriptionDebtStatus.paid.name,
          'paidAt': Timestamp.fromDate(payment.recordedAt),
          'paidBy': by.uid,
        });
        remaining -= due;
        coveredDebtIds.add(doc.id);
      } else {
        batch.update(doc.reference, {
          'paidAmount': alreadyPaid + remaining,
          'status': SubscriptionDebtStatus.partiallyPaid.name,
        });
        remaining = 0;
      }
    }

    final newBalance = subscriber.balance - payment.amount;
    batch.update(subRef, {
      'balance': newBalance,
      'status': newBalance > 0
          ? SubscriberStatus.overdue.name
          : SubscriberStatus.active.name,
    });

    CashboxService.registerSubscriptionPayment(
      batch: batch,
      db: db,
      actor: by,
      adminUid: by.adminUid,
      payment: paymentToWrite,
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
          'Recorded payment ${payment.amount} ${payment.currency.code} for ${subscriber.name}'
          ' (covered ${coveredDebtIds.length} debt(s))',
      before: {
        'subscriberId': subscriber.id,
        'subscriberName': subscriber.name,
        'subscriberBalance': subscriber.balance,
        'subscriberStatus': subscriber.status.name,
        'debts': affectedDebtsBefore,
      },
      after: {
        ...paymentToWrite.toMap(),
        'paymentId': payRef.id,
        'subscriberName': subscriber.name,
      },
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

  String _periodDebtId(DateTime periodStart) =>
      'sub_${periodStart.year.toString().padLeft(4, '0')}'
      '${periodStart.month.toString().padLeft(2, '0')}'
      '${periodStart.day.toString().padLeft(2, '0')}';

  DateTime _dateFromFirestore(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  DateTime _maxDate(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
}

final subscribersRepositoryProvider = Provider<SubscribersRepository>(
  (ref) => SubscribersRepository(
    ref.watch(firestoreProvider),
    ref.watch(historyLoggerProvider),
    ref.watch(notificationsRepositoryProvider),
  ),
);

final subscribersStreamProvider = StreamProvider.autoDispose
    .family<List<Subscriber>, String>((ref, adminUid) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return const Stream.empty();
  return ref.watch(subscribersRepositoryProvider).watchAll(adminUid);
});
