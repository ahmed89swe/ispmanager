import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/firebase_service.dart';
import '../../core/models/models.dart';
import '../auth/auth_repository.dart';
import '../notifications/notifications_repository.dart';

class ChatRepository {
  ChatRepository(this._db, this._notificationsRepo, [this._storage]);
  final FirebaseFirestore? _db;
  final NotificationsRepository _notificationsRepo;
  final FirebaseStorage? _storage;

  DocumentReference<Map<String, dynamic>> _chatDoc(
          String adminUid, String employeeUid) =>
      _db!.collection('admins').doc(adminUid).collection('chats').doc(employeeUid);

  CollectionReference<Map<String, dynamic>> _messagesCol(
          String adminUid, String employeeUid) =>
      _chatDoc(adminUid, employeeUid).collection('messages');

  Stream<List<ChatMessage>> watchMessages(String adminUid, String employeeUid) {
    if (_db == null) return const Stream.empty();
    return _messagesCol(adminUid, employeeUid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromDoc).toList());
  }

  Stream<Map<String, dynamic>?> watchThread(String adminUid, String employeeUid) {
    if (_db == null) return const Stream.empty();
    return _chatDoc(adminUid, employeeUid).snapshots().map((s) => s.data());
  }

  Stream<List<Map<String, dynamic>>> watchAllThreads(String adminUid) {
    final db = _db;
    if (db == null) return const Stream.empty();
    return db
        .collection('admins')
        .doc(adminUid)
        .collection('chats')
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((s) => s.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<String> uploadChatImage({
    required String adminUid,
    required String employeeUid,
    required XFile file,
  }) async {
    final storage = _storage;
    if (storage == null) {
      throw StateError('خدمة تخزين الملفات غير متوفرة');
    }
    var ext = file.name.split('.').last.toLowerCase();
    if (ext.isEmpty || ext.length > 5) ext = 'jpg';
    final filename =
        '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4().substring(0, 8)}.$ext';
    final ref = storage.ref('admins/$adminUid/chats/$employeeUid/$filename');
    final bytes = await file.readAsBytes();
    final contentType = _imageContentType(file.name);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    return await ref.getDownloadURL();
  }

  String _imageContentType(String path) {
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.png')) return 'image/png';
    if (lowerPath.endsWith('.webp')) return 'image/webp';
    if (lowerPath.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<void> sendMessage({
    required AppUser sender,
    required String adminUid,
    required String employeeUid,
    String? text,
    String? imageUrl,
    String? employeeName,
  }) async {
    final db = _db;
    final trimmed = text?.trim() ?? '';
    if (db == null || (trimmed.isEmpty && (imageUrl == null || imageUrl.isEmpty))) {
      return;
    }
    final now = DateTime.now();
    final displaySummary = trimmed.isNotEmpty ? trimmed : '📷 صورة';

    final batch = db.batch();
    final msgRef = _messagesCol(adminUid, employeeUid).doc();
    final msg = ChatMessage(
      id: msgRef.id,
      senderUid: sender.uid,
      senderName: sender.displayName,
      senderRole: sender.role,
      text: trimmed,
      imageUrl: imageUrl,
      createdAt: now,
      isRead: false,
    );
    batch.set(msgRef, msg.toMap());

    final threadRef = _chatDoc(adminUid, employeeUid);
    batch.set(
      threadRef,
      {
        'employeeUid': employeeUid,
        if (employeeName != null && employeeName.isNotEmpty)
          'employeeName': employeeName,
        'lastMessage': displaySummary,
        'lastMessageTime': Timestamp.fromDate(now),
        'lastSenderUid': sender.uid,
        'lastSenderName': sender.displayName,
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    // Trigger in-app notification to the other party
    final recipientUid = sender.isAdmin ? employeeUid : 'admin';
    final notifTitle = sender.isAdmin
        ? 'رسالة من المدير العام'
        : 'رسالة من ${sender.displayName}';

    await _notificationsRepo.sendNotification(
      adminUid: adminUid,
      recipientUid: recipientUid,
      title: notifTitle,
      body: displaySummary,
      type: 'chat_message',
      actor: sender,
      targetId: employeeUid,
      targetType: 'chat',
    );
  }

  Future<void> markMessagesAsRead({
    required String adminUid,
    required String employeeUid,
    required String viewerUid,
  }) async {
    final db = _db;
    if (db == null) return;
    final unreadSnap = await _messagesCol(adminUid, employeeUid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = db.batch();
    var hasUpdates = false;
    for (final doc in unreadSnap.docs) {
      if (doc.data()['senderUid'] != viewerUid) {
        batch.update(doc.reference, {'isRead': true});
        hasUpdates = true;
      }
    }
    if (hasUpdates) {
      await batch.commit();
    }
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    ref.watch(firestoreProvider),
    ref.watch(notificationsRepositoryProvider),
    ref.watch(firebaseStorageProvider),
  );
});

final chatMessagesStreamProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, employeeUid) {
  final user = ref.watch(currentAppUserProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref
      .watch(chatRepositoryProvider)
      .watchMessages(user.adminUid, employeeUid);
});

final chatThreadsStreamProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(currentAppUserProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(chatRepositoryProvider).watchAllThreads(user.adminUid);
});

final chatThreadStreamProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, employeeUid) {
  final user = ref.watch(currentAppUserProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref
      .watch(chatRepositoryProvider)
      .watchThread(user.adminUid, employeeUid);
});
