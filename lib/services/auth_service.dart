import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_kirana/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      // Create user with email and password
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Send email verification with standard Firebase flow and longer expiration
      await userCredential.user!.sendEmailVerification(
        ActionCodeSettings(
          // No URL needed for standard verification
          url: 'https://smart-kirana-81629.firebaseapp.com',
          handleCodeInApp: false,
          // Set to null to use standard email verification
          dynamicLinkDomain: null,
        ),
      );

      // Create user document in Firestore
      await _createUserDocument(userCredential.user!.uid, name, email, phone);

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(
    String uid,
    String name,
    String email,
    String phone,
  ) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'addresses': [],
        'isVerified': false,
        'createdAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
        'role': 'CUSTOMER',
      });
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login
      await _firestore.collection('users').doc(userCredential.user!.uid).update(
        {'lastLogin': Timestamp.now()},
      );

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Check if email is verified
  bool isEmailVerified() {
    User? user = _auth.currentUser;
    return user != null && user.emailVerified;
  }

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        // Use standard Firebase email verification with longer expiration
        await user.sendEmailVerification(
          ActionCodeSettings(
            // No URL needed for standard verification
            url: 'https://smart-kirana-81629.firebaseapp.com',
            handleCodeInApp: false,
            // Set to null to use standard email verification
            dynamicLinkDomain: null,
          ),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Reload user
  Future<void> reloadUser() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.reload();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Update user verification status
  Future<void> updateUserVerificationStatus(bool isVerified) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'isVerified': isVerified,
        });
      }
    } catch (e) {
      rethrow;
    }
  }
}
