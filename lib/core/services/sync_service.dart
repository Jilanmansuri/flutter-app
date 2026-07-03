import 'package:cloud_firestore/cloud_firestore.dart';
import 'hive_service.dart';
import '../../models/transaction_model.dart';
import '../../models/budget_model.dart';
import '../../models/savings_goal_model.dart';
import '../../models/loan_model.dart';
import '../../models/bill_reminder_model.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final HiveService _hiveService = HiveService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Perform full bi-directional sync (Hive <-> Firestore)
  Future<void> syncData() async {
    final user = _hiveService.getUser();
    if (user == null) return; // user not logged in

    try {
      final uid = user.id;

      // 1. Sync Transactions
      final localTxs = _hiveService.getTransactions();
      final pendingTxs = localTxs.where((tx) => tx.isPendingSync).toList();
      
      for (var tx in pendingTxs) {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('transactions')
            .doc(tx.id)
            .set(tx.toMap()..['isPendingSync'] = false);
            
        await _hiveService.saveTransaction(tx.copyWith(isPendingSync: false));
      }

      // 2. Sync Budgets
      final localBudgets = _hiveService.getBudgets();
      final pendingBudgets = localBudgets.where((b) => b.isPendingSync).toList();

      for (var b in pendingBudgets) {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('budgets')
            .doc(b.id)
            .set(b.toMap()..['isPendingSync'] = false);

        await _hiveService.saveBudget(b.copyWith(isPendingSync: false));
      }

      // 3. Sync Savings Goals
      final localSavings = _hiveService.getSavingsGoals();
      final pendingSavings = localSavings.where((s) => s.isPendingSync).toList();

      for (var s in pendingSavings) {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('savings')
            .doc(s.id)
            .set(s.toMap()..['isPendingSync'] = false);

        await _hiveService.saveSavingsGoal(s.copyWith(isPendingSync: false));
      }

      // 4. Sync Loans
      final localLoans = _hiveService.getLoans();
      final pendingLoans = localLoans.where((l) => l.isPendingSync).toList();

      for (var l in pendingLoans) {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('loans')
            .doc(l.id)
            .set(l.toMap()..['isPendingSync'] = false);

        await _hiveService.saveLoan(l.copyWith(isPendingSync: false));
      }

      // 5. Sync Bills
      final localBills = _hiveService.getBills();
      final pendingBills = localBills.where((b) => b.isPendingSync).toList();

      for (var b in pendingBills) {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('bills')
            .doc(b.id)
            .set(b.toMap()..['isPendingSync'] = false);

        await _hiveService.saveBill(b.copyWith(isPendingSync: false));
      }

      // Pull down updates from Firestore (simple date-based check)
      await _pullRemoteData(uid);
      
    } catch (e) {
      // Firebase might not be initialized, or offline
      print('Sync Error: $e');
    }
  }

  // Pull documents from Firestore and merge them into local Hive
  Future<void> _pullRemoteData(String uid) async {
    // 1. Transactions pull
    final txSnap = await _firestore.collection('users').doc(uid).collection('transactions').get();
    if (txSnap.docs.isNotEmpty) {
      final list = txSnap.docs.map((doc) => TransactionModel.fromMap(doc.data())).toList();
      await _hiveService.saveTransactionsBatch(list);
    }

    // 2. Budgets pull
    final budgetSnap = await _firestore.collection('users').doc(uid).collection('budgets').get();
    for (var doc in budgetSnap.docs) {
      await _hiveService.saveBudget(BudgetModel.fromMap(doc.data()));
    }

    // 3. Savings pull
    final savingsSnap = await _firestore.collection('users').doc(uid).collection('savings').get();
    for (var doc in savingsSnap.docs) {
      await _hiveService.saveSavingsGoal(SavingsGoalModel.fromMap(doc.data()));
    }

    // 4. Loans pull
    final loansSnap = await _firestore.collection('users').doc(uid).collection('loans').get();
    for (var doc in loansSnap.docs) {
      await _hiveService.saveLoan(LoanModel.fromMap(doc.data()));
    }

    // 5. Bills pull
    final billsSnap = await _firestore.collection('users').doc(uid).collection('bills').get();
    for (var doc in billsSnap.docs) {
      await _hiveService.saveBill(BillReminderModel.fromMap(doc.data()));
    }
  }
}
