import 'package:flutter_test/flutter_test.dart';
import 'package:isp_user_manager/core/constants.dart';
import 'package:isp_user_manager/core/models/models.dart';
import 'package:isp_user_manager/core/services/cashbox_service.dart';
import 'package:isp_user_manager/features/finance/cashbox_repository.dart';

void main() {
  group('CashboxSnapshot debt normalization', () {
    test('returns exact debt when positive and 0 when zero or tiny epsilon', () {
      final keyIqd = CashboxService.debtKey('emp_1', AppCurrency.iqd);
      final keyUsd = CashboxService.debtKey('emp_1', AppCurrency.usd);

      final snapshot = CashboxSnapshot(
        balances: {'IQD': 50000, 'USD': 100},
        staffDebtToCashbox: {
          keyIqd: 25000,
          keyUsd: 0.00001, // floating-point artifact after full settlement
        },
        cashboxDebtToStaff: {
          keyIqd: 0,
          keyUsd: 15,
        },
      );

      // Positive debt
      expect(snapshot.staffDebtToCashboxForUid('emp_1', AppCurrency.iqd), 25000);
      // Settled / epsilon debt cleanly disappears
      expect(snapshot.staffDebtToCashboxForUid('emp_1', AppCurrency.usd), 0);
      // Cashbox debt to staff
      expect(snapshot.cashboxDebtToStaffForUid('emp_1', AppCurrency.iqd), 0);
      expect(snapshot.cashboxDebtToStaffForUid('emp_1', AppCurrency.usd), 15);
    });
  });

  group('CashboxLedgerEntry getters', () {
    test('identifies personal pocket vs cashbox source accurately', () {
      final pocketEntry = CashboxLedgerEntry(
        id: '1',
        kind: 'supplierRecharge',
        effect: 'cashboxDebtToStaffIncrease',
        amount: 20000,
        currency: AppCurrency.iqd,
        actorUid: 'emp_1',
        actorName: 'Ali',
        actorRole: 'employee',
        paidFrom: 'personal',
        createdAt: DateTime.now(),
      );

      expect(pocketEntry.isPaidFromPersonal, isTrue);
      expect(pocketEntry.isPaidFromCashbox, isFalse);
      expect(pocketEntry.isCustodyPayment, isFalse);

      final custodyPaymentEntry = CashboxLedgerEntry(
        id: '2',
        kind: 'subscriptionPayment',
        effect: 'staffDebtToCashboxIncrease',
        amount: 35000,
        currency: AppCurrency.iqd,
        actorUid: 'emp_1',
        actorName: 'Ali',
        actorRole: 'employee',
        paidFrom: 'personal',
        createdAt: DateTime.now(),
      );

      expect(custodyPaymentEntry.isCustodyPayment, isTrue);
      expect(custodyPaymentEntry.isPaidFromCashbox, isFalse);

      final cashboxSettlement = CashboxLedgerEntry(
        id: '3',
        kind: 'staffSettlement',
        effect: 'cashboxIncrease_staffDebtToCashboxDecrease',
        amount: 35000,
        currency: AppCurrency.iqd,
        actorUid: 'admin_1',
        actorName: 'Admin',
        actorRole: 'admin',
        createdAt: DateTime.now(),
      );

      expect(cashboxSettlement.isSettlement, isTrue);
      expect(cashboxSettlement.isDirectCashIncrease, isTrue);
    });
  });
}

