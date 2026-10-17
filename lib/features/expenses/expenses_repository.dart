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

  DocumentReference<Map<String, dynamic>> _recurringDoc(String adminUid) =>
      _db!.collection('admins').doc(adminUid).collection('finance').doc('recurring_expenses');

  Stream<List<RecurringExpense>> watchRecurringExpenses(String adminUid) {
    if (_db == null) return const Stream.empty();
    return _recurringDoc(adminUid).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return <RecurringExpense>[];
      final rawItems = data['items'];
      if (rawItems is! Map) return <RecurringExpense>[];
      final list = <RecurringExpense>[];
      for (final entry in rawItems.entries) {
        final k = entry.key.toString();
        final v = entry.value;
        if (v is Map) {
          list.add(
            RecurringExpense.fromMap(k, Map<String, dynamic>.from(v)),
          );
        }
      }
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  Future<void> saveRecurringExpense(AppUser by, RecurringExpense item) async {
    final db = _db;
    if (db == null) return;
    final id = item.id.isEmpty ? const Uuid().v4() : item.id;
    final toSave = RecurringExpense(
      id: id,
      title: item.title,
      category: item.category,
      isFixedAmount: item.isFixedAmount,
      defaultAmount: item.defaultAmount,
      currency: item.currency,
      note: item.note,
      createdAt: item.createdAt,
      paidMonths: item.paidMonths,
    );
    await _recurringDoc(by.adminUid).set(
      {
        'items': {
          id: toSave.toMap(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    ).timeout(HistoryLogger.operationTimeout);
  }

  Future<void> deleteRecurringExpense(AppUser by, String recurringId) async {
    final db = _db;
    if (db == null) return;
    final docRef = _recurringDoc(by.adminUid);
    final snap = await docRef.get().timeout(HistoryLogger.operationTimeout);
    if (!snap.exists) return;
    await docRef.update({
      FieldPath(['items', recurringId]): FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }).timeout(HistoryLogger.operationTimeout);
  }

  Future<void> payRecurringExpenseMonth({
    required AppUser by,
    required RecurringExpense item,
    required int year,
    required int month,
    required num amount,
    required MoneyStorage paidFrom,
  }) async {
    final db = _db;
    if (db == null) return;
    final now = DateTime.now();
    final expRef = _col(by.adminUid).doc();
    final monthKey = RecurringExpense.monthKey(year, month);
    final actorName =
        by.displayName.trim().isEmpty ? by.role.name : by.displayName.trim();

    final existingPayment = item.paymentFor(year, month);
    final batch = db.batch();

    // If this month was already paid (editing/correcting an existing payment),
    // reverse the previous expense and cashbox entry first.
    if (existingPayment != null) {
      Expense? oldExpense;
      if (existingPayment.expenseId != null &&
          existingPayment.expenseId!.isNotEmpty) {
        final oldRef = _col(by.adminUid).doc(existingPayment.expenseId);
        final oldSnap =
            await oldRef.get().timeout(HistoryLogger.operationTimeout);
        if (oldSnap.exists) {
          oldExpense = Expense.fromDoc(oldSnap);
          if (by.isAdmin) {
            batch.delete(oldRef);
          }
        }
      }
      oldExpense ??= Expense(
        id: existingPayment.expenseId ?? '',
        type: ExpenseEntryType.expense,
        amount: existingPayment.amount,
        currency: existingPayment.currency,
        paidFrom: existingPayment.paidFrom,
        category: item.category,
        reason: '${item.title} - شهر $month/$year',
        date: existingPayment.paidAt,
        recordedBy: existingPayment.paidBy,
        recordedByName: existingPayment.paidByName,
        recurringId: item.id,
        billingYear: year,
        billingMonth: month,
      );
      CashboxService.registerExpense(
        batch: batch,
        db: db,
        actor: by,
        adminUid: by.adminUid,
        expense: oldExpense,
        expenseId: oldExpense.id,
        reverse: true,
      );
    }

    final expense = Expense(
      id: expRef.id,
      type: ExpenseEntryType.expense,
      amount: amount,
      currency: item.currency,
      paidFrom: paidFrom,
      category: item.category,
      reason: '${item.title} - شهر $month/$year',
      date: now,
      recordedBy: by.uid,
      recordedByName: actorName,
      recordedByRole: by.role,
      recurringId: item.id,
      billingYear: year,
      billingMonth: month,
    );

    final paymentRecord = RecurringExpenseMonthPayment(
      year: year,
      month: month,
      amount: amount,
      currency: item.currency,
      paidFrom: paidFrom,
      paidAt: now,
      paidBy: by.uid,
      paidByName: actorName,
      expenseId: expRef.id,
    );

    final updatedPaidMonths =
        Map<String, RecurringExpenseMonthPayment>.from(item.paidMonths)
          ..[monthKey] = paymentRecord;
    final updatedItem = RecurringExpense(
      id: item.id,
      title: item.title,
      category: item.category,
      isFixedAmount: item.isFixedAmount,
      defaultAmount: item.defaultAmount,
      currency: item.currency,
      note: item.note,
      createdAt: item.createdAt,
      paidMonths: updatedPaidMonths,
    );

    batch.set(expRef, expense.toMap());
    CashboxService.registerExpense(
      batch: batch,
      db: db,
      actor: by,
      adminUid: by.adminUid,
      expense: expense,
      expenseId: expRef.id,
    );
    batch.set(
      _recurringDoc(by.adminUid),
      {
        'items': {
          item.id: updatedItem.toMap(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      _logger.newEventRef(by),
      _logger.eventData(
        actor: by,
        action: existingPayment != null
            ? 'expense.recurring.edit'
            : 'expense.recurring.pay',
        targetType: 'expense',
        targetId: expRef.id,
        summary: existingPayment != null
            ? 'Edited recurring expense ${item.title} ($month/$year): $amount ${item.currency.code}'
            : 'Paid recurring expense ${item.title} ($month/$year): $amount ${item.currency.code}',
        after: expense.toMap(),
      ),
    );
    await batch.commit().timeout(HistoryLogger.operationTimeout);

    if (!by.isAdmin && _notificationsRepo != null) {
      await _notificationsRepo.sendNotification(
        adminUid: by.adminUid,
        recipientUid: 'admin',
        title: existingPayment != null
            ? 'تعديل تسديد مصروف شهري ثابت'
            : 'تسديد مصروف شهري ثابت',
        body:
            'قام الموظف ${by.displayName} بتسديد المصروف الشهري (${item.title} - شهر $month/$year) بقيمة $amount ${item.currency.code}',
        type: 'expense_added',
        actor: by,
        targetId: expRef.id,
        targetType: 'expense',
      );
    }
  }

  Future<void> unpayRecurringExpenseMonth({
    required AppUser by,
    required RecurringExpense item,
    required int year,
    required int month,
  }) async {
    final db = _db;
    if (db == null) return;
    final monthKey = RecurringExpense.monthKey(year, month);
    final payment = item.paymentFor(year, month);
    final batch = db.batch();

    Expense? reversedExpense;
    if (payment?.expenseId != null && payment!.expenseId!.isNotEmpty) {
      final expRef = _col(by.adminUid).doc(payment.expenseId);
      final expSnap =
          await expRef.get().timeout(HistoryLogger.operationTimeout);
      if (expSnap.exists) {
        reversedExpense = Expense.fromDoc(expSnap);
        if (by.isAdmin) {
          batch.delete(expRef);
        }
      }
    }

    if (reversedExpense == null && payment != null) {
      reversedExpense = Expense(
        id: payment.expenseId ?? '',
        type: ExpenseEntryType.expense,
        amount: payment.amount,
        currency: payment.currency,
        paidFrom: payment.paidFrom,
        category: item.category,
        reason: '${item.title} - شهر $month/$year',
        date: payment.paidAt,
        recordedBy: payment.paidBy,
        recordedByName: payment.paidByName,
        recurringId: item.id,
        billingYear: year,
        billingMonth: month,
      );
    }

    if (reversedExpense != null) {
      CashboxService.registerExpense(
        batch: batch,
        db: db,
        actor: by,
        adminUid: by.adminUid,
        expense: reversedExpense,
        expenseId: reversedExpense.id,
        reverse: true,
      );
    }

    final updatedPaidMonths =
        Map<String, RecurringExpenseMonthPayment>.from(item.paidMonths)
          ..remove(monthKey);
    final updatedItem = RecurringExpense(
      id: item.id,
      title: item.title,
      category: item.category,
      isFixedAmount: item.isFixedAmount,
      defaultAmount: item.defaultAmount,
      currency: item.currency,
      note: item.note,
      createdAt: item.createdAt,
      paidMonths: updatedPaidMonths,
    );

    final recDocRef = _recurringDoc(by.adminUid);
    batch.update(recDocRef, {
      'items.${item.id}': updatedItem.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(
      _logger.newEventRef(by),
      _logger.eventData(
        actor: by,
        action: 'expense.recurring.unpay',
        targetType: 'expense',
        targetId: reversedExpense?.id ?? item.id,
        summary:
            'Unpaid recurring expense ${item.title} ($month/$year)',
        before: reversedExpense?.toMap(),
      ),
    );

    await batch.commit().timeout(HistoryLogger.operationTimeout);
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
    if (e.recurringId != null &&
        e.billingYear != null &&
        e.billingMonth != null) {
      final mKey = RecurringExpense.monthKey(e.billingYear!, e.billingMonth!);
      batch.update(_recurringDoc(by.adminUid), {
        'items.${e.recurringId}.paidMonths.$mKey': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
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
      if (deletedExpense.recurringId != null &&
          deletedExpense.billingYear != null &&
          deletedExpense.billingMonth != null) {
        final mKey = RecurringExpense.monthKey(
            deletedExpense.billingYear!, deletedExpense.billingMonth!);
        batch.update(_recurringDoc(by.adminUid), {
          'items.${deletedExpense.recurringId}.paidMonths.$mKey':
              FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
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

final recurringExpensesStreamProvider = StreamProvider.autoDispose
    .family<List<RecurringExpense>, String>((ref, adminUid) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return const Stream.empty();
  return ref.watch(expensesRepositoryProvider).watchRecurringExpenses(adminUid);
});
