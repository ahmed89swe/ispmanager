import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
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
    if (_db == null) {
      throw StateError('Firebase not configured');
    }
    final bytes = await file.readAsBytes();
    String? photoUrl;

    if (_storage != null) {
      try {
        final ref = _storage.ref('users/${user.uid}/avatar.jpg');
        await ref.putData(
          bytes,
          SettableMetadata(contentType: _imageContentType(file.name)),
        );
        photoUrl = await ref.getDownloadURL();
      } catch (e) {
        debugPrint(
            'Firebase Storage upload failed (falling back to Base64 data URL): $e');
      }
    }

    if (photoUrl == null) {
      final mime = _imageContentType(file.name);
      final b64 = base64Encode(bytes);
      photoUrl = 'data:$mime;base64,$b64';
    }

    await _writePhotoUrl(user, photoUrl);
    return photoUrl;
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
    if (_storage != null) {
      try {
        await _storage.ref('users/${user.uid}/avatar.jpg').delete();
      } catch (_) {}
    }
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
    try {
      if (url == null || !url.startsWith('data:')) {
        await _auth?.currentUser?.updatePhotoURL(url);
      }
    } catch (_) {}
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
    ref.watch(firebaseStorageProvider),
  );
});
