import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_theme.dart';
import '../../core/constants.dart';
import '../../core/models/models.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/image_preview_dialog.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/providers/preferences_providers.dart';
import '../auth/auth_repository.dart';
import '../finance/cashbox_repository.dart';
import 'suppliers_repository.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentAppUserProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();
    final canManage = user.can(Permission.manageSuppliers);
    final canRequest = user.can(Permission.notifySupplierPayment);
    final list = ref.watch(suppliersStreamProvider(user.adminUid));
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.cardBorderColor(context),
                ),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon:
                      Icon(Icons.search, color: theme.colorScheme.primary),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  hintText: l.search,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
              ),
            ),
          ),
          Expanded(
            child: list.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (data) {
                final filtered = data
                    .where((s) =>
                        _query.isEmpty ||
                        s.name.toLowerCase().contains(_query) ||
                        (s.contactPhone ?? '').contains(_query))
                    .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hub_outlined,
                            size: 48, color: theme.colorScheme.outline),
                        const SizedBox(height: 8),
                        Text(l.noData, style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 840;
                    Widget buildSupplierCard(Supplier supplier) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: AppTheme.cardDecoration(context),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    SupplierDetailsScreen(supplier: supplier),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: theme.colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    child: Icon(
                                      Icons.hub_outlined,
                                      color: theme.colorScheme.primary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          supplier.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (supplier.contactPhone != null &&
                                            supplier.contactPhone!.isNotEmpty)
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.phone_outlined,
                                                size: 13,
                                                color: theme.colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                supplier.contactPhone!,
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  color: theme.colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          )
                                        else
                                          Text(
                                            l.suppliers,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (supplier.contactPhone != null &&
                                      supplier.contactPhone!.trim().isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.phone_outlined,
                                          color: Color(0xFF00A86B), size: 20),
                                      tooltip: supplier.contactPhone,
                                      onPressed: () async {
                                        final uri = Uri.parse(
                                            'tel:${supplier.contactPhone!.trim()}');
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri);
                                        }
                                      },
                                    ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'request' && canRequest) {
                                        await showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (_) =>
                                              SupplierPaymentRequestSheet(
                                                  supplier: supplier),
                                        );
                                      } else if (value == 'edit' && canManage) {
                                        await showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (_) => SupplierFormSheet(
                                              by: user, existing: supplier),
                                        );
                                      } else if (value == 'delete' &&
                                          canManage) {
                                        await ref
                                            .read(suppliersRepositoryProvider)
                                            .delete(user, supplier);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      if (canRequest)
                                        PopupMenuItem(
                                          value: 'request',
                                        child: Text(l.requestSupplierPayment),
                                      ),
                                    if (canManage)
                                      PopupMenuItem(
                                          value: 'edit', child: Text(l.edit)),
                                    if (canManage)
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text(l.delete,
                                            style: const TextStyle(
                                                color: Colors.red)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      )
                          .animate()
                          .fadeIn(duration: 200.ms)
                          .slideY(begin: 0.04, end: 0);
                    }

                    if (isWide) {
                      final rows = (filtered.length + 1) ~/ 2;
                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 4, bottom: 84),
                        itemCount: rows,
                        itemBuilder: (_, rowIdx) {
                          final first = filtered[rowIdx * 2];
                          final secondIdx = rowIdx * 2 + 1;
                          final second = secondIdx < filtered.length
                              ? filtered[secondIdx]
                              : null;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: buildSupplierCard(first)),
                              Expanded(
                                child: second != null
                                    ? buildSupplierCard(second)
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          );
                        },
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 84),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => buildSupplierCard(filtered[i]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => SupplierFormSheet(by: user),
              ),
              icon: const Icon(Icons.add),
              label: Text(l.newSupplier),
            )
          : null,
    );
  }
}

class SupplierFormSheet extends ConsumerStatefulWidget {
  const SupplierFormSheet({super.key, required this.by, this.existing});
  final AppUser by;
  final Supplier? existing;

  @override
  ConsumerState<SupplierFormSheet> createState() => _SupplierFormSheetState();
}

