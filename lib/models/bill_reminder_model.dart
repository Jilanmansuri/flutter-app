class BillReminderModel {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final String category; // e.g., 'Electricity', 'Internet', 'Netflix', etc.
  final DateTime dueDate;
  final bool isRecurring;
  final String recurringFrequency; // 'monthly', 'weekly', 'yearly'
  final bool isReminderEnabled;
  final bool isPaid;
  final DateTime updatedAt;
  final bool isPendingSync;

  BillReminderModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.category,
    required this.dueDate,
    this.isRecurring = false,
    this.recurringFrequency = 'monthly',
    this.isReminderEnabled = true,
    this.isPaid = false,
    required this.updatedAt,
    this.isPendingSync = false,
  });

  BillReminderModel copyWith({
    String? id,
    String? userId,
    String? title,
    double? amount,
    String? category,
    DateTime? dueDate,
    bool? isRecurring,
    String? recurringFrequency,
    bool? isReminderEnabled,
    bool? isPaid,
    DateTime? updatedAt,
    bool? isPendingSync,
  }) {
    return BillReminderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      isReminderEnabled: isReminderEnabled ?? this.isReminderEnabled,
      isPaid: isPaid ?? this.isPaid,
      updatedAt: updatedAt ?? this.updatedAt,
      isPendingSync: isPendingSync ?? this.isPendingSync,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'amount': amount,
      'category': category,
      'dueDate': dueDate.toIso8601String(),
      'isRecurring': isRecurring,
      'recurringFrequency': recurringFrequency,
      'isReminderEnabled': isReminderEnabled,
      'isPaid': isPaid,
      'updatedAt': updatedAt.toIso8601String(),
      'isPendingSync': isPendingSync,
    };
  }

  factory BillReminderModel.fromMap(Map<String, dynamic> map) {
    return BillReminderModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] ?? 'Bills',
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : DateTime.now(),
      isRecurring: map['isRecurring'] ?? false,
      recurringFrequency: map['recurringFrequency'] ?? 'monthly',
      isReminderEnabled: map['isReminderEnabled'] ?? true,
      isPaid: map['isPaid'] ?? false,
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
      isPendingSync: map['isPendingSync'] ?? false,
    );
  }
}
