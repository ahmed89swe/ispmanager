import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants.dart';
import '../../core/models/models.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/image_preview_dialog.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/providers/preferences_providers.dart';
import '../auth/auth_repository.dart';
import '../finance/cashbox_repository.dart';
import 'expenses_repository.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  static String _cap(String s) =>
      s.isEmpty ? s : s.substring(0, 1).toUpperCase() + s.substring(1);

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final Set<String> _busyExpenseIds = {};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentAppUserProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();
    final canAdd = user.can(Permission.addExpense);
    final stream = ref.watch(expensesStreamProvider(user.adminUid));
    final loc = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);

    return Scaffold(
      body: stream.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 48, color: theme.colorScheme.outline),
                  const SizedBox(height: 8),
                  Text(l.noData, style: theme.textTheme.bodyLarge),
                ],
              ),
            );
          }
          return Column(
            children: [
              _buildSummaryBanner(context, list, l, loc),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 840;
                    Widget buildExpenseItem(Expense e) {
                      final actorLabel = _actorLabel(l, user, e);
                      final isBusy = _busyExpenseIds.contains(e.id);
                      return _ModernExpenseCard(
                        expense: e,
                        actorLabel: actorLabel,
                        isBusy: isBusy,
                        isAdmin: user.isAdmin,
                        locale: loc,
                        onDelete: () => _deleteExpense(context, l, user, e),
                      )
                          .animate()
                          .fadeIn(duration: 200.ms)
                          .slideY(begin: 0.04, end: 0);
                    }

                    if (isWide) {
                      final rows = (list.length + 1) ~/ 2;
                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 4, bottom: 84),
                        itemCount: rows,
                        itemBuilder: (_, rowIdx) {
                          final first = list[rowIdx * 2];
                          final secondIdx = rowIdx * 2 + 1;
                          final second =
                              secondIdx < list.length ? list[secondIdx] : null;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: buildExpenseItem(first)),
                              Expanded(
                                child: second != null
                                    ? buildExpenseItem(second)
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          );
                        },
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 84),
                      itemCount: list.length,
                      itemBuilder: (_, i) => buildExpenseItem(list[i]),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => ExpenseFormSheet(by: user)),
              icon: const Icon(Icons.add),
              label: Text(l.addExpense),
            )
          : null,
    );
  }

  Widget _buildSummaryBanner(BuildContext context, List<Expense> list,
      AppLocalizations l, String loc) {
    num totalIQD = 0;
    num totalUSD = 0;
    for (final e in list) {
      if (e.currency == AppCurrency.iqd) {
        totalIQD += e.amount;
      } else {
        totalUSD += e.amount;
      }
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFF8FAFC), const Color(0xFFEDF2F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.trending_down,
                color: Color(0xFFE53935), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l.expenses} (${list.length})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      CurrencyFormatter.format(totalIQD, AppCurrency.iqd,
                          locale: loc),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE53935),
                      ),
                    ),
                    if (totalUSD > 0) ...[
                      const SizedBox(width: 10),
                      Text(
                        '•  ${CurrencyFormatter.format(totalUSD, AppCurrency.usd, locale: loc)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE53935),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _actorLabel(AppLocalizations l, AppUser user, Expense expense) {
    final name = expense.recordedByName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final role = expense.recordedByRole;
    if (role != null) return l.t(role.name);
    if (expense.recordedBy == user.uid) {
      final currentName = user.displayName.trim();
      return currentName.isEmpty ? l.t(user.role.name) : currentName;
    }
    return l.employee;
  }

  static Future<bool?> _confirmDelete(
          BuildContext context, AppLocalizations l) =>
      showDialog<bool>(
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

  Future<void> _deleteExpense(
    BuildContext context,
    AppLocalizations l,
    AppUser user,
    Expense expense,
  ) async {
    final ok = await _confirmDelete(context, l);
    if (ok != true || !context.mounted) return;
    setState(() => _busyExpenseIds.add(expense.id));
    try {
      final repo = ref.read(expensesRepositoryProvider);
      if (user.isAdmin) {
        await repo.delete(user, expense);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.deleted)),
        );
      } else {
        await repo.createDeleteRequest(user, expense);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.t('deleteRequestSent'))),
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(l, error))),
      );
    } finally {
      if (mounted) setState(() => _busyExpenseIds.remove(expense.id));
    }
  }

  String _errorMessage(AppLocalizations l, Object error) {
    if (error is TimeoutException) return l.t('operationTimedOut');
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') return l.t('permissionDenied');
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) {
        return '${l.errorOccurred}: ${error.code} - $message';
      }
      return '${l.errorOccurred}: ${error.code}';
    }
    return l.errorOccurred;
  }
}

