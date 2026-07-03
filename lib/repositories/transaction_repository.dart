import '../core/services/hive_service.dart';
import '../core/services/sms_service.dart';
import '../core/services/sync_service.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';

class TransactionRepository {
  final HiveService _hiveService = HiveService();
  final SmsService _smsService = SmsService();
  final SyncService _syncService = SyncService();

  // Fetch local transactions with search, sorting and category filter helpers
  List<TransactionModel> getTransactions({
    String? searchQuery,
    String? categoryFilter,
    String? sortBy, // 'date', 'amount'
    bool ascending = false,
  }) {
    List<TransactionModel> txs = _hiveService.getTransactions();

    // Category Filter
    if (categoryFilter != null && categoryFilter != 'All') {
      txs = txs.where((tx) => tx.category == categoryFilter).toList();
    }

    // Search Query (in notes, category or payment method)
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      txs = txs.where((tx) {
        return tx.category.toLowerCase().contains(query) ||
            (tx.notes?.toLowerCase().contains(query) ?? false) ||
            tx.paymentMethod.toLowerCase().contains(query);
      }).toList();
    }

    // Sorting
    if (sortBy == 'amount') {
      txs.sort((a, b) => ascending ? a.amount.compareTo(b.amount) : b.amount.compareTo(a.amount));
    } else {
      // default: date
      txs.sort((a, b) => ascending ? a.date.compareTo(b.date) : b.date.compareTo(a.date));
    }

    return txs;
  }

  // Create or Update Transaction
  Future<void> saveTransaction(TransactionModel tx) async {
    final originalTx = _hiveService.getTransactions().where((t) => t.id == tx.id).firstOrNull;
    
    // Save locally
    await _hiveService.saveTransaction(tx.copyWith(isPendingSync: true));
    
    // Recalculate Budgets spent amount for this category
    await _recalculateBudgetForCategory(tx.category, tx.date);
    if (originalTx != null && originalTx.category != tx.category) {
      await _recalculateBudgetForCategory(originalTx.category, originalTx.date);
    }

    // Async Remote Sync
    _syncService.syncData();
  }

  // Delete Transaction
  Future<void> deleteTransaction(String id) async {
    final list = _hiveService.getTransactions();
    final tx = list.where((t) => t.id == id).firstOrNull;
    
    if (tx != null) {
      await _hiveService.deleteTransaction(id);
      await _recalculateBudgetForCategory(tx.category, tx.date);
      
      // Async Sync deletes
      _syncService.syncData();
    }
  }

  // Fetch device SMS messages, extract new bank alerts, and save them automatically
  Future<int> autoImportSmsTransactions(String userId) async {
    final parsed = await _smsService.readTransactionalSms(userId);
    if (parsed.isEmpty) return 0;

    final existingIds = _hiveService.getTransactions().map((t) => t.id).toSet();
    int newImportCount = 0;

    for (var tx in parsed) {
      if (!existingIds.contains(tx.id)) {
        await _hiveService.saveTransaction(tx.copyWith(isPendingSync: true));
        await _recalculateBudgetForCategory(tx.category, tx.date);
        newImportCount++;
      }
    }

    if (newImportCount > 0) {
      _syncService.syncData();
    }
    return newImportCount;
  }

  // Helper to sync category spending with the Budget module limits
  Future<void> _recalculateBudgetForCategory(String category, DateTime date) async {
    final monthStr = "${date.year}-${date.month.toString().padLeft(2, '0')}";
    final budgets = _hiveService.getBudgets();
    
    // Get budget limits for category or Total
    final catBudget = budgets.where((b) => b.category == category && b.month == monthStr).firstOrNull;
    final totalBudget = budgets.where((b) => b.category == 'Total' && b.month == monthStr).firstOrNull;
    
    // Sum monthly expenses for matching category
    final txs = _hiveService.getTransactions();
    final monthlyExpenseTxs = txs.where((t) => 
      t.type == 'expense' && 
      t.date.year == date.year && 
      t.date.month == date.month
    ).toList();

    if (catBudget != null) {
      final categorySpent = monthlyExpenseTxs
          .where((t) => t.category == category)
          .fold(0.0, (sum, t) => sum + t.amount);
      
      await _hiveService.saveBudget(catBudget.copyWith(
        spentAmount: categorySpent,
        isPendingSync: true,
      ));
    }

    if (totalBudget != null) {
      final totalSpent = monthlyExpenseTxs.fold(0.0, (sum, t) => sum + t.amount);
      await _hiveService.saveBudget(totalBudget.copyWith(
        spentAmount: totalSpent,
        isPendingSync: true,
      ));
    }
  }
}
extension ListFirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
