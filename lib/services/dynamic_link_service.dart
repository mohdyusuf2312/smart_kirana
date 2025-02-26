import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/providers/auth_provider.dart' as app_provider;

/// A service for handling Firebase Auth actions
class DynamicLinkService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // This method is kept for backward compatibility
  Future<void> initDynamicLinks(BuildContext context) async {
    // No implementation needed
    return;
  }

  // Handle email verification manually
  Future<void> handleEmailVerification(
    String actionCode,
    BuildContext context,
  ) async {
    try {
      // Apply the verification code
      await _auth.applyActionCode(actionCode);

      // Update user profile
      User? user = _auth.currentUser;
      if (user != null) {
        await user.reload();

        // Update the auth provider to reflect the new verification status
        if (context.mounted) {
          final authProvider = Provider.of<app_provider.AuthProvider>(
            context,
            listen: false,
          );
          await authProvider.checkEmailVerification();
        }
      }

      // Show success message
      if (context.mounted) {
        // Show a more prominent success message
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Email Verified!'),
              content: const Text(
                'Your email has been successfully verified. You can now access all features of the app.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();

                    // Navigate to home screen
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                  },
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        // Show a more detailed error message
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Verification Failed'),
              content: Text(
                'There was a problem verifying your email: ${e.toString()}\n\n'
                'This may happen if the link has expired or was already used. '
                'Please try requesting a new verification email.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('OK'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();

                    // Resend verification email
                    if (context.mounted) {
                      final authProvider =
                          Provider.of<app_provider.AuthProvider>(
                            context,
                            listen: false,
                          );
                      await authProvider.resendVerificationEmail();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('New verification email sent!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Resend Email'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  // Handle password reset manually
  Future<void> handlePasswordReset(
    String actionCode,
    String email,
    BuildContext context,
  ) async {
    try {
      // Verify the action code is valid
      await _auth.verifyPasswordResetCode(actionCode);

      // Navigate to password reset screen with the code
      if (context.mounted) {
        Navigator.of(context).pushNamed(
          '/reset-password-confirm',
          arguments: {'actionCode': actionCode, 'email': email},
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
