import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/firebase_service.dart';
import '../../core/models/models.dart';
import '../../core/services/cashbox_service.dart';
import '../auth/auth_repository.dart';
import '../history/history_repository.dart';
import '../notifications/notifications_repository.dart';

class CashboxSnapshot {
  const CashboxSnapshot({
    required this.balances,
    required this.staffDebtToCashbox,
    required this.cashboxDebtToStaff,
  });

  final Map<String, num> balances;
  final Map<String, num> staffDebtToCashbox;
  final Map<String, num> cashboxDebtToStaff;

  factory CashboxSnapshot.empty() => const CashboxSnapshot(
        balances: {
          'IQD': 0,
          'USD': 0,
        },
        staffDebtToCashbox: {},
        cashboxDebtToStaff: {},
      );

  factory CashboxSnapshot.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};

    num extractBalance(String currencyCode) {
      num total = 0;
      bool found = false;
      final flatKey = 'balances.$currencyCode';
      if (data.containsKey(flatKey)) {
        final raw = data[flatKey];
        if (raw is num) {
          total += raw;
          found = true;
        } else {
          final p = num.tryParse('$raw');
          if (p != null) {
            total += p;
            found = true;
          }
        }
      }
      if (data['balances'] is Map) {
        final m = data['balances'] as Map;
        final raw = m[currencyCode];
        if (raw is num) {
          if (!found) {
            total += raw;
          } else if (total == 0) {
            total = raw;
          }
        } else if (raw != null) {
          final p = num.tryParse('$raw');
          if (p != null) {
            if (!found) {
              total += p;
            } else if (total == 0) {
              total = p;
            }
          }
        }
      }
      return total;
    }

    Map<String, num> extractDebtMap(String prefix) {
      final result = <String, num>{};
      if (data[prefix] is Map) {
        final m = data[prefix] as Map;
        for (final entry in m.entries) {
          final k = '${entry.key}';
          final v = entry.value is num
              ? entry.value as num
              : num.tryParse('${entry.value}') ?? 0;
          if (v != 0) result[k] = v;
        }
      }
      final dotPrefix = '$prefix.';
      for (final entry in data.entries) {
        if (entry.key.startsWith(dotPrefix)) {
          final subKey = entry.key.substring(dotPrefix.length);
          final v = entry.value is num
              ? entry.value as num
              : num.tryParse('${entry.value}') ?? 0;
          if (v != 0) {
            result[subKey] = v;
          }
        }
      }
      return result;
    }

    return CashboxSnapshot(
      balances: {
        AppCurrency.iqd.code: extractBalance(AppCurrency.iqd.code),
        AppCurrency.usd.code: extractBalance(AppCurrency.usd.code),
      },
      staffDebtToCashbox: extractDebtMap('staffDebtToCashbox'),
      cashboxDebtToStaff: extractDebtMap('cashboxDebtToStaff'),
    );
  }

  num balanceFor(AppCurrency currency) => balances[currency.code] ?? 0;

  num staffDebtToCashboxFor(AppUser user, AppCurrency currency) =>
      staffDebtToCashboxForUid(user.uid, currency);

  num cashboxDebtToStaffFor(AppUser user, AppCurrency currency) =>
      cashboxDebtToStaffForUid(user.uid, currency);

  num staffDebtToCashboxForUid(String uid, AppCurrency currency) {
    final val =
        staffDebtToCashbox[CashboxService.debtKey(uid, currency)] ?? 0;
    return val <= 0.001 ? 0 : val;
  }

  num cashboxDebtToStaffForUid(String uid, AppCurrency currency) {
    final val =
        cashboxDebtToStaff[CashboxService.debtKey(uid, currency)] ?? 0;
    return val <= 0.001 ? 0 : val;
  }

  /// Positive means staff owes cashbox (مطلوب للصندوق).
  /// Negative means cashbox owes staff (يطلب من الصندوق).
  num netStaffDebtForUid(String uid, AppCurrency currency) =>
      staffDebtToCashboxForUid(uid, currency) -
      cashboxDebtToStaffForUid(uid, currency);

  num totalStaffDebtToCashbox(AppCurrency currency) {
    num total = 0;
    final suffix = '_${currency.code}';
    for (final entry in staffDebtToCashbox.entries) {
      if (entry.key.endsWith(suffix)) {
        total += entry.value;
      }
    }
    return total;
  }

  num totalCashboxDebtToStaff(AppCurrency currency) {
    num total = 0;
    final suffix = '_${currency.code}';
    for (final entry in cashboxDebtToStaff.entries) {
      if (entry.key.endsWith(suffix)) {
        total += entry.value;
      }
    }
    return total;
  }
}

