import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/constants.dart';
import '../../core/services/providers.dart';
import '../../models/transaction_model.dart';
import '../../widgets/glass_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isSyncingSms = false;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<void> _syncSms() async {
    final user = ref.read(authNotifierProvider);
    if (user == null) return;

    setState(() => _isSyncingSms = true);
    
    try {
      final repo = ref.read(transactionRepositoryProvider);
      final count = await repo.autoImportSmsTransactions(user.id);
      
      // Refresh list
      ref.invalidate(transactionsListProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count > 0 
                ? 'Successfully imported $count new bank transactions from SMS!'
                : 'Checked SMS. Your transaction log is up to date.'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to read SMS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncingSms = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider);
    final txList = ref.watch(transactionsListProvider);
    final budgets = ref.watch(budgetsProvider);
    final settings = ref.watch(settingsNotifierProvider);
    
    final currency = settings.baseCurrency;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // --- FINANCIAL METRICS CALCULATION ---
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    
    double todayExpense = 0.0;
    double yesterdayExpense = 0.0;
    double weekExpense = 0.0;
    double monthExpense = 0.0;
    double yearExpense = 0.0;
    
    double totalIncome = 0.0;
    double totalExpense = 0.0;

    for (var tx in txList) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      
      if (tx.type == 'expense') {
        totalExpense += tx.amount;
        if (txDate.isAtSameMomentAs(today)) todayExpense += tx.amount;
        if (txDate.isAtSameMomentAs(yesterday)) yesterdayExpense += tx.amount;
        if (txDate.isAfter(startOfWeek.subtract(const Duration(milliseconds: 1))) || txDate.isAtSameMomentAs(startOfWeek)) {
          weekExpense += tx.amount;
        }
        if (tx.date.month == now.month && tx.date.year == now.year) monthExpense += tx.amount;
        if (tx.date.year == now.year) yearExpense += tx.amount;
      } else {
        totalIncome += tx.amount;
      }
    }

    double currentSavings = totalIncome - totalExpense;
    if (currentSavings < 0) currentSavings = 0.0;

    // Budget Tracker summary metrics
    double totalBudgetLimit = budgets.fold(0.0, (sum, b) => sum + b.limitAmount);
    double totalBudgetSpent = budgets.fold(0.0, (sum, b) => sum + b.spentAmount);
    double budgetProgress = totalBudgetLimit > 0 ? (totalBudgetSpent / totalBudgetLimit) : 0.0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting & Sync section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: _isSyncingSms 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.sms_rounded),
                        tooltip: 'Sync SMS Transactions',
                        onPressed: _isSyncingSms ? null : _syncSms,
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(
                          user.photoUrl ?? 'https://api.dicebear.com/7.x/pixel-art/svg?seed=${user.name}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Main Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL BALANCE',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$currency${(totalIncome - totalExpense).toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildBalanceItem('Income', '$currency${totalIncome.toStringAsFixed(0)}', Icons.arrow_upward_rounded),
                        _buildBalanceItem('Expenses', '$currency${totalExpense.toStringAsFixed(0)}', Icons.arrow_downward_rounded),
                        _buildBalanceItem('Savings', '$currency${currentSavings.toStringAsFixed(0)}', Icons.savings_rounded),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // SMS Transaction Calculations Overview
              const Text(
                'Financial Performance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildMetricCard("Today", "$currency${todayExpense.toStringAsFixed(0)}", Colors.redAccent),
                    _buildMetricCard("Yesterday", "$currency${yesterdayExpense.toStringAsFixed(0)}", Colors.orangeAccent),
                    _buildMetricCard("This Week", "$currency${weekExpense.toStringAsFixed(0)}", Colors.purpleAccent),
                    _buildMetricCard("This Month", "$currency${monthExpense.toStringAsFixed(0)}", Colors.indigoAccent),
                    _buildMetricCard("This Year", "$currency${yearExpense.toStringAsFixed(0)}", Colors.tealAccent),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Quick Actions Grid
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _buildQuickAction(context, 'Add Log', Icons.add_circle_outline_rounded, '/transactions?action=add', Colors.blue),
                  _buildQuickAction(context, 'Scan', Icons.document_scanner_outlined, '/transactions?action=scan', Colors.teal),
                  _buildQuickAction(context, 'AI Bot', Icons.psychology_outlined, '/ai', Colors.deepPurple),
                  _buildQuickAction(context, 'Reports', Icons.analytics_outlined, '/analytics', Colors.pink),
                  _buildQuickAction(context, 'Budgets', Icons.wallet_outlined, '/budget', Colors.orange),
                  _buildQuickAction(context, 'Savings', Icons.savings_outlined, '/savings', Colors.green),
                  _buildQuickAction(context, 'Loans', Icons.credit_score_outlined, '/loans', Colors.cyan),
                  _buildQuickAction(context, 'Bills', Icons.receipt_long_outlined, '/bills', Colors.red),
                ],
              ),
              const SizedBox(height: 28),

              // Budget Progress Card
              if (totalBudgetLimit > 0) ...[
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Budget Progress', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '${(budgetProgress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: budgetProgress > 0.9 ? Colors.red : (budgetProgress > 0.75 ? Colors.orange : Colors.green),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: budgetProgress > 1.0 ? 1.0 : budgetProgress,
                        color: budgetProgress > 0.9 ? Colors.red : (budgetProgress > 0.75 ? Colors.orange : Colors.green),
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Spent $currency${totalBudgetSpent.toStringAsFixed(0)} of $currency${totalBudgetLimit.toStringAsFixed(0)} limit',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // Recent Transactions Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  TextButton(
                    onPressed: () => context.push('/transactions'),
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              txList.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: const Text('No transactions recorded. Try importing SMS.', style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: txList.length > 4 ? 4 : txList.length,
                      itemBuilder: (context, index) {
                        final tx = txList[index];
                        return _buildTransactionItem(tx, currency);
                      },
                    ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBalanceItem(String label, String amount, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
            Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String amount, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(amount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String label, IconData icon, String path, Color color) {
    return InkWell(
      onTap: () => context.push(path),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 1),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel tx, String currency) {
    final isExpense = tx.type == 'expense';
    
    // Find category details
    final catInfo = AppConstants.categories.firstWhere((c) => c.name == tx.category, orElse: () => AppConstants.categories.last);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: catInfo.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(catInfo.icon, color: catInfo.color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.notes ?? tx.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('dd MMM yyyy').format(tx.date)} • ${tx.paymentMethod}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isExpense ? "-" : "+"}$currency${tx.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isExpense ? Colors.redAccent : Colors.greenAccent,
                ),
              ),
              if (tx.isSmsAutoRead)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('SMS Auto', style: TextStyle(fontSize: 8, color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (index == 0) return;
        switch (index) {
          case 1:
            context.push('/transactions');
            break;
          case 2:
            context.push('/ai');
            break;
          case 3:
            context.push('/settings');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.swap_horiz_rounded), label: 'Log'),
        BottomNavigationBarItem(icon: Icon(Icons.psychology_rounded), label: 'AI Bot'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
      ],
    );
  }
}
