import 'package:flutter_test/flutter_test.dart';
import 'package:isp_user_manager/core/constants.dart';
import 'package:isp_user_manager/core/models/models.dart';

void main() {
  group('Subscriber advance prepaid cycles', () {
    test('default prepaidCycles is 0', () {
      final sub = Subscriber(
        id: 'sub_1',
        name: 'Test Subscriber',
        monthlyFee: 35000,
        currency: AppCurrency.iqd,
        balance: 0,
        status: SubscriberStatus.active,
        joinedAt: DateTime(2026, 1, 1),
      );

      expect(sub.prepaidCycles, 0);
      expect(sub.toMap()['prepaidCycles'], 0);
    });

    test('copyWith updates prepaidCycles correctly', () {
      final sub = Subscriber(
        id: 'sub_1',
        name: 'Test Subscriber',
        monthlyFee: 35000,
        currency: AppCurrency.iqd,
        balance: 0,
        status: SubscriberStatus.active,
        joinedAt: DateTime(2026, 1, 1),
        prepaidCycles: 0,
      );

      final updated = sub.copyWith(prepaidCycles: 2);
      expect(updated.prepaidCycles, 2);
      expect(updated.toMap()['prepaidCycles'], 2);

      final decremented = updated.copyWith(prepaidCycles: updated.prepaidCycles - 1);
      expect(decremented.prepaidCycles, 1);
    });
  });
}

