import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/sms_message.dart';
import '../services/sms_service.dart';
import '../widgets/debit_dialog.dart';

class SmsListener {
  static final SmsListener _instance = SmsListener._internal();

  factory SmsListener() {
    return _instance;
  }

  SmsListener._internal();

  /// Initialize SMS listener and check permissions
  Future<void> initialize(BuildContext context) async {
    final smsService = SmsService();
    
    // Request SMS permission
    final hasPermission = await smsService.requestSmsPermission();
    if (!hasPermission) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMS permission denied. Enable it in settings to auto-import bank messages.')),
        );
      }
      return;
    }

    // Check for pending debit transactions on first load
    _checkPendingDebits(context);
  }

  /// Check for pending debit messages and show dialog if found
  void _checkPendingDebits(BuildContext context) async {
    final smsService = SmsService();
    final debitMessage = await smsService.getLatestDebitMessage();

    if (debitMessage != null && context.mounted) {
      _showDebitDialog(context, debitMessage);
    }
  }

  /// Show debit dialog and handle the purpose submission
  void _showDebitDialog(BuildContext context, SmsMessage debitMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DebitDialog(
        debitMessage: debitMessage,
        onPurposeSubmitted: (purpose) {
          // TODO: Save the debit transaction with the purpose to Hive
          // For now, just print it
          print('Debit of ${debitMessage.extractAmount()} ETB for: $purpose');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Transaction saved: $purpose')),
          );
        },
      ),
    );
  }
}
