import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/constants.dart';
import '../../core/firebase_service.dart';
import '../../core/models/models.dart';
import '../../core/utils/auth_utils.dart';

class AuthRepository {
  AuthRepository(this._auth, this._db);
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _db;

  Stream<User?> authStateChanges() =>
      _auth?.authStateChanges() ?? const Stream.empty();

  Future<AppUser?> currentAppUser() async {
    final user = _auth?.currentUser;
    if (user == null || _db == null) return null;
    return _resolve(user);
  }

  /// Reads a Firestore doc, retrying briefly on transient permission-denied
  /// errors that can occur right after sign-in while the auth token is
  /// still propagating to Firestore servers.
  Future<DocumentSnapshot<Map<String, dynamic>>> _getWithRetry(
      DocumentReference<Map<String, dynamic>> ref) async {
    FirebaseException? last;
    for (var i = 0; i < 5; i++) {
      try {
        return await ref.get();
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') rethrow;
        last = e;
        await Future.delayed(Duration(milliseconds: 200 * (i + 1)));
      }
    }
    throw last!;
  }

  Future<AppUser> _resolve(User user) async {
    // Force a token refresh
    final tokenResult = await user.getIdTokenResult(true);
    final claims = tokenResult.claims ?? {};
    final claimedAdminUid = claims['adminUid'] as String?;
    final claimedRole = claims['role'] as String?;

    if (claimedRole == 'employee' && claimedAdminUid != null) {
      return _resolveEmployee(user, claimedAdminUid);
    }

    // Check if user is an employee via collectionGroup
    // (Allowed by firestore.rules: match /{path=**}/employees/{empUid} { allow read: if isSignedIn() && (uid() == empUid || resource.data.uid == uid()); })
    if (_db != null) {
      try {
        final empQuery = await _db
            .collectionGroup('employees')
            .where('uid', isEqualTo: user.uid)
            .limit(1)
            .get();
        if (empQuery.docs.isNotEmpty) {
          final empDoc = empQuery.docs.first;
          final adminUid = empDoc.reference.parent.parent?.id;
          if (adminUid != null) {
            return await _resolveEmployee(user, adminUid);
          }
        }
      } catch (e) {
        debugPrint('Employee collectionGroup query: $e');
      }
    }

    // Otherwise treat as admin: read /admins/{user.uid}.
    final adminDoc =
        await _getWithRetry(_db!.collection('admins').doc(user.uid));
    if (!adminDoc.exists) {
      throw StateError('الحساب غير مسجل كمدير أو موظف.');
    }
    final d = adminDoc.data() ?? {};
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: (d['displayName'] ?? user.displayName ?? '') as String,
      role: UserRole.admin,
      adminUid: user.uid,
      permissions: Permission.all,
      photoUrl: (d['photoUrl'] ?? user.photoURL) as String?,
      fcmTokens: List<String>.from(d['fcmTokens'] ?? []),
      themeMode: d['themeMode'] as String?,
      webColorTheme: d['webColorTheme'] as String?,
    );
  }

  Future<AppUser> _resolveEmployee(User user, String adminUid) async {
    final empSnap = await _getWithRetry(_db!
        .collection('admins')
        .doc(adminUid)
        .collection('employees')
        .doc(user.uid));
    if (!empSnap.exists) {
      throw StateError('ملف الموظف غير موجود أو تم حذفه.');
    }
    final emp = Employee.fromDoc(empSnap);
    if (!emp.active) {
      throw StateError('تم إيقاف حساب هذا الموظف من قبل الإدارة.');
    }
    final empData = empSnap.data() ?? {};
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: emp.displayName,
      role: UserRole.employee,
      adminUid: adminUid,
      permissions: emp.permissions,
      photoUrl: emp.photoUrl,
      fcmTokens: List<String>.from(empData['fcmTokens'] ?? []),
      themeMode: empData['themeMode'] as String?,
      webColorTheme: empData['webColorTheme'] as String?,
    );
  }

  Future<AppUser> signInAdminWithGoogle() async {
    if (_auth == null || _db == null) {
      throw StateError('Firebase not configured');
    }
    final UserCredential result;
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      provider.setCustomParameters({'prompt': 'select_account'});
      result = await _auth.signInWithPopup(provider);
    } else {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) throw StateError('Cancelled');
      final googleAuth = await googleUser.authentication;
      final cred = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      result = await _auth.signInWithCredential(cred);
    }
    final user = result.user!;
    // Ensure admin doc exists
    final adminRef = _db.collection('admins').doc(user.uid);
    final snap = await adminRef.get();
    if (!snap.exists) {
      await adminRef.set({
        'email': user.email,
        'displayName': user.displayName ?? user.email?.split('@').first ?? '',
        'photoUrl': user.photoURL,
        'orgName': null,
        'orgLogoUrl': null,
        'defaultCurrency': AppCurrency.iqd.code,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return _resolve(user);
  }

  Future<AppUser> signInEmployee({
    required String adminEmail,
    required String username,
    required String password,
  }) async {
    if (_auth == null || _db == null) {
      throw StateError('Firebase not configured');
    }
    final cleanAdmin = adminEmail.trim().toLowerCase();
    final cleanUser = username.trim();
    if (cleanAdmin.isEmpty || cleanUser.isEmpty || password.isEmpty) {
      throw StateError('يرجى ملء جميع الحقول المطلوبة');
    }

    final empEmail = buildEmployeeEmail(
      adminEmail: cleanAdmin,
      username: cleanUser,
    );

    UserCredential cred;
    try {
      cred = await _auth.signInWithEmailAndPassword(
        email: empEmail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-email') {
        throw StateError(
            'بيانات الدخول غير صحيحة، تأكد من بريد المدير واسم المستخدم وكلمة المرور');
      }
      rethrow;
    }

    return _resolve(cred.user!);
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
    }
    await _auth?.signOut();
  }

  Future<void> addFcmToken(AppUser user, String token) async {
    final db = _db;
    if (db == null || token.trim().isEmpty) return;
    try {
      if (user.isAdmin) {
        await db.collection('admins').doc(user.uid).set({
          'fcmTokens': FieldValue.arrayUnion([token])
        }, SetOptions(merge: true));
      } else {
        await db
            .collection('admins')
            .doc(user.adminUid)
            .collection('employees')
            .doc(user.uid)
            .set({
          'fcmTokens': FieldValue.arrayUnion([token])
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  Future<void> updateFcmTokens(AppUser user, List<String> fcmTokens) async {
    final db = _db;
    if (db == null) return;
    try {
      if (user.isAdmin) {
        await db
            .collection('admins')
            .doc(user.uid)
            .set({'fcmTokens': fcmTokens}, SetOptions(merge: true));
      } else {
        await db
            .collection('admins')
            .doc(user.adminUid)
            .collection('employees')
            .doc(user.uid)
            .set({'fcmTokens': fcmTokens}, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error updating FCM tokens: $e');
    }
  }

  Stream<AppUser?> currentAppUserStream() {
    final auth = _auth;
    final db = _db;
    if (auth == null || db == null) return Stream.value(null);

    return auth.authStateChanges().asyncExpand((user) async* {
      if (user == null) {
        yield null;
        return;
      }

      AppUser? initialUser;
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          initialUser = await _resolve(user);
          break;
        } catch (e) {
          if (attempt == 2) {
            debugPrint('currentAppUserStream resolve error: $e');
            yield null;
            return;
          }
          await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
        }
      }

      if (initialUser == null) {
        yield null;
        return;
      }

      if (initialUser.isAdmin) {
        try {
          await for (final snap
              in db.collection('admins').doc(user.uid).snapshots()) {
            if (!snap.exists) {
              yield null;
              continue;
            }
            final d = snap.data() ?? {};
            yield AppUser(
              uid: user.uid,
              email: user.email,
              displayName:
                  (d['displayName'] ?? user.displayName ?? '') as String,
              role: UserRole.admin,
              adminUid: user.uid,
              permissions: Permission.all,
              photoUrl: (d['photoUrl'] ?? user.photoURL) as String?,
              fcmTokens: List<String>.from(d['fcmTokens'] ?? []),
              themeMode: d['themeMode'] as String?,
              webColorTheme: d['webColorTheme'] as String?,
            );
          }
        } catch (e) {
          debugPrint('Admin snapshots stream ended (signOut or error): $e');
          yield null;
        }
      } else {
        final adminUid = initialUser.adminUid;
        try {
          await for (final snap in db
              .collection('admins')
              .doc(adminUid)
              .collection('employees')
              .doc(user.uid)
              .snapshots()) {
            if (!snap.exists) {
              yield null;
              continue;
            }
            final emp = Employee.fromDoc(snap);
            if (!emp.active) {
              yield null;
              continue;
            }
            final empData = snap.data() ?? {};
            yield AppUser(
              uid: user.uid,
              email: user.email,
              displayName: emp.displayName,
              role: UserRole.employee,
              adminUid: adminUid,
              permissions: emp.permissions,
              photoUrl: emp.photoUrl,
              fcmTokens: List<String>.from(empData['fcmTokens'] ?? []),
              themeMode: empData['themeMode'] as String?,
              webColorTheme: empData['webColorTheme'] as String?,
            );
          }
        } catch (e) {
          debugPrint('Employee snapshots stream ended (signOut or error): $e');
          yield null;
        }
      }
    });
  }

  /// Persists the selected theme preference (mode and/or color palette)
  /// into the user's Firestore profile so it is loaded whenever they log in.
  Future<void> saveUserThemePreference({
    required AppUser user,
    String? themeMode,
    String? webColorTheme,
  }) async {
    if (_db == null) return;
    final updates = <String, dynamic>{
      if (themeMode != null) 'themeMode': themeMode,
      if (webColorTheme != null) 'webColorTheme': webColorTheme,
    };
    if (updates.isEmpty) return;
    try {
      if (user.isAdmin) {
        await _db.collection('admins').doc(user.uid).update(updates);
      } else {
        await _db
            .collection('admins')
            .doc(user.adminUid)
            .collection('employees')
            .doc(user.uid)
            .update(updates);
      }
    } catch (e) {
      debugPrint('Failed to save user theme preference to account: $e');
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  if (auth == null) return const Stream.empty();
  return auth.authStateChanges();
});

final currentAppUserProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).currentAppUserStream();
});
