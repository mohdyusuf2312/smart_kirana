import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service to ensure the default admin user exists when the app starts
class AdminInitializationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Default admin credentials from guidelines
  static const String defaultAdminEmail = 'mohdyusufr@gmail.com';
  static const String defaultAdminPassword = 'yusuf11';
  static const String defaultAdminName = 'Mohd Yusuf';
  static const String defaultAdminPhone = '9084662330'; // Default phone number

  /// Initialize the default admin user if it doesn't exist
  Future<void> initializeDefaultAdmin() async {
    try {
      debugPrint('Initializing default admin user...');

      // Check if admin user exists in Firestore
      final adminQuery =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: defaultAdminEmail)
              .get();

      if (adminQuery.docs.isEmpty) {
        // No user with this email exists in Firestore, create it
        debugPrint('No user with admin email found in Firestore, creating...');
        await _createDefaultAdmin();
      } else {
        // User exists, check if it has admin role
        final userDoc = adminQuery.docs.first;
        final userData = userDoc.data();

        if (userData['role'] == 'ADMIN') {
          debugPrint('Default admin user already exists with correct role');
        } else {
          // User exists but doesn't have admin role, update it
          debugPrint('User exists but not as admin, updating role...');
          await _firestore.collection('users').doc(userDoc.id).update({
            'role': 'ADMIN',
            'isVerified': true,
            'lastLogin': Timestamp.now(),
          });
          debugPrint('Updated user to admin role');
        }
      }
    } catch (e) {
      // Log error but don't crash the app
      debugPrint('Error initializing default admin: $e');
    }
  }

  /// Create the default admin user in Firebase Auth and Firestore
  Future<void> _createDefaultAdmin() async {
    try {
      // First, check if the user already exists in Firebase Auth
      // We'll use a more direct approach to avoid credential issues
      bool userExists = false;
      String? userId;

      try {
        // Try to create the user - if it fails with email-already-in-use, then the user exists
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: defaultAdminEmail,
          password: defaultAdminPassword,
        );

        userId = userCredential.user!.uid;
        userExists = false;

        // Send verification email for the new user
        try {
          await userCredential.user!.sendEmailVerification();
        } catch (e) {
          // Ignore verification email errors - we'll mark as verified in Firestore
          debugPrint('Could not send verification email: $e');
        }

        debugPrint('Created new admin user in Firebase Auth');
      } catch (e) {
        if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
          // User already exists, try to get the UID
          userExists = true;
          debugPrint('Admin user already exists in Firebase Auth');

          // We need to get the user ID, but we can't sign in if there are credential issues
          // Instead, we'll query Firestore to find the user document by email
          final userQuery =
              await _firestore
                  .collection('users')
                  .where('email', isEqualTo: defaultAdminEmail)
                  .get();

          if (userQuery.docs.isNotEmpty) {
            userId = userQuery.docs.first.id;
            debugPrint('Found existing admin user ID: $userId');
          }
        } else {
          // Some other error occurred
          debugPrint('Error checking if admin exists: $e');
          rethrow;
        }
      }

      // If we have a user ID, ensure the Firestore document exists with admin role
      if (userId != null) {
        await _createAdminDocument(userId);
        debugPrint('Admin user document created or updated in Firestore');
      } else if (userExists) {
        // User exists in Auth but we couldn't get the ID
        // This is a rare case, but we should handle it
        debugPrint('Admin user exists but could not retrieve ID');
      }

      // Make sure we're signed out
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }
    } catch (e) {
      debugPrint('Error creating default admin: $e');
      // Don't rethrow - we want the app to continue even if admin creation fails
    }
  }

  /// Create or update the admin document in Firestore
  Future<void> _createAdminDocument(String uid) async {
    try {
      // Check if document exists first
      final docSnapshot = await _firestore.collection('users').doc(uid).get();

      if (docSnapshot.exists) {
        // Document exists, update only the role and verification status
        await _firestore.collection('users').doc(uid).update({
          'role': 'ADMIN',
          'isVerified': true,
          'lastLogin': Timestamp.now(),
        });
        debugPrint('Updated existing admin document');
      } else {
        // Document doesn't exist, create it
        await _firestore.collection('users').doc(uid).set({
          'name': defaultAdminName,
          'email': defaultAdminEmail,
          'phone': defaultAdminPhone,
          'addresses': [],
          'isVerified': true, // Admin is pre-verified
          'createdAt': Timestamp.now(),
          'lastLogin': Timestamp.now(),
          'role': 'ADMIN', // Set role to ADMIN
        });
        debugPrint('Created new admin document');
      }
    } catch (e) {
      debugPrint('Error creating/updating admin document: $e');
      // Don't rethrow - we want the app to continue even if this fails
    }
  }
}
