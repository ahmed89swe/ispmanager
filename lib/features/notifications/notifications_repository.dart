import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase_service.dart';
import '../../core/models/models.dart';
import '../auth/auth_repository.dart';

class NotificationsRepository {
  NotificationsRepository(this._db);
  final FirebaseFirestore? _db;

  CollectionReference<Map<String, dynamic>> _col(String adminUid) =>
      _db!.collection('admins').doc(adminUid).collection('notifications');

  Stream<List<AppNotification>> watchNotifications(
    String adminUid,
    String userUid, {
    bool isAdmin = false,
    int limit = 100,
  }) {
    if (_db == null) return const Stream.empty();
    return _col(adminUid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map(AppNotification.fromDoc)
          .where((n) {
            if (isAdmin) {
              return n.recipientUid == 'admin' ||
                  n.recipientUid == userUid ||
                  n.recipientUid == 'all';
            } else {
              return n.recipientUid == userUid || n.recipientUid == 'all';
            }
          })
          .toList();
    });
  }

  Stream<int> watchUnreadCount(
    String adminUid,
    String userUid, {
    bool isAdmin = false,
  }) {
    return watchNotifications(adminUid, userUid, isAdmin: isAdmin)
        .map((list) => list.where((n) => !n.isRead).length);
  }

  Future<void> sendNotification({
    required String adminUid,
    required String recipientUid,
    required String title,
    required String body,
    required String type,
    required AppUser actor,
    String? targetId,
    String? targetType,
  }) async {
    if (_db == null) return;
    final docRef = _col(adminUid).doc();
    final notif = AppNotification(
      id: docRef.id,
      title: title,
      body: body,
      type: type,
      recipientUid: recipientUid,
      actorUid: actor.uid,
      actorName: actor.displayName,
      createdAt: DateTime.now(),
      isRead: false,
      targetId: targetId,
      targetType: targetType,
    );
    await docRef.set(notif.toMap());
  }

  Future<void> markAsRead(String adminUid, String notificationId) async {
    if (_db == null) return;
    await _col(adminUid).doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead(
    String adminUid,
    String userUid, {
    bool isAdmin = false,
  }) async {
    final db = _db;
    if (db == null) return;
    final snap = await _col(adminUid).where('isRead', isEqualTo: false).get();
    final batch = db.batch();
    for (final doc in snap.docs) {
      final rUid = doc.data()['recipientUid'] as String?;
      final belongs = isAdmin
          ? (rUid == 'admin' || rUid == userUid || rUid == 'all')
          : (rUid == userUid || rUid == 'all');
      if (belongs) {
        batch.update(doc.reference, {'isRead': true});
      }
    }
    await batch.commit();
  }

  Future<void> delete(String adminUid, String notificationId) async {
    if (_db == null) return;
    await _col(adminUid).doc(notificationId).delete();
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(firestoreProvider));
});

final notificationsStreamProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final user = ref.watch(currentAppUserProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref
      .watch(notificationsRepositoryProvider)
      .watchNotifications(user.adminUid, user.uid, isAdmin: user.isAdmin);
});

final unreadNotificationsCountProvider =
    StreamProvider.autoDispose<int>((ref) {
  final user = ref.watch(currentAppUserProvider).valueOrNull;
  if (user == null) return Stream.value(0);
  return ref
      .watch(notificationsRepositoryProvider)
      .watchUnreadCount(user.adminUid, user.uid, isAdmin: user.isAdmin);
});
