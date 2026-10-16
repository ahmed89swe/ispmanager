import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/models.dart';
import '../../core/utils/formatters.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_repository.dart';
import 'chat_repository.dart';

class ChatConversationScreen extends ConsumerStatefulWidget {
  const ChatConversationScreen({
    super.key,
    required this.employeeUid,
    required this.employeeName,
    this.employeeRole,
  });

  final String employeeUid;
  final String employeeName;
  final String? employeeRole;

  @override
  ConsumerState<ChatConversationScreen> createState() =>
      _ChatConversationScreenState();
}

class _ChatConversationScreenState
    extends ConsumerState<ChatConversationScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  bool _uploadingImage = false;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _markRead() {
    final user = ref.read(currentAppUserProvider).valueOrNull;
    if (user == null) return;
    ref.read(chatRepositoryProvider).markMessagesAsRead(
          adminUid: user.adminUid,
          employeeUid: widget.employeeUid,
          viewerUid: user.uid,
        );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImage = picked;
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في اختيار الصورة: $e')),
        );
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0x1A2196F3),
                    child: Icon(Icons.camera_alt_rounded, color: Colors.blue),
                  ),
                  title: const Text('الكاميرا'),
                  subtitle: const Text('التقاط صورة جديدة'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0x1A4CAF50),
                    child: Icon(Icons.photo_library_rounded, color: Colors.green),
                  ),
                  title: const Text('معرض الصور'),
                  subtitle: const Text('اختيار من ألبوم الصور'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openImagePreview(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white54,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    final imageFile = _selectedImage;
    if ((text.isEmpty && imageFile == null) || _sending) return;

    final user = ref.read(currentAppUserProvider).valueOrNull;
    if (user == null) return;

    setState(() {
      _sending = true;
      if (imageFile != null) _uploadingImage = true;
    });

    try {
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await ref.read(chatRepositoryProvider).uploadChatImage(
              adminUid: user.adminUid,
              employeeUid: widget.employeeUid,
              file: imageFile,
            );
      }

      await ref.read(chatRepositoryProvider).sendMessage(
            sender: user,
            adminUid: user.adminUid,
            employeeUid: widget.employeeUid,
            employeeName: widget.employeeName,
            text: text.isNotEmpty ? text : null,
            imageUrl: imageUrl,
          );

      _textController.clear();
      if (mounted) {
        setState(() {
          _selectedImage = null;
          _selectedImageBytes = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في إرسال الرسالة: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _uploadingImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final loc = Localizations.localeOf(context).languageCode;
    final user = ref.watch(currentAppUserProvider).valueOrNull;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l.pleaseSignIn)),
      );
    }

    final isManagerView = user.isAdmin;
    final title = isManagerView ? widget.employeeName : 'المدير العام / الإدارة';
    final subtitle = isManagerView
        ? (widget.employeeRole != null && widget.employeeRole!.isNotEmpty
            ? widget.employeeRole!
            : l.employee)
        : 'إدارة النظام';

    final messagesAsync =
        ref.watch(chatMessagesStreamProvider(widget.employeeUid));

    // Also mark read whenever new messages arrive
    ref.listen(chatMessagesStreamProvider(widget.employeeUid), (_, next) {
      if (next.hasValue) {
        _markRead();
      }
    });

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isManagerView
                  ? theme.colorScheme.primaryContainer
                  : Colors.indigo.withAlpha(40),
              foregroundColor: isManagerView
                  ? theme.colorScheme.onPrimaryContainer
                  : Colors.indigo,
              child: isManagerView
                  ? Text(
                      widget.employeeName.isNotEmpty
                          ? widget.employeeName.substring(0, 1).toUpperCase()
                          : 'E',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  : const Icon(Icons.shield_outlined, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 64,
                          color: theme.colorScheme.outline.withAlpha(120),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l.t('noChats'),
                          style: TextStyle(
                            color: theme.colorScheme.outline,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ابدأ المحادثة الآن بإرسال رسالة في الأسفل',
                          style: TextStyle(
                            color: theme.colorScheme.outline.withAlpha(180),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (ctx, idx) {
                    final msg = messages[idx];
                    final isMe = msg.senderUid == user.uid;
                    return _buildMessageBubble(
                        ctx, theme, msg, isMe, loc);
                  },
                );
              },
            ),
          ),
          _buildInputBar(theme, l),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    ThemeData theme,
    ChatMessage msg,
    bool isMe,
    String loc,
  ) {
    final bg = isMe
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final fg = isMe
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;
    final timeColor = isMe
        ? theme.colorScheme.onPrimary.withAlpha(180)
        : theme.colorScheme.outline;

    final timeStr = DateFormatter.time(msg.createdAt, locale: loc);
    final hasImage = msg.imageUrl != null && msg.imageUrl!.isNotEmpty;

    return Align(
      alignment: isMe ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: hasImage
            ? const EdgeInsets.all(6)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: EdgeInsets.only(
                  left: hasImage ? 8 : 0,
                  right: hasImage ? 8 : 0,
                  bottom: 4,
                  top: hasImage ? 4 : 0,
                ),
                child: Text(
                  msg.senderName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            if (hasImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onTap: () => _openImagePreview(context, msg.imageUrl!),
                  child: Hero(
                    tag: 'msg_img_${msg.id}',
                    child: CachedNetworkImage(
                      imageUrl: msg.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.black12,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 120,
                        width: double.infinity,
                        color: Colors.black12,
                        child: const Icon(Icons.broken_image_rounded, size: 40),
                      ),
                    ),
                  ),
                ),
              ),
              if (msg.text.isNotEmpty) const SizedBox(height: 6),
            ],
            if (msg.text.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: hasImage ? 8 : 0,
                  vertical: hasImage ? 2 : 0,
                ),
                child: Text(
                  msg.text,
                  style: TextStyle(
                    color: fg,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.only(
                left: hasImage ? 8 : 0,
                right: hasImage ? 8 : 0,
                top: 4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(fontSize: 10, color: timeColor),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      msg.isRead ? Icons.done_all : Icons.done,
                      size: 13,
                      color: msg.isRead
                          ? Colors.lightBlueAccent
                          : timeColor,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme, AppLocalizations l) {
    return Container(
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(70),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedImage != null && _selectedImageBytes != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(160),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withAlpha(100),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _selectedImageBytes!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'صورة جاهزة للإرسال',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          _uploadingImage
                              ? 'جارِ الرفع والإرسال...'
                              : 'يمكنك كتابة تعليق أو إرسالها مباشرة',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_sending)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => setState(() {
                        _selectedImage = null;
                        _selectedImageBytes = null;
                      }),
                      tooltip: 'إلغاء الصورة',
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                onPressed: _sending ? null : _showImageSourcePicker,
                icon: const Icon(Icons.image_outlined),
                tooltip: 'إرفاق صورة',
                color: theme.colorScheme.primary,
              ),
              Expanded(
                child: TextField(
                  controller: _textController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: _selectedImage != null
                        ? 'اكتب تعليقاً على الصورة...'
                        : l.t('typeMessage'),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    filled: true,
                    fillColor:
                        theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sending ? null : _sendMessage,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
                tooltip: l.t('sendMessage'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

