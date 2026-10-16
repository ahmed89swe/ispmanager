import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Synthesizes a deterministic, unique, ASCII-safe internal email for an employee
/// based on the manager's email and the employee's username.
///
/// This works completely offline / client-side without Cloud Functions or billing.
String buildEmployeeEmail({
  required String adminEmail,
  required String username,
}) {
  final cleanAdmin = adminEmail.trim().toLowerCase();
  final cleanUser = username.trim().toLowerCase();
  final bytes = utf8.encode('$cleanAdmin:$cleanUser');
  final hash = sha256.convert(bytes).toString().substring(0, 20);
  return 'emp_$hash@isp-app.local';
}

