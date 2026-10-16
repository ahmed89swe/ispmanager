import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/firebase_service.dart';
import '../../core/models/models.dart';
import '../../core/services/cashbox_service.dart';
import '../auth/auth_repository.dart';
import '../history/history_repository.dart';
import '../notifications/notifications_repository.dart';

class ExpensesRepository {
  ExpensesRepository(this._db, this._logger, [this._notificationsRepo, this._storage]);
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
      _db!.collection('admins').doc(adminUid).collection('expenses');

  CollectionReference<Map<String, dynamic>> _deleteReqCol(String adminUid) =>
      _db!
          .collection('admins')
          .doc(adminUid)
          .collection('expenseDeleteRequests');

  Stream<List<Expense>> watchAll(String adminUid) {
    if (_db == null) return const Stream.empty();
    return _col(adminUid).orderBy('date', descending: true).snapshots().map(
          (s) => s.docs.map(Expense.fromDoc).toList(),
        );
  }

  Future<void> add(AppUser by, Expense e) async {
    final db = _db;
    if (db == null) return;
    final ref = _col(by.adminUid).doc();
    final batch = db.batch();
    batch.set(ref, e.toMap());
    CashboxService.registerExpense(
      batch: batch,
      db: db,
      actor: by,
      adminUid: by.adminUid,
      expense: e,
      expenseId: ref.id,
    );
    batch.set(
      _logger.newEventRef(by),
      _logger.eventData(
        actor: by,
        action: 'expense.add',
        targetType: 'expense',
        targetId: ref.id,
        summary:
            'Expense ${e.amount} ${e.currency.code} (${e.category.name}): ${e.reason}',
        after: e.toMap(),
      ),
    );
    await batch.commit().timeout(HistoryLogger.operationTimeout);

    if (!by.isAdmin && _notificationsRepo != null) {
      await _notificationsRepo.sendNotification(
        adminUid: by.adminUid,
        recipientUid: 'admin',
        title: 'تسجيل مصروف جديد',
        body: 'قام الموظف ${by.displayName} بتسجيل مصروف جديد بقيمة ${e.amount} ${e.currency.code}: ${e.reason}',
        type: 'expense_added',
        actor: by,
        targetId: ref.id,
        targetType: 'expense',
      );
    }
  }

  Future<void> delete(AppUser by, Expense e) async {
    final db = _db;
    if (db == null) return;
    final ref = _col(by.adminUid).doc(e.id);
    final before =
        (await ref.get().timeout(HistoryLogger.operationTimeout)).data() ??
            e.toMap();
    final batch = db.batch();
    batch.delete(ref);
    CashboxService.registerExpense(
      batch: batch,
      db: db,
      actor: by,
      adminUid: by.adminUid,
      expense: e,
      expenseId: e.id,
      reverse: true,
    );
    batch.set(
      _logger.newEventRef(by),
      _logger.eventData(
        actor: by,
        action: 'expense.delete',
        targetType: 'expense',
        targetId: e.id,
        summary: 'Deleted expense ${e.amount} ${e.currency.code}: ${e.reason}',
        before: before,
      ),
    );
    await batch.commit().timeout(HistoryLogger.operationTimeout);
  }

  Stream<List<ExpenseDeleteRequest>> watchDeleteRequests(String adminUid,
      {PaymentRequestStatus? status}) {
    if (_db == null) return const Stream.empty();
    Query<Map<String, dynamic>> q =
        _deleteReqCol(adminUid).orderBy('createdAt', descending: true);
    if (status != null) q = q.where('status', isEqualTo: status.name);
    return q
        .snapshots()
        .map((s) => s.docs.map(ExpenseDeleteRequest.fromDoc).toList());
  }

