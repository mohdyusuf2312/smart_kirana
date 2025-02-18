import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';

class DynamicLinkService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDynamicLinks _dynamicLinks = FirebaseDynamicLinks.instance;

  // Initialize dynamic links
  Future<void> initDynamicLinks(BuildContext context) async {
    // Handle links that open the app
    final PendingDynamicLinkData? initialLink = await _dynamicLinks.getInitialLink();
    if (initialLink != null) {
      _handleDynamicLink(initialLink, context);
    }

    // Handle links in the foreground
    _dynamicLinks.onLink.listen((dynamicLinkData) {
      _handleDynamicLink(dynamicLinkData, context);
    }).onError((error) {
      print('Dynamic link error: $error');
    });
  }

  // Handle dynamic link
  Future<void> _handleDynamicLink(PendingDynamicLinkData data, BuildContext context) async {
    final Uri deepLink = data.link;
    
    // Handle email verification
    if (deepLink.path.contains('/finishSignUp')) {
      await _handleEmailVerification(deepLink, context);
    }
    
    // Handle password reset
    if (deepLink.path.contains('/resetPassword')) {
      await _handlePasswordReset(deepLink, context);
    }
  }

  // Handle email verification link
  Future<void> _handleEmailVerification(Uri deepLink, BuildContext context) async {
    try {
      // Extract the verification code from the link
      final actionCode = deepLink.queryParameters['oobCode'];
      
      if (actionCode != null) {
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

  // Handle password reset link
  Future<void> _handlePasswordReset(Uri deepLink, BuildContext context) async {
    try {
      // Extract the action code from the link
      final actionCode = deepLink.queryParameters['oobCode'];
      
      if (actionCode != null) {
        // Verify the action code is valid
        await _auth.verifyPasswordResetCode(actionCode);
        
        // Navigate to password reset screen with the code
        if (context.mounted) {
          Navigator.of(context).pushNamed(
            '/reset-password-confirm',
            arguments: {
              'actionCode': actionCode,
              'email': deepLink.queryParameters['email'],
            },
          );
        }
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
