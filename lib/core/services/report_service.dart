import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../models/transaction_model.dart';
import 'hive_service.dart';

class ReportService {
  final HiveService _hiveService = HiveService();

  // Generate and Share PDF Report
  Future<void> exportPdfReport(List<TransactionModel> transactions, String title) async {
    final pdf = pw.Document();
    final currency = _hiveService.baseCurrency;

    final income = transactions.where((tx) => tx.type == 'income').fold(0.0, (sum, tx) => sum + tx.amount);
    final expense = transactions.where((tx) => tx.type == 'expense').fold(0.0, (sum, tx) => sum + tx.amount);
    final net = income - expense;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Smart Finance Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(title, style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Financial Summary Block
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildPdfSummaryCard('Total Income', '$currency${income.toStringAsFixed(2)}', PdfColors.green700),
                _buildPdfSummaryCard('Total Expense', '$currency${expense.toStringAsFixed(2)}', PdfColors.red700),
                _buildPdfSummaryCard('Net Savings', '$currency${net.toStringAsFixed(2)}', PdfColors.blue700),
              ],
            ),
            pw.SizedBox(height: 30),
            
            pw.Text('Transaction Log', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),

            // Table Grid
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Category', 'Payment Method', 'Type', 'Amount (Rs)'],
              data: transactions.map((tx) {
                return [
                  '${tx.date.day}/${tx.date.month}/${tx.date.year}',
                  tx.category,
                  tx.paymentMethod,
                  tx.type.toUpperCase(),
                  tx.amount.toStringAsFixed(2),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/SmartFinance_Report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    await Share.shareXFiles([XFile(file.path)], text: 'Exported Smart Finance Financial Report');
  }

  // Generate and Share Excel Spreadsheet Report
  Future<void> exportExcelReport(List<TransactionModel> transactions, String title) async {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Headers
    sheet.appendRow([
      xl.TextCellValue('Transaction ID'),
      xl.TextCellValue('Date'),
      xl.TextCellValue('Time'),
      xl.TextCellValue('Category'),
      xl.TextCellValue('Payment Method'),
      xl.TextCellValue('Type'),
      xl.TextCellValue('Amount'),
      xl.TextCellValue('Notes'),
      xl.TextCellValue('Bank'),
    ]);

    // Rows
    for (var tx in transactions) {
      sheet.appendRow([
        xl.TextCellValue(tx.id),
        xl.TextCellValue(tx.date.toIso8601String().split('T')[0]),
        xl.TextCellValue(tx.time),
        xl.TextCellValue(tx.category),
        xl.TextCellValue(tx.paymentMethod),
        xl.TextCellValue(tx.type),
        xl.DoubleCellValue(tx.amount),
        xl.TextCellValue(tx.notes ?? ''),
        xl.TextCellValue(tx.bankName ?? ''),
      ]);
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/SmartFinance_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Exported Excel Financial Spreadsheet');
    }
  }

  // Generate and Share CSV Text Report
  Future<void> exportCsvReport(List<TransactionModel> transactions, String title) async {
    List<List<dynamic>> rows = [];
    rows.add(['ID', 'Date', 'Time', 'Category', 'Payment Method', 'Type', 'Amount', 'Notes', 'Bank']);

    for (var tx in transactions) {
      rows.add([
        tx.id,
        '${tx.date.year}-${tx.date.month}-${tx.date.day}',
        tx.time,
        tx.category,
        tx.paymentMethod,
        tx.type,
        tx.amount,
        tx.notes ?? '',
        tx.bankName ?? '',
      ]);
    }

    String csvContent = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/SmartFinance_Report_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvContent);

    await Share.shareXFiles([XFile(file.path)], text: 'Exported CSV Financial Log');
  }

  // PDF helper block
  pw.Widget _buildPdfSummaryCard(String title, String value, PdfColor textColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.SizedBox(height: 5),
          pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }
}
