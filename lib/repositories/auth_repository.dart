import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/hive_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HiveService _hiveService = HiveService();

  // Watch auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current logged-in user profile from local database
  UserModel? get currentUser => _hiveService.getUser();

  // Auto Login local validation check
  bool checkAutoLogin() {
    return _hiveService.getUser() != null;
  }

  // Register with Email and Password
  Future<UserModel> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;
      final user = UserModel(
        id: uid,
        name: name,
        email: email,
        photoUrl: null,
        baseCurrency: '₹',
        language: 'en',
        isDarkMode: true,
        lastSyncedAt: DateTime.now(),
      );

      // Save locally & on cloud
      await _hiveService.saveUser(user);
      await _firestore.collection('users').doc(uid).set(user.toMap());

      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Login with Email and Password
  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;
      
      // Pull remote document if exists, else construct standard user
      UserModel user;
      try {
        final doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          user = UserModel.fromMap(doc.data()!);
        } else {
          user = UserModel(
            id: uid,
            name: credential.user!.displayName ?? 'User',
            email: email,
            photoUrl: credential.user!.photoURL,
            baseCurrency: '₹',
            language: 'en',
            isDarkMode: true,
            lastSyncedAt: DateTime.now(),
          );
          await _firestore.collection('users').doc(uid).set(user.toMap());
        }
      } catch (e) {
        // Fallback for offline login initializations
        user = UserModel(
          id: uid,
          name: credential.user!.displayName ?? 'Offline User',
          email: email,
          photoUrl: credential.user!.photoURL,
          baseCurrency: '₹',
          language: 'en',
          isDarkMode: true,
          lastSyncedAt: DateTime.now(),
        );
      }

      await _hiveService.saveUser(user);
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Mock Google Sign In (Google credentials logic simulation)
  Future<UserModel> signInWithGoogleMock() async {
    try {
      // Simulation of oauth token fetching
      final email = 'googleuser@gmail.com';
      final name = 'Google User';
      final uid = 'google_mock_uid_12345';
      
      final user = UserModel(
        id: uid,
        name: name,
        email: email,
        photoUrl: 'https://api.dicebear.com/7.x/adventurer/svg?seed=google',
        baseCurrency: '₹',
        language: 'en',
        isDarkMode: true,
        lastSyncedAt: DateTime.now(),
      );

      await _hiveService.saveUser(user);
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Reset Password
  Future<void> sendForgotPasswordEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Log out user
  Future<void> logout() async {
    await _auth.signOut();
    await _hiveService.clearAllData();
  }

  // Delete User Account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      final uid = user.uid;
      // Delete Cloud data
      await _firestore.collection('users').doc(uid).delete();
      await user.delete();
    }
    await _hiveService.clearAllData();
  }
}
