class LoanModel {
  final String id;
  final String userId;
  final String name;
  final double loanAmount;
  final double interestRate; // Annual %
  final double emiAmount;
  final double remainingAmount;
  final DateTime dueDate;
  final bool isReminderEnabled;
  final DateTime updatedAt;
  final bool isPendingSync;

  LoanModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.loanAmount,
    required this.interestRate,
    required this.emiAmount,
    required this.remainingAmount,
    required this.dueDate,
    this.isReminderEnabled = true,
    required this.updatedAt,
    this.isPendingSync = false,
  });

  double get progressPercentage {
    if (loanAmount <= 0) return 0.0;
    final paid = loanAmount - remainingAmount;
    final percentage = (paid / loanAmount) * 100;
    return percentage < 0 ? 0.0 : (percentage > 100 ? 100.0 : percentage);
  }

  LoanModel copyWith({
    String? id,
    String? userId,
    String? name,
    double? loanAmount,
    double? interestRate,
    double? emiAmount,
    double? remainingAmount,
    DateTime? dueDate,
    bool? isReminderEnabled,
    DateTime? updatedAt,
    bool? isPendingSync,
  }) {
    return LoanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      loanAmount: loanAmount ?? this.loanAmount,
      interestRate: interestRate ?? this.interestRate,
      emiAmount: emiAmount ?? this.emiAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      dueDate: dueDate ?? this.dueDate,
      isReminderEnabled: isReminderEnabled ?? this.isReminderEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
      isPendingSync: isPendingSync ?? this.isPendingSync,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'loanAmount': loanAmount,
      'interestRate': interestRate,
      'emiAmount': emiAmount,
      'remainingAmount': remainingAmount,
      'dueDate': dueDate.toIso8601String(),
      'isReminderEnabled': isReminderEnabled,
      'updatedAt': updatedAt.toIso8601String(),
      'isPendingSync': isPendingSync,
    };
  }

  factory LoanModel.fromMap(Map<String, dynamic> map) {
    return LoanModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      loanAmount: (map['loanAmount'] as num).toDouble(),
      interestRate: (map['interestRate'] as num).toDouble(),
      emiAmount: (map['emiAmount'] as num).toDouble(),
      remainingAmount: (map['remainingAmount'] as num).toDouble(),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : DateTime.now(),
      isReminderEnabled: map['isReminderEnabled'] ?? true,
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
      isPendingSync: map['isPendingSync'] ?? false,
    );
  }
}
