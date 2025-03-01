import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_kirana/models/user_model.dart';
import 'package:smart_kirana/services/auth_service.dart';
import 'package:smart_kirana/services/firebase_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _authService.currentUser != null;
  bool get isEmailVerified => _firebaseAuthService.isEmailVerified();
  User? get currentUser => _authService.currentUser;

  // Initialize provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _loadUserData();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load user data
  Future<void> _loadUserData() async {
    if (_authService.currentUser != null) {
      final userData = await _authService.getUserData();
      if (_user?.id != userData?.id ||
          _user?.email != userData?.email ||
          _user?.name != userData?.name ||
          _user?.isVerified != userData?.isVerified) {
        _user = userData;
        notifyListeners();
      }
    }
  }

  // Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      await _loadUserData();
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'The email address is already in use.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is invalid.';
          break;
        case 'weak-password':
          errorMessage = 'The password is too weak.';
          break;
        default:
          errorMessage = 'An error occurred during sign up. Please try again.';
      }
      _setError(errorMessage);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in
  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _loadUserData();
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is invalid.';
          break;
        case 'user-disabled':
          errorMessage = 'This user has been disabled.';
          break;
        default:
          errorMessage = 'An error occurred during sign in. Please try again.';
      }
      _setError(errorMessage);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to sign out. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.resetPassword(email);
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'The email address is invalid.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        default:
          errorMessage = 'An error occurred. Please try again.';
      }
      _setError(errorMessage);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Resend verification email
  Future<bool> resendVerificationEmail() async {
    _setLoading(true);
    _clearError();
    try {
      // Use the new FirebaseAuthService
      await _firebaseAuthService.sendVerificationEmail();
      return true;
    } catch (e) {
      _setError('Failed to send verification email. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check email verification
  Future<bool> checkEmailVerification() async {
    // Don't set loading state if we're just checking verification status
    // This prevents unnecessary UI rebuilds
    try {
      // Use the new FirebaseAuthService
      await _firebaseAuthService.reloadUser();
      bool isVerified = _firebaseAuthService.isEmailVerified();
      if (isVerified) {
        // Only update Firestore and notify listeners if verification status changed
        await _authService.updateUserVerificationStatus(true);
        await _loadUserData();
      }
      return isVerified;
    } catch (e) {
      // Only set error if it's a significant error, not just a verification check
      if (e.toString().contains('network') ||
          e.toString().contains('permission') ||
          e.toString().contains('unauthorized')) {
        _setError('Failed to check email verification. Please try again.');
      }
      return false;
    }
  }

  // Helper methods
  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      // Only notify listeners if the component is actively waiting for this state
      // This prevents unnecessary rebuilds in components that use the provider
      notifyListeners();
    }
  }

  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      // Only notify if there was an actual error to clear
      notifyListeners();
    }
  }

  // Public method to check if email is verified without triggering state changes
  // This can be used for silent checks that don't need UI updates
  Future<bool> checkEmailVerificationSilently() async {
    try {
      // Use the new FirebaseAuthService
      await _firebaseAuthService.reloadUser();
      return _firebaseAuthService.isEmailVerified();
    } catch (e) {
      return false;
    }
  }
}
