import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/models/models.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_repository.dart';
import '../subscribers/subscribers_repository.dart';

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
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
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
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        recordedBy: user.uid,
        recordedAt: DateTime.now(),
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
          Text('${l.recordPayment} — ${widget.subscriber.name}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
              controller: _amount,
              decoration: InputDecoration(labelText: l.amount),
              keyboardType: TextInputType.number),
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
            ],
            onChanged: (v) =>
                setState(() => _receivedIn = v ?? MoneyStorage.cashbox),
          ),
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
    );
  }
}
