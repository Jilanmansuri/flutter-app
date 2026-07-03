import '../core/services/hive_service.dart';
import '../core/services/sync_service.dart';
import '../models/budget_model.dart';

class BudgetRepository {
  final HiveService _hiveService = HiveService();
  final SyncService _syncService = SyncService();

  // Get active budgets for a specific month
  List<BudgetModel> getBudgetsForMonth(String month) {
    return _hiveService.getBudgets().where((b) => b.month == month).toList();
  }

  // Create or Update budget
  Future<void> saveBudget(BudgetModel budget) async {
    // Determine current spending for this budget category in the selected month
    final txs = _hiveService.getTransactions();
    final year = int.parse(budget.month.split('-')[0]);
    final month = int.parse(budget.month.split('-')[1]);

    final monthlyExpenses = txs.where((tx) =>
        tx.type == 'expense' &&
        tx.date.year == year &&
        tx.date.month == month).toList();

    double spent = 0.0;
    if (budget.category == 'Total') {
      spent = monthlyExpenses.fold(0.0, (sum, tx) => sum + tx.amount);
    } else {
      spent = monthlyExpenses
          .where((tx) => tx.category == budget.category)
          .fold(0.0, (sum, tx) => sum + tx.amount);
    }

    final updatedBudget = budget.copyWith(
      spentAmount: spent,
      isPendingSync: true,
      updatedAt: DateTime.now(),
    );

    await _hiveService.saveBudget(updatedBudget);
    _syncService.syncData();
  }

  // Remove budget limit definition
  Future<void> deleteBudget(String id) async {
    await _hiveService.deleteBudget(id);
    _syncService.syncData();
  }
}
