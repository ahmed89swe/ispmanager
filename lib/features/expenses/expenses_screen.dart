import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme/app_theme.dart';
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

class _ExpensesScreenState extends ConsumerState<ExpensesScreen>
    with SingleTickerProviderStateMixin {
  final Set<String> _busyExpenseIds = {};
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentAppUserProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();
    final canAdd = user.can(Permission.addExpense);
    final stream = ref.watch(expensesStreamProvider(user.adminUid));
    final recurringStream =
        ref.watch(recurringExpensesStreamProvider(user.adminUid));
    final loc = Localizations.localeOf(context).languageCode;
    final isAr = loc.startsWith('ar');
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            padding: const EdgeInsets.all(4),
            decoration: AppTheme.cardDecoration(context, borderRadius: 14),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
              tabs: [
                Tab(
                  height: 42,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          isAr
                              ? 'المصاريف الشهرية الثابتة'
                              : 'Fixed Monthly Expenses',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  height: 42,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long_rounded, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          isAr
                              ? 'المصاريف المتفرقة (الطارئة)'
                              : 'Variable / General Expenses',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Fixed Monthly Expenses
                _buildRecurringExpensesTab(
                    context, recurringStream, user, l, loc, isAr, canAdd),
                // Tab 2: Variable / General Expenses
                _buildVariableExpensesTab(
                    context, stream, user, l, loc, isAr, theme),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () {
                if (_tabController.index == 0) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => RecurringExpenseFormSheet(by: user),
                  );
                } else {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => ExpenseFormSheet(by: user),
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: Text(
                _tabController.index == 0
                    ? (isAr
                        ? 'إضافة مصروف شهري ثابت'
                        : 'Add Fixed Monthly Expense')
                    : (isAr ? 'إضافة مصروف متفرق' : l.addExpense),
              ),
            )
          : null,
    );
  }

  Widget _buildRecurringExpensesTab(
    BuildContext context,
    AsyncValue<List<RecurringExpense>> recurringStream,
    AppUser user,
    AppLocalizations l,
    String loc,
    bool isAr,
    bool canAdd,
  ) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    return recurringStream.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month_outlined,
                      size: 54, color: theme.colorScheme.outline),
                  const SizedBox(height: 10),
                  Text(
                    isAr
                        ? 'لا توجد مصاريف شهرية ثابتة مضافة بعد'
                        : 'No fixed monthly expenses added yet',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAr
                        ? 'أضف التزاماتك الشهرية الثابتة (مثل الإيجار، الرواتب، الكهرباء، الإنترنت) لتتبع سدادها كل شهر بسهولة'
                        : 'Add your monthly recurring expenses (rent, salaries, electricity, etc.) to track them every month',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        int paidThisMonthCount = 0;
        num paidIqdThisMonth = 0;
        num paidUsdThisMonth = 0;
        for (final item in items) {
          final p = item.paymentFor(now.year, now.month);
          if (p != null) {
            paidThisMonthCount++;
            if (p.currency == AppCurrency.iqd) {
              paidIqdThisMonth += p.amount;
            } else {
              paidUsdThisMonth += p.amount;
            }
          }
        }
        final unpaidThisMonthCount = items.length - paidThisMonthCount;

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(14, 8, 14, 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: AppTheme.cardDecoration(context),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.event_repeat_rounded,
                        color: theme.colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr
                              ? 'التزامات شهر ${now.month}/${now.year} (${items.length})'
                              : 'Month ${now.month}/${now.year} Commitments (${items.length})',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            Text(
                              isAr
                                  ? 'المسدد: $paidThisMonthCount'
                                  : 'Paid: $paidThisMonthCount',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              isAr
                                  ? 'المتبقي لهذا الشهر: $unpaidThisMonthCount'
                                  : 'Unpaid: $unpaidThisMonthCount',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: unpaidThisMonthCount > 0
                                    ? Colors.orange.shade800
                                    : Colors.grey,
                              ),
                            ),
                            if (paidIqdThisMonth > 0)
                              Text(
                                '• ${CurrencyFormatter.format(paidIqdThisMonth, AppCurrency.iqd, locale: loc)}',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            if (paidUsdThisMonth > 0)
                              Text(
                                '• ${CurrencyFormatter.format(paidUsdThisMonth, AppCurrency.usd, locale: loc)}',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 840;
                  Widget buildCard(RecurringExpense item) {
                    return _RecurringExpenseCard(
                      item: item,
                      user: user,
                      locale: loc,
                      isAr: isAr,
                      canPay: canAdd,
                      onOpenMonths: () => showDialog(
                        context: context,
                        builder: (_) => _RecurringExpenseMonthsDialog(
                          itemId: item.id,
                          initialItem: item,
                          user: user,
                          locale: loc,
                          isAr: isAr,
                        ),
                      ),
                      onPayCurrentMonth: () => showDialog(
                        context: context,
                        builder: (_) => _PayRecurringMonthDialog(
                          item: item,
                          year: now.year,
                          month: now.month,
                          user: user,
                          isAr: isAr,
                        ),
                      ),
                      onEdit: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => RecurringExpenseFormSheet(
                          by: user,
                          existing: item,
                        ),
                      ),
                      onDelete: () async {
                        final ok = await _confirmDelete(context, l);
                        if (ok != true || !context.mounted) return;
                        await ref
                            .read(expensesRepositoryProvider)
                            .deleteRecurringExpense(user, item.id);
                      },
                    )
                        .animate()
                        .fadeIn(duration: 200.ms)
                        .slideY(begin: 0.04, end: 0);
                  }

                  if (isWide) {
                    final rows = (items.length + 1) ~/ 2;
                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 84),
                      itemCount: rows,
                      itemBuilder: (_, rowIdx) {
                        final first = items[rowIdx * 2];
                        final secondIdx = rowIdx * 2 + 1;
                        final second =
                            secondIdx < items.length ? items[secondIdx] : null;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: buildCard(first)),
                            Expanded(
                              child: second != null
                                  ? buildCard(second)
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        );
                      },
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 84),
                    itemCount: items.length,
                    itemBuilder: (_, i) => buildCard(items[i]),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVariableExpensesTab(
    BuildContext context,
    AsyncValue<List<Expense>> stream,
    AppUser user,
    AppLocalizations l,
    String loc,
    bool isAr,
    ThemeData theme,
  ) {
    return stream.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (rawList) {
        final list = rawList.where((e) => e.recurringId == null).toList();
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

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppTheme.cardDecoration(context),
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
                    child:
                        Icon(Icons.photo_library_rounded, color: Colors.green),
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
        attachmentUrl =
            await ref.read(expensesRepositoryProvider).uploadReceipt(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withAlpha(160),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withAlpha(100),
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
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
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
                      onPressed: _busy
                          ? null
                          : () => setState(() {
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
      decoration: AppTheme.cardDecoration(context),
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

const List<String> _arabicMonths = [
  'كانون الثاني (1)',
  'شباط (2)',
  'آذار (3)',
  'نيسان (4)',
  'أيار (5)',
  'حزيران (6)',
  'تموز (7)',
  'آب (8)',
  'أيلول (9)',
  'تشرين الأول (10)',
  'تشرين الثاني (11)',
  'كانون الأول (12)',
];

const List<String> _englishMonths = [
  'Jan (1)',
  'Feb (2)',
  'Mar (3)',
  'Apr (4)',
  'May (5)',
  'Jun (6)',
  'Jul (7)',
  'Aug (8)',
  'Sep (9)',
  'Oct (10)',
  'Nov (11)',
  'Dec (12)',
];

class _RecurringExpenseCard extends StatelessWidget {
  const _RecurringExpenseCard({
    required this.item,
    required this.user,
    required this.locale,
    required this.isAr,
    required this.canPay,
    required this.onOpenMonths,
    required this.onPayCurrentMonth,
    required this.onEdit,
    required this.onDelete,
  });

  final RecurringExpense item;
  final AppUser user;
  final String locale;
  final bool isAr;
  final bool canPay;
  final VoidCallback onOpenMonths;
  final VoidCallback onPayCurrentMonth;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final currentPayment = item.paymentFor(now.year, now.month);
    final isPaidThisMonth = currentPayment != null;

    final (IconData catIcon, Color catColor) = switch (item.category) {
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

    int paidMonthsThisYear = 0;
    for (int m = 1; m <= 12; m++) {
      if (item.isPaidFor(now.year, m)) paidMonthsThisYear++;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: AppTheme.cardDecoration(context),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpenMonths,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 21,
                    backgroundColor: catColor.withValues(alpha: 0.14),
                    child: Icon(catIcon, size: 22, color: catColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isPaidThisMonth
                                    ? Colors.green.withValues(alpha: 0.14)
                                    : Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isPaidThisMonth
                                      ? Colors.green.withValues(alpha: 0.4)
                                      : Colors.orange.withValues(alpha: 0.45),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPaidThisMonth
                                        ? Icons.check_circle_rounded
                                        : Icons.schedule_rounded,
                                    size: 13,
                                    color: isPaidThisMonth
                                        ? Colors.green.shade700
                                        : Colors.orange.shade800,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isPaidThisMonth
                                        ? (isAr
                                            ? 'مسدد لشهر ${now.month}'
                                            : 'Paid (${now.month})')
                                        : (isAr
                                            ? 'مستحق لشهر ${now.month}'
                                            : 'Due (${now.month})'),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: isPaidThisMonth
                                          ? Colors.green.shade700
                                          : Colors.orange.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l.t('category${ExpensesScreen._cap(item.category.name)}'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: catColor,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: item.isFixedAmount
                                    ? theme.colorScheme.primary
                                        .withValues(alpha: 0.1)
                                    : Colors.purple.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.isFixedAmount
                                    ? (isAr
                                        ? 'مبلغ ثابت: ${CurrencyFormatter.format(item.defaultAmount, item.currency, locale: locale)}'
                                        : 'Fixed: ${CurrencyFormatter.format(item.defaultAmount, item.currency, locale: locale)}')
                                    : (isAr
                                        ? 'مبلغ متغير شهرياً (${item.currency.code})'
                                        : 'Variable Amount (${item.currency.code})'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: item.isFixedAmount
                                      ? theme.colorScheme.primary
                                      : Colors.purple,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (user.isAdmin)
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.more_vert,
                          size: 19, color: theme.colorScheme.outline),
                      onSelected: (val) {
                        if (val == 'edit') onEdit();
                        if (val == 'delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined, size: 18),
                              const SizedBox(width: 8),
                              Text(l.edit),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(l.delete,
                                  style: const TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Mini 12-month visual strip for current year
              Row(
                children: List.generate(12, (idx) {
                  final m = idx + 1;
                  final paid = item.isPaidFor(now.year, m);
                  final isCurrent = m == now.month;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: paid
                            ? Colors.green.withValues(alpha: 0.18)
                            : isCurrent
                                ? Colors.orange.withValues(alpha: 0.2)
                                : theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: paid
                              ? Colors.green.withValues(alpha: 0.55)
                              : isCurrent
                                  ? Colors.orange.withValues(alpha: 0.7)
                                  : Colors.transparent,
                          width: isCurrent ? 1.2 : 0.8,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$m',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: paid
                              ? Colors.green.shade700
                              : isCurrent
                                  ? Colors.orange.shade800
                                  : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.calendar_month_rounded,
                      size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      isAr
                          ? 'اضغط لعرض سجل الأشهر ($paidMonthsThisYear/12 مسدد في ${now.year})'
                          : 'Tap for all months ($paidMonthsThisYear/12 paid in ${now.year})',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  if (!isPaidThisMonth && canPay)
                    FilledButton.tonalIcon(
                      onPressed: onPayCurrentMonth,
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded,
                          size: 16),
                      label: Text(
                        isAr ? 'تسديد شهر ${now.month}' : 'Pay Month ${now.month}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    )
                  else if (isPaidThisMonth)
                    Text(
                      CurrencyFormatter.format(
                        currentPayment.amount,
                        currentPayment.currency,
                        locale: locale,
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.green.shade700,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecurringExpenseFormSheet extends ConsumerStatefulWidget {
  const RecurringExpenseFormSheet({
    super.key,
    required this.by,
    this.existing,
  });

  final AppUser by;
  final RecurringExpense? existing;

  @override
  ConsumerState<RecurringExpenseFormSheet> createState() =>
      _RecurringExpenseFormSheetState();
}

class _RecurringExpenseFormSheetState
    extends ConsumerState<RecurringExpenseFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _notes;
  late ExpenseCategory _category;
  late AppCurrency _currency;
  late bool _isFixedAmount;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _title = TextEditingController(text: ex?.title ?? '');
    _amount = TextEditingController(
      text: ex != null && ex.defaultAmount > 0 ? '${ex.defaultAmount}' : '',
    );
    _notes = TextEditingController(text: ex?.note ?? '');
    _category = ex?.category ?? ExpenseCategory.rent;
    _currency = ex?.currency ?? AppCurrency.iqd;
    _isFixedAmount = ex?.isFixedAmount ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
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
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('،', '')
        .replaceAll(' ', '');
    return num.tryParse(normalized);
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.fieldRequired)));
      return;
    }
    final parsedAmount = _parseAmount(_amount.text) ?? 0;
    if (_isFixedAmount && parsedAmount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.invalidAmount)));
      return;
    }

    setState(() => _busy = true);
    try {
      final ex = widget.existing;
      final item = RecurringExpense(
        id: ex?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _title.text.trim(),
        category: _category,
        isFixedAmount: _isFixedAmount,
        defaultAmount: parsedAmount,
        currency: _currency,
        note: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        createdAt: ex?.createdAt ?? DateTime.now(),
        paidMonths: ex?.paidMonths ?? const {},
      );
      await ref
          .read(expensesRepositoryProvider)
          .saveRecurringExpense(widget.by, item);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              isAr ? 'تم حفظ الالتزام الشهري بنجاح' : 'Monthly expense saved'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء الحفظ: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null
                  ? (isAr
                      ? 'إضافة مصروف شهري ثابت'
                      : 'Add Fixed Monthly Expense')
                  : (isAr
                      ? 'تعديل المصروف الشهري'
                      : 'Edit Fixed Monthly Expense'),
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _title,
              decoration: InputDecoration(
                labelText: isAr
                    ? 'اسم المصروف الشهري (مثل: إيجار المكتب، راتب، كهرباء...)'
                    : 'Expense Title (e.g. Office Rent, Salary, Electricity)',
                prefixIcon: const Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<ExpenseCategory>(
              value: _category,
              decoration: InputDecoration(
                labelText: l.category,
                prefixIcon: const Icon(Icons.category_outlined),
              ),
              items: ExpenseCategory.values
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child:
                            Text(l.t('category${ExpensesScreen._cap(c.name)}')),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: true,
                  icon: const Icon(Icons.lock_clock_outlined, size: 18),
                  label: Text(isAr ? 'مبلغ ثابت شهرياً' : 'Fixed Amount'),
                ),
                ButtonSegment(
                  value: false,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: Text(
                      isAr ? 'مبلغ متغير (يحدد عند السداد)' : 'Variable Amount'),
                ),
              ],
              selected: {_isFixedAmount},
              onSelectionChanged: (s) =>
                  setState(() => _isFixedAmount = s.first),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _isFixedAmount
                          ? (isAr ? 'المبلغ الشهري الثابت' : 'Fixed Monthly Amount')
                          : (isAr
                              ? 'مبلغ افتراضي تقريبي (اختياري)'
                              : 'Estimated Default Amount (Optional)'),
                      prefixIcon: const Icon(Icons.payments_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<AppCurrency>(
                    value: _currency,
                    decoration: InputDecoration(labelText: l.currency),
                    items: AppCurrency.values
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c.code)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _currency = v ?? _currency),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notes,
              decoration: InputDecoration(
                labelText: isAr ? 'ملاحظات (اختياري)' : 'Notes (optional)',
                prefixIcon: const Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(l.save),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _RecurringExpenseMonthsDialog extends ConsumerStatefulWidget {
  const _RecurringExpenseMonthsDialog({
    required this.itemId,
    required this.initialItem,
    required this.user,
    required this.locale,
    required this.isAr,
  });

  final String itemId;
  final RecurringExpense initialItem;
  final AppUser user;
  final String locale;
  final bool isAr;

  @override
  ConsumerState<_RecurringExpenseMonthsDialog> createState() =>
      _RecurringExpenseMonthsDialogState();
}

class _RecurringExpenseMonthsDialogState
    extends ConsumerState<_RecurringExpenseMonthsDialog> {
  late int _selectedYear;
  String? _busyMonthKey;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
  }

  Future<void> _unpayMonth(
    RecurringExpense item,
    int year,
    int month,
  ) async {
    final key = RecurringExpense.monthKey(year, month);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            widget.isAr ? 'إلغاء تسديد الشهر' : 'Cancel Month Payment'),
        content: Text(
          widget.isAr
              ? 'هل تريد إلغاء تسديد شهر $month/$year لـ "${item.title}"؟ سيتم حذف المصروف المرتبط وإرجاع المبلغ للصندوق.'
              : 'Undo payment for month $month/$year of "${item.title}"? The linked expense will be removed and refunded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(widget.isAr ? 'تراجع' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(widget.isAr ? 'إلغاء التسديد' : 'Undo Payment'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _busyMonthKey = key);
    try {
      await ref.read(expensesRepositoryProvider).unpayRecurringExpenseMonth(
            by: widget.user,
            item: item,
            year: year,
            month: month,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isAr
                ? 'تم إلغاء تسديد شهر $month/$year'
                : 'Payment for $month/$year undone',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    } finally {
      if (mounted) setState(() => _busyMonthKey = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final recurringList = ref
            .watch(recurringExpensesStreamProvider(widget.user.adminUid))
            .valueOrNull ??
        const [];
    final item = recurringList
            .where((e) => e.id == widget.itemId)
            .firstOrNull ??
        widget.initialItem;

    final canPay = widget.user.can(Permission.addExpense);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.14),
                    child: Icon(Icons.event_repeat_rounded,
                        color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          item.isFixedAmount
                              ? (widget.isAr
                                  ? 'مبلغ شهري ثابت: ${CurrencyFormatter.format(item.defaultAmount, item.currency, locale: widget.locale)}'
                                  : 'Fixed Monthly: ${CurrencyFormatter.format(item.defaultAmount, item.currency, locale: widget.locale)}')
                              : (widget.isAr
                                  ? 'مبلغ متغير يحدد عند كل شهر (${item.currency.code})'
                                  : 'Variable monthly amount (${item.currency.code})'),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Year selector bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _selectedYear--),
                      icon: const Icon(Icons.chevron_left_rounded),
                      tooltip: widget.isAr ? 'السنة السابقة' : 'Previous Year',
                    ),
                    Text(
                      widget.isAr
                          ? 'سجل أشهر سنة $_selectedYear'
                          : 'Months of $_selectedYear',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _selectedYear++),
                      icon: const Icon(Icons.chevron_right_rounded),
                      tooltip: widget.isAr ? 'السنة التالية' : 'Next Year',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: 12,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final m = idx + 1;
                    final key = RecurringExpense.monthKey(_selectedYear, m);
                    final payment = item.paymentFor(_selectedYear, m);
                    final isPaid = payment != null;
                    final isCurrentMonth =
                        _selectedYear == now.year && m == now.month;
                    final isBusy = _busyMonthKey == key;
                    final monthLabel =
                        widget.isAr ? _arabicMonths[idx] : _englishMonths[idx];

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? Colors.green.withValues(alpha: 0.08)
                            : isCurrentMonth
                                ? Colors.orange.withValues(alpha: 0.09)
                                : theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPaid
                              ? Colors.green.withValues(alpha: 0.45)
                              : isCurrentMonth
                                  ? Colors.orange.withValues(alpha: 0.6)
                                  : theme.dividerColor.withValues(alpha: 0.35),
                          width: isCurrentMonth ? 1.4 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: isPaid
                                ? Colors.green.withValues(alpha: 0.18)
                                : isCurrentMonth
                                    ? Colors.orange.withValues(alpha: 0.2)
                                    : theme.colorScheme.surfaceContainerHighest,
                            child: Icon(
                              isPaid
                                  ? Icons.check_circle_rounded
                                  : isCurrentMonth
                                      ? Icons.notifications_active_outlined
                                      : Icons.calendar_today_outlined,
                              size: 18,
                              color: isPaid
                                  ? Colors.green.shade700
                                  : isCurrentMonth
                                      ? Colors.orange.shade800
                                      : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      monthLabel,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (isCurrentMonth) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: Colors.orange
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          widget.isAr
                                              ? 'الشهر الحالي'
                                              : 'Current',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.orange.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                if (isPaid)
                                  Text(
                                    widget.isAr
                                        ? 'مسدد: ${CurrencyFormatter.format(payment.amount, payment.currency, locale: widget.locale)} • بتاريخ ${DateFormatter.date(payment.paidAt, locale: widget.locale)} (${payment.paidByName ?? ""})'
                                        : 'Paid: ${CurrencyFormatter.format(payment.amount, payment.currency, locale: widget.locale)} • ${DateFormatter.date(payment.paidAt, locale: widget.locale)}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade700,
                                    ),
                                  )
                                else
                                  Text(
                                    item.isFixedAmount
                                        ? (widget.isAr
                                            ? 'غير مسدد • المطلوب: ${CurrencyFormatter.format(item.defaultAmount, item.currency, locale: widget.locale)}'
                                            : 'Unpaid • Due: ${CurrencyFormatter.format(item.defaultAmount, item.currency, locale: widget.locale)}')
                                        : (widget.isAr
                                            ? 'غير مسدد • يُحدد المبلغ عند التسديد'
                                            : 'Unpaid • Amount set on payment'),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isBusy)
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else if (isPaid)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.isAr ? 'مسدد ✓' : 'Paid ✓',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ),
                                if (widget.user.isAdmin) ...[
                                  const SizedBox(width: 4),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    tooltip: widget.isAr
                                        ? 'إلغاء التسديد'
                                        : 'Undo Payment',
                                    icon: const Icon(
                                        Icons.replay_rounded,
                                        size: 18,
                                        color: Colors.redAccent),
                                    onPressed: () =>
                                        _unpayMonth(item, _selectedYear, m),
                                  ),
                                ],
                              ],
                            )
                          else if (canPay)
                            FilledButton.tonal(
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => _PayRecurringMonthDialog(
                                  item: item,
                                  year: _selectedYear,
                                  month: m,
                                  user: widget.user,
                                  isAr: widget.isAr,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                              ),
                              child: Text(
                                widget.isAr ? 'تسديد' : 'Pay',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayRecurringMonthDialog extends ConsumerStatefulWidget {
  const _PayRecurringMonthDialog({
    required this.item,
    required this.year,
    required this.month,
    required this.user,
    required this.isAr,
  });

  final RecurringExpense item;
  final int year;
  final int month;
  final AppUser user;
  final bool isAr;

  @override
  ConsumerState<_PayRecurringMonthDialog> createState() =>
      _PayRecurringMonthDialogState();
}

class _PayRecurringMonthDialogState
    extends ConsumerState<_PayRecurringMonthDialog> {
  late final TextEditingController _amount;
  late MoneyStorage _paidFrom;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: widget.item.defaultAmount > 0
          ? '${widget.item.defaultAmount}'
          : '',
    );
    _paidFrom = MoneyStorage.cashbox;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
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
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('،', '')
        .replaceAll(' ', '');
    return num.tryParse(normalized);
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final loc = Localizations.localeOf(context).languageCode;
    final amount = _parseAmount(_amount.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.invalidAmount)));
      return;
    }

    if (_paidFrom == MoneyStorage.cashbox) {
      final cashbox =
          ref.read(cashboxStreamProvider(widget.user.adminUid)).valueOrNull;
      final available = cashbox?.balanceFor(widget.item.currency) ?? 0;
      if (amount > available) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'لا يمكن إتمام العملية: المبلغ المطلوب (${CurrencyFormatter.format(amount, widget.item.currency, locale: loc)}) يتجاوز رصيد الصندوق المتوفر (${CurrencyFormatter.format(available, widget.item.currency, locale: loc)})',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _busy = true);
    try {
      await ref.read(expensesRepositoryProvider).payRecurringExpenseMonth(
            by: widget.user,
            item: widget.item,
            year: widget.year,
            month: widget.month,
            amount: amount,
            paidFrom: _paidFrom,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isAr
                ? 'تم تسديد شهر ${widget.month}/${widget.year} لـ "${widget.item.title}"'
                : 'Paid month ${widget.month}/${widget.year} for "${widget.item.title}"',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء التسديد: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final loc = Localizations.localeOf(context).languageCode;
    final cashbox =
        ref.watch(cashboxStreamProvider(widget.user.adminUid)).valueOrNull;
    final availableBalance = cashbox?.balanceFor(widget.item.currency) ?? 0;

    return AlertDialog(
      title: Text(
        widget.isAr
            ? 'تسديد شهر ${widget.month}/${widget.year} — ${widget.item.title}'
            : 'Pay ${widget.month}/${widget.year} — ${widget.item.title}',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              autofocus: !widget.item.isFixedAmount,
              decoration: InputDecoration(
                labelText: widget.item.isFixedAmount
                    ? (widget.isAr
                        ? 'المبلغ الشهري (${widget.item.currency.code})'
                        : 'Monthly Amount (${widget.item.currency.code})')
                    : (widget.isAr
                        ? 'أدخل مبلغ هذا الشهر (${widget.item.currency.code})'
                        : 'Enter amount for this month (${widget.item.currency.code})'),
                prefixIcon: const Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<MoneyStorage>(
              value: _paidFrom,
              decoration: InputDecoration(
                labelText: l.t('expenseFunding'),
                helperText: _paidFrom == MoneyStorage.cashbox
                    ? 'الرصيد المتوفر في الصندوق: ${CurrencyFormatter.format(availableBalance, widget.item.currency, locale: loc)}'
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton.icon(
          onPressed: _busy ? null : _submit,
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_outline_rounded, size: 18),
          label: Text(widget.isAr ? 'تأكيد التسديد' : 'Confirm Payment'),
        ),
      ],
    );
  }
}

