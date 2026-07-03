import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../models/transaction_model.dart';
import '../../models/budget_model.dart';
import '../../models/savings_goal_model.dart';
import '../../models/loan_model.dart';
import '../../models/bill_reminder_model.dart';

import 'hive_service.dart';
import 'sms_service.dart';
import 'ocr_service.dart';
import 'ai_service.dart';
import 'notification_service.dart';
import 'report_service.dart';
import 'biometric_service.dart';
import 'sync_service.dart';

import '../../repositories/auth_repository.dart';
import '../../repositories/transaction_repository.dart';
import '../../repositories/budget_repository.dart';
import '../../repositories/savings_repository.dart';
import '../../repositories/loan_repository.dart';
import '../../repositories/bill_repository.dart';

// --- SERVICE PROVIDERS ---
final hiveServiceProvider = Provider<HiveService>((ref) => HiveService());
final smsServiceProvider = Provider<SmsService>((ref) => SmsService());
final ocrServiceProvider = Provider<OcrService>((ref) => OcrService());
final aiServiceProvider = Provider<AiService>((ref) => AiService());
final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());
final reportServiceProvider = Provider<ReportService>((ref) => ReportService());
final biometricServiceProvider = Provider<BiometricService>((ref) => BiometricService());
final syncServiceProvider = Provider<SyncService>((ref) => SyncService());

// --- REPOSITORY PROVIDERS ---
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) => TransactionRepository());
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) => BudgetRepository());
final savingsRepositoryProvider = Provider<SavingsRepository>((ref) => SavingsRepository());
final loanRepositoryProvider = Provider<LoanRepository>((ref) => LoanRepository());
final billRepositoryProvider = Provider<BillRepository>((ref) => BillRepository());

// --- STATE NOTIFIERS ---

// Auth Session State
class AuthNotifier extends StateNotifier<UserModel?> {
  final AuthRepository _repo;
  AuthNotifier(this._repo) : super(_repo.currentUser);

  Future<void> login(String email, String password) async {
    state = await _repo.loginWithEmail(email: email, password: password);
  }

  Future<void> register(String name, String email, String password) async {
    state = await _repo.registerWithEmail(name: name, email: email, password: password);
  }

  Future<void> loginWithGoogle() async {
    state = await _repo.signInWithGoogleMock();
  }

  Future<void> logout() async {
    await _repo.logout();
    state = null;
  }

  Future<void> deleteAccount() async {
    await _repo.deleteAccount();
    state = null;
  }

  void refreshUser() {
    state = _repo.currentUser;
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

// Settings & Preferences State
class SettingsState {
  final bool isDarkTheme;
  final String baseCurrency;
  final String language;
  
  SettingsState({
    required this.isDarkTheme,
    required this.baseCurrency,
    required this.language,
  });

  SettingsState copyWith({
    bool? isDarkTheme,
    String? baseCurrency,
    String? language,
  }) {
    return SettingsState(
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      language: language ?? this.language,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final HiveService _hive;
  SettingsNotifier(this._hive) : super(SettingsState(
    isDarkTheme: _hive.isDarkTheme,
    baseCurrency: _hive.baseCurrency,
    language: _hive.language,
  ));

  void toggleTheme(bool val) {
    _hive.isDarkTheme = val;
    state = state.copyWith(isDarkTheme: val);
  }

  void setCurrency(String symbol) {
    _hive.baseCurrency = symbol;
    state = state.copyWith(baseCurrency: symbol);
  }

  void setLanguage(String code) {
    _hive.language = code;
    state = state.copyWith(language: code);
  }
}

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref.read(hiveServiceProvider));
});

// Transactions List State
class TransactionFilterState {
  final String searchQuery;
  final String categoryFilter;
  final String sortBy;
  final bool ascending;

  TransactionFilterState({
    this.searchQuery = '',
    this.categoryFilter = 'All',
    this.sortBy = 'date',
    this.ascending = false,
  });

  TransactionFilterState copyWith({
    String? searchQuery,
    String? categoryFilter,
    String? sortBy,
    bool? ascending,
  }) {
    return TransactionFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
    );
  }
}

