import '../core/services/hive_service.dart';
import '../core/services/sync_service.dart';
import '../models/loan_model.dart';

class LoanRepository {
  final HiveService _hiveService = HiveService();
  final SyncService _syncService = SyncService();

  // Get active loans list
  List<LoanModel> getLoans() {
    return _hiveService.getLoans();
  }

  // Create or Update Loan details
  Future<void> saveLoan(LoanModel loan) async {
    await _hiveService.saveLoan(loan.copyWith(
      isPendingSync: true,
      updatedAt: DateTime.now(),
    ));
    _syncService.syncData();
  }

  // Delete Loan entry
  Future<void> deleteLoan(String id) async {
    await _hiveService.deleteLoan(id);
    _syncService.syncData();
  }

  // Mark EMI as paid (reduces remaining balance)
  Future<void> payEmi(String id) async {
    final loans = _hiveService.getLoans();
    final loan = loans.where((l) => l.id == id).firstOrNull;

    if (loan != null) {
      double newRemaining = loan.remainingAmount - loan.emiAmount;
      if (newRemaining < 0) newRemaining = 0.0;

      // Increment next monthly due date
      final nextDue = DateTime(loan.dueDate.year, loan.dueDate.month + 1, loan.dueDate.day);

      await _hiveService.saveLoan(loan.copyWith(
        remainingAmount: newRemaining,
        dueDate: nextDue,
        isPendingSync: true,
        updatedAt: DateTime.now(),
      ));

      _syncService.syncData();
    }
  }
}
extension LoanFirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
