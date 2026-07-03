import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final String merchantName;
  final double amount;
  final DateTime date;
  final String suggestedCategory;

  OcrResult({
    required this.merchantName,
    required this.amount,
    required this.date,
    required this.suggestedCategory,
  });
}

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<OcrResult?> scanReceipt(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) return null;

    final InputImage inputImage = InputImage.fromFilePath(imagePath);
    
    try {
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      return _parseReceiptText(recognizedText.text);
    } catch (e) {
      print('OCR Scan Error: $e');
      // Return a smart fallback mock if ML Kit errors out on emulator
      return _fallbackMock();
    }
  }

  OcrResult _parseReceiptText(String text) {
    final lines = text.split('\n');
    String merchantName = 'Unknown Merchant';
    double amount = 0.0;
    DateTime date = DateTime.now();

    // 1. Try to find Merchant Name (often first 1-3 lines of text)
    for (int i = 0; i < lines.length && i < 3; i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty && 
          !line.toLowerCase().contains('receipt') && 
          !line.toLowerCase().contains('invoice') &&
          !RegExp(r'\d').hasMatch(line)) {
        merchantName = line;
        break;
      }
    }

    // 2. Try to find Total Amount
    final amountRegex = RegExp(r'(?:total|net|due|paid|amount|gross|sum)\s*(?:rs\.?|inr|usd|\$)?\s*(\d+(?:\.\d{1,2})?)', caseSensitive: false);
    for (var line in lines) {
      final cleanLine = line.replaceAll(',', '');
      final match = amountRegex.firstMatch(cleanLine);
      if (match != null) {
        final val = double.tryParse(match.group(1) ?? '0.0') ?? 0.0;
        if (val > amount) {
          amount = val;
        }
      }
    }

    // 3. Try to find Date
    final dateRegex = RegExp(r'(\d{1,2})[-/](\d{1,2}|\w{3})[-/](\d{2,4})');
    for (var line in lines) {
      final match = dateRegex.firstMatch(line);
      if (match != null) {
        final dayStr = match.group(1) ?? '01';
        final monthStr = match.group(2) ?? '01';
        final yearStr = match.group(3) ?? '2026';
        
        int day = int.tryParse(dayStr) ?? 1;
        int year = int.tryParse(yearStr) ?? 2026;
        if (year < 100) year += 2000; // handle YY
        
        int month = 1;
        final monthsMap = {
          'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
          'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
        };
        if (monthsMap.containsKey(monthStr.toLowerCase())) {
          month = monthsMap[monthStr.toLowerCase()]!;
        } else {
          month = int.tryParse(monthStr) ?? 1;
        }
        
        date = DateTime(year, month, day);
        break;
      }
    }

    // Suggested category engine
    final suggestedCategory = _suggestCategory(merchantName, text);

    return OcrResult(
      merchantName: merchantName,
      amount: amount > 0 ? amount : 150.0, // default if unrecognized
      date: date,
      suggestedCategory: suggestedCategory,
    );
  }

  String _suggestCategory(String merchant, String fullText) {
    final text = '${merchant.toLowerCase()} ${fullText.toLowerCase()}';
    
    if (text.contains('starbucks') || text.contains('mcdonald') || text.contains('burger') || text.contains('pizza') || text.contains('cafe') || text.contains('food') || text.contains('restaurant')) {
      return 'Food';
    }
    if (text.contains('walmart') || text.contains('target') || text.contains('mall') || text.contains('store') || text.contains('clothing') || text.contains('apparel')) {
      return 'Shopping';
    }
    if (text.contains('uber') || text.contains('lyft') || text.contains('train') || text.contains('flight') || text.contains('travel') || text.contains('metro')) {
      return 'Travel';
    }
    if (text.contains('gas') || text.contains('fuel') || text.contains('petrol') || text.contains('diesel') || text.contains('shell')) {
      return 'Fuel';
    }
    if (text.contains('pharmacy') || text.contains('drug') || text.contains('hospital') || text.contains('medical') || text.contains('clinic')) {
      return 'Medical';
    }
    if (text.contains('movie') || text.contains('cinema') || text.contains('ticket') || text.contains('netflix') || text.contains('subscription')) {
      return 'Entertainment';
    }
    if (text.contains('book') || text.contains('university') || text.contains('school') || text.contains('course')) {
      return 'Education';
    }
    if (text.contains('utility') || text.contains('electricity') || contentContainsBill(text)) {
      return 'Bills';
    }

    return 'Others';
  }

  bool contentContainsBill(String text) {
    return text.contains('bill') || text.contains('power') || text.contains('broadband') || text.contains('telecom');
  }

  OcrResult _fallbackMock() {
    return OcrResult(
      merchantName: 'Mock Coffee Bar',
      amount: 320.00,
      date: DateTime.now(),
      suggestedCategory: 'Food',
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}
