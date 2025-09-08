import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class UserSyncService {
  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Initialize user sync - call this when app starts
  static void initializeUserSync() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // User signed in - create/update user document
        createOrUpdateUser(user);
      }
    });
  }

  // Create or update user document in Firestore
  static Future<void> createOrUpdateUser(User firebaseUser) async {
    try {
      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'email': firebaseUser.email,
        'displayName': firebaseUser.displayName ?? 'No Name',
        'emailVerified': firebaseUser.emailVerified,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignInTime': FieldValue.serverTimestamp(),
        'photoURL': firebaseUser.photoURL,
        'isActive': true,
        'phoneNumber': firebaseUser.phoneNumber,
        'providerData':
            firebaseUser.providerData
                .map(
                  (info) => {
                    'providerId': info.providerId,
                    'uid': info.uid,
                    'displayName': info.displayName,
                    'email': info.email,
                    'photoURL': info.photoURL,
                  },
                )
                .toList(),
      }, SetOptions(merge: true));

      print('User synced to Firestore: ${firebaseUser.email}');
    } catch (e) {
      print('Error syncing user to Firestore: $e');
    }
  }

  // Update user's last sign in time
  static Future<void> updateLastSignIn(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastSignInTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating last sign in: $e');
    }
  }

  // Sync existing Firebase Auth users to Firestore
  // Note: This requires Admin SDK in production
  static Future<void> syncExistingUsers() async {
    try {
      // This is a placeholder - in production you'd need Admin SDK
      // or a Cloud Function to get all Firebase Auth users
      print('Syncing existing users...');

      // For now, we'll just sync the current user if they exist
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await createOrUpdateUser(currentUser);
      }
    } catch (e) {
      print('Error syncing existing users: $e');
    }
  }

  // Get user document from Firestore
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }
}
