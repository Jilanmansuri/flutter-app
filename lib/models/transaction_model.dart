class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String type; // 'income' or 'expense'
  final String category;
  final DateTime date;
  final String time; // 'HH:mm'
  final String paymentMethod;
  final String? notes;
  final String? receiptImageUrl;
  final String? bankName;
  final String? accountLast4;
  final String? upiId;
  final bool isSmsAutoRead;
  final double? availableBalance;
  final DateTime updatedAt;
  final bool isPendingSync;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    required this.time,
    required this.paymentMethod,
    this.notes,
    this.receiptImageUrl,
    this.bankName,
    this.accountLast4,
    this.upiId,
    this.isSmsAutoRead = false,
    this.availableBalance,
    required this.updatedAt,
    this.isPendingSync = false,
  });

  TransactionModel copyWith({
    String? id,
    String? userId,
    double? amount,
    String? type,
    String? category,
    DateTime? date,
    String? time,
    String? paymentMethod,
    String? notes,
    String? receiptImageUrl,
    String? bankName,
    String? accountLast4,
    String? upiId,
    bool? isSmsAutoRead,
    double? availableBalance,
    DateTime? updatedAt,
    bool? isPendingSync,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      time: time ?? this.time,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      bankName: bankName ?? this.bankName,
      accountLast4: accountLast4 ?? this.accountLast4,
      upiId: upiId ?? this.upiId,
      isSmsAutoRead: isSmsAutoRead ?? this.isSmsAutoRead,
      availableBalance: availableBalance ?? this.availableBalance,
      updatedAt: updatedAt ?? this.updatedAt,
      isPendingSync: isPendingSync ?? this.isPendingSync,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date.toIso8601String(),
      'time': time,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'receiptImageUrl': receiptImageUrl,
      'bankName': bankName,
      'accountLast4': accountLast4,
      'upiId': upiId,
      'isSmsAutoRead': isSmsAutoRead,
      'availableBalance': availableBalance,
      'updatedAt': updatedAt.toIso8601String(),
      'isPendingSync': isPendingSync,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] ?? 'expense',
      category: map['category'] ?? 'Others',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      time: map['time'] ?? '00:00',
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      notes: map['notes'],
      receiptImageUrl: map['receiptImageUrl'],
      bankName: map['bankName'],
      accountLast4: map['accountLast4'],
      upiId: map['upiId'],
      isSmsAutoRead: map['isSmsAutoRead'] ?? false,
      availableBalance: map['availableBalance'] != null 
          ? (map['availableBalance'] as num).toDouble() 
          : null,
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
      isPendingSync: map['isPendingSync'] ?? false,
    );
  }
}
