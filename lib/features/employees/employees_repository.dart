import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants.dart';
import '../../core/firebase_service.dart';
import '../../core/models/models.dart';
import '../../core/utils/auth_utils.dart';
import '../history/history_repository.dart';
import '../notifications/notifications_repository.dart';

class EmployeesRepository {
  EmployeesRepository(
    this._db,
    this._logger, [
    this._notificationsRepo,
    this._storage,
  ]);
  final FirebaseFirestore? _db;
  final HistoryLogger _logger;
  final NotificationsRepository? _notificationsRepo;
  final FirebaseStorage? _storage;

  CollectionReference<Map<String, dynamic>> _col(String adminUid) =>
      _db!.collection('admins').doc(adminUid).collection('employees');

  Stream<List<Employee>> watchAll(String adminUid) {
    if (_db == null || adminUid.trim().isEmpty) {
      return Stream.value(const <Employee>[]);
    }
    return _col(adminUid).orderBy('username').snapshots().map(
          (s) => s.docs.map(Employee.fromDoc).toList(),
        );
  }

  /// Creates an employee Auth account and Firestore document.
  /// Uses a secondary FirebaseApp to create the Auth user without signing out the admin,
  /// completely bypassing Cloud Functions to work seamlessly without Google Cloud Billing.
  Future<void> create(
    AppUser by, {
    required String username,
    required String displayName,
    required String password,
    required Set<Permission> permissions,
  }) async {
    if (_db == null) throw StateError('Firebase is not available');

    final cleanUsername = username.trim();
    if (cleanUsername.length < 2) {
      throw 'اسم المستخدم يجب أن يكون حرفين على الأقل';
    }
    if (password.length < 6) {
      throw 'كلمة المرور يجب أن تتكون من 6 أحرف على الأقل';
    }

    final adminUid = by.adminUid;
    var adminEmail = by.email?.trim().toLowerCase();
    if (adminEmail == null || adminEmail.isEmpty) {
      final adminDoc = await _db.collection('admins').doc(adminUid).get();
      adminEmail =
          (adminDoc.data()?['email'] as String?)?.trim().toLowerCase();
    }
    if (adminEmail == null || adminEmail.isEmpty) {
      throw 'تعذر العثور على البريد الإلكتروني للمدير لإتمام عملية الربط';
    }

    // Check if username already exists for this admin in Firestore
    final existing = await _col(adminUid)
        .where('username', isEqualTo: cleanUsername)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw 'اسم المستخدم مستخدم بالفعل لدى موظف آخر';
    }

    final email = buildEmployeeEmail(
      adminEmail: adminEmail,
      username: cleanUsername,
    );

