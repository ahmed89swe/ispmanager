import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme/app_theme.dart';
import '../../core/constants.dart';
import '../../core/models/models.dart';
import '../../core/widgets/app_avatar.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_repository.dart';
import 'employees_repository.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  final Set<String> _busyEmployeeIds = {};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentAppUserProvider).valueOrNull;
    if (user == null || !user.isAdmin) {
      return Center(child: Text(l.pleaseSignIn));
    }
    final stream = ref.watch(employeesStreamProvider(user.adminUid));

    final theme = Theme.of(context);

    return Scaffold(
      body: stream.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) return Center(child: Text(l.noData));
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 840;
              Widget buildEmployeeCard(Employee e) {
                final isBusy = _busyEmployeeIds.contains(e.id);
                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: AppTheme.cardDecoration(context),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: Stack(
                      children: [
                        AppAvatar(
                          photoUrl: e.photoUrl,
                          name: e.displayName.isNotEmpty
                              ? e.displayName
                              : e.username,
                          radius: 22,
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: InkWell(
                            onTap: isBusy
                                ? null
                                : () => _changeEmployeeAvatar(user, e),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt,
                                  size: 11, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      e.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${e.username} • ${e.permissions.length} ${l.permissions}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: e.active,
                          onChanged: isBusy
                              ? null
                              : (v) => ref
                                  .read(employeesRepositoryProvider)
                                  .setActive(user, e, v),
                        ),
                        isBusy
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : IconButton(
                                tooltip: l.delete,
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent),
                                onPressed: () =>
                                    _deleteEmployee(context, user, e),
                              ),
                      ],
                    ),
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => PermissionsSheet(by: user, employee: e),
                    ),
                  ),
                );
              }

              if (isWide) {
                final rows = (list.length + 1) ~/ 2;
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 84),
                  itemCount: rows,
                  itemBuilder: (_, rowIdx) {
                    final first = list[rowIdx * 2];
                    final secondIdx = rowIdx * 2 + 1;
                    final second =
                        secondIdx < list.length ? list[secondIdx] : null;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: buildEmployeeCard(first)),
                        Expanded(
                          child: second != null
                              ? buildEmployeeCard(second)
                              : const SizedBox.shrink(),
                        ),
                      ],
                    );
                  },
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 84),
                itemCount: list.length,
                itemBuilder: (_, i) => buildEmployeeCard(list[i]),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => EmployeeFormSheet(by: user)),
        icon: const Icon(Icons.person_add_alt),
        label: Text(l.newEmployee),
      ),
    );
  }

  Future<void> _deleteEmployee(
      BuildContext context, AppUser user, Employee employee) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.no),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.yes),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    setState(() => _busyEmployeeIds.add(employee.id));
    try {
      await ref.read(employeesRepositoryProvider).delete(user, employee);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.deleted)),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _busyEmployeeIds.remove(employee.id));
    }
  }

  Future<void> _changeEmployeeAvatar(AppUser user, Employee emp) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('اختيار صورة من المعرض'),
                onTap: () => Navigator.pop(ctx, 'pick'),
              ),
              if (emp.photoUrl != null && emp.photoUrl!.isNotEmpty)
                ListTile(
                  leading:
                      const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('إزالة الصورة',
                      style: TextStyle(color: Colors.redAccent)),
                  onTap: () => Navigator.pop(ctx, 'remove'),
                ),
            ],
          ),
        ),
      ),
    );

    if (action == null || !mounted) return;

    if (action == 'pick') {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 600,
        maxHeight: 600,
      );
      if (picked == null || !mounted) return;
      setState(() => _busyEmployeeIds.add(emp.id));
      try {
        await ref
            .read(employeesRepositoryProvider)
            .uploadAvatar(user, emp, picked);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF00A86B),
              content: Text('تم تحديث صورة الموظف بنجاح'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل حفظ صورة الموظف: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _busyEmployeeIds.remove(emp.id));
      }
    } else if (action == 'remove') {
      setState(() => _busyEmployeeIds.add(emp.id));
      try {
        await ref.read(employeesRepositoryProvider).removeAvatar(user, emp);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت إزالة صورة الموظف')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل إزالة الصورة: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _busyEmployeeIds.remove(emp.id));
      }
    }
  }
}