class CashboxRepository {
  CashboxRepository(this._db, this._logger, [this._notificationsRepo]);
  final FirebaseFirestore? _db;
  final HistoryLogger _logger;
  final NotificationsRepository? _notificationsRepo;

  Stream<CashboxSnapshot> watchCashbox(String adminUid) {
    final db = _db;
    if (db == null) return Stream.value(CashboxSnapshot.empty());
    return CashboxService.cashboxRef(db, adminUid)
        .snapshots()
        .map(CashboxSnapshot.fromDoc);
  }

  Stream<List<CashboxLedgerEntry>> watchLedger(
    String adminUid, {
    AppCurrency? currency,
    int limit = 200,
  }) {
    final db = _db;
    if (db == null) return Stream.value([]);
    Query<Map<String, dynamic>> q = CashboxService.ledgerCol(db, adminUid)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (currency != null) {
      q = q.where('currency', isEqualTo: currency.code);
    }
    return q
        .snapshots()
        .map((s) => s.docs.map(CashboxLedgerEntry.fromDoc).toList());
  }

  Future<void> directAdjustment(
    AppUser by, {
    required num amount,
    required AppCurrency currency,
    required bool isDeposit,
    required String reason,
    String? note,
  }) async {
    final db = _db;
    if (db == null) return;
    final batch = db.batch();
    CashboxService.registerDirectAdjustment(
      batch: batch,
      db: db,
      actor: by,
      adminUid: by.adminUid,
      amount: amount,
      currency: currency,
      isDeposit: isDeposit,
      reason: reason,
      note: note,
    );
    batch.set(
      _logger.newEventRef(by),
      _logger.eventData(
        actor: by,
        action: isDeposit ? 'cashbox.deposit' : 'cashbox.withdrawal',
        targetType: 'cashbox',
        targetId: 'cashbox',
        summary:
            '${isDeposit ? 'Direct deposit' : 'Direct withdrawal'} $amount ${currency.code}: $reason',
        after: {
          'amount': amount,
          'currency': currency.code,
          'isDeposit': isDeposit,
          'reason': reason,
          'note': note,
        },
      ),
    );
    await batch.commit().timeout(HistoryLogger.operationTimeout);
  }

  Future<void> settleStaffDebt(
    AppUser by, {
    required String staffUid,
    required String staffName,
    required num amount,
    required AppCurrency currency,
    required StaffSettlementDirection direction,
    String? note,
  }) async {
    final db = _db;
    if (db == null) return;
    final batch = db.batch();
    CashboxService.settleStaffDebt(
      batch: batch,
      db: db,
      actor: by,
      adminUid: by.adminUid,
      staffUid: staffUid,
      staffName: staffName,
      amount: amount,
      currency: currency,
      direction: direction,
      note: note,
    );
    batch.set(
      _logger.newEventRef(by),
      _logger.eventData(
        actor: by,
        action: direction == StaffSettlementDirection.toCashbox
            ? 'cashbox.settlement.toCashbox'
            : 'cashbox.settlement.fromCashbox',
        targetType: 'staffDebt',
        targetId: staffUid,
        summary:
            '${direction == StaffSettlementDirection.toCashbox ? 'Staff handover to cashbox' : 'Cashbox reimbursement to staff'} $amount ${currency.code} for $staffName',
        after: {
          'staffUid': staffUid,
          'staffName': staffName,
          'amount': amount,
          'currency': currency.code,
          'direction': direction.name,
          'note': note,
        },
      ),
    );
    await batch.commit().timeout(HistoryLogger.operationTimeout);

    if (_notificationsRepo != null) {
      if (!by.isAdmin) {
        await _notificationsRepo.sendNotification(
          adminUid: by.adminUid,
          recipientUid: 'admin',
          title: 'تسليم عهدة للصندوق',
          body:
              'قام الموظف $staffName بتوريد وتسليم مبلغ $amount ${currency.code} إلى الصندوق.',
          type: 'staff_settlement',
          actor: by,
          targetId: staffUid,
          targetType: 'staff_debt',
        );
      } else if (staffUid != by.uid) {
        final isHandover = direction == StaffSettlementDirection.toCashbox;
        await _notificationsRepo.sendNotification(
          adminUid: by.adminUid,
          recipientUid: staffUid,
          title: isHandover
              ? 'تم تسجيل تسليم عهدة'
              : 'تم صرف مستحقات لك من الصندوق',
          body: isHandover
              ? 'قام المدير بتسجيل استلام عهدة بقيمة $amount ${currency.code} وتخفيض ذمتك.'
              : 'قام المدير بصرف مبلغ $amount ${currency.code} من الصندوق لحسابك.',
          type: 'staff_settlement',
          actor: by,
          targetId: staffUid,
          targetType: 'staff_debt',
        );
      }
    }
  }

