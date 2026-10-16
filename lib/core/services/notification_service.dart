import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../firebase_service.dart';
import '../../core/models/models.dart';
import '../../features/auth/auth_repository.dart';

class NotificationService {
  final FirebaseMessaging? _messaging;
  final AuthRepository _authRepo;
  StreamSubscription<String>? _tokenRefreshSub;

  NotificationService(this._messaging, this._authRepo);

  Future<void> init() async {
    final messaging = _messaging;
    if (messaging == null || kIsWeb) return;

    try {
      // Request notification permissions (iOS + Android 13+)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('FCM permission status: ${settings.authorizationStatus}');

      // Configure foreground presentation options (iOS)
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Listen to foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM foreground message: ${message.messageId}');
        if (message.notification != null) {
          debugPrint(
              'Notification title: ${message.notification?.title}, body: ${message.notification?.body}');
        }
      });

      // Listen to notification clicks when opened from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM message opened app: ${message.data}');
      });

      // Token refresh listener
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = messaging.onTokenRefresh.listen((newToken) async {
        final user = await _authRepo.currentAppUser();
        if (user != null) {
          await _authRepo.addFcmToken(user, newToken);
        }
      });
    } catch (e) {
      debugPrint('FCM initialization error: $e');
    }
  }

  /// Explicitly syncs the current device's FCM token to the given authenticated user.
  Future<void> syncUserToken(AppUser user) async {
    final messaging = _messaging;
    if (messaging == null || kIsWeb) return;

    try {
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _authRepo.addFcmToken(user, token);
        debugPrint('Synced FCM token for user ${user.uid}');
      }
    } catch (e) {
      debugPrint('Error syncing FCM token: $e');
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final messaging = ref.watch(firebaseMessagingProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  return NotificationService(messaging, authRepo);
});
