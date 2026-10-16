import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase_options.dart';

class FirebaseService {
  static bool initialized = false;
  static bool isAvailable = false;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);

      if (!kIsWeb) {
        final messaging = FirebaseMessaging.instance;
        await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      isAvailable = true;
    } catch (e) {
      debugPrint('Firebase init failed: $e');
      isAvailable = false;
    }
    initialized = true;
  }
}

final firebaseAvailableProvider =
    Provider<bool>((ref) => FirebaseService.isAvailable);

final firebaseAuthProvider = Provider<FirebaseAuth?>((ref) {
  return FirebaseService.isAvailable ? FirebaseAuth.instance : null;
});

final firestoreProvider = Provider<FirebaseFirestore?>((ref) {
  return FirebaseService.isAvailable ? FirebaseFirestore.instance : null;
});

final firebaseStorageProvider = Provider<FirebaseStorage?>((ref) {
  return FirebaseService.isAvailable ? FirebaseStorage.instance : null;
});

final firebaseMessagingProvider = Provider<FirebaseMessaging?>((ref) {
  return FirebaseService.isAvailable && !kIsWeb
      ? FirebaseMessaging.instance
      : null;
});
