import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../models/user.dart';
import '../utils/constants.dart';

enum AuthStatus {
  authenticated,
  unauthenticated,
  loading,
  error,
}

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  // State variables
  AuthStatus _status = AuthStatus.loading;
  AppUser? _currentUser;
  String? _errorMessage;
  bool _isAppLocked = false;
  
  // Getters
  AuthStatus get status => _status;
  AppUser? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAppLocked => _isAppLocked;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAnonymous => _currentUser?.isAnonymous ?? true;

  // Constructor initializes the auth state
  AuthService() {
    _initAuthState();
  }

  // Initialize auth state on app startup
  Future<void> _initAuthState() async {
    _status = AuthStatus.loading;
    notifyListeners();

    // Check for app lock
    await _checkAppLock();
    
    // Listen to Firebase auth state changes
    _auth.authStateChanges().listen((User? user) async {
      if (user == null) {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
      } else {
        await _loadUserData(user);
        _status = AuthStatus.authenticated;
      }
      notifyListeners();
    });
  }

  // Check if app lock is enabled and verify it's locked
  Future<void> _checkAppLock() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appLockEnabled = prefs.getBool(AppConstants.keyAppLockEnabled) ?? false;
      
      if (appLockEnabled) {
        _isAppLocked = true;
        notifyListeners();
      }
    } catch (e) {
      print('Error checking app lock: $e');
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserData(User user) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();
      
      if (doc.exists) {
        _currentUser = AppUser.fromFirestore(doc);
      } else {
        // Create new user document if it doesn't exist
        final newUser = AppUser(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoUrl: user.photoURL,
          isAnonymous: user.isAnonymous,
        );
        
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .set(newUser.toFirestore());
            
        _currentUser = newUser;
      }
      
      // Save user info to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyUserEmail, _currentUser!.email);
      await prefs.setString(AppConstants.keyUserId, _currentUser!.uid);
      
      // Update last login time
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update({
        'lastLoginAt': Timestamp.now(),
      });
    } catch (e) {
      _errorMessage = 'Failed to load user data: $e';
      _status = AuthStatus.error;
    }
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return true;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      
      switch (e.code) {
        case 'user-not-found':
          _errorMessage = 'No user found for that email.';
          break;
        case 'wrong-password':
          _errorMessage = 'Wrong password provided.';
          break;
        case 'invalid-email':
          _errorMessage = 'The email address is badly formatted.';
          break;
        case 'user-disabled':
          _errorMessage = 'This user has been disabled.';
          break;
        default:
          _errorMessage = 'Authentication failed: ${e.message}';
      }
      
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Authentication failed: $e';
      notifyListeners();
      return false;
    }
  }

  // Register with email and password
  Future<bool> registerWithEmailAndPassword(String email, String password, String? displayName) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        // Update display name if provided
        if (displayName != null && displayName.isNotEmpty) {
          await userCredential.user!.updateDisplayName(displayName);
        }
        
        // Force refresh to get the updated user info
        await userCredential.user!.reload();
        
        return true;
      }
      
      return false;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      
      switch (e.code) {
        case 'email-already-in-use':
          _errorMessage = 'The email address is already in use.';
          break;
        case 'invalid-email':
          _errorMessage = 'The email address is badly formatted.';
          break;
        case 'operation-not-allowed':
          _errorMessage = 'Email/password accounts are not enabled.';
          break;
        case 'weak-password':
          _errorMessage = 'The password is too weak.';
          break;
        default:
          _errorMessage = 'Registration failed: ${e.message}';
      }
      
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Registration failed: $e';
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      
      // Clear shared preferences except for app lock settings
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyUserEmail);
      await prefs.remove(AppConstants.keyUserId);
      
      _status = AuthStatus.unauthenticated;
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Sign out failed: $e';
      notifyListeners();
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = 'Failed to send password reset email: ${e.message}';
      notifyListeners();
      return false;
    }
  }

  // Set PIN for app lock
  Future<bool> setAppLockPin(String pin) async {
    try {
      await _secureStorage.write(
        key: AppConstants.keyAppLockPin,
        value: pin,
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyAppLockEnabled, true);
      
      _isAppLocked = true;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to set app lock PIN: $e';
      notifyListeners();
      return false;
    }
  }

  // Verify app lock PIN
  Future<bool> verifyAppLockPin(String pin) async {
    try {
      final storedPin = await _secureStorage.read(key: AppConstants.keyAppLockPin);
      if (storedPin == pin) {
        _isAppLocked = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to verify PIN: $e';
      notifyListeners();
      return false;
    }
  }

  // Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics && 
             await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;
      
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your notes',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      
      if (authenticated) {
        _isAppLocked = false;
        notifyListeners();
      }
      
      return authenticated;
    } catch (e) {
      _errorMessage = 'Biometric authentication failed: $e';
      notifyListeners();
      return false;
    }
  }

  // Disable app lock
  Future<bool> disableAppLock() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyAppLockEnabled, false);
      await _secureStorage.delete(key: AppConstants.keyAppLockPin);
      
      _isAppLocked = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to disable app lock: $e';
      notifyListeners();
      return false;
    }
  }

  // Lock the app
  void lockApp() {
    _isAppLocked = true;
    notifyListeners();
  }

  // Update user settings in Firestore
  Future<bool> updateUserSettings(Map<String, dynamic> newSettings) async {
    try {
      if (_currentUser == null) return false;
      
      final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(_currentUser!.uid);
          
      await userRef.update({
        'settings': newSettings,
      });
      
      _currentUser = _currentUser!.copyWith(settings: newSettings);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update settings: $e';
      notifyListeners();
      return false;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({String? displayName, String? photoUrl}) async {
    try {
      if (_currentUser == null) return false;
      
      final user = _auth.currentUser;
      if (user == null) return false;
      
      // Update Firebase Auth profile
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      
      // Update Firestore document
      final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(_currentUser!.uid);
          
      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      
      if (updates.isNotEmpty) {
        await userRef.update(updates);
        
        _currentUser = _currentUser!.copyWith(
          displayName: displayName ?? _currentUser!.displayName,
          photoUrl: photoUrl ?? _currentUser!.photoUrl,
        );
        
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      notifyListeners();
      return false;
    }
  }
}
