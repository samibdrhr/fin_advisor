import 'package:flutter/material.dart';
import '../models/sms_message.dart';

class DebitDialog extends StatefulWidget {
  final SmsMessage debitMessage;
  final Function(String) onPurposeSubmitted;

  const DebitDialog({required this.debitMessage, required this.onPurposeSubmitted, super.key});

  @override
  State<DebitDialog> createState() => _DebitDialogState();
}

class _DebitDialogState extends State<DebitDialog> {
  late TextEditingController _purposeController;
  final List<String> _commonPurposes = ['Food & Groceries', 'Transportation', 'Utilities', 'Entertainment', 'Shopping', 'Medical', 'Education', 'Other'];

  @override
  void initState() {
    super.initState();
    _purposeController = TextEditingController();
  }

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.debitMessage.extractAmount();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.payment, size: 40, color: Colors.orange),
              const SizedBox(height: 16),
              Text('Debit Transaction', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (amount != null)
                Text('ETB ${amount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.red, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('What was this payment for?', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: _commonPurposes.map((purpose) => ChoiceChip(label: Text(purpose), selected: _purposeController.text == purpose, onSelected: (selected) {
                  setState(() => _purposeController.text = purpose);
                })).toList(),
              ),
              const SizedBox(height: 16),
              TextField(controller: _purposeController, decoration: InputDecoration(hintText: 'Enter custom purpose', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), maxLines: 2),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_purposeController.text.isNotEmpty) {
                          widget.onPurposeSubmitted(_purposeController.text);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Save'),
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
