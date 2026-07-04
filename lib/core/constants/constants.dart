import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Smart Finance';
  
  // Storage Keys
  static const String settingsBoxName = 'settings_box';
  static const String transactionsBoxName = 'transactions_box';
  static const String budgetsBoxName = 'budgets_box';
  static const String savingsBoxName = 'savings_box';
  static const String loansBoxName = 'loans_box';
  static const String billsBoxName = 'bills_box';
  static const String userBoxName = 'user_box';

  static const String isDarkThemeKey = 'is_dark_theme';
  static const String currencyKey = 'base_currency';
  static const String languageKey = 'base_language';
  static const String isPinLockedKey = 'is_pin_locked';
  static const String pinHashKey = 'pin_hash';
  static const String isBiometricEnabledKey = 'is_biometric_enabled';
  
  // Default values
  static const String defaultCurrency = '₹';
  static const String defaultLanguage = 'en';

  // Categories with matching Icons and Colors
  static final List<CategoryInfo> categories = [
    CategoryInfo(name: 'Food', icon: Icons.fastfood_rounded, color: Colors.orange, isExpense: true),
    CategoryInfo(name: 'Shopping', icon: Icons.shopping_bag_rounded, color: Colors.pink, isExpense: true),
    CategoryInfo(name: 'Travel', icon: Icons.directions_car_rounded, color: Colors.blue, isExpense: true),
    CategoryInfo(name: 'Fuel', icon: Icons.local_gas_station_rounded, color: Colors.teal, isExpense: true),
    CategoryInfo(name: 'Medical', icon: Icons.local_hospital_rounded, color: Colors.red, isExpense: true),
    CategoryInfo(name: 'Entertainment', icon: Icons.movie_creation_rounded, color: Colors.purple, isExpense: true),
    CategoryInfo(name: 'Education', icon: Icons.school_rounded, color: Colors.indigo, isExpense: true),
    CategoryInfo(name: 'Investment', icon: Icons.trending_up_rounded, color: Colors.lightGreen, isExpense: true),
    CategoryInfo(name: 'Bills', icon: Icons.receipt_long_rounded, color: Colors.amber, isExpense: true),
    CategoryInfo(name: 'Rent', icon: Icons.home_work_rounded, color: Colors.brown, isExpense: true),
    
    CategoryInfo(name: 'Salary', icon: Icons.account_balance_wallet_rounded, color: Colors.green, isExpense: false),
    CategoryInfo(name: 'Freelance', icon: Icons.laptop_chromebook_rounded, color: Colors.cyan, isExpense: false),
    CategoryInfo(name: 'Investment Return', icon: Icons.show_chart_rounded, color: const Color(0xFF0F9D58), isExpense: false),
    
    CategoryInfo(name: 'Others', icon: Icons.more_horiz_rounded, color: Colors.grey, isExpense: true),
  ];

  static List<String> get expenseCategories => categories
      .where((c) => c.isExpense)
      .map((c) => c.name)
      .toList();

  static List<String> get incomeCategories => categories
      .where((c) => !c.isExpense)
      .map((c) => c.name)
      .toList();

  // Payment Methods
  static const List<String> paymentMethods = [
    'UPI',
    'Bank Transfer',
    'Debit Card',
    'Credit Card',
    'Cash',
    'Net Banking',
    'Wallet'
  ];
}

class CategoryInfo {
  final String name;
  final IconData icon;
  final Color color;
  final bool isExpense;

  CategoryInfo({
    required this.name,
    required this.icon,
    required this.color,
    required this.isExpense,
  });
}
