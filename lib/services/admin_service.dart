import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminService {
  // Lazy getters to avoid accessing Firebase before initializeApp()
  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static FirebaseDatabase get _database => FirebaseDatabase.instance;
  static FirebaseFunctions get _functions => FirebaseFunctions.instance;

  // Check if current user is admin
  static Future<bool> isAdmin() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      // Check if user document exists in admins collection
      final adminRef = await _database.ref('admins/${user.uid}').get();

      return adminRef.exists;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Create admin user in Firestore
  static Future<void> createAdminUser(
    String uid,
    String email,
    String name,
  ) async {
    try {
      await _database.ref('admins/$uid').set({
        'email': email,
        'name': name,
        'role': 'admin',
        'createdAt': ServerValue.timestamp,
        'isActive': true,
      });
    } catch (e) {
      print('Error creating admin user: $e');
      rethrow;
    }
  }

  // Get admin user data
  static Future<Map<String, dynamic>?> getAdminData() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      final adminSnapshot = await _database.ref('admins/${user.uid}').get();

      if (adminSnapshot.exists) {
        return Map<String, dynamic>.from(adminSnapshot.value as Map);
      }
      return null;
    } catch (e) {
      print('Error getting admin data: $e');
      return null;
    }
  }

  // Sign out admin
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Create or update user document in Firestore
  // This should be called when a user registers or signs in
  static Future<void> createOrUpdateUser(User firebaseUser) async {
    try {
      await _database.ref('users/${firebaseUser.uid}').set({
        'email': firebaseUser.email,
        'displayName': firebaseUser.displayName ?? 'No Name',
        'emailVerified': firebaseUser.emailVerified,
        'createdAt': ServerValue.timestamp,
        'lastSignInTime': ServerValue.timestamp,
        'photoURL': firebaseUser.photoURL,
        'isActive': true,
      });
    } catch (e) {
      print('Error creating/updating user: $e');
    }
  }

  // Update user's last sign in time
  static Future<void> updateLastSignIn(String uid) async {
    try {
      await _database.ref('users/${uid}').update({
        'lastSignInTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating last sign in: $e');
    }
  }

  // Delete user from Firestore
  static Future<void> deleteUser(String uid) async {
    try {
      await _database.ref('users/$uid').remove();
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  // Sync all existing Firebase Auth users to Firestore
  // This creates a comprehensive user list for the admin panel
  static Future<void> syncAllFirebaseAuthUsers() async {
    try {
      print('Starting to sync all Firebase Auth users...');

      // Get current user to ensure we have access
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('No current user found. Please sign in first.');
        return;
      }

      // Create a comprehensive user document for the current user
      await _database.ref('users/${currentUser.uid}').set({
        'email': currentUser.email,
        'displayName': currentUser.displayName ?? 'No Name',
        'emailVerified': currentUser.emailVerified,
        'createdAt': ServerValue.timestamp,
        'lastSignInTime': ServerValue.timestamp,
        'photoURL': currentUser.photoURL,
        'isActive': true,
        'phoneNumber': currentUser.phoneNumber,
        'providerData':
            currentUser.providerData
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
        'metadata': {
          'creationTime':
              currentUser.metadata.creationTime?.millisecondsSinceEpoch,
          'lastSignInTime':
              currentUser.metadata.lastSignInTime?.millisecondsSinceEpoch,
        },
      });

      print('Current user synced successfully');

      // Note: To get ALL Firebase Auth users, you would need:
      // 1. Firebase Admin SDK (server-side)
      // 2. A Cloud Function that lists all users
      // 3. Or manually add users as they sign up

      // For now, we'll create a placeholder for demonstration
      // In production, you'd call a Cloud Function here
      print(
        'To see all Firebase Auth users, implement a Cloud Function that uses Admin SDK',
      );
    } catch (e) {
      print('Error syncing Firebase Auth users: $e');
    }
  }

  // Get users with better error handling and fallback
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      // First try to get users from Firestore
      DatabaseEvent event =
          await _database.ref('users').orderByChild('createdAt').once();

      List<Map<String, dynamic>> users = [];

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> userMap =
            event.snapshot.value as Map<dynamic, dynamic>;
        userMap.forEach((key, value) {
          Map<String, dynamic> userData = Map<String, dynamic>.from(value);
          userData['uid'] = key;
          // Convert Firestore timestamps to DateTime
          if (userData['createdAt'] is int) {
            userData['creationTime'] = DateTime.fromMillisecondsSinceEpoch(
              userData['createdAt'],
            );
          } else if (userData['createdAt'] == null) {
            userData['creationTime'] = DateTime.now(); // Fallback
          }

          if (userData['lastSignInTime'] is int) {
            userData['lastSignInTime'] = DateTime.fromMillisecondsSinceEpoch(
              userData['lastSignInTime'],
            );
          } else if (userData['lastSignInTime'] == null) {
            userData['lastSignInTime'] = DateTime.now(); // Fallback
          }

          users.add(userData);
        });
      }
      // If no users found, try to sync current user
      if (users.isEmpty) {
        print(
          'No users found in Firestore, attempting to sync current user...',
        );
        await syncAllFirebaseAuthUsers();

        // Try again after sync
        DatabaseEvent retryEvent =
            await _database.ref('users').orderByChild('createdAt').once();

        if (retryEvent.snapshot.value != null) {
          Map<dynamic, dynamic> retryUserMap =
              retryEvent.snapshot.value as Map<dynamic, dynamic>;
          retryUserMap.forEach((key, value) {
            Map<String, dynamic> userData = Map<String, dynamic>.from(value);
            userData['uid'] = key;
            // Convert Firestore timestamps to DateTime
            if (userData['createdAt'] is int) {
              userData['creationTime'] = DateTime.fromMillisecondsSinceEpoch(
                userData['createdAt'],
              );
            } else if (userData['createdAt'] == null) {
              userData['creationTime'] = DateTime.now(); // Fallback
            }

            if (userData['lastSignInTime'] is int) {
              userData['lastSignInTime'] = DateTime.fromMillisecondsSinceEpoch(
                userData['lastSignInTime'],
              );
            } else if (userData['lastSignInTime'] == null) {
              userData['lastSignInTime'] = DateTime.now(); // Fallback
            }

            users.add(userData);
          });
        }}
        return users;
      }
         catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  // Get all users directly from Firebase Auth using Cloud Function
  static Future<List<Map<String, dynamic>>> getAllFirebaseAuthUsers() async {
    try {
      final callable = _functions.httpsCallable('getAllUsers');
      final result = await callable.call();

      final data = result.data as Map<String, dynamic>;
      final users = data['users'] as List<dynamic>;

      return users.map((user) {
        Map<String, dynamic> userData = user as Map<String, dynamic>;

        // Convert timestamps to DateTime
        if (userData['creationTime'] != null) {
          userData['creationTime'] = DateTime.fromMillisecondsSinceEpoch(
            userData['creationTime'],
          );
        }

        if (userData['lastSignInTime'] != null) {
          userData['lastSignInTime'] = DateTime.fromMillisecondsSinceEpoch(
            userData['lastSignInTime'],
          );
        }

        return userData;
      }).toList();
    } catch (e) {
      print('Error fetching Firebase Auth users: $e');
      return [];
    }
  }

  // Sync all Firebase Auth users to Firestore using Cloud Function
  static Future<void> syncAllFirebaseAuthUsersToFirestore() async {
    try {
      final callable = _functions.httpsCallable('syncAllUsersToFirestore');
      final result = await callable.call();

      final data = result.data as Map<String, dynamic>;
      print('Sync result: ${data['message']}');
    } catch (e) {
      print('Error syncing Firebase Auth users to Firestore: $e');
      rethrow;
    }
  }
}
