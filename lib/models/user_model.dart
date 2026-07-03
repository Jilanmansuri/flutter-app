class UserModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String baseCurrency;
  final String language;
  final bool isDarkMode;
  final String? pinHash;
  final bool isBiometricEnabled;
  final DateTime lastSyncedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.baseCurrency = '₹',
    this.language = 'en',
    this.isDarkMode = true,
    this.pinHash,
    this.isBiometricEnabled = false,
    required this.lastSyncedAt,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? baseCurrency,
    String? language,
    bool? isDarkMode,
    String? pinHash,
    bool? isBiometricEnabled,
    DateTime? lastSyncedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      language: language ?? this.language,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      pinHash: pinHash ?? this.pinHash,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'baseCurrency': baseCurrency,
      'language': language,
      'isDarkMode': isDarkMode,
      'pinHash': pinHash,
      'isBiometricEnabled': isBiometricEnabled,
      'lastSyncedAt': lastSyncedAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      baseCurrency: map['baseCurrency'] ?? '₹',
      language: map['language'] ?? 'en',
      isDarkMode: map['isDarkMode'] ?? true,
      pinHash: map['pinHash'],
      isBiometricEnabled: map['isBiometricEnabled'] ?? false,
      lastSyncedAt: map['lastSyncedAt'] != null 
          ? DateTime.parse(map['lastSyncedAt']) 
          : DateTime.now(),
    );
  }
}
