import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import 'package:firebase_database/firebase_database.dart';

class _InboxList extends StatelessWidget {
  const _InboxList();

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

  @override
  Widget build(BuildContext context) {
    final myId = ChatService.currentUid;
    if (myId == null) {
      return const Center(child: Text('Please sign in to view messages'));
    }
    return StreamBuilder<List<Map<dynamic, dynamic>>>(
      stream: ChatService.streamAdminDmThreads(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final threads = snapshot.data ?? [];
        if (threads.isEmpty) {
          return const Center(child: Text('No messages yet'));
        }
        return ListView.separated(
          itemCount: threads.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final data = threads[index];
            final threadId = data['threadId'] as String;
            final participants = List<dynamic>.from(data['participants'] ?? []);
            final lastMessage = (data['lastMessage'] ?? '') as String;
            final unread = Map<dynamic, dynamic>.from(data['unreadCounts'] ?? {});
            final myUnread = (myId != null ? (unread[myId] ?? 0) : 0) as int;

            final otherId = participants.firstWhere(
              (p) => p != myId,
              orElse: () => '',
            ) as String;
                         return FutureBuilder<String>(
               future: otherId.isEmpty
                   ? null
                   : _getUserName(otherId),
               builder: (context, userSnap) {
                 final userName = userSnap.data ?? (otherId.isNotEmpty ? otherId : 'Conversation');
                 final title = userName;
                return ListTile(
                  title: Text(title),
                  subtitle: Text(
                    lastMessage.isEmpty ? 'No messages yet' : lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: myUnread > 0
                      ? CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child: Text(
                            myUnread > 9 ? '9+' : '$myUnread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : null,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _ThreadScreen(threadId: threadId),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ThreadScreen extends StatefulWidget {
  final String threadId;
  const _ThreadScreen({required this.threadId});

  @override
  State<_ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<_ThreadScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    ChatService.markThreadRead(widget.threadId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversation')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<dynamic, dynamic>>>(
              stream: ChatService.streamThreadMessages(widget.threadId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final msgs = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    final m = msgs[index];
                    final mine = m['senderId'] == ChatService.currentUid;
                    final senderId = m['senderId'] as String?;
                    final senderFuture = senderId == null
                        ? null
                        : _getUserName(senderId);
                    return FutureBuilder<String>(
                      future: senderFuture,
                      builder: (context, senderSnap) {
                        final senderName = senderSnap.data ?? 'User';
                        final namePrefix = mine ? 'You' : senderName;
                        return Align(
                          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: mine ? Colors.blue : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  namePrefix,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: mine ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  (m['text'] ?? '') as String,
                                  style: TextStyle(
                                    color: mine ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _groupNameController = TextEditingController();
  final Set<String> _selectedUserIds = <String>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chats Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            tabs: const [Tab(text: 'Inbox'), Tab(text: 'Groups')],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [const _InboxList(), _buildGroupsTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsTab() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _groupNameController,
                decoration: const InputDecoration(hintText: 'Group name'),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                await _openAddMembersDialog();
              },
              child: const Text('Add members'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                final name = _groupNameController.text.trim();
                if (name.isEmpty || _selectedUserIds.isEmpty) return;
                final id = await ChatService.createGroup(
                  name,
                  _selectedUserIds.toList(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Group "$name" created')),
                  );
                }
                _groupNameController.clear();
                _selectedUserIds.clear();
              },
              child: const Text('Create group'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<List<Map<dynamic, dynamic>>>(
            stream: ChatService.streamGroups(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final groups = snapshot.data!;
              if (groups.isEmpty) {
                return const Center(child: Text('No groups'));
              }
              return ListView.separated(
                itemCount: groups.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final g = groups[index];
                  final members = List<String>.from(g['members'] ?? <String>[]);
                  return ListTile(
                    title: Text(g['name'] ?? 'Unnamed'),
                    subtitle: Text('Members: ${members.length}'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _GroupThreadScreen(groupId: g['groupId']),
                        ),
                      );
                    },
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'rename') {
                          final controller = TextEditingController(
                            text: g['name'] ?? '',
                          );
                          final newName = await showDialog<String>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Rename group'),
                              content: TextField(controller: controller),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(context, controller.text.trim()),
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          );
                          if (newName != null && newName.isNotEmpty) {
                            await ChatService.renameGroup(g['groupId'], newName);
                          }
                        } else if (value == 'add') {
                          final added = await _pickMembers(
                            context,
                            exclude: members,
                          );
                          if (added.isNotEmpty) {
                            await ChatService.addGroupMembers(g['groupId'], added);
                          }
                        } else if (value == 'remove') {
                          final removed = await _pickMembers(
                            context,
                            preset: members,
                          );
                          for (final uid in removed) {
                            await ChatService.removeGroupMember(g['groupId'], uid);
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'rename',
                          child: Text('Rename'),
                        ),
                        PopupMenuItem(
                          value: 'add',
                          child: Text('Add members'),
                        ),
                        PopupMenuItem(
                          value: 'remove',
                          child: Text('Remove members'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openAddMembersDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select members'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref('users').onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users = (snapshot.data!.snapshot.value as Map<dynamic, dynamic>?) ?? {};
                final userList = users.entries.map((e) {
                  final userData = Map<dynamic, dynamic>.from(e.value as Map);
                  userData['uid'] = e.key;
                  return userData;
                }).toList();
                return ListView.builder(
                  itemCount: userList.length,
                  itemBuilder: (context, index) {
                    final u = userList[index];
                    final uid = u['uid'] as String;
                    final name = (u['displayName'] ?? 'No Name') as String;
                    final email = (u['email'] ?? '') as String;
                    final selected = _selectedUserIds.contains(uid);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedUserIds.add(uid);
                          } else {
                            _selectedUserIds.remove(uid);
                          }
                        });
                      },
                      title: Text(name),
                      subtitle: Text(email),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Future<List<String>> _pickMembers(
    BuildContext context, {
    List<String> preset = const <String>[],
    List<String> exclude = const <String>[],
  }) async {
    final selected = preset.toSet();
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select members'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref('users').onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users = (snapshot.data!.snapshot.value as Map<dynamic, dynamic>?) ?? {};
                final userList = users.entries.map((e) {
                  final userData = Map<dynamic, dynamic>.from(e.value as Map);
                  userData['uid'] = e.key;
                  return userData;
                }).toList();
                return ListView.builder(
                  itemCount: userList.length,
                  itemBuilder: (context, index) {
                    final u = userList[index];
                    final uid = u['uid'] as String;
                    if (exclude.contains(uid)) {
                      return const SizedBox.shrink();
                    }
                    final name = (u['displayName'] ?? 'No Name') as String;
                    final email = (u['email'] ?? '') as String;
                    final checked = selected.contains(uid);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (v) {
                        if (v == true) {
                          selected.add(uid);
                        } else {
                          selected.remove(uid);
                        }
                        (context as Element).markNeedsBuild();
                      },
                      title: Text(name),
                      subtitle: Text(email),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, <String>[]),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selected.toList()),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
    return result ?? <String>[];
  }
}

class _GroupThreadScreen extends StatefulWidget {
  final String groupId;
  const _GroupThreadScreen({required this.groupId});

  @override
  State<_GroupThreadScreen> createState() => _GroupThreadScreenState();
}

class _GroupThreadScreenState extends State<_GroupThreadScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Group Conversation')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<dynamic, dynamic>>>(
              stream: ChatService.streamGroupMessages(widget.groupId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }
                final msgs = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    final m = msgs[index];
                    final type = (m['type'] ?? 'message') as String;
                    if (type == 'system') {
                      final actorId = m['actorId'] as String?;
                      final actorFuture = actorId == null
                          ? null
                          : _getUserName(actorId);
                      final List<dynamic> targets = List<dynamic>.from(m['targets'] ?? []);
                      
                      return FutureBuilder<String>(
                        future: actorFuture,
                        builder: (context, actorSnap) {
                          final actorName = actorSnap.data ?? 'Someone';
                          
                          if (targets.isEmpty) {
                            final textKey = (m['text'] ?? '') as String;
                            final display = textKey == 'added_to_group'
                                ? '$actorName added to group'
                                : textKey == 'removed_from_group'
                                    ? '$actorName removed from group'
                                    : textKey;
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  display,
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            );
                          }
                          
                          final Future<List<String>> targetNamesFuture = Future.wait(
                            targets.map((t) => _getUserName(t.toString())),
                          );
                          
                          return FutureBuilder<List<String>>(
                            future: targetNamesFuture,
                            builder: (context, tgtSnap) {
                              final targetNames = (tgtSnap.data ?? targets.map((e)=>e.toString()).toList());
                              final joined = targetNames.join(', ');
                              final textKey = (m['text'] ?? '') as String;
                              final display = textKey == 'added_to_group'
                                  ? '$actorName added $joined'
                                  : textKey == 'removed_from_group'
                                      ? '$actorName removed $joined'
                                      : textKey;
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Text(
                                    display,
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    }
                    final mine = m['senderId'] == ChatService.currentUid;
                    final senderId = m['senderId'] as String?;
                    final senderFuture = senderId == null
                        ? null
                        : _getUserName(senderId);
                    return FutureBuilder<String>(
                      future: senderFuture,
                      builder: (context, senderSnap) {
                        final senderName = senderSnap.data ?? 'User';
                        final namePrefix = mine ? 'You' : senderName;
                        return Align(
                          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: mine ? Colors.blue : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  namePrefix,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: mine ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  (m['text'] ?? '') as String,
                                  style: TextStyle(
                                    color: mine ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
                    await ChatService.sendGroupMessage(widget.groupId, text);
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
