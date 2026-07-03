import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/constants.dart';
import '../../core/services/providers.dart';
import '../../models/transaction_model.dart';
import '../../widgets/glass_card.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _timeRange = 'Month'; // 'Week', 'Month', 'Year'
  bool _isExporting = false;

  List<TransactionModel> _getFilteredTransactions(List<TransactionModel> txs) {
    final now = DateTime.now();
    if (_timeRange == 'Week') {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final todayMidnight = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      return txs.where((tx) => tx.date.isAfter(todayMidnight.subtract(const Duration(milliseconds: 1)))).toList();
    } else if (_timeRange == 'Year') {
      return txs.where((tx) => tx.date.year == now.year).toList();
    }
    // Default: Current month
    return txs.where((tx) => tx.date.month == now.month && tx.date.year == now.year).toList();
  }

  Future<void> _exportReport(String type) async {
    final txs = ref.read(transactionsListProvider);
    if (txs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transaction history to export.')),
      );
      return;
    }

    setState(() => _isExporting = true);
    final reportService = ref.read(reportServiceProvider);
    final title = 'Financial Report (${_timeRange}ly)';

    try {
      if (type == 'pdf') {
        await reportService.exportPdfReport(txs, title);
      } else if (type == 'excel') {
        await reportService.exportExcelReport(txs, title);
      } else if (type == 'csv') {
        await reportService.exportCsvReport(txs, title);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allTxs = ref.watch(transactionsListProvider);
    final filteredTxs = _getFilteredTransactions(allTxs);
    final settings = ref.watch(settingsNotifierProvider);
    final currency = settings.baseCurrency;

    final expenses = filteredTxs.where((t) => t.type == 'expense').toList();
    
    // Group expenses by category
    final Map<String, double> categoryTotals = {};
    double totalExpenseSum = 0.0;
    for (var tx in expenses) {
      categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0.0) + tx.amount;
      totalExpenseSum += tx.amount;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Analytics'),
        actions: [
          if (_isExporting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Export Statement',
              onSelected: _exportReport,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'pdf', child: Text('Share PDF Report')),
                const PopupMenuItem(value: 'excel', child: Text('Share Excel Spreadsheet')),
                const PopupMenuItem(value: 'csv', child: Text('Share CSV Statement')),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time filter segment
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Week', label: Text('Weekly')),
                ButtonSegment(value: 'Month', label: Text('Monthly')),
                ButtonSegment(value: 'Year', label: Text('Yearly')),
              ],
              selected: {_timeRange},
              onSelectionChanged: (val) {
                setState(() => _timeRange = val.first);
              },
            ),
            const SizedBox(height: 24),

            // Summary Info
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Outgoings', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 6),
                        Text(
                          '$currency${totalExpenseSum.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Inflow', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 6),
                        Text(
                          '$currency${filteredTxs.where((t) => t.type == 'income').fold(0.0, (sum, t) => sum + t.amount).toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Pie Chart distribution
            const Text('Spending Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            expenses.isEmpty
                ? Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: const Text('No expenses recorded for this range.', style: TextStyle(color: Colors.grey)),
                  )
                : AspectRatio(
                    aspectRatio: 1.4,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 40,
                        sections: categoryTotals.entries.map((entry) {
                          final categoryInfo = AppConstants.categories.firstWhere((c) => c.name == entry.key, orElse: () => AppConstants.categories.last);
                          final percentage = (entry.value / totalExpenseSum) * 100;
                          return PieChartSectionData(
                            color: categoryInfo.color,
                            value: entry.value,
                            title: '${percentage.toStringAsFixed(0)}%',
                            radius: 50,
                            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
            const SizedBox(height: 24),

            // Legend indicators
            if (expenses.isNotEmpty) ...[
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: categoryTotals.keys.map((catName) {
                  final catInfo = AppConstants.categories.firstWhere((c) => c.name == catName, orElse: () => AppConstants.categories.last);
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: catInfo.color, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(catName, style: const TextStyle(fontSize: 11)),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
            ],

            // Spending Trend Bar Chart (Simulated weekly grid)
            const Text('Spending Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: totalExpenseSum > 0 ? totalExpenseSum * 0.8 : 1000,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          if (val >= 0 && val < weekdays.length) {
                            return Text(weekdays[val.toInt()], style: const TextStyle(fontSize: 10, color: Colors.grey));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: _generateSimulatedTrendGroups(filteredTxs),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to map actual transactions into daily bar values
  List<BarChartGroupData> _generateSimulatedTrendGroups(List<TransactionModel> txs) {
    final List<double> dailyTotals = List.filled(7, 0.0);
    
    // Group by weekday (0 = Monday, 6 = Sunday)
    for (var tx in txs.where((t) => t.type == 'expense')) {
      final idx = tx.date.weekday - 1;
      if (idx >= 0 && idx < 7) {
        dailyTotals[idx] += tx.amount;
      }
    }

    return List.generate(7, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: dailyTotals[i] > 0 ? dailyTotals[i] : 10.0,
            color: Theme.of(context).colorScheme.primary,
            width: 14,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }
}
