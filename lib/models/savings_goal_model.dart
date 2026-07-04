class SavingsGoalModel {
  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final DateTime deadline;
  final String? imageUrl;
  final bool isCompleted;
  final DateTime updatedAt;
  final bool isPendingSync;

  SavingsGoalModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    required this.deadline,
    this.imageUrl,
    this.isCompleted = false,
    required this.updatedAt,
    this.isPendingSync = false,
  });

  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    final percentage = (savedAmount / targetAmount) * 100;
    return percentage > 100 ? 100.0 : percentage;
  }

  SavingsGoalModel copyWith({
    String? id,
    String? userId,
    String? title,
    double? targetAmount,
    double? savedAmount,
    DateTime? deadline,
    String? imageUrl,
    bool? isCompleted,
    DateTime? updatedAt,
    bool? isPendingSync,
  }) {
    return SavingsGoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      deadline: deadline ?? this.deadline,
      imageUrl: imageUrl ?? this.imageUrl,
      isCompleted: isCompleted ?? this.isCompleted,
      updatedAt: updatedAt ?? this.updatedAt,
      isPendingSync: isPendingSync ?? this.isPendingSync,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'deadline': deadline.toIso8601String(),
      'imageUrl': imageUrl,
      'isCompleted': isCompleted,
      'updatedAt': updatedAt.toIso8601String(),
      'isPendingSync': isPendingSync,
    };
  }

  factory SavingsGoalModel.fromMap(Map<String, dynamic> map) {
    return SavingsGoalModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      targetAmount: (map['targetAmount'] as num).toDouble(),
      savedAmount: (map['savedAmount'] as num?)?.toDouble() ?? 0.0,
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : DateTime.now(),
      imageUrl: map['imageUrl'],
      isCompleted: map['isCompleted'] ?? false,
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
      isPendingSync: map['isPendingSync'] ?? false,
    );
  }
}
