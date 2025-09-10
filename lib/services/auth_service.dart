import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Update user profile with display name
      await userCredential.user?.updateDisplayName(name);

      // Create user document in Firestore
      final user = userCredential.user;
      if (user != null) {
        final databaseRef = FirebaseDatabase.instance.ref();
        await databaseRef.child('users/${user.uid}').set({
          'email': user.email,
          'displayName': name,
          'emailVerified': user.emailVerified,
          'createdAt': ServerValue.timestamp,
          'lastSignInTime': ServerValue.timestamp,
          'photoURL': user.photoURL,
          'isActive': true,
        },);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Optional: Update last sign-in time in Realtime Database
      final user = userCredential.user;
      if (user != null) {
        final userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
        await userRef.update({
          'lastSignInTime': ServerValue.timestamp,
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Failed to sign out: $e';
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google using Firebase native provider (Android/iOS use native UI)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleAuthProvider provider = GoogleAuthProvider();
      provider.addScope('email');
      return await _auth.signInWithProvider(provider);
    } on FirebaseAuthException catch (e) {
      // Treat user cancellation gracefully across platforms
      final code = e.code.toLowerCase();
      if (code == 'canceled' ||
          code == 'user-cancelled' ||
          code == 'web-context-canceled' ||
          code == 'popup-closed-by-user') {
        return null;
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Google sign-in failed: $e';
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'invalid-credential':
        return 'The provided credentials are invalid.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email address but different sign-in credentials.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please log in again.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}