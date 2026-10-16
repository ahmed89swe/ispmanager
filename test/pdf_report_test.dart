import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:isp_user_manager/core/constants.dart';
import 'package:isp_user_manager/core/models/models.dart';
import 'package:isp_user_manager/core/services/pdf_report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  test('buildSubscriberStatementPdf generates valid bytes with mixed Arabic and Latin text', () async {
    final sub = Subscriber(
      id: 'sub_1',
      name: 'hhhh',
      phone: '07701234567',
      monthlyFee: 40000,
      currency: AppCurrency.iqd,
      balance: 10000,
      status: SubscriberStatus.active,
      supplierId: 'sup_1',
      supplierName: 'liwss',
      packageName: 'evo',
      joinedAt: DateTime.now().subtract(const Duration(days: 30)),
      subscriptionEndsAt: DateTime.now().add(const Duration(days: 30)),
    );

    final debts = <SubscriberDebt>[
      SubscriberDebt(
        id: 'd_1',
        subscriberId: 'sub_1',
        amount: 40000,
        currency: AppCurrency.iqd,
        agentCost: 30000,
        periodStart: DateTime.now(),
        periodEnd: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        paidAmount: 30000,
        status: SubscriptionDebtStatus.partiallyPaid,
        packageName: 'evo',
        recordedBy: 'admin',
      ),
    ];

    final payments = <Payment>[
      Payment(
        id: 'p_1',
        subscriberId: 'sub_1',
        amount: 30000,
        currency: AppCurrency.iqd,
        receivedIn: MoneyStorage.cashbox,
        recordedBy: 'admin',
        recordedAt: DateTime.now(),
        note: 'الاشتراك الأول - تسديد جزئي',
      ),
    ];

    final bytes = await PdfReportService().buildSubscriberStatementPdf(
      subscriber: sub,
      debts: debts,
      payments: payments,
      generatedBy: 'admin',
      locale: 'ar',
    );

    expect(bytes, isNotNull);
    expect(bytes.length, greaterThan(1000));
  });

  test('buildSubscribersDebtReportPdf generates valid bytes without needing allDebts query', () async {
    final sub1 = Subscriber(
      id: 'sub_1',
      name: 'hhhh',
      phone: '07701234567',
      monthlyFee: 40000,
      currency: AppCurrency.iqd,
      balance: 40000,
      status: SubscriberStatus.overdue,
      supplierId: 'sup_1',
      supplierName: 'liwss',
      packageName: 'evo',
      joinedAt: DateTime.now().subtract(const Duration(days: 60)),
      subscriptionEndsAt: DateTime.now().subtract(const Duration(days: 2)),
    );

    final sub2 = Subscriber(
      id: 'sub_2',
      name: 'احمد',
      phone: '07801234567',
      monthlyFee: 35,
      currency: AppCurrency.usd,
      balance: 35,
      status: SubscriberStatus.active,
      supplierId: 'sup_2',
      supplierName: 'Earthlink',
      packageName: 'VIP',
      joinedAt: DateTime.now().subtract(const Duration(days: 15)),
      subscriptionEndsAt: DateTime.now().add(const Duration(days: 15)),
    );

    final bytes = await PdfReportService().buildSubscribersDebtReportPdf(
      subscribers: [sub1, sub2],
      generatedBy: 'ISP Manager',
      locale: 'ar',
    );

    expect(bytes, isNotNull);
    expect(bytes.length, greaterThan(1000));
  });
}
