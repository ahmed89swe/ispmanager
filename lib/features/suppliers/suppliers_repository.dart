import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/firebase_service.dart';
import '../../core/models/models.dart';
import '../../core/services/cashbox_service.dart';
import '../history/history_repository.dart';
import '../notifications/notifications_repository.dart';

class SuppliersRepository {
  SuppliersRepository(this._db, this._logger, [this._notificationsRepo, this._storage]);
  final FirebaseFirestore? _db;
  final HistoryLogger _logger;
  final NotificationsRepository? _notificationsRepo;
  final FirebaseStorage? _storage;

  Future<String> uploadReceipt({
    required String adminUid,
    required XFile file,
  }) async {
    final storage = _storage;
    if (storage == null) {
      throw StateError('خدمة تخزين الملفات غير متوفرة');
    }
    var ext = file.name.split('.').last.toLowerCase();
    if (ext.isEmpty || ext.length > 5) ext = 'jpg';
    final filename =
        '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4().substring(0, 8)}.$ext';
    final ref = storage.ref('admins/$adminUid/receipts/$filename');
    final bytes = await file.readAsBytes();
    final contentType = ext == 'png'
        ? 'image/png'
        : ext == 'webp'
            ? 'image/webp'
            : 'image/jpeg';
    await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    return await ref.getDownloadURL();
  }

  CollectionReference<Map<String, dynamic>> _col(String adminUid) =>
      _db!.collection('admins').doc(adminUid).collection('suppliers');

  Stream<List<Supplier>> watchAll(String adminUid) {
    if (_db == null || adminUid.trim().isEmpty) {
      return Stream.value(const <Supplier>[]);
    }
    return _col(adminUid).orderBy('name').snapshots().map(
          (s) => s.docs.map(Supplier.fromDoc).toList(),
        );
  }

  Future<String> add(AppUser by, Supplier s) async {
    final ref = await _col(by.adminUid).add(s.toMap());
    await _logger.log(
      actor: by,
      action: 'supplier.add',
      targetType: 'supplier',
      targetId: ref.id,
      summary: 'Added supplier ${s.name}',
      after: s.toMap(),
    );
    return ref.id;
  }

  Future<void> update(AppUser by, Supplier s) async {
    final ref = _col(by.adminUid).doc(s.id);
    final before = (await ref.get()).data();
    await ref.update(s.toMap());
    await _logger.log(
      actor: by,
      action: 'supplier.edit',
      targetType: 'supplier',
      targetId: s.id,
      summary: 'Edited supplier ${s.name}',
      before: before,
      after: s.toMap(),
    );
  }

  Future<void> delete(AppUser by, Supplier s) async {
    await _col(by.adminUid).doc(s.id).delete();
    await _logger.log(
      actor: by,
      action: 'supplier.delete',
      targetType: 'supplier',
      targetId: s.id,
      summary: 'Deleted supplier ${s.name}',
      before: s.toMap(),
    );
  }

  // Packages
  CollectionReference<Map<String, dynamic>> _pkgCol(
          String adminUid, String supplierId) =>
      _col(adminUid).doc(supplierId).collection('packages');

  Stream<List<SupplierPackageTemplate>> watchPackages(
      String adminUid, String supplierId) {
    if (_db == null || supplierId.trim().isEmpty) {
      return Stream.value(const <SupplierPackageTemplate>[]);
    }
    return _pkgCol(adminUid, supplierId).orderBy('name').snapshots().map((s) =>
        s.docs
            .map((d) => SupplierPackageTemplate.fromDoc(d, supplierId))
            .toList());
  }

  Future<void> addPackage(AppUser by, SupplierPackageTemplate p) async {
    final ref = await _pkgCol(by.adminUid, p.supplierId).add(p.toMap());
    await _logger.log(
      actor: by,
      action: 'supplier.package.add',
      targetType: 'package',
      targetId: ref.id,
      summary: 'Added package ${p.name}',
      after: {...p.toMap(), 'supplierId': p.supplierId},
    );
  }

  Future<void> updatePackage(AppUser by, SupplierPackageTemplate p) async {
    final ref = _pkgCol(by.adminUid, p.supplierId).doc(p.id);
    final before = (await ref.get()).data();
    await ref.update(p.toMap());
    final after = {...p.toMap(), 'supplierId': p.supplierId};
    await _logger.log(
      actor: by,
      action: 'supplier.package.edit',
      targetType: 'package',
      targetId: p.id,
      summary: 'Edited package ${p.name}',
      before: before == null ? null : {...before, 'supplierId': p.supplierId},
      after: after,
    );
  }

