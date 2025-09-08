import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:park_view_admin_panel/constants/app_colors.dart';
import '../services/chat_service.dart';

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: const Text('Admin Chat Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Direct Message Threads',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<Map<dynamic, dynamic>>>(
                stream: ChatService.streamAdminDmThreads(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final threads = snapshot.data!;

                  return ListView.builder(
                    itemCount: threads.length,
                    itemBuilder: (context, index) {
                      final thread = threads[index];
                      final participants = List<dynamic>.from(thread['participants'] ?? []);
                      final otherParticipantId = participants.firstWhere(
                        (id) => id != ChatService.currentUid,
                        orElse: () => 'Unknown',
                      );

                      return FutureBuilder<String>(
                        future: _getUserName(otherParticipantId),
                        builder: (context, userSnapshot) {
                          final userName = userSnapshot.data ?? 'Unknown User';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryBlue,
                              child: Text(
                                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(userName),
                            subtitle: Text(thread['lastMessage'] ?? 'No messages yet'),
                            trailing: thread['unreadCounts']?[ChatService.currentUid] != null &&
                                    thread['unreadCounts'][ChatService.currentUid] > 0
                                ? CircleAvatar(
                                    radius: 10,
                                    backgroundColor: AppColors.primaryRed,
                                    child: Text(
                                      '${thread['unreadCounts'][ChatService.currentUid]}',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  )
                                : null,
                            onTap: () {
                              // Navigate to chat thread
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => _ChatThreadScreen(
                                    threadId: thread['threadId'],
                                    otherUserName: userName,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to get user name from UID
  Future<String> _getUserName(String uid) async {
    try {
      final userSnap = await FirebaseDatabase.instance.ref('users/$uid').get();
      if (userSnap.exists && userSnap.value is Map) {
        final userData = Map<dynamic, dynamic>.from(userSnap.value as Map);
        final displayName = userData['displayName'] as String?;
        if (displayName != null && displayName.trim().isNotEmpty) {
          return displayName.trim();
        }
        final email = userData['email'] as String?;
        if (email != null && email.trim().isNotEmpty) {
          return email.trim();
        }
      }
      return uid; // Fallback to UID if no name/email found
    } catch (e) {
      return uid; // Fallback to UID on error
    }
  }
}

class _ChatThreadScreen extends StatefulWidget {
  final String threadId;
  final String otherUserName;

  const _ChatThreadScreen({
    required this.threadId,
    required this.otherUserName,
  });

  @override
  State<_ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<_ChatThreadScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: Text('Chat with ${widget.otherUserName}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<dynamic, dynamic>>>(
              stream: ChatService.streamThreadMessages(widget.threadId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isFromCurrentUser = message['senderId'] == ChatService.currentUid;

                    return Align(
                      alignment: isFromCurrentUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isFromCurrentUser
                              ? AppColors.primaryBlue
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          message['text'] ?? '',
                          style: TextStyle(
                            color: isFromCurrentUser ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    final text = _controller.text.trim();
                    if (text.isEmpty) return;
                    _controller.clear();
                    await ChatService.sendDmMessage(widget.threadId, text);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