  CollectionReference<Map<String, dynamic>> _reimbursementReqCol(
          String adminUid) =>
      _db!
          .collection('admins')
          .doc(adminUid)
          .collection('staffReimbursementRequests');

  Stream<List<StaffReimbursementRequest>> watchReimbursementRequests(
    String adminUid, {
    PaymentRequestStatus? status,
  }) {
    if (_db == null) return const Stream.empty();
    Query<Map<String, dynamic>> q =
        _reimbursementReqCol(adminUid).orderBy('createdAt', descending: true);
    if (status != null) q = q.where('status', isEqualTo: status.name);
    return q
        .snapshots()
        .map((s) => s.docs.map(StaffReimbursementRequest.fromDoc).toList());
  }

  Future<void> requestReimbursement(
    AppUser by, {
    required num amount,
    required AppCurrency currency,
    String? note,
  }) async {
    final db = _db;
    if (db == null || amount <= 0) return;
    final ref = _reimbursementReqCol(by.adminUid).doc();
    final req = StaffReimbursementRequest(
      id: ref.id,
      amount: amount,
      currency: currency,
      note: note,
      byEmployeeUid: by.uid,
      byEmployeeName: by.displayName,
      byEmployeeRole: by.role,
      status: PaymentRequestStatus.pending,
      createdAt: DateTime.now(),
    );
    final batch = db.batch();
    batch.set(ref, req.toMap());
    batch.set(
      _logger.newEventRef(by),
      _logger.eventData(
        actor: by,
        action: 'cashbox.reimbursement.request',
        targetType: 'staffReimbursementRequest',
        targetId: ref.id,
        summary:
            'Requested reimbursement of $amount ${currency.code} from cashbox',
        after: req.toMap(),
      ),
    );
    await batch.commit().timeout(HistoryLogger.operationTimeout);

    if (_notificationsRepo != null) {
      await _notificationsRepo.sendNotification(
        adminUid: by.adminUid,
        recipientUid: 'admin',
        title: 'طلب سحب مستحقات جديد',
        body:
            'قدم الموظف ${by.displayName} طلباً لصرف مستحقات بمبلغ $amount ${currency.code} من الصندوق.',
        type: 'reimbursement_request',
        actor: by,
        targetId: ref.id,
        targetType: 'reimbursement_request',
      );
    }
  }

