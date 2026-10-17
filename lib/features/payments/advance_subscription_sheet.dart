import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/models/models.dart';
import '../../core/utils/formatters.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_repository.dart';
import '../subscribers/subscribers_repository.dart';

class AdvanceSubscriptionSheet extends ConsumerStatefulWidget {
  const AdvanceSubscriptionSheet({super.key, required this.subscriber});

  final Subscriber subscriber;

  static Future<void> show(BuildContext context, Subscriber subscriber) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdvanceSubscriptionSheet(subscriber: subscriber),
    );
  }

  @override
  ConsumerState<AdvanceSubscriptionSheet> createState() =>
      _AdvanceSubscriptionSheetState();
}

class _AdvanceSubscriptionSheetState
    extends ConsumerState<AdvanceSubscriptionSheet> {
  int _cycles = 1;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  MoneyStorage _receivedIn = MoneyStorage.cashbox;
  DateTime _paymentDate = DateTime.now();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final defaultAmount = widget.subscriber.monthlyFee * _cycles;
    _amountController =
        TextEditingController(text: defaultAmount > 0 ? '$defaultAmount' : '');
    _noteController =
        TextEditingController(text: 'تسديد اشتراك قادم مقدماً (دورة واحدة)');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onCyclesChanged(int newCycles) {
    setState(() {
      _cycles = newCycles;
      final newAmount = widget.subscriber.monthlyFee * _cycles;
      _amountController.text = newAmount > 0 ? '$newAmount' : '';
      _noteController.text = _cycles == 1
          ? 'تسديد اشتراك قادم مقدماً (دورة واحدة)'
          : 'تسديد اشتراك قادم مقدماً ($_cycles دورات)';
    });
  }

  Future<void> _pickPaymentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final now = DateTime.now();
      setState(() {
        _paymentDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          now.hour,
          now.minute,
          now.second,
        );
      });
    }
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final amount = num.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invalidAmount)),
      );
      return;
    }

    final user = ref.read(currentAppUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(subscribersRepositoryProvider)
          .recordAdvanceSubscriptionPayment(
            user,
            widget.subscriber,
            amount: amount,
            receivedIn: _receivedIn,
            cycles: _cycles,
            paidAt: _paymentDate,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF00A86B),
            content: Text(l.t('advancePaymentRecorded')),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final loc = Localizations.localeOf(context).languageCode;
    final isDark = theme.brightness == Brightness.dark;

    final sub = widget.subscriber;
    final upcomingStart = sub.subscriptionEndsAt;
    final upcomingEnd = DateFormatter.addDays(upcomingStart, 30 * _cycles);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_repeat_rounded,
                    color: Color(0xFF1976D2),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.t('payAdvanceSubscriptionTitle'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        sub.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Period Information Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF1976D2),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l.t('upcomingPeriod'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D47A1),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${DateFormatter.date(upcomingStart, locale: loc)}  ⬅  ${DateFormatter.date(upcomingEnd, locale: loc)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.t('advancePaymentInfo'),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  if (sub.prepaidCycles > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ملاحظة: المشترك لديه بالفعل ${sub.prepaidCycles} دورة مسددة مقدماً. إضافة هذه الدفعة ستزيد الرصيد المدفوع مقدماً إلى ${sub.prepaidCycles + _cycles} دورات.',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.brown,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Cycles selector
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.t('cyclesCount'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text('1')),
                    ButtonSegment(value: 2, label: Text('2')),
                    ButtonSegment(value: 3, label: Text('3')),
                  ],
                  selected: {_cycles},
                  onSelectionChanged: (set) {
                    if (set.isNotEmpty) _onCyclesChanged(set.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Amount field
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l.amount,
                suffixText: sub.currency.code,
                prefixIcon: const Icon(Icons.attach_money_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Payment date field
            InkWell(
              onTap: _pickPaymentDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText:
                      loc.startsWith('ar') ? 'تاريخ التسديد' : 'Payment Date',
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  suffixIcon: const Icon(Icons.edit_calendar_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  DateFormatter.date(_paymentDate, locale: loc),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Payment destination (Cashbox vs Collector)
            DropdownButtonFormField<MoneyStorage>(
              isExpanded: true,
              initialValue: _receivedIn,
              decoration: InputDecoration(
                labelText: l.t('paymentDestination'),
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: MoneyStorage.cashbox,
                  child: Text(l.t('putInCashbox')),
                ),
                DropdownMenuItem(
                  value: MoneyStorage.personal,
                  child: Text(l.t('keptByCollectorDebt')),
                ),
                DropdownMenuItem(
                  value: MoneyStorage.none,
                  child: Text(l.t('noCashboxSettlement')),
                ),
              ],
              onChanged: (v) =>
                  setState(() => _receivedIn = v ?? MoneyStorage.cashbox),
            ),
            const SizedBox(height: 12),

            // Note field
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: l.note,
                prefixIcon: const Icon(Icons.note_alt_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                _busy ? 'جاري الحفظ…' : 'تأكيد تسديد الاشتراك القادم',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
