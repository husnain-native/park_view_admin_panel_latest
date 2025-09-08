import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatService {
  static FirebaseDatabase get _database => FirebaseDatabase.instance;
  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static String? get currentUid => _auth.currentUser?.uid;

  // Database refs
  static DatabaseReference get _threadsCol => _database.ref('threads');
  static DatabaseReference get _groupsCol => _database.ref('groups');

  // Ensure a DM thread exists between admin and user
  static Future<String> createOrGetDmThread(String userId) async {
    final String? adminId = currentUid;
    if (adminId == null) throw Exception('Not signed in');

    final snapshot = await _threadsCol.get();

    if (snapshot.exists) {
      final Map<dynamic, dynamic> threads =
          snapshot.value as Map<dynamic, dynamic>;
      for (final entry in threads.entries) {
        final threadId = entry.key;
        final threadData = entry.value as Map<dynamic, dynamic>;
        final isGroup = threadData['isGroup'] as bool? ?? false;
        final participants = List<dynamic>.from(
          threadData['participants'] ?? [],
        );

        if (!isGroup &&
            participants.contains(adminId) &&
            participants.contains(userId)) {
          return threadId;
        }
      }
    }

    // No matching thread found, create a new one
    final newThreadRef = _threadsCol.push();
    await newThreadRef.set({
      'isGroup': false,
      'participants': [adminId, userId],
      'createdAt': ServerValue.timestamp,
      'lastMessage': null,
      'lastMessageAt': ServerValue.timestamp,
      'unreadCounts': {userId: 0, adminId: 0},
    });

    return newThreadRef.key!;
  }

  // Stream DM threads for the current user
  static Stream<List<Map<dynamic, dynamic>>> streamAdminDmThreads() {
    final String? adminId = currentUid;
    if (adminId == null) {
      return Stream.value([]);
    }

    return _threadsCol.onValue.map((DatabaseEvent event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) return [];

      final Map<dynamic, dynamic> threads =
          snapshot.value as Map<dynamic, dynamic>;
      final List<Map<dynamic, dynamic>> dmThreads = [];

      for (final entry in threads.entries) {
        final threadData = entry.value as Map<dynamic, dynamic>;
        final isGroup = threadData['isGroup'] as bool? ?? false;
        final participants = List<dynamic>.from(
          threadData['participants'] ?? [],
        );

        if (!isGroup && participants.contains(adminId)) {
          final threadWithId = Map<dynamic, dynamic>.from(threadData);
          threadWithId['threadId'] = entry.key;
          dmThreads.add(threadWithId);
        }
      }

      // Sort by lastMessageAt (descending)
      dmThreads.sort((a, b) {
        final aTime = a['lastMessageAt'] as int? ?? 0;
        final bTime = b['lastMessageAt'] as int? ?? 0;
        return bTime.compareTo(aTime);
      });

      return dmThreads;
    });
  }

  // Send message in DM thread
  static Future<void> sendDmMessage(String threadId, String text) async {
    final String? senderId = currentUid;
    if (senderId == null) throw Exception('Not signed in');

    final threadRef = _threadsCol.child(threadId);
    final threadSnap = await threadRef.get();
    if (!threadSnap.exists) throw Exception('Thread not found');

    final data = threadSnap.value as Map<dynamic, dynamic>;
    final participants = List<dynamic>.from(data['participants'] ?? []);

    final messageRef = threadRef.child('messages').push();
    await messageRef.set({
      'text': text,
      'senderId': senderId,
      'createdAt': ServerValue.timestamp,
    });

    final Map<dynamic, dynamic> unread = Map<dynamic, dynamic>.from(
      data['unreadCounts'] ?? {},
    );
    for (final pid in participants) {
      if (pid == senderId) continue;
      unread[pid] = (unread[pid] ?? 0) + 1;
    }

    await threadRef.update({
      'lastMessage': text,
      'lastMessageAt': ServerValue.timestamp,
      'unreadCounts': unread,
    });
  }

  // Mark thread as read by current admin
  static Future<void> markThreadRead(String threadId) async {
    final String? uid = currentUid;
    if (uid == null) return;

    final ref = _threadsCol.child(threadId);
    await ref.update({'unreadCounts/$uid': 0});
  }

  // Stream messages for a DM thread
  static Stream<List<Map<dynamic, dynamic>>> streamThreadMessages(
      String threadId) {
    final messagesRef = _threadsCol.child('$threadId/messages');

    return messagesRef.onValue.map((DatabaseEvent event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) return [];

      final Map<dynamic, dynamic> messages =
          snapshot.value as Map<dynamic, dynamic>;
      final List<Map<dynamic, dynamic>> messageList =
          messages.entries.map((entry) {
        final messageData = Map<dynamic, dynamic>.from(entry.value as Map);
        messageData['messageId'] = entry.key;
        return messageData;
      }).toList();

      // Sort by createdAt (ascending)
      messageList.sort((a, b) {
        final aTime = a['createdAt'] as int? ?? 0;
        final bTime = b['createdAt'] as int? ?? 0;
        return aTime.compareTo(bTime);
      });

      return messageList;
    });
  }

  // GROUPS
  static Stream<List<Map<dynamic, dynamic>>> streamGroups() {
    return _groupsCol.onValue.map((DatabaseEvent event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) return [];

      final Map<dynamic, dynamic> groups =
          snapshot.value as Map<dynamic, dynamic>;
      final List<Map<dynamic, dynamic>> groupList =
          groups.entries.map((entry) {
        final groupData = Map<dynamic, dynamic>.from(entry.value as Map);
        groupData['groupId'] = entry.key;
        return groupData;
      }).toList();

      // Sort by createdAt (descending)
      groupList.sort((a, b) {
        final aTime = a['createdAt'] as int? ?? 0;
        final bTime = b['createdAt'] as int? ?? 0;
        return bTime.compareTo(aTime);
      });

      return groupList;
    });
  }

  static Future<String> createGroup(String name, List<String> memberIds) async {
    final String? adminId = currentUid;
    if (adminId == null) throw Exception('Not signed in');

    final groupRef = _groupsCol.push();
    await groupRef.set({
      'name': name,
      'members': memberIds,
      'createdBy': adminId,
      'createdAt': ServerValue.timestamp,
      'lastMessage': null,
      'lastMessageAt': ServerValue.timestamp,
    });

    return groupRef.key!;
  }

  static Stream<List<Map<dynamic, dynamic>>> streamGroupMessages(
    String groupId,
  ) {
    final messagesRef = _groupsCol.child('$groupId/messages');

    return messagesRef.onValue.map((DatabaseEvent event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) return [];

      final Map<dynamic, dynamic> messages =
          snapshot.value as Map<dynamic, dynamic>;
      final List<Map<dynamic, dynamic>> messageList =
          messages.entries.map((entry) {
        final messageData = Map<dynamic, dynamic>.from(entry.value as Map);
        messageData['messageId'] = entry.key;
        return messageData;
      }).toList();

      messageList.sort((a, b) {
        final aTime = a['createdAt'] as int? ?? 0;
        final bTime = b['createdAt'] as int? ?? 0;
        return aTime.compareTo(bTime);
      });

      return messageList;
    });
  }

  static Future<void> sendGroupMessage(String groupId, String text) async {
    final String? senderId = currentUid;
    if (senderId == null) throw Exception('Not signed in');

    final groupRef = _groupsCol.child(groupId);
    final messageRef = groupRef.child('messages').push();
    await messageRef.set({
      'text': text,
      'senderId': senderId,
      'createdAt': ServerValue.timestamp,
      'type': 'message',
    });

    await groupRef.update({
      'lastMessage': text,
      'lastMessageAt': ServerValue.timestamp,
    });
  }

  static Future<void> renameGroup(String groupId, String newName) async {
    final groupRef = _groupsCol.child(groupId);
    await groupRef.update({'name': newName});
  }

  static Future<void> addGroupMembers(
    String groupId,
    List<String> memberIds,
  ) async {
    final String? adminId = currentUid;
    if (adminId == null) throw Exception('Not signed in');

    final groupRef = _groupsCol.child(groupId);
    final groupSnap = await groupRef.get();
    if (!groupSnap.exists) throw Exception('Group not found');

    final data = groupSnap.value as Map<dynamic, dynamic>;
    final currentMembers = List<dynamic>.from(data['members'] ?? []);
    final updatedMembers = {...currentMembers, ...memberIds}.toList();

    await groupRef.update({'members': updatedMembers});

    final messageRef = groupRef.child('messages').push();
    await messageRef.set({
      'type': 'system',
      'text': 'added_to_group',
      'actorId': adminId,
      'targets': memberIds,
      'createdAt': ServerValue.timestamp,
    });
  }

  static Future<void> removeGroupMember(String groupId, String memberId) async {
    final String? adminId = currentUid;
    if (adminId == null) throw Exception('Not signed in');

    final groupRef = _groupsCol.child(groupId);
    final groupSnap = await groupRef.get();
    if (!groupSnap.exists) throw Exception('Group not found');

    final data = groupSnap.value as Map<dynamic, dynamic>;
    final currentMembers = List<dynamic>.from(data['members'] ?? []);
    final updatedMembers = List<dynamic>.from(currentMembers)..remove(memberId);

    await groupRef.update({'members': updatedMembers});

    final messageRef = groupRef.child('messages').push();
    await messageRef.set({
      'type': 'system',
      'text': 'removed_from_group',
      'actorId': adminId,
      'targets': [memberId],
      'createdAt': ServerValue.timestamp,
    });
  }

  static Future<void> deleteGroupMessage(
    String groupId,
    String messageId,
  ) async {
    final messageRef = _groupsCol.child('$groupId/messages/$messageId');
    await messageRef.remove();
  }
}
