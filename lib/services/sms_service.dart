import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

class DetectedTransaction {
  final String title;
  final double amount;
  final bool isIncome;
  final DateTime date;
  final String rawBody;
  final String sender;
  final String? suggestedAccountName; // Telebirr, CBE, etc.

  DetectedTransaction({
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.date,
    required this.rawBody,
    required this.sender,
    this.suggestedAccountName,
  });
}

class SmsService {
  static Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  static Future<bool> hasPermission() async {
    return await Permission.sms.isGranted;
  }

  /// Scan recent SMS and return possible bank/Telebirr transactions
  static Future<List<DetectedTransaction>> scanRecentSms({int days = 14}) async {
    final hasPerm = await hasPermission();
    if (!hasPerm) {
      final granted = await requestPermission();
      if (!granted) return [];
    }

    final query = SmsQuery();
    final messages = await query.querySms(
      kinds: [SmsQueryKind.inbox],
      count: 200,
    );

    final cutoff = DateTime.now().subtract(Duration(days: days));
    final detected = <DetectedTransaction>[];

    for (final msg in messages) {
      if (msg.date == null || msg.date!.isBefore(cutoff)) continue;
      final body = msg.body ?? '';
      final sender = msg.sender ?? '';
      final parsed = _parseEthiopianSms(body, sender, msg.date!);
      if (parsed != null) {
        detected.add(parsed);
      }
    }

    // Sort newest first
    detected.sort((a, b) => b.date.compareTo(a.date));
    return detected;
  }

  static DetectedTransaction? _parseEthiopianSms(
      String body, String sender, DateTime date) {
    final lower = body.toLowerCase();
    final senderLower = sender.toLowerCase();

    // Detect provider
    String? provider;
    if (senderLower.contains('telebirr') ||
        lower.contains('telebirr') ||
        lower.contains('ethio telecom')) {
      provider = 'Telebirr';
    } else if (senderLower.contains('cbe') ||
        lower.contains('commercial bank of ethiopia') ||
        lower.contains('cbe birr')) {
      provider = 'CBE';
    } else if (senderLower.contains('dashen') || lower.contains('dashen')) {
      provider = 'Dashen Bank';
    } else if (senderLower.contains('awash') || lower.contains('awash')) {
      provider = 'Awash Bank';
    } else if (senderLower.contains('abyssinia') ||
        lower.contains('bank of abyssinia')) {
      provider = 'Bank of Abyssinia';
    } else if (lower.contains('debited') ||
        lower.contains('credited') ||
        lower.contains('transferred') ||
        lower.contains('received') ||
        lower.contains('sent')) {
      // Generic financial SMS
      provider = 'Bank';
    } else {
      return null;
    }

    // Extract amount (ETB patterns)
    final amountRegex = RegExp(
      r'(?:etb|br|birr)?\s*([\d,]+\.?\d*)\s*(?:etb|br|birr)?',
      caseSensitive: false,
    );
    final match = amountRegex.firstMatch(body);
    if (match == null) return null;

    double? amount;
    try {
      amount = double.parse(match.group(1)!.replaceAll(',', ''));
    } catch (_) {
      return null;
    }
    if (amount <= 0) return null;

    // Determine income vs expense
    bool isIncome = false;
    if (lower.contains('received') ||
        lower.contains('credited') ||
        lower.contains('deposit') ||
        lower.contains('you have received') ||
        lower.contains('has been credited')) {
      isIncome = true;
    } else if (lower.contains('sent') ||
        lower.contains('debited') ||
        lower.contains('withdrawn') ||
        lower.contains('paid') ||
        lower.contains('transfer to') ||
        lower.contains('you have sent')) {
      isIncome = false;
    } else {
      // default to expense if unclear
      isIncome = false;
    }

    final title = isIncome
        ? 'Received via $provider'
        : 'Sent via $provider';

    return DetectedTransaction(
      title: title,
      amount: amount,
      isIncome: isIncome,
      date: date,
      rawBody: body,
      sender: sender,
      suggestedAccountName: provider,
    );
  }
}
