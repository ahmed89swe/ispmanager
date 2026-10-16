import 'package:flutter_test/flutter_test.dart';
import 'package:isp_user_manager/core/utils/auth_utils.dart';

void main() {
  group('buildEmployeeEmail', () {
    test('produces deterministic email regardless of casing and whitespace', () {
      final email1 = buildEmployeeEmail(
        adminEmail: 'Admin@Example.com ',
        username: ' Ahmed ',
      );
      final email2 = buildEmployeeEmail(
        adminEmail: 'admin@example.com',
        username: 'ahmed',
      );

      expect(email1, equals(email2));
      expect(email1.startsWith('emp_'), isTrue);
      expect(email1.endsWith('@isp-app.local'), isTrue);
    });

    test('handles Arabic usernames seamlessly without crashing or empty strings', () {
      final emailArabic1 = buildEmployeeEmail(
        adminEmail: 'manager@isp.com',
        username: 'علي حسن',
      );
      final emailArabic2 = buildEmployeeEmail(
        adminEmail: 'manager@isp.com',
        username: 'كرار',
      );

      expect(emailArabic1.startsWith('emp_'), isTrue);
      expect(emailArabic2.startsWith('emp_'), isTrue);
      expect(emailArabic1, isNot(equals(emailArabic2)));
    });

    test('distinguishes between different admins with the same username', () {
      final empAdminA = buildEmployeeEmail(
        adminEmail: 'adminA@example.com',
        username: 'samir',
      );
      final empAdminB = buildEmployeeEmail(
        adminEmail: 'adminB@example.com',
        username: 'samir',
      );

      expect(empAdminA, isNot(equals(empAdminB)));
    });
  });
}