  Future<void> deletePackage(AppUser by, SupplierPackageTemplate p) async {
    await _pkgCol(by.adminUid, p.supplierId).doc(p.id).delete();
    await _logger.log(
      actor: by,
      action: 'supplier.package.delete',
      targetType: 'package',
      targetId: p.id,
      summary: 'Deleted package ${p.name}',
      before: {...p.toMap(), 'supplierId': p.supplierId},
    );
  }

  // Purchases
  CollectionReference<Map<String, dynamic>> _purchaseCol(String adminUid) =>
      _db!.collection('admins').doc(adminUid).collection('supplierPurchases');

  Stream<List<SupplierPurchase>> watchPurchases(String adminUid,
      {String? supplierId}) {
    if (_db == null || adminUid.trim().isEmpty) {
      return Stream.value(const <SupplierPurchase>[]);
    }
    Query<Map<String, dynamic>> q =
        _purchaseCol(adminUid).orderBy('date', descending: true);
    if (supplierId != null) {
      q = q.where('supplierId', isEqualTo: supplierId);
    }
    return q
        .snapshots()
        .map((s) => s.docs.map(SupplierPurchase.fromDoc).toList());
  }

  Future<void> addPurchase(AppUser by, SupplierPurchase p) async {
    final ref = await _purchaseCol(by.adminUid).add(p.toMap());
    await _logger.log(
      actor: by,
      action: 'supplier.purchase.add',
      targetType: 'purchase',
      targetId: ref.id,
      summary: 'Purchase total ${p.totalPrice} ${p.currency.code}',
      after: p.toMap(),
    );
  }

