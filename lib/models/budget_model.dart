class BudgetModel {
  final String id;
  final String userId;
  final String month; // format: YYYY-MM (e.g. "2026-07")
  final String category; // 'Total' or specific category name
  final double limitAmount;
  final double spentAmount;
  final DateTime updatedAt;
  final bool isPendingSync;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.month,
    required this.category,
    required this.limitAmount,
    this.spentAmount = 0.0,
    required this.updatedAt,
    this.isPendingSync = false,
  });

  BudgetModel copyWith({
    String? id,
    String? userId,
    String? month,
    String? category,
    double? limitAmount,
    double? spentAmount,
    DateTime? updatedAt,
    bool? isPendingSync,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      month: month ?? this.month,
      category: category ?? this.category,
      limitAmount: limitAmount ?? this.limitAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      updatedAt: updatedAt ?? this.updatedAt,
      isPendingSync: isPendingSync ?? this.isPendingSync,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'month': month,
      'category': category,
      'limitAmount': limitAmount,
      'spentAmount': spentAmount,
      'updatedAt': updatedAt.toIso8601String(),
      'isPendingSync': isPendingSync,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      month: map['month'] ?? '',
      category: map['category'] ?? 'Total',
      limitAmount: (map['limitAmount'] as num).toDouble(),
      spentAmount: (map['spentAmount'] as num ?? 0.0).toDouble(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
      isPendingSync: map['isPendingSync'] ?? false,
    );
  }
}