  Future<void> createDeleteRequest(AppUser by, Expense e) async {
    final db = _db;
    if (db == null) return;
    final request = ExpenseDeleteRequest(
      id: '',
      expenseId: e.id,
      expenseReason: e.reason,
      amount: e.amount,
      currency: e.currency,
      byEmployeeUid: by.uid,
      byEmployeeName:
          by.displayName.trim().isEmpty ? by.role.name : by.displayName.trim(),
      status: PaymentRequestStatus.pending,
      createdAt: DateTime.now(),
    );
    final requestRef = _deleteReqCol(by.adminUid).doc();
    final batch = db.batch();
    batch.set(requestRef, request.toMap());
    batch.set(
      _logger.newEventRef(by),
      _logger.eventData(
        actor: by,
        action: 'expense.delete.request',
        targetType: 'expenseDeleteRequest',
        targetId: requestRef.id,
        summary:
            'Requested deleting expense ${e.amount} ${e.currency.code}: ${e.reason}',
        after: request.toMap(),
      ),
    );
    await batch.commit().timeout(HistoryLogger.operationTimeout);

    if (_notificationsRepo != null) {
      await _notificationsRepo.sendNotification(
        adminUid: by.adminUid,
        recipientUid: 'admin',
        title: 'طلب حذف مصروف جديد',
        body:
            'طلب الموظف ${by.displayName} حذف مصروف بقيمة ${e.amount} ${e.currency.code}: ${e.reason}.',
        type: 'expense_delete',
        actor: by,
        targetId: requestRef.id,
        targetType: 'expense_delete_request',
      );
    }
  }

  Future<void> decideDeleteRequest(AppUser by, ExpenseDeleteRequest request,
      PaymentRequestStatus decision) async {
    final db = _db;
    if (db == null) return;
    final requestRef = _deleteReqCol(by.adminUid).doc(request.id);
    final expenseRef = _col(by.adminUid).doc(request.expenseId);
    final expenseSnap =
        await expenseRef.get().timeout(HistoryLogger.operationTimeout);
    final before = expenseSnap.data();

    final batch = db.batch();
    batch.update(requestRef, {
      'status': decision.name,
      'decidedAt': FieldValue.serverTimestamp(),
      'decidedBy': by.uid,
    });

    if (decision == PaymentRequestStatus.approved && before != null) {
      batch.delete(expenseRef);
      final deletedExpense = Expense.fromDoc(expenseSnap);
      CashboxService.registerExpense(
        batch: batch,
        db: db,
        actor: by,
        adminUid: by.adminUid,
        expense: deletedExpense,
        expenseId: deletedExpense.id,
        reverse: true,
      );
    }

    batch.set(
      _logger.newEventRef(by),
      _logger.eventData(
        actor: by,
        action: decision == PaymentRequestStatus.approved
            ? 'expense.delete.approve'
            : 'expense.delete.reject',
        targetType: before == null ? 'expenseDeleteRequest' : 'expense',
        targetId: before == null ? request.id : request.expenseId,
        summary:
            '${decision.name.toUpperCase()} delete request for ${request.expenseReason}',
        before: before,
        after: before == null
            ? {
                ...request.toMap(),
                'status': decision.name,
                'decidedAt': Timestamp.fromDate(DateTime.now()),
                'decidedBy': by.uid,
              }
            : null,
      ),
    );
    await batch.commit().timeout(HistoryLogger.operationTimeout);

    if (_notificationsRepo != null) {
      final isApproved = decision == PaymentRequestStatus.approved;
      await _notificationsRepo.sendNotification(
        adminUid: by.adminUid,
        recipientUid: request.byEmployeeUid,
        title: isApproved
            ? 'تمت الموافقة على طلب حذف المصروف'
            : 'تم رفض طلب حذف المصروف',
        body: isApproved
            ? 'وافق المدير على حذف المصروف بقيمة ${request.amount} ${request.currency.code}.'
            : 'تم رفض طلب حذف المصروف بقيمة ${request.amount} ${request.currency.code}.',
        type: isApproved ? 'expense_deleted' : 'expense_delete_rejected',
        actor: by,
        targetId: request.id,
        targetType: 'expense_delete_request',
      );
    }
  }
}

final expensesRepositoryProvider = Provider<ExpensesRepository>(
  (ref) => ExpensesRepository(
    ref.watch(firestoreProvider),
    ref.watch(historyLoggerProvider),
    ref.watch(notificationsRepositoryProvider),
    ref.watch(firebaseStorageProvider),
  ),
);

final expensesStreamProvider =
    StreamProvider.autoDispose.family<List<Expense>, String>((ref, adminUid) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return const Stream.empty();
  return ref.watch(expensesRepositoryProvider).watchAll(adminUid);
});