class _SupplierFormSheetState extends ConsumerState<SupplierFormSheet> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _phone =
      TextEditingController(text: widget.existing?.contactPhone ?? '');
  late final _email =
      TextEditingController(text: widget.existing?.contactEmail ?? '');
  late final _notes = TextEditingController(text: widget.existing?.notes ?? '');
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(suppliersRepositoryProvider);
      final supplier = Supplier(
        id: widget.existing?.id ?? '',
        name: _name.text.trim(),
        contactPhone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        contactEmail: _email.text.trim().isEmpty ? null : _email.text.trim(),
        logoUrl: widget.existing?.logoUrl,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        active: true,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      );
      if (widget.existing == null) {
        await repo.add(widget.by, supplier);
      } else {
        await repo.update(widget.by, supplier);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
          children: [
            Text(widget.existing == null ? l.newSupplier : l.edit,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: l.supplierName),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phone,
              decoration: InputDecoration(labelText: l.phone),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notes,
              decoration: InputDecoration(labelText: l.note),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(l.save),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class SupplierDetailsScreen extends ConsumerWidget {
  const SupplierDetailsScreen({super.key, required this.supplier});
  final Supplier supplier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentAppUserProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();
    final canManagePackages = user.can(Permission.manageSuppliers);
    final canManageBalance = user.can(Permission.manageSupplierPurchases);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(supplier.name),
          bottom: TabBar(tabs: [
            Tab(text: l.t('recharges')),
            Tab(text: l.packages),
          ]),
        ),
        body: TabBarView(
          children: [
            _SupplierBalanceTransactionsTab(
              supplier: supplier,
              by: user,
              type: SupplierBalanceTransactionType.recharge,
              canManage: canManageBalance,
            ),
            _PackagesTab(
              supplier: supplier,
              canManage: canManagePackages,
              by: user,
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierBalanceTransactionsTab extends ConsumerWidget {
  const _SupplierBalanceTransactionsTab({
    required this.supplier,
    required this.by,
    required this.type,
    required this.canManage,
  });

  final Supplier supplier;
  final AppUser by;
  final SupplierBalanceTransactionType type;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final loc = Localizations.localeOf(context).languageCode;
    final stream =
        ref.watch(suppliersRepositoryProvider).watchBalanceTransactions(
              by.adminUid,
              supplierId: supplier.id,
            );
    return Scaffold(
      body: StreamBuilder<List<SupplierBalanceTransaction>>(
        stream: stream,
        builder: (_, snap) {
          final list = (snap.data ?? [])
              .where((transaction) => transaction.type == type)
              .toList();
          if (list.isEmpty) return Center(child: Text(l.noData));
          final totalIqd = list
              .where((t) => t.currency == AppCurrency.iqd)
              .fold<num>(0, (sum, item) => sum + item.amount);
          final totalUsd = list
              .where((t) => t.currency == AppCurrency.usd)
              .fold<num>(0, (sum, item) => sum + item.amount);

          final String totalLabel;
          if (totalIqd > 0 && totalUsd > 0) {
            totalLabel =
                '${CurrencyFormatter.format(totalIqd, AppCurrency.iqd, locale: loc)} • ${CurrencyFormatter.format(totalUsd, AppCurrency.usd, locale: loc)}';
          } else if (totalUsd > 0) {
            totalLabel =
                CurrencyFormatter.format(totalUsd, AppCurrency.usd, locale: loc);
          } else {
            totalLabel =
                CurrencyFormatter.format(totalIqd, AppCurrency.iqd, locale: loc);
          }

          return ListView.separated(
            itemCount: list.length + 1,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, index) {
              if (index == 0) {
                return ListTile(
                  leading: Icon(type == SupplierBalanceTransactionType.recharge
                      ? Icons.add_card_outlined
                      : Icons.payments_outlined),
                  title: Text(l.total),
                  trailing: Text(
                    totalLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }
              final transaction = list[index - 1];
              final isPersonal = transaction.paidFrom == MoneyStorage.personal;
              final fundingLabel = isPersonal
                  ? (transaction.recordedByName.isNotEmpty
                      ? 'من جيب الموظف (${transaction.recordedByName})'
                      : 'من جيب الموظف')
                  : 'من الصندوق';
              return ListTile(
                leading: Icon(type == SupplierBalanceTransactionType.recharge
                    ? Icons.add_circle_outline
                    : Icons.check_circle_outline),
                title: Row(
                  children: [
                    Text(CurrencyFormatter.format(
                      transaction.amount,
                      transaction.currency,
                      locale: loc,
                    )),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPersonal
                            ? Colors.blue.withAlpha(25)
                            : Colors.teal.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPersonal
                              ? Colors.blue.withAlpha(70)
                              : Colors.teal.withAlpha(70),
                        ),
                      ),
                      child: Text(
                        fundingLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isPersonal
                              ? Colors.blue.shade800
                              : Colors.teal.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  '${DateFormatter.dateTime(transaction.date, locale: loc)}\n'
                  '${transaction.recordedByName.isEmpty ? '-' : transaction.recordedByName} • ${l.t(transaction.recordedByRole.name)}',
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (transaction.note != null &&
                        transaction.note!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          transaction.note!,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    if (transaction.receiptUrl != null &&
                        transaction.receiptUrl!.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.receipt_long_rounded,
                            color: Colors.blue),
                        tooltip: 'عرض صورة الوصل',
                        onPressed: () => showFullScreenImage(
                          context,
                          imageUrl: transaction.receiptUrl!,
                          title: 'وصل تعبئة مجهز',
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: Text(type == SupplierBalanceTransactionType.recharge
                  ? l.t('addRecharge')
                  : l.t('addSupplierPayment')),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => SupplierBalanceTransactionSheet(
                  supplier: supplier,
                  by: by,
                  type: type,
                ),
              ),
            )
          : null,
    );
  }
}

class SupplierBalanceTransactionSheet extends ConsumerStatefulWidget {
  const SupplierBalanceTransactionSheet({
    super.key,
    required this.supplier,
    required this.by,
    required this.type,
  });

  final Supplier supplier;
  final AppUser by;
  final SupplierBalanceTransactionType type;

  @override
  ConsumerState<SupplierBalanceTransactionSheet> createState() =>
      _SupplierBalanceTransactionSheetState();
}

class _SupplierBalanceTransactionSheetState
    extends ConsumerState<SupplierBalanceTransactionSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late AppCurrency _currency = ref.read(currencyProvider);
  MoneyStorage _paidFrom = MoneyStorage.cashbox;
  XFile? _receiptImage;
  Uint8List? _receiptImageBytes;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
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
    final amount = num.tryParse(_amount.text) ?? 0;
    if (amount <= 0) return;

    if (_paidFrom == MoneyStorage.cashbox) {
      final cashbox =
          ref.read(cashboxStreamProvider(widget.by.adminUid)).valueOrNull;
      final availableInBox = cashbox?.balanceFor(_currency) ?? 0;
      if (amount > availableInBox) {
        final loc = Localizations.localeOf(context).languageCode;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'لا يمكن إتمام التعبئة: المبلغ المطلوب (${CurrencyFormatter.format(amount, _currency, locale: loc)}) يتجاوز رصيد الصندوق المتوفر (${CurrencyFormatter.format(availableInBox, _currency, locale: loc)})',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _busy = true);
    try {
      String? receiptUrl;
      if (_receiptImage != null) {
        receiptUrl = await ref
            .read(suppliersRepositoryProvider)
            .uploadReceipt(
              adminUid: widget.by.adminUid,
              file: _receiptImage!,
            );
      }

      final transaction = SupplierBalanceTransaction(
        id: '',
        supplierId: widget.supplier.id,
        type: widget.type,
        amount: amount,
        currency: _currency,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        date: DateTime.now(),
        recordedBy: widget.by.uid,
        recordedByName: widget.by.displayName,
        recordedByRole: widget.by.role,
        paidFrom: _paidFrom,
        receiptUrl: receiptUrl,
      );
      await ref.read(suppliersRepositoryProvider).addBalanceTransaction(
            widget.by,
            transaction,
            supplierName: widget.supplier.name,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final loc = Localizations.localeOf(context).languageCode;
    final cashbox =
        ref.watch(cashboxStreamProvider(widget.by.adminUid)).valueOrNull;
    final availableInBox = cashbox?.balanceFor(_currency) ?? 0;

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
            Text(
              widget.type == SupplierBalanceTransactionType.recharge
                  ? l.t('addRecharge')
                  : l.t('addSupplierPayment'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              decoration: InputDecoration(labelText: l.amount),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<AppCurrency>(
              value: _currency,
              decoration: InputDecoration(labelText: l.currency),
              items: AppCurrency.values
                  .map((currency) => DropdownMenuItem(
                        value: currency,
                        child: Text(currency.code),
                      ))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _currency = value ?? _currency),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<MoneyStorage>(
              value: _paidFrom,
              decoration: InputDecoration(
                labelText: widget.type == SupplierBalanceTransactionType.recharge
                    ? 'طريقة دفع مبلغ التعبئة'
                    : l.t('expenseFunding'),
                helperText: _paidFrom == MoneyStorage.cashbox
                    ? 'الرصيد المتوفر في الصندوق: ${CurrencyFormatter.format(availableInBox, _currency, locale: loc)}'
                    : 'من جيب الموظف (يُضاف كدين على الصندوق للموظف)',
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
              controller: _note,
              decoration: InputDecoration(labelText: l.note),
            ),
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
                            'سيتم حفظ الوصل مع تفاصيل التعبئة',
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
                minimumSize: const Size.fromHeight(48),
              ),
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

class _PackagesTab extends ConsumerWidget {
  const _PackagesTab({
    required this.supplier,
    required this.canManage,
    required this.by,
  });

  final Supplier supplier;
  final bool canManage;
  final AppUser by;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final loc = Localizations.localeOf(context).languageCode;
    final stream = ref
        .watch(suppliersRepositoryProvider)
        .watchPackages(by.adminUid, supplier.id);
    return Scaffold(
      body: StreamBuilder<List<SupplierPackageTemplate>>(
        stream: stream,
        builder: (_, snap) {
          final list = snap.data ?? [];
          if (list.isEmpty) return Center(child: Text(l.noData));
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final package = list[i];
              return ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(package.name),
                subtitle: Text(
                  '${l.t('agentPrice')}: ${CurrencyFormatter.format(package.agentPrice, package.currency, locale: loc)}\n'
                  '${l.t('subscriberPrice')}: ${CurrencyFormatter.format(package.subscriberPrice, package.currency, locale: loc)}',
                ),
                isThreeLine: true,
                trailing: canManage
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => ref
                            .read(suppliersRepositoryProvider)
                            .deletePackage(by, package),
                      )
                    : null,
              );
            },
          );
        },
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: Text(l.newPackage),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) =>
                    PackageFormSheet(supplierId: supplier.id, by: by),
              ),
            )
          : null,
    );
  }
}

class PackageFormSheet extends ConsumerStatefulWidget {
  const PackageFormSheet(
      {super.key, required this.supplierId, required this.by});
  final String supplierId;
  final AppUser by;

  @override
  ConsumerState<PackageFormSheet> createState() => _PackageFormSheetState();
}

class _PackageFormSheetState extends ConsumerState<PackageFormSheet> {
  final _name = TextEditingController();
  final _agentPrice = TextEditingController();
  final _subscriberPrice = TextEditingController();
  late AppCurrency _currency = ref.read(currencyProvider);
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _agentPrice.dispose();
    _subscriberPrice.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    final agentPrice = num.tryParse(_agentPrice.text) ?? 0;
    final subscriberPrice = num.tryParse(_subscriberPrice.text) ?? 0;
    setState(() => _busy = true);
    try {
      final package = SupplierPackageTemplate(
        id: '',
        supplierId: widget.supplierId,
        name: _name.text.trim(),
        agentPrice: agentPrice,
        subscriberPrice: subscriberPrice,
        currency: _currency,
        active: true,
      );
      await ref
          .read(suppliersRepositoryProvider)
          .addPackage(widget.by, package);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
          children: [
            Text(l.newPackage, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: l.name),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _agentPrice,
              decoration: InputDecoration(labelText: l.t('agentPrice')),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _subscriberPrice,
              decoration: InputDecoration(labelText: l.t('subscriberPrice')),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<AppCurrency>(
              value: _currency,
              decoration: InputDecoration(labelText: l.currency),
              items: AppCurrency.values
                  .map((currency) => DropdownMenuItem(
                        value: currency,
                        child: Text(currency.code),
                      ))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _currency = value ?? _currency),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(l.save),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class SupplierPaymentRequestSheet extends ConsumerStatefulWidget {
  const SupplierPaymentRequestSheet({super.key, required this.supplier});
  final Supplier supplier;

  @override
  ConsumerState<SupplierPaymentRequestSheet> createState() =>
      _SupplierPaymentRequestSheetState();
}

class _SupplierPaymentRequestSheetState
    extends ConsumerState<SupplierPaymentRequestSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late AppCurrency _currency = ref.read(currencyProvider);

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${l.requestSupplierPayment} - ${widget.supplier.name}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            decoration: InputDecoration(labelText: l.amount),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<AppCurrency>(
            value: _currency,
            decoration: InputDecoration(labelText: l.currency),
            items: AppCurrency.values
                .map((currency) => DropdownMenuItem(
                      value: currency,
                      child: Text(currency.code),
                    ))
                .toList(),
            onChanged: (value) =>
                setState(() => _currency = value ?? _currency),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _note,
            decoration: InputDecoration(labelText: l.note),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final user = ref.read(currentAppUserProvider).valueOrNull!;
              final amount = num.tryParse(_amount.text) ?? 0;
              if (amount <= 0) return;
              final request = SupplierPaymentRequest(
                id: '',
                supplierId: widget.supplier.id,
                amount: amount,
                currency: _currency,
                note: _note.text.trim().isEmpty ? null : _note.text.trim(),
                byEmployeeUid: user.uid,
                byEmployeeName: user.displayName,
                status: PaymentRequestStatus.pending,
                createdAt: DateTime.now(),
              );
              await ref.read(suppliersRepositoryProvider).createRequest(
                    user,
                    request,
                  );
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: Text(l.save),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
