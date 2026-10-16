import 'package:flutter_test/flutter_test.dart';
import 'package:isp_user_manager/core/constants.dart';
import 'package:isp_user_manager/core/models/models.dart';

void main() {
  group('StaffReimbursementRequest model', () {
    test('serializes to Map correctly', () {
      final now = DateTime(2026, 10, 9, 14, 30);
      final req = StaffReimbursementRequest(
        id: 'req_123',
        amount: 50000,
        currency: AppCurrency.iqd,
        note: 'مصروف صيانة كوابل',
        byEmployeeUid: 'emp_01',
        byEmployeeName: 'أحمد',
        byEmployeeRole: UserRole.employee,
        status: PaymentRequestStatus.pending,
        createdAt: now,
      );

      final map = req.toMap();
      expect(map['amount'], 50000);
      expect(map['currency'], 'IQD');
      expect(map['note'], 'مصروف صيانة كوابل');
      expect(map['byEmployeeUid'], 'emp_01');
      expect(map['byEmployeeName'], 'أحمد');
      expect(map['byEmployeeRole'], 'employee');
      expect(map['status'], 'pending');
    });
  });

  group('ChatMessage model', () {
    test('serializes to Map and reads fields correctly', () {
      final now = DateTime(2026, 10, 9, 15, 0);
      final msg = ChatMessage(
        id: 'msg_01',
        senderUid: 'admin_1',
        senderName: 'المدير العام',
        senderRole: UserRole.admin,
        text: 'مرحباً، تم اعتماد الطلب بنجاح',
        imageUrl: 'https://storage.googleapis.com/test.jpg',
        createdAt: now,
        isRead: false,
      );

      final map = msg.toMap();
      expect(map['senderUid'], 'admin_1');
      expect(map['senderName'], 'المدير العام');
      expect(map['senderRole'], 'admin');
      expect(map['text'], 'مرحباً، تم اعتماد الطلب بنجاح');
      expect(map['imageUrl'], 'https://storage.googleapis.com/test.jpg');
      expect(map['isRead'], false);
    });
  });

  group('AppNotification model', () {
    test('serializes to Map and retains types', () {
      final now = DateTime(2026, 10, 9, 15, 30);
      final notif = AppNotification(
        id: 'notif_01',
        title: 'طلب سحب مستحقات جديد',
        body: 'قدم الموظف أحمد طلباً لصرف مستحقات',
        type: 'reimbursement_request',
        recipientUid: 'admin_1',
        actorUid: 'emp_01',
        actorName: 'أحمد',
        createdAt: now,
        isRead: false,
        targetId: 'req_123',
        targetType: 'reimbursement_request',
      );

      final map = notif.toMap();
      expect(map['title'], 'طلب سحب مستحقات جديد');
      expect(map['type'], 'reimbursement_request');
      expect(map['recipientUid'], 'admin_1');
      expect(map['actorUid'], 'emp_01');
      expect(map['targetId'], 'req_123');
      expect(map['isRead'], false);
    });
  });
}

