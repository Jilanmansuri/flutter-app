import 'package:hive_flutter/hive_flutter.dart';
import '../../models/transaction_model.dart';
import '../../models/budget_model.dart';
import '../../models/savings_goal_model.dart';
import '../../models/loan_model.dart';
import '../../models/bill_reminder_model.dart';
import '../../models/user_model.dart';
import '../constants/constants.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  Future<void> init() async {
    await Hive.initFlutter();
    
    // Open boxes for local persistent storage
    await Hive.openBox(AppConstants.settingsBoxName);
    await Hive.openBox(AppConstants.userBoxName);
    await Hive.openBox(AppConstants.transactionsBoxName);
    await Hive.openBox(AppConstants.budgetsBoxName);
    await Hive.openBox(AppConstants.savingsBoxName);
    await Hive.openBox(AppConstants.loansBoxName);
    await Hive.openBox(AppConstants.billsBoxName);
  }

  // --- SETTINGS OR PREFERENCES ---
  Box get _settingsBox => Hive.box(AppConstants.settingsBoxName);

  bool get isDarkTheme => _settingsBox.get(AppConstants.isDarkThemeKey, defaultValue: true);
  set isDarkTheme(bool val) => _settingsBox.put(AppConstants.isDarkThemeKey, val);

  String get baseCurrency => _settingsBox.get(AppConstants.currencyKey, defaultValue: AppConstants.defaultCurrency);
  set baseCurrency(String symbol) => _settingsBox.put(AppConstants.currencyKey, symbol);

  String get language => _settingsBox.get(AppConstants.languageKey, defaultValue: AppConstants.defaultLanguage);
  set language(String code) => _settingsBox.put(AppConstants.languageKey, code);

  // --- USER PROFILE ---
  Box get _userBox => Hive.box(AppConstants.userBoxName);

  UserModel? getUser() {
    final data = _userBox.get('current_user');
    if (data == null) return null;
    return UserModel.fromMap(Map<String, dynamic>.from(data));
  }

  Future<void> saveUser(UserModel user) async {
    await _userBox.put('current_user', user.toMap());
  }

  Future<void> clearUser() async {
    await _userBox.delete('current_user');
  }

  // --- TRANSACTIONS CRUD ---
  Box get _txBox => Hive.box(AppConstants.transactionsBoxName);

  List<TransactionModel> getTransactions() {
    return _txBox.values
        .map((e) => TransactionModel.fromMap(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> saveTransaction(TransactionModel transaction) async {
    await _txBox.put(transaction.id, transaction.toMap());
  }

  Future<void> deleteTransaction(String id) async {
    await _txBox.delete(id);
  }

  Future<void> saveTransactionsBatch(List<TransactionModel> list) async {
    final Map<String, dynamic> data = {};
    for (var tx in list) {
      data[tx.id] = tx.toMap();
    }
    await _txBox.putAll(data);
  }

  // --- BUDGETS CRUD ---
  Box get _budgetBox => Hive.box(AppConstants.budgetsBoxName);

  List<BudgetModel> getBudgets() {
    return _budgetBox.values
        .map((e) => BudgetModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveBudget(BudgetModel budget) async {
    await _budgetBox.put(budget.id, budget.toMap());
  }

  Future<void> deleteBudget(String id) async {
    await _budgetBox.delete(id);
  }

  // --- SAVINGS GOALS CRUD ---
  Box get _savingsBox => Hive.box(AppConstants.savingsBoxName);

  List<SavingsGoalModel> getSavingsGoals() {
    return _savingsBox.values
        .map((e) => SavingsGoalModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveSavingsGoal(SavingsGoalModel goal) async {
    await _savingsBox.put(goal.id, goal.toMap());
  }

  Future<void> deleteSavingsGoal(String id) async {
    await _savingsBox.delete(id);
  }

  // --- LOANS CRUD ---
  Box get _loansBox => Hive.box(AppConstants.loansBoxName);

  List<LoanModel> getLoans() {
    return _loansBox.values
        .map((e) => LoanModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveLoan(LoanModel loan) async {
    await _loansBox.put(loan.id, loan.toMap());
  }

  Future<void> deleteLoan(String id) async {
    await _loansBox.delete(id);
  }

  // --- BILLS CRUD ---
  Box get _billsBox => Hive.box(AppConstants.billsBoxName);

  List<BillReminderModel> getBills() {
    return _billsBox.values
        .map((e) => BillReminderModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveBill(BillReminderModel bill) async {
    await _billsBox.put(bill.id, bill.toMap());
  }

  Future<void> deleteBill(String id) async {
    await _billsBox.delete(id);
  }

  // Clear all data (e.g. for sign out or account deletion)
  Future<void> clearAllData() async {
    await _txBox.clear();
    await _budgetBox.clear();
    await _savingsBox.clear();
    await _loansBox.clear();
    await _billsBox.clear();
    await _userBox.clear();
  }
}
