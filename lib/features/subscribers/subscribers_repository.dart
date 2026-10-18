import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/firebase_service.dart';
import '../../core/models/models.dart';
import '../../core/services/cashbox_service.dart';
import '../../core/utils/formatters.dart';
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
    if (_db == null || adminUid.trim().isEmpty) {
      return Stream.value(const <Subscriber>[]);
    }
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
    DateTime? paidAt,
  }) async {
    if (_db == null) return;
    final db = _db;
    final subRef = _col(by.adminUid).doc();
    final subId = subRef.id;

    final now = DateTime.now();
    final paymentDate = paidAt ?? now;
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
      paidAt: isPaid ? paymentDate : null,
      paidBy: isPaid ? by.uid : null,
    );

    final finalSubscriber = s.copyWith(
      id: subId,
      balance: isPaid ? 0 : s.monthlyFee,
      status: isPaid ? SubscriberStatus.active : SubscriberStatus.overdue,
      lastPaymentAmount: (isPaid && s.monthlyFee > 0) ? s.monthlyFee : null,
      lastPaymentAt: (isPaid && s.monthlyFee > 0) ? paymentDate : null,
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
        recordedAt: paymentDate,
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
    if (_db == null || subscriberId.trim().isEmpty) {
      return Stream.value(const <SubscriberDebt>[]);
    }
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
    if (_db == null || subscriberId.trim().isEmpty) {
      return Stream.value(const <Payment>[]);
    }
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
    if (db == null || adminUid.trim().isEmpty) {
      return Stream.value(const <SubscriberDebt>[]);
    }
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
        if (newDebt.paidAt != null)
          'paidAt': Timestamp.fromDate(newDebt.paidAt!),
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

    // Read remaining debts to properly restore subscriptionEndsAt and exact remaining balance
    final allDebtsSnap = await _debtCol(by.adminUid, subscriber.id).get();
    DateTime? maxPeriodEnd;
    num remainingBalance = 0;
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
      final status = d['status'] as String?;
      if (status != SubscriptionDebtStatus.paid.name) {
        final amt = (d['amount'] ?? 0) as num;
        final pd = (d['paidAmount'] ?? 0) as num;
        remainingBalance += (amt - pd).clamp(0, double.infinity);
      }
    }

    await _db.runTransaction((tx) async {
      final snap = await tx.get(subRef);
      if (!snap.exists) return;
      final nextStatus = remainingBalance > 0
          ? SubscriberStatus.overdue.name
          : SubscriberStatus.active.name;

      final updates = <String, dynamic>{
        'balance': remainingBalance,
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
      {MoneyStorage receivedIn = MoneyStorage.cashbox,
      DateTime? paidAt}) async {
    if (_db == null || debt.isPaid) return;
    if (receivedIn == MoneyStorage.none && !by.isAdmin) {
      throw StateError('تصفية الحسابات القديمة بدون صندوق متاحة للمدير فقط');
    }
    final db = _db;
    final subRef = _col(by.adminUid).doc(subscriber.id);
    final debtRef = _debtCol(by.adminUid, subscriber.id).doc(debt.id);
    final paymentRef = subRef.collection('payments').doc();
    final remainingDue = debt.amount - debt.paidAmount;
    final paymentDate = paidAt ?? DateTime.now();
    final payment = Payment(
      id: paymentRef.id,
      subscriberId: subscriber.id,
      amount: remainingDue,
      currency: debt.currency,
      receivedIn: receivedIn,
      method: 'subscription',
      note: debt.note ??
          (receivedIn == MoneyStorage.none
              ? 'تصفية حساب قديم (بدون صندوق)'
              : null),
      recordedBy: by.uid,
      recordedAt: paymentDate,
    );
    final batch = db.batch();
    batch.set(paymentRef, payment.toMap());
    batch.update(debtRef, {
      'status': SubscriptionDebtStatus.paid.name,
      'paidAmount': debt.amount,
      'paidAt': Timestamp.fromDate(paymentDate),
      'paidBy': by.uid,
    });

    // Query all debts for this subscriber to calculate the exact remaining open balance
    final allDebtsSnap = await _debtCol(by.adminUid, subscriber.id).get();
    num remainingBalance = 0;
    for (final doc in allDebtsSnap.docs) {
      if (doc.id == debt.id) continue; // This debt is now paid!
      final d = doc.data();
      final status = d['status'] as String?;
      if (status != SubscriptionDebtStatus.paid.name) {
        final amt = (d['amount'] ?? 0) as num;
        final pd = (d['paidAmount'] ?? 0) as num;
        remainingBalance += (amt - pd).clamp(0, double.infinity);
      }
    }

    batch.set(subRef, {
      'balance': remainingBalance,
      'status': remainingBalance > 0
          ? SubscriberStatus.overdue.name
          : SubscriberStatus.active.name,
      'lastPaymentAmount': remainingDue,
      'lastPaymentAt': Timestamp.fromDate(paymentDate),
    }, SetOptions(merge: true));
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
    try {
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
          body:
              'قام الموظف ${by.displayName} بتسديد دين بقيمة $remainingDue ${debt.currency.code} للمشترك: ${subscriber.name}',
          type: 'subscriber_payment',
          actor: by,
          targetId: subscriber.id,
          targetType: 'subscriber',
        );
      }
    } catch (e) {
      debugPrint('Non-fatal error logging debt payment: $e');
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
    final allDebtsSnap = await _debtCol(by.adminUid, subscriber.id).get();
    num remainingBalance = debt.amount;
    for (final doc in allDebtsSnap.docs) {
      if (doc.id == debt.id) continue;
      final d = doc.data();
      final status = d['status'] as String?;
      if (status != SubscriptionDebtStatus.paid.name) {
        final amt = (d['amount'] ?? 0) as num;
        final pd = (d['paidAmount'] ?? 0) as num;
        remainingBalance += (amt - pd).clamp(0, double.infinity);
      }
    }
    batch.update(subRef, {
      'balance': remainingBalance,
      'status': remainingBalance > 0
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
    final now = DateTime.now();

    // If subscription is not expired, but subscriber still shows debt, self-heal balance
    if (!subscriber.autoRenew || subscriber.subscriptionEndsAt.isAfter(now)) {
      if (subscriber.balance > 0) {
        await syncSubscriberBalance(by.adminUid, subscriber.id);
      }
      return;
    }

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

    // Read all existing open debts in _debtCol to set the EXACT true balance
    final allDebtsSnap = await _debtCol(by.adminUid, subscriber.id).get();
    final realBalance = allDebtsSnap.docs
        .map((d) => SubscriberDebt.fromDoc(d, subscriberId: subscriber.id))
        .where((d) => !d.isPaid)
        .fold<num>(0, (acc, d) => acc + d.remaining) + addedBalance;

    final updates = <String, dynamic>{
      'subscriptionEndsAt': Timestamp.fromDate(periodStart),
      'prepaidCycles': remainingPrepaid,
      'balance': realBalance,
      'status': realBalance > 0
          ? SubscriberStatus.overdue.name
          : SubscriberStatus.active.name,
    };
    batch.update(_col(by.adminUid).doc(subscriber.id), updates);
    await batch.commit();
  }

  /// Recalculates and updates the subscriber's balance and status based directly on
  /// the source-of-truth unpaid debts in their debts subcollection.
  /// Fixes any historical or race-condition discrepancies where balance > 0 while
  /// all debts are already paid.
  Future<num> syncSubscriberBalance(String adminUid, String subscriberId) async {
    if (_db == null || subscriberId.isEmpty) return 0;
    try {
      final debtsSnap = await _debtCol(adminUid, subscriberId).get();
      final realBalance = debtsSnap.docs
          .map((d) => SubscriberDebt.fromDoc(d, subscriberId: subscriberId))
          .where((d) => !d.isPaid)
          .fold<num>(0, (acc, d) => acc + d.remaining);

      final subRef = _col(adminUid).doc(subscriberId);
      final subSnap = await subRef.get();
      if (subSnap.exists) {
        final data = subSnap.data() ?? {};
        final currentBalance = (data['balance'] ?? 0) as num;
        final currentStatus = data['status'] as String?;
        final targetStatus = realBalance > 0
            ? SubscriberStatus.overdue.name
            : SubscriberStatus.active.name;

        if (currentBalance != realBalance || currentStatus != targetStatus) {
          await subRef.update({
            'balance': realBalance,
            'status': targetStatus,
          });
        }
      }
      return realBalance;
    } catch (e) {
      debugPrint('Error syncing subscriber balance: $e');
      return 0;
    }
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

  /// Shifts the subscriber's auto-renewal / subscription dates when the subscriber
  /// was not activated on the exact day of expiration.
  /// Updates `subscriptionEndsAt` on the subscriber document, and if `targetDebtId`
  /// is provided (the current/latest cycle debt), shifts its `periodStart` and `periodEnd`
  /// accordingly.
  Future<void> shiftAutoRenewal(
    AppUser by,
    Subscriber subscriber, {
    required DateTime newActivationDate,
    required DateTime newSubscriptionEndsAt,
    String? targetDebtId,
  }) async {
    if (_db == null) return;
    final db = _db;
    final subRef = _col(by.adminUid).doc(subscriber.id);
    final batch = db.batch();

    batch.update(subRef, {
      'subscriptionEndsAt': Timestamp.fromDate(newSubscriptionEndsAt),
    });

    Map<String, dynamic>? oldDebtData;
    if (targetDebtId != null && targetDebtId.isNotEmpty) {
      final debtRef = _debtCol(by.adminUid, subscriber.id).doc(targetDebtId);
      final debtSnap = await debtRef.get();
      if (debtSnap.exists) {
        oldDebtData = debtSnap.data();
        batch.update(debtRef, {
          'periodStart': Timestamp.fromDate(newActivationDate),
          'periodEnd': Timestamp.fromDate(newSubscriptionEndsAt),
        });
      }
    }

    await batch.commit();

    await _logger.log(
      actor: by,
      action: 'subscriber.autoRenew.shift',
      targetType: 'subscriber',
      targetId: subscriber.id,
      summary:
          'إزاحة التجديد التلقائي للمشترك ${subscriber.name} إلى ${DateFormatter.date(newActivationDate)} - ${DateFormatter.date(newSubscriptionEndsAt)}',
      before: {
        ...subscriber.toMap(),
        if (oldDebtData != null) 'shiftedDebtBefore': oldDebtData,
      },
      after: {
        ...subscriber
            .copyWith(subscriptionEndsAt: newSubscriptionEndsAt)
            .toMap(),
        'newActivationDate': Timestamp.fromDate(newActivationDate),
        'newSubscriptionEndsAt': Timestamp.fromDate(newSubscriptionEndsAt),
        if (targetDebtId != null) 'targetDebtId': targetDebtId,
      },
    );
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
    DateTime? paidAt,
  }) async {
    if (_db == null) return;
    final db = _db;
    final subRef = _col(by.adminUid).doc(subscriber.id);
    final payRef = subRef.collection('payments').doc();
    final paymentDate = paidAt ?? DateTime.now();

    final payment = Payment(
      id: payRef.id,
      subscriberId: subscriber.id,
      amount: amount,
      currency: subscriber.currency,
      receivedIn: receivedIn,
      method: 'advance_subscription',
      note: note ?? 'تسديد اشتراك قادم مقدماً ($cycles دورة)',
      recordedBy: by.uid,
      recordedAt: paymentDate,
    );

    final batch = db.batch();
    batch.set(payRef, payment.toMap());

    final nextPrepaid = subscriber.prepaidCycles + cycles;
    batch.update(subRef, {
      'prepaidCycles': nextPrepaid,
      'lastPaymentAmount': amount,
      'lastPaymentAt': Timestamp.fromDate(paymentDate),
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
    if (payment.receivedIn == MoneyStorage.none && !by.isAdmin) {
      throw StateError('تصفية الحسابات القديمة بدون صندوق متاحة للمدير فقط');
    }
    final db = _db;
    final subRef = _col(by.adminUid).doc(subscriber.id);
    final payRef = subRef.collection('payments').doc();

    // Read subscriber doc and all debts, then filter/sort open debts oldest first in memory
    // so Firestore does not require a composite index on (status, periodStart).
    final subSnap = await subRef.get();
    final currentBalance =
        (subSnap.data()?['balance'] ?? subscriber.balance) as num;

    final debtsSnap = await _debtCol(by.adminUid, subscriber.id).get();
    final openDebtDocs = debtsSnap.docs.where((doc) {
      final d = doc.data();
      final status = d['status'] as String?;
      return status == null ||
          status == SubscriptionDebtStatus.unpaid.name ||
          status == SubscriptionDebtStatus.partiallyPaid.name;
    }).toList()
      ..sort((a, b) {
        final aStart = _dateFromFirestore(a.data()['periodStart']);
        final bStart = _dateFromFirestore(b.data()['periodStart']);
        return aStart.compareTo(bStart);
      });

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
    final updatedPaidAmounts = <String, num>{};

    for (final doc in openDebtDocs) {
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
        updatedPaidAmounts[doc.id] = amount;
        remaining -= due;
        coveredDebtIds.add(doc.id);
      } else {
        final newPaid = alreadyPaid + remaining;
        batch.update(doc.reference, {
          'paidAmount': newPaid,
          'status': SubscriptionDebtStatus.partiallyPaid.name,
          'paidAt': Timestamp.fromDate(payment.recordedAt),
          'paidBy': by.uid,
        });
        updatedPaidAmounts[doc.id] = newPaid;
        remaining = 0;
      }
    }

    // Calculate exact remaining balance across all debts in _debtCol
    num finalRemainingBalance = 0;
    for (final doc in debtsSnap.docs) {
      final d = doc.data();
      final amount = (d['amount'] ?? 0) as num;
      final currentPaid =
          updatedPaidAmounts[doc.id] ?? ((d['paidAmount'] ?? 0) as num);
      final currentStatus = updatedPaidAmounts.containsKey(doc.id)
          ? (updatedPaidAmounts[doc.id]! >= amount
              ? SubscriptionDebtStatus.paid.name
              : SubscriptionDebtStatus.partiallyPaid.name)
          : (d['status'] as String?);
      if (currentStatus != SubscriptionDebtStatus.paid.name) {
        final rem = (amount - currentPaid).clamp(0, double.infinity);
        finalRemainingBalance += rem;
      }
    }

    batch.set(subRef, {
      'balance': finalRemainingBalance,
      'status': finalRemainingBalance > 0
          ? SubscriberStatus.overdue.name
          : SubscriberStatus.active.name,
      'lastPaymentAmount': payment.amount,
      'lastPaymentAt': Timestamp.fromDate(payment.recordedAt),
    }, SetOptions(merge: true));

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
    try {
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
          'subscriberBalance': currentBalance,
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
          body:
              'قام الموظف ${by.displayName} بتسجيل دفعة بقيمة ${payment.amount} ${payment.currency.code} للمشترك: ${subscriber.name}',
          type: 'subscriber_payment',
          actor: by,
          targetId: subscriber.id,
          targetType: 'subscriber',
        );
      }
    } catch (e) {
      debugPrint('Non-fatal error logging payment: $e');
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

final subscribersStreamProvider =
    StreamProvider.family<List<Subscriber>, String>((ref, adminUid) {
  if (adminUid.trim().isEmpty) return Stream.value(const <Subscriber>[]);
  return ref.watch(subscribersRepositoryProvider).watchAll(adminUid);
});
