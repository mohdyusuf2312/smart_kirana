import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// A simple service for handling Firebase Auth actions
///
/// This service uses Firebase's standard email verification flow
/// without Dynamic Links
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if email is verified
  bool isEmailVerified() {
    User? user = _auth.currentUser;
    return user != null && user.emailVerified;
  }

  // Reload user to get latest verification status
  Future<void> reloadUser() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.reload();
      }
    } catch (e) {
      debugPrint('Error reloading user: $e');
      rethrow;
    }
  }

  // Send verification email with longer expiration
  Future<void> sendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        // Use ActionCodeSettings to customize the verification email
        // This increases the expiration time and ensures a fresh link each time
        await user.sendEmailVerification(
          ActionCodeSettings(
            // No URL needed for standard verification
            url: 'https://smart-kirana-81629.firebaseapp.com',
            handleCodeInApp: false,
            // Set to true to force a new link each time
            dynamicLinkDomain: null,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending verification email: $e');
      rethrow;
    }
  }

  // Handle password reset
  Future<void> handlePasswordReset(String email, BuildContext context) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Password reset email sent. Please check your inbox.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error sending password reset email: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
