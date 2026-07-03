import '../core/services/hive_service.dart';
import '../core/services/sync_service.dart';
import '../models/savings_goal_model.dart';

class SavingsRepository {
  final HiveService _hiveService = HiveService();
  final SyncService _syncService = SyncService();

  // Get all active savings goals
  List<SavingsGoalModel> getSavingsGoals() {
    return _hiveService.getSavingsGoals();
  }

  // Save (Create/Update) goal
  Future<void> saveSavingsGoal(SavingsGoalModel goal) async {
    final bool completed = goal.savedAmount >= goal.targetAmount;
    final updatedGoal = goal.copyWith(
      isCompleted: completed,
      isPendingSync: true,
      updatedAt: DateTime.now(),
    );

    await _hiveService.saveSavingsGoal(updatedGoal);
    _syncService.syncData();
  }

  // Delete Goal
  Future<void> deleteSavingsGoal(String id) async {
    await _hiveService.deleteSavingsGoal(id);
    _syncService.syncData();
  }

  // Allocate funds to a goal
  Future<void> addFundsToGoal(String id, double amount) async {
    final goals = _hiveService.getSavingsGoals();
    final goal = goals.where((g) => g.id == id).firstOrNull;

    if (goal != null) {
      final newSaved = goal.savedAmount + amount;
      final completed = newSaved >= goal.targetAmount;

      await _hiveService.saveSavingsGoal(goal.copyWith(
        savedAmount: newSaved,
        isCompleted: completed,
        isPendingSync: true,
        updatedAt: DateTime.now(),
      ));

      _syncService.syncData();
    }
  }
}
extension SavingsFirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
