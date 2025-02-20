import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DynamicLinkService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize dynamic links
  Future<void> initDynamicLinks(BuildContext context) async {
    // Skip dynamic links on web platform
    if (kIsWeb) {
      return;
    }
    
    // Dynamic links are not used in this version
    // We'll implement a different approach for handling verification
    // and password reset links
  }

  // Handle email verification manually
  Future<void> handleEmailVerification(String actionCode, BuildContext context) async {
    try {
      // Apply the verification code
      await _auth.applyActionCode(actionCode);
      
      // Update user profile
      User? user = _auth.currentUser;
      if (user != null) {
        await user.reload();
      }
      
      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying email: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Handle password reset manually
  Future<void> handlePasswordReset(String actionCode, String email, BuildContext context) async {
    try {
      // Verify the action code is valid
      await _auth.verifyPasswordResetCode(actionCode);
      
      // Navigate to password reset screen with the code
      if (context.mounted) {
        Navigator.of(context).pushNamed(
          '/reset-password-confirm',
          arguments: {
            'actionCode': actionCode,
            'email': email,
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error with password reset link: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