class ExpenseFormSheet extends ConsumerStatefulWidget {
  const ExpenseFormSheet({super.key, required this.by});
  final AppUser by;
  @override
  ConsumerState<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends ConsumerState<ExpenseFormSheet> {
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  ExpenseEntryType _type = ExpenseEntryType.expense;
  ExpenseCategory _category = ExpenseCategory.other;
  MoneyStorage _paidFrom = MoneyStorage.cashbox;
  late AppCurrency _currency = ref.read(currencyProvider);
  bool _busy = false;
  XFile? _receiptImage;
  Uint8List? _receiptImageBytes;

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt(ImageSource source) async {
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
          _receiptImage = picked;
          _receiptImageBytes = bytes;
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

  void _showReceiptSourcePicker() {
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
                  subtitle: const Text('تصوير وصل جديد'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickReceipt(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0x1A4CAF50),
                    child: Icon(Icons.photo_library_rounded, color: Colors.green),
                  ),
                  title: const Text('معرض الصور'),
                  subtitle: const Text('اختيار وصل من الألبوم'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickReceipt(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final amount = _parseAmount(_amount.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.invalidAmount)));
      return;
    }
    if (_reason.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.fieldRequired)));
      return;
    }
    if (_paidFrom == MoneyStorage.cashbox) {
      final cashbox =
          ref.read(cashboxStreamProvider(widget.by.adminUid)).valueOrNull;
      final available = cashbox?.balanceFor(_currency) ?? 0;
      if (amount > available) {
        final loc = Localizations.localeOf(context).languageCode;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'لا يمكن إتمام العملية: المبلغ المطلوب (${CurrencyFormatter.format(amount, _currency, locale: loc)}) يتجاوز رصيد الصندوق المتوفر (${CurrencyFormatter.format(available, _currency, locale: loc)})',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    setState(() => _busy = true);
    try {
      String? attachmentUrl;
      if (_receiptImage != null) {
        attachmentUrl = await ref.read(expensesRepositoryProvider).uploadReceipt(
              adminUid: widget.by.adminUid,
              file: _receiptImage!,
            );
      }
      final e = Expense(
        id: '',
        type: _type,
        amount: amount,
        currency: _currency,
        paidFrom: _paidFrom,
        category: _category,
        reason: _reason.text.trim(),
        attachmentUrl: attachmentUrl,
        date: DateTime.now(),
        recordedBy: widget.by.uid,
        recordedByName: widget.by.displayName.trim().isEmpty
            ? l.t(widget.by.role.name)
            : widget.by.displayName.trim(),
        recordedByRole: widget.by.role,
      );
      await ref.read(expensesRepositoryProvider).add(widget.by, e);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.saved)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('خطأ أثناء حفظ المصروف: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  num? _parseAmount(String input) {
    final normalized = input
        .trim()
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9')
        .replaceAll('۰', '0')
        .replaceAll('۱', '1')
        .replaceAll('۲', '2')
        .replaceAll('۳', '3')
        .replaceAll('۴', '4')
        .replaceAll('۵', '5')
        .replaceAll('۶', '6')
        .replaceAll('۷', '7')
        .replaceAll('۸', '8')
        .replaceAll('۹', '9')
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('،', '')
        .replaceAll(' ', '');
    return num.tryParse(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final loc = Localizations.localeOf(context).languageCode;
    final cashbox =
        ref.watch(cashboxStreamProvider(widget.by.adminUid)).valueOrNull;
    final availableBalance = cashbox?.balanceFor(_currency) ?? 0;

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
          children: [
            Text(l.addExpense, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExpenseEntryType>(
              value: _type,
              decoration: InputDecoration(labelText: l.t('operationType')),
              items: ExpenseEntryType.values
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(l.t(type.name)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 8),
            TextField(
                controller: _amount,
                decoration: InputDecoration(labelText: l.amount),
                keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            DropdownButtonFormField<AppCurrency>(
              value: _currency,
              decoration: InputDecoration(labelText: l.currency),
              items: AppCurrency.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.code)))
                  .toList(),
              onChanged: (v) => setState(() => _currency = v ?? _currency),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ExpenseCategory>(
              value: _category,
              decoration: InputDecoration(labelText: l.category),
              items: ExpenseCategory.values
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child:
                            Text(l.t('category${ExpensesScreen._cap(c.name)}')),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<MoneyStorage>(
              value: _paidFrom,
              decoration: InputDecoration(
                labelText: l.t('expenseFunding'),
                helperText: _paidFrom == MoneyStorage.cashbox
                    ? 'الرصيد المتوفر في الصندوق: ${CurrencyFormatter.format(availableBalance, _currency, locale: loc)}'
                    : 'من جيب الموظف (يُسجل كدين للموظف على الصندوق)',
              ),
              items: [
                DropdownMenuItem(
                  value: MoneyStorage.cashbox,
                  child: Text(l.t('fromCashbox')),
                ),
                DropdownMenuItem(
                  value: MoneyStorage.personal,
                  child: Text(l.t('fromPersonalCashboxDebt')),
                ),
              ],
              onChanged: (v) =>
                  setState(() => _paidFrom = v ?? MoneyStorage.cashbox),
            ),
            const SizedBox(height: 8),
            TextField(
                controller: _reason,
                decoration: InputDecoration(labelText: l.reason)),
            const SizedBox(height: 12),
            if (_receiptImage == null)
              OutlinedButton.icon(
                onPressed: _busy ? null : _showReceiptSourcePicker,
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('إرفاق صورة الوصل (اختياري)'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(160),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant.withAlpha(100),
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _receiptImageBytes!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تم إرفاق صورة الوصل',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            'سيتم حفظ الوصل مع تفاصيل المصروف',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: _busy ? null : () => setState(() {
                        _receiptImage = null;
                        _receiptImageBytes = null;
                      }),
                      tooltip: 'إلغاء الوصل',
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _save,
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l.save),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ModernExpenseCard extends StatelessWidget {
  const _ModernExpenseCard({
    required this.expense,
    required this.actorLabel,
    required this.isBusy,
    required this.isAdmin,
    required this.locale,
    required this.onDelete,
  });

  final Expense expense;
  final String actorLabel;
  final bool isBusy;
  final bool isAdmin;
  final String locale;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l = AppLocalizations.of(context);

    final isWithdrawal = expense.type == ExpenseEntryType.withdrawal;
    final (IconData catIcon, Color catColor) = isWithdrawal
        ? (Icons.account_balance_wallet_outlined, const Color(0xFFE53935))
        : switch (expense.category) {
            ExpenseCategory.rent => (
                Icons.storefront_outlined,
                const Color(0xFF5C6BC0)
              ),
            ExpenseCategory.salary => (
                Icons.payments_outlined,
                const Color(0xFF00897B)
              ),
            ExpenseCategory.maintenance => (
                Icons.build_circle_outlined,
                const Color(0xFFFB8C00)
              ),
            ExpenseCategory.utilities => (
                Icons.bolt_outlined,
                const Color(0xFFF9A825)
              ),
            ExpenseCategory.other => (
                Icons.receipt_long_outlined,
                const Color(0xFF546E7A)
              ),
          };

    final isFromCashbox = expense.paidFrom == MoneyStorage.cashbox;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: catColor.withValues(alpha: 0.12),
                child: Icon(catIcon, size: 20, color: catColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.reason,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isWithdrawal
                                ? l.t('withdrawal')
                                : l.t(
                                    'category${ExpensesScreen._cap(expense.category.name)}'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: catColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isFromCashbox
                                ? theme.colorScheme.primary
                                    .withValues(alpha: 0.08)
                                : Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isFromCashbox
                                    ? Icons.savings_outlined
                                    : Icons.person_outline,
                                size: 11,
                                color: isFromCashbox
                                    ? theme.colorScheme.primary
                                    : Colors.amber.shade900,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                isFromCashbox
                                    ? l.t('fromCashbox')
                                    : l.t('fromPersonalCashboxDebt'),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: isFromCashbox
                                      ? theme.colorScheme.primary
                                      : Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '- ${CurrencyFormatter.format(expense.amount, expense.currency, locale: locale)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE53935),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (expense.attachmentUrl != null &&
                          expense.attachmentUrl!.isNotEmpty) ...[
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.receipt_long_rounded,
                              size: 20, color: Colors.blue),
                          tooltip: 'عرض صورة الوصل',
                          onPressed: () => showFullScreenImage(
                            context,
                            imageUrl: expense.attachmentUrl!,
                            title: 'وصل مصروف: ${expense.reason}',
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (isBusy)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(Icons.more_vert,
                              size: 18, color: theme.colorScheme.outline),
                          onSelected: (val) {
                            if (val == 'delete') onDelete();
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline,
                                      size: 18, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text(
                                    isAdmin ? l.delete : l.t('requestDelete'),
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.person_outline,
                  size: 12, color: theme.colorScheme.outline),
              const SizedBox(width: 4),
              Text(
                '${l.t('by')}: $actorLabel',
                style: TextStyle(
                    fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
              ),
              const Spacer(),
              Icon(Icons.access_time,
                  size: 12, color: theme.colorScheme.outline),
              const SizedBox(width: 4),
              Text(
                DateFormatter.date(expense.date, locale: locale),
                style: TextStyle(
                    fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
