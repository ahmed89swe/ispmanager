import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants.dart';
import '../models/models.dart';

class CashboxService {
  static const cashboxDocId = 'cashbox';

  static DocumentReference<Map<String, dynamic>> cashboxRef(
    FirebaseFirestore db,
    String adminUid,
  ) {
    return db
        .collection('admins')
        .doc(adminUid)
        .collection('finance')
        .doc(cashboxDocId);
  }

  static CollectionReference<Map<String, dynamic>> ledgerCol(
    FirebaseFirestore db,
    String adminUid,
  ) {
    return db
        .collection('admins')
        .doc(adminUid)
        .collection('finance')
        .doc(cashboxDocId)
        .collection('ledger');
  }

  static String debtKey(String uid, AppCurrency currency) =>
      '${uid}_${currency.code}';

  static Map<String, dynamic> initialData() => {
        'balances': {
          AppCurrency.iqd.code: 0,
          AppCurrency.usd.code: 0,
        },
        'staffDebtToCashbox': <String, num>{},
        'cashboxDebtToStaff': <String, num>{},
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static void ensureExists(
    WriteBatch batch,
    FirebaseFirestore db,
    String adminUid,
  ) {
    batch.set(
      cashboxRef(db, adminUid),
      initialData(),
      SetOptions(merge: true),
    );
  }

  static Map<String, dynamic> _updateMeta(AppUser actor) => {
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': actor.uid,
        'updatedByName': actor.displayName,
        'updatedByRole': actor.role.name,
      };

  static void registerSubscriptionPayment({
    required WriteBatch batch,
    required FirebaseFirestore db,
    required AppUser actor,
    required String adminUid,
    required Payment payment,
    required String paymentId,
    required String subscriberId,
    required String subscriberName,
  }) {
    final boxRef = cashboxRef(db, adminUid);
    final key = debtKey(actor.uid, payment.currency);
    final amt = payment.amount.toDouble();
    if (payment.receivedIn == MoneyStorage.cashbox) {
      batch.set(
        boxRef,
        {
          'balances.${payment.currency.code}': FieldValue.increment(amt),
          ..._updateMeta(actor),
        },
        SetOptions(merge: true),
      );
    } else {
      batch.set(
        boxRef,
        {
          'staffDebtToCashbox.$key': FieldValue.increment(amt),
          ..._updateMeta(actor),
        },
        SetOptions(merge: true),
      );
    }

    final ledgerRef = ledgerCol(db, adminUid).doc();
    batch.set(ledgerRef, {
      'kind': 'subscriptionPayment',
      'effect': payment.receivedIn == MoneyStorage.cashbox
          ? 'cashboxIncrease'
          : 'staffDebtToCashboxIncrease',
      'amount': payment.amount,
      'currency': payment.currency.code,
      'actorUid': actor.uid,
      'actorName': actor.displayName,
      'actorRole': actor.role.name,
      'subscriberId': subscriberId,
      'subscriberName': subscriberName,
      'paymentId': paymentId,
      'paidFrom': payment.receivedIn.name,
      'note': payment.note,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static void registerExpense({
    required WriteBatch batch,
    required FirebaseFirestore db,
    required AppUser actor,
    required String adminUid,
    required Expense expense,
    required String expenseId,
    bool reverse = false,
  }) {
    final boxRef = cashboxRef(db, adminUid);
    final key = debtKey(actor.uid, expense.currency);
    final signedAmount =
        reverse ? -expense.amount.toDouble() : expense.amount.toDouble();

    if (expense.paidFrom == MoneyStorage.cashbox) {
      batch.set(
        boxRef,
        {
          'balances.${expense.currency.code}':
              FieldValue.increment(-signedAmount),
          ..._updateMeta(actor),
        },
        SetOptions(merge: true),
      );
    } else {
      batch.set(
        boxRef,
        {
          'cashboxDebtToStaff.$key': FieldValue.increment(signedAmount),
          ..._updateMeta(actor),
        },
        SetOptions(merge: true),
      );
    }

    final ledgerRef = ledgerCol(db, adminUid).doc();
    batch.set(ledgerRef, {
      'kind': expense.type == ExpenseEntryType.withdrawal
          ? 'withdrawal'
          : 'expense',
      'effect': expense.paidFrom == MoneyStorage.cashbox
          ? (reverse ? 'cashboxIncreaseReversal' : 'cashboxDecrease')
          : (reverse
              ? 'cashboxDebtToStaffDecreaseReversal'
              : 'cashboxDebtToStaffIncrease'),
      'reverse': reverse,
      'amount': expense.amount,
      'currency': expense.currency.code,
      'actorUid': actor.uid,
      'actorName': actor.displayName,
      'actorRole': actor.role.name,
      'expenseId': expenseId,
      'reason': expense.reason,
      'paidFrom': expense.paidFrom.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static void registerSupplierPayment({
    required WriteBatch batch,
    required FirebaseFirestore db,
    required AppUser actor,
    required String adminUid,
    required String supplierId,
    required String supplierName,
    required num amount,
    required AppCurrency currency,
    MoneyStorage paidFrom = MoneyStorage.cashbox,
    String? note,
    String? transactionId,
    String kind = 'supplierPayment',
  }) {
    final boxRef = cashboxRef(db, adminUid);
    final key = debtKey(actor.uid, currency);
    final amt = amount.toDouble();

    if (paidFrom == MoneyStorage.cashbox) {
      batch.set(
        boxRef,
        {
          'balances.${currency.code}': FieldValue.increment(-amt),
          ..._updateMeta(actor),
        },
        SetOptions(merge: true),
      );
    } else {
      batch.set(
        boxRef,
        {
          'cashboxDebtToStaff.$key': FieldValue.increment(amt),
          ..._updateMeta(actor),
        },
        SetOptions(merge: true),
      );
    }

    final ledgerRef = ledgerCol(db, adminUid).doc();
    batch.set(ledgerRef, {
      'kind': kind,
      'effect': paidFrom == MoneyStorage.cashbox
          ? 'cashboxDecrease'
          : 'cashboxDebtToStaffIncrease',
      'amount': amount,
      'currency': currency.code,
      'actorUid': actor.uid,
      'actorName': actor.displayName,
      'actorRole': actor.role.name,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'paidFrom': paidFrom.name,
      'note': note,
      'paymentId': transactionId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static void settleStaffDebt({
    required WriteBatch batch,
    required FirebaseFirestore db,
    required AppUser actor,
    required String adminUid,
    required String staffUid,
    required String staffName,
    required num amount,
    required AppCurrency currency,
    required StaffSettlementDirection direction,
    String? note,
  }) {
    final boxRef = cashboxRef(db, adminUid);
    final key = debtKey(staffUid, currency);
    final amt = amount.toDouble();

    if (direction == StaffSettlementDirection.toCashbox) {
      batch.set(
        boxRef,
        {
          'balances.${currency.code}': FieldValue.increment(amt),
          'staffDebtToCashbox.$key': FieldValue.increment(-amt),
          ..._updateMeta(actor),
        },
        SetOptions(merge: true),
      );
    } else {
      batch.set(
        boxRef,
        {
          'balances.${currency.code}': FieldValue.increment(-amt),
          'cashboxDebtToStaff.$key': FieldValue.increment(-amt),
          ..._updateMeta(actor),
        },
        SetOptions(merge: true),
      );
    }

    final ledgerRef = ledgerCol(db, adminUid).doc();
    batch.set(ledgerRef, {
      'kind': direction == StaffSettlementDirection.toCashbox
          ? 'staffSettlement'
          : 'staffReimbursement',
      'effect': direction == StaffSettlementDirection.toCashbox
          ? 'cashboxIncrease_staffDebtDecrease'
          : 'cashboxDecrease_cashboxDebtDecrease',
      'amount': amount,
      'currency': currency.code,
      'actorUid': actor.uid,
      'actorName': actor.displayName,
      'actorRole': actor.role.name,
      'subscriberId': staffUid,
      'subscriberName': staffName,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static void registerDirectAdjustment({
    required WriteBatch batch,
    required FirebaseFirestore db,
    required AppUser actor,
    required String adminUid,
    required num amount,
    required AppCurrency currency,
    required bool isDeposit,
    required String reason,
    String? note,
  }) {
    final boxRef = cashboxRef(db, adminUid);
    final amt = amount.toDouble();
    final signedAmt = isDeposit ? amt : -amt;

    batch.set(
      boxRef,
      {
        'balances.${currency.code}': FieldValue.increment(signedAmt),
        ..._updateMeta(actor),
      },
      SetOptions(merge: true),
    );

    final ledgerRef = ledgerCol(db, adminUid).doc();
    batch.set(ledgerRef, {
      'kind': isDeposit ? 'manualDeposit' : 'manualWithdrawal',
      'effect': isDeposit ? 'cashboxIncrease' : 'cashboxDecrease',
      'amount': amount,
      'currency': currency.code,
      'actorUid': actor.uid,
      'actorName': actor.displayName,
      'actorRole': actor.role.name,
      'reason': reason,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