class EmployeeFormSheet extends ConsumerStatefulWidget {
  const EmployeeFormSheet({super.key, required this.by});
  final AppUser by;
  @override
  ConsumerState<EmployeeFormSheet> createState() => _EmployeeFormSheetState();
}

class _EmployeeFormSheetState extends ConsumerState<EmployeeFormSheet> {
  final _username = TextEditingController();
  final _displayName = TextEditingController();
  final _password = TextEditingController();
  final _perms = <Permission>{
    Permission.viewSubscribers,
    Permission.viewSuppliers,
    Permission.recordSubscriberPayment,
  };
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.newEmployee, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
                controller: _username,
                decoration: InputDecoration(labelText: l.username)),
            const SizedBox(height: 8),
            TextField(
                controller: _displayName,
                decoration: InputDecoration(labelText: l.displayName)),
            const SizedBox(height: 8),
            TextField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(labelText: l.password)),
            const SizedBox(height: 16),
            Text(l.permissions, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final p in Permission.values)
              CheckboxListTile(
                dense: true,
                value: _perms.contains(p),
                title: Text(l.t(_permKey(p))),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _perms.add(p);
                  } else {
                    _perms.remove(p);
                  }
                }),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () async {
                      final u = _username.text.trim();
                      final p = _password.text;
                      if (u.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('يرجى كتابة اسم المستخدم')),
                        );
                        return;
                      }
                      if (p.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('كلمة المرور يجب أن لا تقل عن 6 أحرف')),
                        );
                        return;
                      }
                      setState(() => _busy = true);
                      try {
                        await ref.read(employeesRepositoryProvider).create(
                              widget.by,
                              username: u,
                              displayName: _displayName.text.trim().isEmpty
                                  ? u
                                  : _displayName.text.trim(),
                              password: p,
                              permissions: _perms,
                            );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تم إضافة الموظف ($u) بنجاح'),
                            backgroundColor: Colors.green.shade700,
                          ),
                        );
                        Navigator.pop(context);
                      } catch (e) {
                        if (!context.mounted) return;
                        final msg = e
                            .toString()
                            .replaceFirst(RegExp(r'^Exception:\s*|^Error:\s*|\[.*?\]\s*'), '');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(msg),
                            backgroundColor: Colors.red.shade700,
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l.save),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class PermissionsSheet extends ConsumerStatefulWidget {
  const PermissionsSheet({super.key, required this.by, required this.employee});
  final AppUser by;
  final Employee employee;
  @override
  ConsumerState<PermissionsSheet> createState() => _PermissionsSheetState();
}

class _PermissionsSheetState extends ConsumerState<PermissionsSheet> {
  late final Set<Permission> _perms = {...widget.employee.permissions};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppAvatar(
                  photoUrl: widget.employee.photoUrl,
                  name: widget.employee.displayName.isNotEmpty
                      ? widget.employee.displayName
                      : widget.employee.username,
                  radius: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.employee.displayName.isNotEmpty
                            ? widget.employee.displayName
                            : widget.employee.username,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        '${l.permissions} • ${widget.employee.username}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final p in Permission.values)
              CheckboxListTile(
                dense: true,
                value: _perms.contains(p),
                title: Text(l.t(_permKey(p))),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _perms.add(p);
                  } else {
                    _perms.remove(p);
                  }
                }),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                await ref
                    .read(employeesRepositoryProvider)
                    .updatePermissions(widget.by, widget.employee, _perms);
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              child: Text(l.save),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

String _permKey(Permission p) {
  switch (p) {
    case Permission.recordSubscriberPayment:
      return 'permissionRecordPayment';
    case Permission.addSubscriber:
      return 'permissionAddSubscriber';
    case Permission.editSubscriber:
      return 'permissionEditSubscriber';
    case Permission.deleteSubscriber:
      return 'permissionDeleteSubscriber';
    case Permission.notifySupplierPayment:
      return 'permissionNotifySupplierPayment';
    case Permission.addExpense:
      return 'permissionAddExpense';
    case Permission.viewSubscribers:
      return 'permissionViewSubscribers';
    case Permission.viewSuppliers:
      return 'permissionViewSuppliers';
    case Permission.viewReports:
      return 'permissionViewReports';
    case Permission.viewHistory:
      return 'permissionViewHistory';
    case Permission.manageSuppliers:
      return 'permissionManageSuppliers';
    case Permission.manageSupplierPurchases:
      return 'permissionManageSupplierPurchases';
  }
}