  Future<void> applyPaymentToPurchase(
      AppUser by, String purchaseId, num amount) async {
    final ref = _purchaseCol(by.adminUid).doc(purchaseId);
    await _db!.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final paid = (snap.data()?['paid'] ?? 0) as num;
      tx.update(ref, {'paid': paid + amount});
    });
  }

  // Supplier balance transactions
  CollectionReference<Map<String, dynamic>> _balanceCol(String adminUid) => _db!
      .collection('admins')
      .doc(adminUid)
      .collection('supplierBalanceTransactions');

  Stream<List<SupplierBalanceTransaction>> watchBalanceTransactions(
      String adminUid,
      {String? supplierId}) {
    if (_db == null || adminUid.trim().isEmpty) {
      return Stream.value(const <SupplierBalanceTransaction>[]);
    }
    Query<Map<String, dynamic>> q =
        _balanceCol(adminUid).orderBy('date', descending: true);
    if (supplierId != null) {
      q = q.where('supplierId', isEqualTo: supplierId);
    }
    return q
        .snapshots()
        .map((s) => s.docs.map(SupplierBalanceTransaction.fromDoc).toList());
  }

  Future<void> addBalanceTransaction(
      AppUser by, SupplierBalanceTransaction transaction,
      {String supplierName = ''}) async {
    if (_db == null) return;
    final db = _db;
    final ref = _balanceCol(by.adminUid).doc();
    final batch = db.batch();
    batch.set(ref, transaction.toMap());

    final kind = transaction.type == SupplierBalanceTransactionType.recharge
        ? 'supplierRecharge'
        : 'supplierPayment';
    CashboxService.registerSupplierPayment(
      batch: batch,
      db: db,
      actor: by,
      adminUid: by.adminUid,
      supplierId: transaction.supplierId,
      supplierName:
          supplierName.isEmpty ? transaction.supplierId : supplierName,
      amount: transaction.amount,
      currency: transaction.currency,
      paidFrom: transaction.paidFrom,
      note: transaction.note,
      transactionId: ref.id,
      kind: kind,
    );
    await batch.commit();

    await _logger.log(
      actor: by,
      action: transaction.type == SupplierBalanceTransactionType.recharge
          ? 'supplier.balance.recharge'
          : 'supplier.balance.payment',
      targetType: 'supplierBalanceTransaction',
      targetId: ref.id,
      summary:
          '${transaction.type.name} ${transaction.amount} ${transaction.currency.code}',
      after: transaction.toMap(),
    );

    if (!by.isAdmin && _notificationsRepo != null) {
      final isRecharge =
          transaction.type == SupplierBalanceTransactionType.recharge;
      await _notificationsRepo.sendNotification(
        adminUid: by.adminUid,
        recipientUid: 'admin',
        title: isRecharge ? 'تعبئة رصيد مجهز' : 'تسديد مجهز',
        body:
            'قام الموظف ${by.displayName} بـ ${isRecharge ? "تعبئة رصيد" : "تسديد"} بمبلغ ${transaction.amount} ${transaction.currency.code} للمجهز ${supplierName.isNotEmpty ? supplierName : transaction.supplierId}',
        type: 'supplier_transaction',
        actor: by,
        targetId: ref.id,
        targetType: 'supplier_transaction',
      );
    }
  }

  // Payment requests
  CollectionReference<Map<String, dynamic>> _reqCol(String adminUid) => _db!
      .collection('admins')
      .doc(adminUid)
      .collection('supplierPaymentRequests');

  Stream<List<SupplierPaymentRequest>> watchRequests(String adminUid,
      {PaymentRequestStatus? status}) {
    if (_db == null || adminUid.trim().isEmpty) {
      return Stream.value(const <SupplierPaymentRequest>[]);
    }
    Query<Map<String, dynamic>> q =
        _reqCol(adminUid).orderBy('createdAt', descending: true);
    if (status != null) q = q.where('status', isEqualTo: status.name);
    return q
        .snapshots()
        .map((s) => s.docs.map(SupplierPaymentRequest.fromDoc).toList());
  }

  Future<void> createRequest(AppUser by, SupplierPaymentRequest r) async {
    final ref = await _reqCol(by.adminUid).add(r.toMap());
    await _logger.log(
      actor: by,
      action: 'supplier.payment.request',
      targetType: 'paymentRequest',
      targetId: ref.id,
      summary: 'Requested supplier payment ${r.amount} ${r.currency.code}',
      after: r.toMap(),
    );

    if (_notificationsRepo != null) {
      await _notificationsRepo.sendNotification(
        adminUid: by.adminUid,
        recipientUid: 'admin',
        title: 'طلب تسديد مجهز جديد',
        body:
            'قدم الموظف ${by.displayName} طلباً لتسديد مجهز بمبلغ ${r.amount} ${r.currency.code}.',
        type: 'supplier_request',
        actor: by,
        targetId: ref.id,
        targetType: 'supplier_request',
      );
    }
  }

  Future<void> decideRequest(
      AppUser by, SupplierPaymentRequest r, PaymentRequestStatus decision,
      {String? linkedPurchaseId, String supplierName = ''}) async {
    if (_db == null) return;
    final db = _db;
    final batch = db.batch();
    batch.update(_reqCol(by.adminUid).doc(r.id), {
      'status': decision.name,
      'decidedAt': FieldValue.serverTimestamp(),
      'decidedBy': by.uid,
      'linkedPurchaseId': linkedPurchaseId,
    });

    if (decision == PaymentRequestStatus.approved) {
      CashboxService.registerSupplierPayment(
        batch: batch,
        db: db,
        actor: by,
        adminUid: by.adminUid,
        supplierId: r.supplierId,
        supplierName: supplierName.isEmpty ? r.supplierId : supplierName,
        amount: r.amount,
        currency: r.currency,
        paidFrom: MoneyStorage.cashbox,
        note: r.note,
        transactionId: r.id,
      );
    }
    await batch.commit();

    await _logger.log(
      actor: by,
      action: decision == PaymentRequestStatus.approved
          ? 'supplier.payment.approve'
          : 'supplier.payment.reject',
      targetType: 'paymentRequest',
      targetId: r.id,
      summary:
          '${decision.name.toUpperCase()} request ${r.amount} ${r.currency.code}',
    );

    if (_notificationsRepo != null) {
      final isApproved = decision == PaymentRequestStatus.approved;
      await _notificationsRepo.sendNotification(
        adminUid: by.adminUid,
        recipientUid: r.byEmployeeUid,
        title: isApproved
            ? 'تمت الموافقة على طلب تسديد المجهز'
            : 'تم رفض طلب تسديد المجهز',
        body: isApproved
            ? 'وافق المدير على طلب تسديد المجهز بمبلغ ${r.amount} ${r.currency.code}.'
            : 'تم رفض طلب تسديد المجهز بمبلغ ${r.amount} ${r.currency.code}.',
        type: isApproved ? 'supplier_payment' : 'supplier_rejected',
        actor: by,
        targetId: r.id,
        targetType: 'supplier_request',
      );
    }
  }
}

final suppliersRepositoryProvider = Provider<SuppliersRepository>(
  (ref) => SuppliersRepository(
    ref.watch(firestoreProvider),
    ref.watch(historyLoggerProvider),
    ref.watch(notificationsRepositoryProvider),
    ref.watch(firebaseStorageProvider),
  ),
);

final suppliersStreamProvider =
    StreamProvider.family<List<Supplier>, String>((ref, adminUid) {
  if (adminUid.trim().isEmpty) return Stream.value(const <Supplier>[]);
  return ref.watch(suppliersRepositoryProvider).watchAll(adminUid);
});
