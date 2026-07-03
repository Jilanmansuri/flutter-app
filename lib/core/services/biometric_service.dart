import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'hive_service.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  final HiveService _hiveService = HiveService();

  // Check if biometric authentication is available on device
  Future<bool> isBiometricAvailable() async {
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
    return canAuthenticate;
  }

  // Authenticate user using biometric scan (fingerprint or face)
  Future<bool> authenticate() async {
    final bool available = await isBiometricAvailable();
    if (!available) return false;
    
    try {
      return await _auth.authenticate(
        localizedReason: 'Please authenticate to unlock Smart Finance',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      print('Biometric auth error: $e');
      return false;
    }
  }

  // Set local secure PIN (hashed using SHA-256)
  Future<void> setPin(String pin) async {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    
    // Save to Hive preferences
    _hiveService.isDarkTheme; // dummy to verify active settings
    await _hiveService.saveUser(_hiveService.getUser()!.copyWith(
      pinHash: digest.toString(),
      isBiometricEnabled: true,
    ));
  }

  // Verify numerical PIN
  bool verifyPin(String pin) {
    final user = _hiveService.getUser();
    if (user == null || user.pinHash == null) return true; // bypass if no PIN is set yet
    
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString() == user.pinHash;
  }
}