final transactionFilterProvider = StateNotifierProvider<StateNotifier<TransactionFilterState>, TransactionFilterState>((ref) {
  class FilterNotifier extends StateNotifier<TransactionFilterState> {
    FilterNotifier() : super(TransactionFilterState());
  }
  return FilterNotifier();
});

final transactionsListProvider = Provider<List<TransactionModel>>((ref) {
  final filters = ref.watch(transactionFilterProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  // Re-trigger calculation on state changes
  return repo.getTransactions(
    searchQuery: filters.searchQuery,
    categoryFilter: filters.categoryFilter,
    sortBy: filters.sortBy,
    ascending: filters.ascending,
  );
});

// Budgets State Notifier
class BudgetsNotifier extends StateNotifier<List<BudgetModel>> {
  final BudgetRepository _repo;
  BudgetsNotifier(this._repo) : super([]) {
    loadBudgets();
  }

  void loadBudgets() {
    final monthStr = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";
    state = _repo.getBudgetsForMonth(monthStr);
  }

  Future<void> addBudget(BudgetModel budget) async {
    await _repo.saveBudget(budget);
    loadBudgets();
  }

  Future<void> removeBudget(String id) async {
    await _repo.deleteBudget(id);
    loadBudgets();
  }
}

final budgetsProvider = StateNotifierProvider<BudgetsNotifier, List<BudgetModel>>((ref) {
  return BudgetsNotifier(ref.read(budgetRepositoryProvider));
});

// Savings Goals State Notifier
class SavingsNotifier extends StateNotifier<List<SavingsGoalModel>> {
  final SavingsRepository _repo;
  SavingsNotifier(this._repo) : super([]) {
    loadGoals();
  }

  void loadGoals() {
    state = _repo.getSavingsGoals();
  }

  Future<void> saveGoal(SavingsGoalModel goal) async {
    await _repo.saveSavingsGoal(goal);
    loadGoals();
  }

  Future<void> deleteGoal(String id) async {
    await _repo.deleteSavingsGoal(id);
    loadGoals();
  }

  Future<void> addSavings(String id, double amount) async {
    await _repo.addFundsToGoal(id, amount);
    loadGoals();
  }
}

final savingsProvider = StateNotifierProvider<SavingsNotifier, List<SavingsGoalModel>>((ref) {
  return SavingsNotifier(ref.read(savingsRepositoryProvider));
});

// Loans State Notifier
class LoansNotifier extends StateNotifier<List<LoanModel>> {
  final LoanRepository _repo;
  LoansNotifier(this._repo) : super([]) {
    loadLoans();
  }

  void loadLoans() {
    state = _repo.getLoans();
  }

  Future<void> saveLoan(LoanModel loan) async {
    await _repo.saveLoan(loan);
    loadLoans();
  }

  Future<void> deleteLoan(String id) async {
    await _repo.deleteLoan(id);
    loadLoans();
  }

  Future<void> makeEmiPayment(String id) async {
    await _repo.payEmi(id);
    loadLoans();
  }
}

final loansProvider = StateNotifierProvider<LoansNotifier, List<LoanModel>>((ref) {
  return LoansNotifier(ref.read(loanRepositoryProvider));
});

// Bills State Notifier
class BillsNotifier extends StateNotifier<List<BillReminderModel>> {
  final BillRepository _repo;
  BillsNotifier(this._repo) : super([]) {
    loadBills();
  }

  void loadBills() {
    state = _repo.getBills();
  }

  Future<void> saveBill(BillReminderModel bill) async {
    await _repo.saveBill(bill);
    loadBills();
  }

  Future<void> deleteBill(String id) async {
    await _repo.deleteBill(id);
    loadBills();
  }

  Future<void> payBill(String id) async {
    await _repo.markAsPaid(id);
    loadBills();
  }
}

final billsProvider = StateNotifierProvider<BillsNotifier, List<BillReminderModel>>((ref) {
  return BillsNotifier(ref.read(billRepositoryProvider));
});
