import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants.dart';
import '../../core/firebase_service.dart';
import '../../core/models/models.dart';

class ProfileRepository {
  ProfileRepository(this._db, this._auth, this._storage);
  final FirebaseFirestore? _db;
  final FirebaseAuth? _auth;
  final FirebaseStorage? _storage;

  Future<String> uploadAvatar(AppUser user, XFile file) async {
    if (_storage == null || _db == null) {
      throw StateError('Firebase not configured');
    }
    final ref = _storage.ref('users/${user.uid}/avatar.jpg');
    final bytes = await file.readAsBytes();
    await ref.putData(
      bytes,
      SettableMetadata(contentType: _imageContentType(file.name)),
    );
    final url = await ref.getDownloadURL();
    await _writePhotoUrl(user, url);
    return url;
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

  Future<void> removeAvatar(AppUser user) async {
    if (_storage == null) return;
    try {
      await _storage.ref('users/${user.uid}/avatar.jpg').delete();
    } catch (_) {}
    await _writePhotoUrl(user, null);
  }

  Future<void> updateDisplayName(AppUser user, String displayName) async {
    if (_db == null) return;
    final docRef = user.role == UserRole.admin
        ? _db.collection('admins').doc(user.uid)
        : _db
            .collection('admins')
            .doc(user.adminUid)
            .collection('employees')
            .doc(user.uid);
    await docRef.set({'displayName': displayName}, SetOptions(merge: true));
    await _auth?.currentUser?.updateDisplayName(displayName);
  }

  Future<void> _writePhotoUrl(AppUser user, String? url) async {
    if (_db == null) return;
    final docRef = user.role == UserRole.admin
        ? _db.collection('admins').doc(user.uid)
        : _db
            .collection('admins')
            .doc(user.adminUid)
            .collection('employees')
            .doc(user.uid);
    await docRef.set({'photoUrl': url}, SetOptions(merge: true));
    await _auth?.currentUser?.updatePhotoURL(url);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
    ref.watch(firebaseStorageProvider),
  );
});