  Future<void> decideReimbursementRequest(
    AppUser admin,
    StaffReimbursementRequest request,
    PaymentRequestStatus status,
  ) async {
    final db = _db;
    if (db == null || request.status != PaymentRequestStatus.pending) return;
    final reqRef = _reimbursementReqCol(admin.adminUid).doc(request.id);
    final batch = db.batch();

    if (status == PaymentRequestStatus.approved) {
      final snap = await CashboxService.cashboxRef(db, admin.adminUid).get();
      final cashbox = CashboxSnapshot.fromDoc(snap);
      if (cashbox.balanceFor(request.currency) < request.amount) {
        throw Exception('رصيد الصندوق غير كافٍ لإتمام عملية الصرف');
      }

      CashboxService.settleStaffDebt(
        batch: batch,
        db: db,
        actor: admin,
        adminUid: admin.adminUid,
        staffUid: request.byEmployeeUid,
        staffName: request.byEmployeeName,
        amount: request.amount,
        currency: request.currency,
        direction: StaffSettlementDirection.fromCashbox,
        note: 'بناءً على طلب صرف المستحقات رقم ${request.id}',
      );

      batch.update(reqRef, {
        'status': PaymentRequestStatus.approved.name,
        'decidedAt': FieldValue.serverTimestamp(),
        'decidedBy': admin.uid,
      });

      batch.set(
        _logger.newEventRef(admin),
        _logger.eventData(
          actor: admin,
          action: 'cashbox.reimbursement.approve',
          targetType: 'staffReimbursementRequest',
          targetId: request.id,
          summary:
              'Approved reimbursement ${request.amount} ${request.currency.code} for ${request.byEmployeeName}',
        ),
      );

      await batch.commit().timeout(HistoryLogger.operationTimeout);

      if (_notificationsRepo != null) {
        await _notificationsRepo.sendNotification(
          adminUid: admin.adminUid,
          recipientUid: request.byEmployeeUid,
          title: 'تمت الموافقة على طلب صرف المستحقات',
          body:
              'وافق المدير على صرف مستحقاتك بمبلغ ${request.amount} ${request.currency.code} وتم خصمها من الصندوق.',
          type: 'reimbursement_approved',
          actor: admin,
          targetId: request.id,
          targetType: 'reimbursement_request',
        );
      }
    } else if (status == PaymentRequestStatus.rejected) {
      batch.update(reqRef, {
        'status': PaymentRequestStatus.rejected.name,
        'decidedAt': FieldValue.serverTimestamp(),
        'decidedBy': admin.uid,
      });

      batch.set(
        _logger.newEventRef(admin),
        _logger.eventData(
          actor: admin,
          action: 'cashbox.reimbursement.reject',
          targetType: 'staffReimbursementRequest',
          targetId: request.id,
          summary:
              'Rejected reimbursement ${request.amount} ${request.currency.code} for ${request.byEmployeeName}',
        ),
      );

      await batch.commit().timeout(HistoryLogger.operationTimeout);

      if (_notificationsRepo != null) {
        await _notificationsRepo.sendNotification(
          adminUid: admin.adminUid,
          recipientUid: request.byEmployeeUid,
          title: 'تم رفض طلب صرف المستحقات',
          body:
              'تم رفض طلبك لصرف مبلغ ${request.amount} ${request.currency.code} من الصندوق من قبل الإدارة.',
          type: 'reimbursement_rejected',
          actor: admin,
          targetId: request.id,
          targetType: 'reimbursement_request',
        );
      }
    }
  }
}

final cashboxRepositoryProvider = Provider<CashboxRepository>((ref) {
  return CashboxRepository(
    ref.watch(firestoreProvider),
    ref.watch(historyLoggerProvider),
    ref.watch(notificationsRepositoryProvider),
  );
});

final reimbursementRequestsStreamProvider = StreamProvider.autoDispose
    .family<List<StaffReimbursementRequest>, String>((ref, adminUid) {
  return ref
      .watch(cashboxRepositoryProvider)
      .watchReimbursementRequests(adminUid);
});

final cashboxStreamProvider =
    StreamProvider.autoDispose.family<CashboxSnapshot, String>((ref, adminUid) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return Stream.value(CashboxSnapshot.empty());
  return ref.watch(cashboxRepositoryProvider).watchCashbox(adminUid);
});

final cashboxLedgerStreamProvider = StreamProvider.autoDispose
    .family<List<CashboxLedgerEntry>, String>((ref, adminUid) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return Stream.value([]);
  return ref.watch(cashboxRepositoryProvider).watchLedger(adminUid);
});
