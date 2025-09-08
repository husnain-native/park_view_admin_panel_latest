const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Auto-reply on first user message in a DM thread
exports.autoReplyOnFirstMessage = functions.firestore
  .document('threads/{threadId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    try {
      const message = snap.data();
      const threadRef = admin.firestore().collection('threads').doc(context.params.threadId);
      const threadSnap = await threadRef.get();
      if (!threadSnap.exists) return;
      const thread = threadSnap.data();
      if (!thread || thread.isGroup) return; // only DM

      const participants = thread.participants || [];
      // If there is only one message in this thread, send auto-reply
      const msgs = await threadRef.collection('messages').orderBy('createdAt').limit(2).get();
      if (msgs.size === 1) {
        // Do not auto-reply if the sender is an admin
        const senderId = message.senderId;
        if (senderId) {
          const adminDoc = await admin.firestore().collection('admins').doc(senderId).get();
          if (adminDoc.exists) {
            return;
          }
        }
        await threadRef.collection('messages').add({
          text: 'Hello! Thanks for reaching out to Park View City support. How can we assist you today?',
          senderId: 'system',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        // bump lastMessage
        await threadRef.update({
          lastMessage: 'Auto-reply: How can we assist you today?',
          lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      console.error('autoReplyOnFirstMessage error', e);
    }
  });
// Helper: set/unset admin custom claim based on admins/{uid} doc
exports.syncAdminClaim = functions.firestore
  .document('admins/{uid}')
  .onWrite(async (change, context) => {
    const uid = context.params.uid;
    try {
      if (!change.after.exists) {
        // Admin doc deleted -> remove claim
        await admin.auth().setCustomUserClaims(uid, { admin: false });
        console.log(`Removed admin claim for ${uid}`);
        return;
      }

      // Admin doc created/updated -> set claim true
      const currentClaims = (await admin.auth().getUser(uid)).customClaims || {};
      if (currentClaims.admin === true) {
        console.log(`Admin claim already set for ${uid}`);
        return;
      }
      await admin.auth().setCustomUserClaims(uid, { ...currentClaims, admin: true });
      console.log(`Set admin claim for ${uid}`);
    } catch (error) {
      console.error('Error syncing admin claim:', error);
    }
  });

// Cloud Function to get all Firebase Auth users
exports.getAllUsers = functions.https.onCall(async (data, context) => {
  try {
    // Check if the request is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    // Check if the user is an admin
    const adminDoc = await admin.firestore()
      .collection('admins')
      .doc(context.auth.uid)
      .get();

    if (!adminDoc.exists) {
      throw new functions.https.HttpsError('permission-denied', 'Admin access required');
    }

    // Get all users from Firebase Auth
    const listUsersResult = await admin.auth().listUsers();
    
    // Transform the data for the client
    const users = listUsersResult.users.map(userRecord => ({
      uid: userRecord.uid,
      email: userRecord.email,
      displayName: userRecord.displayName || 'No Name',
      emailVerified: userRecord.emailVerified,
      creationTime: userRecord.metadata.creationTime,
      lastSignInTime: userRecord.metadata.lastSignInTime,
      photoURL: userRecord.photoURL,
      phoneNumber: userRecord.phoneNumber,
      disabled: userRecord.disabled,
      providerData: userRecord.providerData.map(provider => ({
        providerId: provider.providerId,
        uid: provider.uid,
        displayName: provider.displayName,
        email: provider.email,
        photoURL: provider.photoURL,
      })),
    }));

    return { users };
  } catch (error) {
    console.error('Error fetching users:', error);
    throw new functions.https.HttpsError('internal', 'Error fetching users');
  }
});

// Cloud Function to sync all Firebase Auth users to Firestore
exports.syncAllUsersToFirestore = functions.https.onCall(async (data, context) => {
  try {
    // Check if the request is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    // Check if the user is an admin
    const adminDoc = await admin.firestore()
      .collection('admins')
      .doc(context.auth.uid)
      .get();

    if (!adminDoc.exists) {
      throw new functions.https.HttpsError('permission-denied', 'Admin access required');
    }

    // Get all users from Firebase Auth
    const listUsersResult = await admin.auth().listUsers();
    
    // Sync each user to Firestore
    const batch = admin.firestore().batch();
    
    listUsersResult.users.forEach(userRecord => {
      const userRef = admin.firestore().collection('users').doc(userRecord.uid);
      
      batch.set(userRef, {
        email: userRecord.email,
        displayName: userRecord.displayName || 'No Name',
        emailVerified: userRecord.emailVerified,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        lastSignInTime: admin.firestore.FieldValue.serverTimestamp(),
        photoURL: userRecord.photoURL,
        isActive: !userRecord.disabled,
        phoneNumber: userRecord.phoneNumber,
        providerData: userRecord.providerData.map(provider => ({
          providerId: provider.providerId,
          uid: provider.uid,
          displayName: provider.displayName,
          email: provider.email,
          photoURL: provider.photoURL,
        })),
        metadata: {
          creationTime: userRecord.metadata.creationTime,
          lastSignInTime: userRecord.metadata.lastSignInTime,
        },
        disabled: userRecord.disabled,
      }, { merge: true });
    });

    await batch.commit();
    
    return { 
      success: true, 
      message: `Synced ${listUsersResult.users.length} users to Firestore` 
    };
  } catch (error) {
    console.error('Error syncing users:', error);
    throw new functions.https.HttpsError('internal', 'Error syncing users');
  }
});
