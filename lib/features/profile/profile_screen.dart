import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/widgets/app_avatar.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_repository.dart';
import 'profile_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  bool _initialized = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final user = ref.read(currentAppUserProvider).valueOrNull;
    if (user == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 600,
      maxHeight: 600,
    );
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .uploadAvatar(user, picked);
      if (mounted) {
        ref.invalidate(currentAppUserProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF00A86B),
            content: Text('تم تحديث الصورة الشخصية بنجاح'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حفظ الصورة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeAvatar() async {
    final user = ref.read(currentAppUserProvider).valueOrNull;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider).removeAvatar(user);
      if (mounted) {
        ref.invalidate(currentAppUserProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إزالة الصورة الشخصية')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إزالة الصورة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveName() async {
    final user = ref.read(currentAppUserProvider).valueOrNull;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateDisplayName(user, _name.text.trim());
      if (mounted) ref.invalidate(currentAppUserProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final userAsync = ref.watch(currentAppUserProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.profile)),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (user) {
          if (user == null) return Center(child: Text(l.pleaseSignIn));
          if (!_initialized) {
            _name.text = user.displayName;
            _initialized = true;
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Stack(
                  children: [
                    AppAvatar(
                      photoUrl: user.photoUrl,
                      name: user.displayName,
                      radius: 56,
                      fontSize: 42,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 18),
                          onPressed: _busy ? null : _pickAvatar,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: _busy ? null : _removeAvatar,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l.removePhoto),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _name,
                decoration: InputDecoration(labelText: l.displayName),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _saveName,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
                child: Text(l.save),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.alternate_email),
                title: Text(user.email ?? '-'),
              ),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: Text(user.role.name),
              ),
            ],
          );
        },
      ),
    );
  }
}