    // Create Firebase Auth user using a secondary FirebaseApp instance
    final appName = 'EmpCreator_${DateTime.now().microsecondsSinceEpoch}';
    FirebaseApp? secondaryApp;
    String empUid;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      try {
        final cred = await secondaryAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (cred.user == null) {
          throw 'تعذر إنشاء حساب الموظف';
        }
        empUid = cred.user!.uid;
        await cred.user!.updateDisplayName(displayName);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // If auth user was created in a previous session, reuse it if credentials match
          try {
            final cred = await secondaryAuth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            empUid = cred.user!.uid;
            await cred.user!.updateDisplayName(displayName);
          } catch (_) {
            throw 'حساب الموظف مسجل مسبقاً. يرجى اختيار اسم مستخدم مختلف أو استخدام كلمة المرور السابقة';
          }
        } else if (e.code == 'weak-password') {
          throw 'كلمة المرور ضعيفة جداً';
        } else {
          rethrow;
        }
      }
    } finally {
      await secondaryApp?.delete();
    }

    // Save employee document in Firestore under /admins/{adminUid}/employees/{empUid}
    final empRef = _col(adminUid).doc(empUid);
    await empRef.set({
      'uid': empUid,
      'username': cleanUsername,
      'email': email,
      'displayName': displayName,
      'permissions': permissions.map((p) => p.name).toList(),
      'active': true,
      'photoUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _logger.log(
      actor: by,
      action: 'employee.create',
      targetType: 'employee',
      targetId: empUid,
      summary: 'Created employee $cleanUsername',
      after: {
        'username': cleanUsername,
        'displayName': displayName,
        'permissions': permissions.map((p) => p.name).toList(),
      },
    );
  }

  Future<void> updatePermissions(
      AppUser by, Employee emp, Set<Permission> permissions) async {
    final ref = _col(by.adminUid).doc(emp.id);
    final before = (await ref.get()).data();
    await ref.update({
      'permissions': permissions.map((p) => p.name).toList(),
    });
    await _logger.log(
      actor: by,
      action: 'employee.update',
      targetType: 'employee',
      targetId: emp.id,
      summary: 'Updated permissions for ${emp.username}',
      before: before,
      after: {
        ...emp.toMap(),
        'permissions': permissions.map((p) => p.name).toList(),
      },
    );

    if (_notificationsRepo != null) {
      await _notificationsRepo.sendNotification(
        adminUid: by.adminUid,
        recipientUid: emp.uid,
        title: 'تحديث صلاحيات الحساب',
        body: 'قام المدير بتحديث صلاحيات الوصول الخاصة بك.',
        type: 'permissions_updated',
        actor: by,
        targetId: emp.id,
        targetType: 'employee',
      );
    }
  }

  Future<void> setActive(AppUser by, Employee emp, bool active) async {
    final ref = _col(by.adminUid).doc(emp.id);
    final before = (await ref.get()).data();
    await ref.update({'active': active});
    await _logger.log(
      actor: by,
      action: active ? 'employee.enable' : 'employee.disable',
      targetType: 'employee',
      targetId: emp.id,
      summary: '${active ? 'Enabled' : 'Disabled'} ${emp.username}',
      before: before,
      after: {...emp.toMap(), 'active': active},
    );

    if (_notificationsRepo != null) {
      await _notificationsRepo.sendNotification(
        adminUid: by.adminUid,
        recipientUid: emp.uid,
        title: active ? 'تفعيل الحساب' : 'إيقاف الحساب',
        body: active
            ? 'قام المدير بتفعيل حسابك.'
            : 'قام المدير بإيقاف حسابك مؤقتاً.',
        type: 'account_status',
        actor: by,
        targetId: emp.id,
        targetType: 'employee',
      );
    }
  }

  Future<void> delete(AppUser by, Employee emp) async {
    // 1. Delete employee document directly from Firestore
    await _col(by.adminUid).doc(emp.id).delete();

    // 2. Log audit history
    await _logger.log(
      actor: by,
      action: 'employee.delete',
      targetType: 'employee',
      targetId: emp.id,
      summary: 'Deleted employee ${emp.username}',
      before: emp.toMap(),
    );
  }

  Future<String> uploadAvatar(AppUser by, Employee emp, XFile file) async {
    final bytes = await file.readAsBytes();
    final mime = _imageContentType(file.name);
    final b64 = base64Encode(bytes);
    final base64Url = 'data:$mime;base64,$b64';
    String photoUrl = base64Url;

    if (_storage != null) {
      try {
        final ref = _storage.ref('users/${emp.uid}/avatar.jpg');
        await ref.putData(
          bytes,
          SettableMetadata(contentType: mime),
        );
        if (!kIsWeb) {
          photoUrl = await ref.getDownloadURL();
        }
      } catch (e) {
        debugPrint(
            'Firebase Storage upload warning for employee (using Base64 data URL): $e');
      }
    }

    await _col(by.adminUid).doc(emp.id).update({'photoUrl': photoUrl});
    await _logger.log(
      actor: by,
      action: 'employee.update_photo',
      targetType: 'employee',
      targetId: emp.id,
      summary: 'Updated photo for employee ${emp.username}',
    );
    return photoUrl;
  }

  Future<void> removeAvatar(AppUser by, Employee emp) async {
    if (_storage != null) {
      try {
        await _storage.ref('users/${emp.uid}/avatar.jpg').delete();
      } catch (_) {}
    }
    await _col(by.adminUid).doc(emp.id).update({'photoUrl': null});
    await _logger.log(
      actor: by,
      action: 'employee.remove_photo',
      targetType: 'employee',
      targetId: emp.id,
      summary: 'Removed photo for employee ${emp.username}',
    );
  }

  String _imageContentType(String path) {
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.png')) return 'image/png';
    if (lowerPath.endsWith('.webp')) return 'image/webp';
    if (lowerPath.endsWith('.gif')) return 'image/gif';
    if (lowerPath.endsWith('.heic')) return 'image/heic';
    if (lowerPath.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }
}

final employeesRepositoryProvider = Provider<EmployeesRepository>(
  (ref) => EmployeesRepository(
    ref.watch(firestoreProvider),
    ref.watch(historyLoggerProvider),
    ref.watch(notificationsRepositoryProvider),
    ref.watch(firebaseStorageProvider),
  ),
);

final employeesStreamProvider =
    StreamProvider.family<List<Employee>, String>((ref, adminUid) {
  if (adminUid.trim().isEmpty) return Stream.value(const <Employee>[]);
  return ref.watch(employeesRepositoryProvider).watchAll(adminUid);
});
