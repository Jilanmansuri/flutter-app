import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../models/transaction_model.dart';
import '../../models/budget_model.dart';
import '../../models/bill_reminder_model.dart';
import 'hive_service.dart';

class AiInsightCard {
  final String title;
  final String description;
  final String type; // 'warning', 'success', 'info'
  final String valueChange; // e.g., '+₹2,300', '18%', '-5%'

  AiInsightCard({
    required this.title,
    required this.description,
    required this.type,
    required this.valueChange,
  });
}

class AiService {
  final HiveService _hiveService = HiveService();
  
  // Gemini API Key config
  // Developers can set this using String.fromEnvironment or config variables
  static const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  GenerativeModel? _model;

  AiService() {
    if (_geminiApiKey.isNotEmpty) {
      _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _geminiApiKey);
    }
  }

  // Generate automated financial insights based on real local data
  List<AiInsightCard> generateInsights() {
    final transactions = _hiveService.getTransactions();
    final budgets = _hiveService.getBudgets();
    final bills = _hiveService.getBills();

    List<AiInsightCard> insights = [];

    // Calculate this month's stats
    final now = DateTime.now();
    final thisMonthTxs = transactions.where((tx) => tx.date.month == now.month && tx.date.year == now.year).toList();
    final lastMonthTxs = transactions.where((tx) => tx.date.month == (now.month == 1 ? 12 : now.month - 1) && tx.date.year == (now.month == 1 ? now.year - 1 : now.year)).toList();

    // 1. Food check
    final thisMonthFood = thisMonthTxs.where((tx) => tx.category == 'Food' && tx.type == 'expense').fold(0.0, (sum, tx) => sum + tx.amount);
    final lastMonthFood = lastMonthTxs.where((tx) => tx.category == 'Food' && tx.type == 'expense').fold(0.0, (sum, tx) => sum + tx.amount);
    if (lastMonthFood > 0) {
      final pctIncrease = ((thisMonthFood - lastMonthFood) / lastMonthFood) * 100;
      if (pctIncrease > 10) {
        insights.add(AiInsightCard(
          title: 'Food Expenses Spike',
          description: 'You spent ${pctIncrease.toStringAsFixed(0)}% more on Food compared to last month.',
          type: 'warning',
          valueChange: '+${pctIncrease.toStringAsFixed(0)}%',
        ));
      }
    }

    // 2. Shopping check
    final thisMonthShop = thisMonthTxs.where((tx) => tx.category == 'Shopping' && tx.type == 'expense').fold(0.0, (sum, tx) => sum + tx.amount);
    final lastMonthShop = lastMonthTxs.where((tx) => tx.category == 'Shopping' && tx.type == 'expense').fold(0.0, (sum, tx) => sum + tx.amount);
    if (thisMonthShop > lastMonthShop) {
      final diff = thisMonthShop - lastMonthShop;
      if (diff > 500) {
        insights.add(AiInsightCard(
          title: 'Shopping Expense Surge',
          description: 'Shopping expenses increased. Try postponing non-essential purchases.',
          type: 'warning',
          valueChange: '+${_hiveService.baseCurrency}${diff.toStringAsFixed(0)}',
        ));
      }
    }

    // 3. Entertainment savings suggestion
    final entertainmentExpense = thisMonthTxs.where((tx) => tx.category == 'Entertainment' && tx.type == 'expense').fold(0.0, (sum, tx) => sum + tx.amount);
    if (entertainmentExpense > 1000) {
      final potentialSavings = entertainmentExpense * 0.5;
      insights.add(AiInsightCard(
        title: 'Save on Entertainment',
        description: 'You can save ${_hiveService.baseCurrency}${potentialSavings.toStringAsFixed(0)} by trimming subscription counts or movie outings.',
        type: 'info',
        valueChange: '${_hiveService.baseCurrency}${potentialSavings.toStringAsFixed(0)}',
      ));
    }

    // 4. Bills due reminder
    final pendingBills = bills.where((b) => !b.isPaid && b.dueDate.isAfter(now) && b.dueDate.difference(now).inDays <= 5).toList();
    if (pendingBills.isNotEmpty) {
      insights.add(AiInsightCard(
        title: 'Upcoming Bill Reminders',
        description: '${pendingBills.length} bills are due within the next 5 days.',
        type: 'warning',
        valueChange: '${pendingBills.length} Due',
      ));
    }

    // 5. General savings milestone
    final totalIncome = thisMonthTxs.where((tx) => tx.type == 'income').fold(0.0, (sum, tx) => sum + tx.amount);
    final totalExpense = thisMonthTxs.where((tx) => tx.type == 'expense').fold(0.0, (sum, tx) => sum + tx.amount);
    if (totalIncome > 0) {
      final savingsRate = ((totalIncome - totalExpense) / totalIncome) * 100;
      if (savingsRate > 20) {
        insights.add(AiInsightCard(
          title: 'Healthy Savings Rate',
          description: 'Great job! You saved ${savingsRate.toStringAsFixed(0)}% of your monthly income.',
          type: 'success',
          valueChange: '${savingsRate.toStringAsFixed(0)}%',
        ));
      }
    }

    // Add fallback default cards if data is empty
    if (insights.isEmpty) {
      insights.addAll([
        AiInsightCard(
          title: 'Savings Overview',
          description: 'Keep logging transactions to view customized metrics and budget advisories.',
          type: 'info',
          valueChange: 'Active',
        ),
        AiInsightCard(
          title: 'Budget Alert',
          description: 'Create monthly category budgets to keep your card spendings within range.',
          type: 'success',
          valueChange: '0 Limits',
        ),
      ]);
    }

    return insights;
  }

  // Answer freeform finance questions. Fallback to a local analytical engine if API Key is not set.
  Future<String> askAssistant(String question) async {
    final transactions = _hiveService.getTransactions();
    final budgets = _hiveService.getBudgets();
    final bills = _hiveService.getBills();

    // Data summaries
    final now = DateTime.now();
    final currency = _hiveService.baseCurrency;
    
    final totalIncome = transactions.where((tx) => tx.type == 'income').fold(0.0, (sum, tx) => sum + tx.amount);
    final totalExpense = transactions.where((tx) => tx.type == 'expense').fold(0.0, (sum, tx) => sum + tx.amount);
    final balance = totalIncome - totalExpense;

    final thisMonthExp = transactions
        .where((tx) => tx.type == 'expense' && tx.date.month == now.month && tx.date.year == now.year)
        .fold(0.0, (sum, tx) => sum + tx.amount);

    final categorySpends = <String, double>{};
    for (var tx in transactions.where((tx) => tx.type == 'expense')) {
      categorySpends[tx.category] = (categorySpends[tx.category] ?? 0.0) + tx.amount;
    }
    
    String topCategory = 'None';
    double topCategoryAmt = 0.0;
    categorySpends.forEach((cat, amt) {
      if (amt > topCategoryAmt) {
        topCategoryAmt = amt;
        topCategory = cat;
      }
    });

    // Parse question patterns locally
    final q = question.toLowerCase();
    
    if (_model != null) {
      // Prompt construction for GenAI
      final prompt = """
You are a highly capable AI Financial Assistant for the Smart Finance App.
Below is the user's real-time financial data:
- Base Currency: $currency
- Total Account Balance: $currency$balance
- Total Income: $currency$totalIncome
- Total Expenses: $currency$totalExpense
- This Month's Expenses: $currency$thisMonthExp
- Highest Spending Category: $topCategory ($currency$topCategoryAmt)
- Detailed category expenses: ${jsonEncode(categorySpends)}
- Active Budgets: ${jsonEncode(budgets.map((b) => b.toMap()).toList())}
- Unpaid Reminders: ${jsonEncode(bills.where((b) => !b.isPaid).map((b) => b.toMap()).toList())}

User Question: "$question"

Please provide a concise, direct, and helpful answer in markdown format. Give exact figures where appropriate. Keep it polite, actionable and finance-focused.
""";

      try {
        final content = [Content.text(prompt)];
        final response = await _model!.generateContent(content);
        return response.text ?? 'Sorry, I could not generate an answer right now.';
      } catch (e) {
        print('Gemini API Error: $e');
        // fall through to local analyzer on connection failure
      }
    }

    // --- LOCAL ANALYTICAL HEURISTIC ENGINE ---
    if (q.contains('how much') && q.contains('spend') && (q.contains('month') || q.contains('this month'))) {
      return "You have spent **$currency${thisMonthExp.toStringAsFixed(2)}** in the current calendar month. Your total all-time expenses are **$currency${totalExpense.toStringAsFixed(2)}**.";
    }

    if (q.contains('food') && (q.contains('spend') || q.contains('expense'))) {
      final foodAmt = categorySpends['Food'] ?? 0.0;
      return "Your spending on **Food** is **$currency${foodAmt.toStringAsFixed(2)}**.";
    }

    if (q.contains('category') && (q.contains('most') || q.contains('highest') || q.contains('cost'))) {
      if (topCategoryAmt > 0) {
        return "Your highest spending category is **$topCategory** with a total of **$currency${topCategoryAmt.toStringAsFixed(2)}**, which represents ${((topCategoryAmt / (totalExpense > 0 ? totalExpense : 1)) * 100).toStringAsFixed(1)}% of your overall expenses.";
      }
      return "No expenses have been recorded yet.";
    }

    if (q.contains('save money') || q.contains('saving suggestions') || q.contains('savings')) {
      final suggestions = [
        "1. **Audit Entertainment**: Your entertainment spend is $currency${(categorySpends['Entertainment'] ?? 0.0).toStringAsFixed(0)}. Trim subscriptions.",
        "2. **Category Budgeting**: Establish a category limit for $topCategory, your top spending area.",
        "3. **Follow the 50/30/20 Rule**: Allocate 50% for Needs (Rent, Bills), 30% for Wants (Shopping, Entertainment), and 20% directly into Savings.",
      ];
      return "Here are custom tips based on your balance card:\n\n${suggestions.join('\n')}";
    }

    if (q.contains('report') || q.contains('summarize') || q.contains('summary')) {
      return """
### Financial Summary Report
- **Account status**: Current Balance is **$currency${balance.toStringAsFixed(2)}**
- **Inflow/Outflow**: Total Income: **$currency${totalIncome.toStringAsFixed(2)}** | Total Expenses: **$currency${totalExpense.toStringAsFixed(2)}**
- **Budget Tracking**: Active Budgets: **${budgets.length}** categories.
- **Top Outgoings**: Highest category is **$topCategory** at **$currency${topCategoryAmt.toStringAsFixed(2)}**.
""";
    }

    if (q.contains('predict') || q.contains('next month')) {
      final nextMonthEstimate = thisMonthExp * 1.05;
      return "Based on your spending rate of **$currency${thisMonthExp.toStringAsFixed(2)}** this month, next month's predicted expenses are approximately **$currency${nextMonthEstimate.toStringAsFixed(2)}** (assuming a standard 5% baseline variation). I recommend setting up category budgets to offset this projection.";
    }

    if (q.contains('unusual') || q.contains('anomaly')) {
      // Find single transactions that exceed 30% of total monthly expenses
      final unusual = transactions.where((tx) => tx.type == 'expense' && tx.amount > (thisMonthExp * 0.3) && tx.date.month == now.month).toList();
      if (unusual.isNotEmpty) {
        final items = unusual.map((tx) => "- **$currency${tx.amount}** at `${tx.category}` (${tx.paymentMethod}) on ${tx.date.day} ${_getMonthName(tx.date.month)}").join('\n');
        return "I detected **${unusual.length} unusual/large transactions** this month (exceeding 30% of monthly average):\n\n$items";
      }
      return "Excellent! No unusual spikes or transaction anomalies were detected this month.";
    }

    return "Hello! I am your AI Financial Assistant. Ask me anything like:\n"
        "- *How much did I spend this month?*\n"
        "- *Show food expenses.*\n"
        "- *Which category costs the most?*\n"
        "- *Predict next month's expenses.*\n"
        "- *Detect unusual spending.*\n"
        "- *Summarize my finances.*";
  }

  String _getMonthName(int month) {
    const list = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return list[month - 1];
  }
}
