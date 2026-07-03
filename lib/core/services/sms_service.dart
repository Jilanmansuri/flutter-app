import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';
import '../../models/transaction_model.dart';
import '../constants/constants.dart';

class SmsService {
  final Telephony _telephony = Telephony.instance;

  // Request SMS Read permission
  Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  // Check if SMS permission is granted
  Future<bool> isPermissionGranted() async {
    return await Permission.sms.isGranted;
  }

  // Read transactions from SMS Inbox
  Future<List<TransactionModel>> readTransactionalSms(String userId) async {
    final bool granted = await isPermissionGranted();
    if (!granted) {
      final success = await requestPermission();
      if (!success) return [];
    }

    try {
      List<SmsMessage> messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)]
      );

      List<TransactionModel> parsedTransactions = [];
      
      for (var msg in messages) {
        final body = msg.body ?? '';
        final sender = msg.address ?? '';
        
        if (_isTransactional(body, sender)) {
          final tx = _parseSms(body, sender, userId, msg.date);
          if (tx != null) {
            parsedTransactions.add(tx);
          }
        }
      }
      return parsedTransactions;
    } catch (e) {
      print('Error reading SMS: $e');
      return [];
    }
  }

  // Helper to determine if an SMS is transactional (ignores personal and promotional messages)
  bool _isTransactional(String body, String sender) {
    final cleanBody = body.toLowerCase();
    
    // Quick checks for common promotional indicators
    if (cleanBody.contains('apply now') ||
        cleanBody.contains('congratulations') ||
        cleanBody.contains('win prize') ||
        cleanBody.contains('pre-approved') ||
        cleanBody.contains('discounts') ||
        cleanBody.contains('loan offer')) {
      return false;
    }

    // Checking common banking and payment keywords
    final hasTxKeywords = cleanBody.contains('debited') ||
        cleanBody.contains('credited') ||
        cleanBody.contains('sent rs') ||
        cleanBody.contains('received rs') ||
        cleanBody.contains('spent') ||
        cleanBody.contains('transaction') ||
        cleanBody.contains('withdrawn') ||
        cleanBody.contains('payment of') ||
        cleanBody.contains('declined') ||
        cleanBody.contains('failed');

    final isNumericSender = RegExp(r'[a-zA-Z0-9]{6,}').hasMatch(sender);
    
    return hasTxKeywords && isNumericSender;
  }

  // Regular expression parsing logic to extract transactional parameters
  TransactionModel? _parseSms(String body, String sender, String userId, int? epochDate) {
    final cleanBody = body.replaceAll(',', ''); // remove comma for easy number parsing
    final date = epochDate != null ? DateTime.fromMillisecondsSinceEpoch(epochDate) : DateTime.now();
    final timeStr = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

    // 1. Determine Debit vs Credit
    String type = 'expense'; // default
    final isCredit = RegExp(r'(credited|received|deposited|refunded|added)', caseSensitive: false).hasMatch(cleanBody);
    final isDebit = RegExp(r'(debited|sent|withdrawn|spent|charged|paid)', caseSensitive: false).hasMatch(cleanBody);
    
    if (isCredit && !isDebit) {
      type = 'income';
    } else if (isDebit) {
      type = 'expense';
    }

    // 2. Extract Amount
    double amount = 0.0;
    // Matches common amount formats like Rs. 500, Rs 500, INR 500, Rs.500.00, $500, etc.
    final amtRegex = RegExp(r'(?:rs\.?|inr|usd|\$)\s*(\d+(?:\.\d{1,2})?)', caseSensitive: false);
    final amtMatch = amtRegex.firstMatch(cleanBody);
    if (amtMatch != null) {
      amount = double.tryParse(amtMatch.group(1) ?? '0.0') ?? 0.0;
    } else {
      // Secondary amount regex check for raw numbers near transaction keywords
      final fallbackAmtRegex = RegExp(r'(?:spent|debited|credited|of)\s*(\d+(?:\.\d{1,2})?)', caseSensitive: false);
      final fallbackMatch = fallbackAmtRegex.firstMatch(cleanBody);
      if (fallbackMatch != null) {
        amount = double.tryParse(fallbackMatch.group(1) ?? '0.0') ?? 0.0;
      }
    }

    if (amount <= 0) return null; // Unrecognized transaction amount

    // 3. Extract Card / Account Number (last 4 digits)
    String? accountLast4;
    final accRegex = RegExp(r'(?:a/c|acct|card|account|xx|x)\s*(?:ending)?\s*([0-9]*[0-9]{4})\b', caseSensitive: false);
    final accMatch = accRegex.firstMatch(cleanBody);
    if (accMatch != null) {
      final matchStr = accMatch.group(1) ?? '';
      if (matchStr.length >= 4) {
        accountLast4 = matchStr.substring(matchStr.length - 4);
      }
    }

    // 4. Extract UPI ID
    String? upiId;
    final upiRegex = RegExp(r'([a-zA-Z0-9.\-_]+@[a-zA-Z0-9.\-_]+)', caseSensitive: false);
    final upiMatch = upiRegex.firstMatch(cleanBody);
    if (upiMatch != null) {
      upiId = upiMatch.group(1);
    }

    // 5. Extract Bank / Wallet Name (from sender or message body)
    String bankName = sender.toUpperCase();
    if (bankName.length >= 6) {
      // Typically bank SMS senders are like "AD-HDFCBK" or "VK-SBIINB"
      final bankParts = bankName.split('-');
      if (bankParts.length > 1) {
        bankName = bankParts[1];
      }
    }
    
    // Look for bank keywords in body if sender is cryptic
    final bodyBankRegex = RegExp(r'\b(SBI|HDFC|ICICI|AXIS|PAYTM|GPAY|PHONEPE|AMAZONPAY|KOTAK|BOB|PNB)\b', caseSensitive: false);
    final bodyBankMatch = bodyBankRegex.firstMatch(cleanBody);
    if (bodyBankMatch != null) {
      bankName = bodyBankMatch.group(1)!.toUpperCase();
    }

    // 6. Extract Merchant / Receiver Name
    String? merchant;
    final merchantRegex = RegExp(r'(?:at|to|info:?|ref:?)\s+([a-zA-Z0-9\s.\-_]+?)(?:\s+on|\s+ref|\s+bal|\s+via|\.|\b)', caseSensitive: false);
    final merchantMatch = merchantRegex.firstMatch(cleanBody);
    if (merchantMatch != null) {
      merchant = merchantMatch.group(1)?.trim();
    }
    
    // Filter merchant name to exclude common generic phrases
    if (merchant != null && (merchant.toLowerCase().contains('account') || merchant.toLowerCase().contains('card') || merchant.length < 3)) {
      merchant = null;
    }

    // 7. Extract Available Balance
    double? availableBalance;
    final balRegex = RegExp(r'(?:bal|balance|avl bal)\s*(?:is)?\s*(?:rs\.?|inr)?\s*(\d+(?:\.\d{1,2})?)', caseSensitive: false);
    final balMatch = balRegex.firstMatch(cleanBody);
    if (balMatch != null) {
      availableBalance = double.tryParse(balMatch.group(1) ?? '');
    }

    // 8. Auto-categorize based on keywords in body/merchant
    final category = _autoCategorize(cleanBody, merchant);

    final paymentMethod = upiId != null ? 'UPI' : (accountLast4 != null ? 'Bank Transfer' : 'Cash');

    return TransactionModel(
      id: 'sms_${epochDate ?? DateTime.now().millisecondsSinceEpoch}_${amount.toInt()}',
      userId: userId,
      amount: amount,
      type: type,
      category: category,
      date: date,
      time: timeStr,
      paymentMethod: paymentMethod,
      notes: body,
      bankName: bankName,
      accountLast4: accountLast4,
      upiId: upiId,
      isSmsAutoRead: true,
      availableBalance: availableBalance,
      updatedAt: DateTime.now(),
    );
  }

  // Automatic categorization routine using keywords
  String _autoCategorize(String text, String? merchant) {
    final content = '${text.toLowerCase()} ${merchant?.toLowerCase() ?? ""}';

    if (content.contains('swiggy') || content.contains('zomato') || content.contains('restaurant') || content.contains('food') || content.contains('cafe') || content.contains('dining') || content.contains('starbucks')) {
      return 'Food';
    }
    if (content.contains('amazon') || content.contains('flipkart') || content.contains('myntra') || content.contains('shopping') || content.contains('mall') || content.contains('fashion')) {
      return 'Shopping';
    }
    if (content.contains('uber') || content.contains('ola') || content.contains('irctc') || content.contains('rail') || content.contains('metro') || content.contains('cab') || content.contains('travel') || content.contains('flight')) {
      return 'Travel';
    }
    if (content.contains('petrol') || content.contains('fuel') || content.contains('shell') || content.contains('cng') || content.contains('diesel') || content.contains('hpc') || content.contains('iocl')) {
      return 'Fuel';
    }
    if (content.contains('hospital') || content.contains('medical') || content.contains('pharmacy') || content.contains('medicine') || content.contains('doctor') || content.contains('clinic')) {
      return 'Medical';
    }
    if (content.contains('netflix') || content.contains('spotify') || content.contains('prime') || content.contains('movie') || content.contains('hotstar') || content.contains('pvr') || content.contains('theater')) {
      return 'Entertainment';
    }
    if (content.contains('school') || content.contains('college') || content.contains('tuition') || content.contains('book') || content.contains('education') || content.contains('course') || content.contains('udemy')) {
      return 'Education';
    }
    if (content.contains('mutual fund') || content.contains('zerodha') || content.contains('groww') || content.contains('stock') || content.contains('shares') || content.contains('sip') || content.contains('investment')) {
      return 'Investment';
    }
    if (content.contains('electricity') || content.contains('electricity bill') || content.contains('water bill') || content.contains('broadband') || content.contains('wi-fi') || content.contains('recharge') || content.contains('dth') || content.contains('postpaid')) {
      return 'Bills';
    }
    if (content.contains('rent') || content.contains('landlord') || content.contains('pg accommodation')) {
      return 'Rent';
    }
    if (content.contains('salary') || content.contains('credited with salary') || content.contains('payroll')) {
      return 'Salary';
    }
    if (content.contains('fiverr') || content.contains('upwork') || content.contains('freelance') || content.contains('consulting')) {
      return 'Freelance';
    }

    // Default categorized transactions
    return 'Others';
  }
}
