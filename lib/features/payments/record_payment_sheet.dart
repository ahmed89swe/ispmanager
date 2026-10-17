import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/models/models.dart';
import '../../core/utils/formatters.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_repository.dart';
import '../subscribers/subscribers_repository.dart';
import 'advance_subscription_sheet.dart';

class RecordPaymentSheet extends ConsumerStatefulWidget {
  const RecordPaymentSheet({super.key, required this.subscriber});
  final Subscriber subscriber;

  @override
  ConsumerState<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<RecordPaymentSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  MoneyStorage _receivedIn = MoneyStorage.cashbox;
  DateTime _paymentDate = DateTime.now();
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
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

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final amount = num.tryParse(_amount.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.invalidAmount)));
      return;
    }
    final user = ref.read(currentAppUserProvider).valueOrNull;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      final p = Payment(
        id: '',
        subscriberId: widget.subscriber.id,
        amount: amount,
        currency: widget.subscriber.currency,
        receivedIn: _receivedIn,
        note: _note.text.trim().isNotEmpty
            ? _note.text.trim()
            : (_receivedIn == MoneyStorage.none
                ? 'تصفية حساب قديم (بدون صندوق)'
                : null),
        recordedBy: user.uid,
        recordedAt: _paymentDate,
      );
      await ref
          .read(subscribersRepositoryProvider)
          .recordPaymentAndDistribute(user, widget.subscriber, p);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.saved)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final loc = Localizations.localeOf(context).languageCode;
    final isAr = loc.startsWith('ar');
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
            Text('${l.recordPayment} — ${widget.subscriber.name}',
                style: Theme.of(context).textTheme.titleMedium),
            if (widget.subscriber.balance <= 0)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF1976D2).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: Color(0xFF1976D2)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'المشترك ليس عليه ديون حالية. لتسديد اشتراك قادم مقدماً:',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF0D47A1)),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        AdvanceSubscriptionSheet.show(
                            context, widget.subscriber);
                      },
                      child: const Text('تسديد مقدماً',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            TextField(
                controller: _amount,
                decoration: InputDecoration(labelText: l.amount),
                keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickPaymentDate,
              borderRadius: BorderRadius.circular(10),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: isAr ? 'تاريخ التسديد' : 'Payment Date',
                  prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                  suffixIcon: const Icon(Icons.edit_calendar_outlined, size: 18),
                ),
                child: Text(
                  DateFormatter.date(_paymentDate, locale: loc),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: widget.subscriber.currency.code,
              decoration: InputDecoration(
                labelText: l.currency,
                suffixIcon: const Icon(Icons.lock_outline, size: 18),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<MoneyStorage>(
              isExpanded: true,
              value: _receivedIn,
              decoration: InputDecoration(labelText: l.t('paymentDestination')),
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
            if (_receivedIn == MoneyStorage.none) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.amber.shade700.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: Colors.amber.shade900),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.t('noCashboxSettlementHint'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
                controller: _note,
                decoration: InputDecoration(labelText: l.note)),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: _busy ? null : _save,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
                child: Text(l.save)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
