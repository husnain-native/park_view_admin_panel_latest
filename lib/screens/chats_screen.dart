import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../services/chat_service.dart';
import 'admin_chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({Key? key, this.initialTabIndex = 0}) : super(key: key);

  final int initialTabIndex;

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _groupNameController = TextEditingController();
  final Set<String> _selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _groupNameController.dispose();
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
      appBar: AppBar(
        title: const Text('Chats Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
    ));
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
                          final controller =
                              TextEditingController(text: g['name'] ?? '');
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
                          final added =
                              await _pickMembers(context, exclude: members);
                          if (added.isNotEmpty) {
                            await ChatService.addGroupMembers(g['groupId'], added);
                          }
                        } else if (value == 'remove') {
                          final removed =
                              await _pickMembers(context, preset: members);
                          for (final uid in removed) {
                            await ChatService.removeGroupMember(g['groupId'], uid);
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'rename', child: Text('Rename')),
                        PopupMenuItem(value: 'add', child: Text('Add members')),
                        PopupMenuItem(value: 'remove', child: Text('Remove members')),
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
    final picked = await _pickMembers(context);
    setState(() {
      _selectedUserIds
        ..clear()
        ..addAll(picked);
    });
  }

  Future<List<String>> _pickMembers(BuildContext context,
      {List<String> exclude = const [], List<String> preset = const []}) async {
    final usersSnap = await FirebaseDatabase.instance.ref('users').get();
    final List<Map<String, String>> users = [];
    if (usersSnap.exists && usersSnap.value is Map) {
      final map = usersSnap.value as Map<dynamic, dynamic>;
      map.forEach((k, v) {
        final mv = v as Map<dynamic, dynamic>;
        final uid = k.toString();
        final displayName = mv['displayName']?.toString() ?? '';
        final email = mv['email']?.toString() ?? uid;
        final displayText = displayName.isNotEmpty ? displayName : email;
        if (!exclude.contains(uid)) {
          users.add({'uid': uid, 'displayText': displayText});
        }
      });
    }

    final Set<String> selection = {...preset};
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Select members'),
        content: SizedBox(
          width: 400,
          height: 400,
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (ctx, i) {
              final u = users[i];
              final uid = u['uid']!;
              final checked = selection.contains(uid);
              return CheckboxListTile(
                value: checked,
                onChanged: (val) {
                  if (val == true) {
                    selection.add(uid);
                  } else {
                    selection.remove(uid);
                  }
                  (ctx as Element).markNeedsBuild();
                },
                title: Text(u['displayText']!),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, selection.toList()),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    // Return empty list on cancel to avoid accidental removals
    return result ?? <String>[];
  }
}

class _InboxList extends StatelessWidget {
  const _InboxList();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        child: const Text('Open Admin Chat'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdminChatScreen()),
          );
        },
      ),
    );
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

                    // system message
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

                    // normal message
                    final senderId = m['senderId'] as String?;
                    final mine = senderId == ChatService.currentUid;
                    final senderFuture = senderId == null
                        ? null
                        : _getUserName(senderId);

                    return FutureBuilder<String>(
                      future: senderFuture,
                      builder: (context, senderSnap) {
                        final senderName = senderSnap.data ?? 'User';
                        final namePrefix = mine ? 'You' : senderName;

                        return Align(
                          alignment: mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
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

          // input box
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
