import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:park_view_admin_panel/constants/app_colors.dart';
import 'package:park_view_admin_panel/constants/app_text_styles.dart';

class AdminLostFoundScreen extends StatefulWidget {
  const AdminLostFoundScreen({super.key});

  @override
  State<AdminLostFoundScreen> createState() => _AdminLostFoundScreenState();
}

class _AdminLostFoundScreenState extends State<AdminLostFoundScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<_LostFoundItem> _lostItems = [];
  List<_LostFoundItem> _foundItems = [];
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Check authentication status
    if (FirebaseAuth.instance.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to access Admin Lost & Found')),
        );
        // Optionally redirect to login screen
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
      });
    } else {
      _checkAdminStatus();
      _fetchItems();
    }
  }

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final adminRef = _database.child('admins').child(user.uid);
      final snapshot = await adminRef.get();
      setState(() {
        _isAdmin = snapshot.exists;
      });
      if (!_isAdmin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You do not have admin privileges')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Fetch lost and found items from Firebase RTDB
  void _fetchItems() {
    // Fetch lost items
    _database.child('lost').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      final List<_LostFoundItem> loadedLostItems = [];
      if (data != null) {
        data.forEach((key, value) {
          try {
            // Skip items with missing or invalid data
            if (value['title'] == null || value['uid'] == null) {
              print('Skipping invalid lost item $key: missing required fields');
              return;
            }
            loadedLostItems.add(_LostFoundItem(
              id: key,
              title: value['title'] ?? '',
              description: value['description'] ?? '',
              location: value['location'] ?? '',
              timestamp: DateTime.tryParse(value['timestamp'] ?? '') ?? DateTime.now(),
              isLost: true,
              contactName: value['contactName'],
              contactPhone: value['contactPhone'],
              uid: value['uid'] ?? '',
            ));
          } catch (e) {
            print('Error parsing lost item $key: $e');
          }
        });
        // Sort by timestamp (newest first)
        loadedLostItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      setState(() {
        _lostItems = loadedLostItems;
      });
    }, onError: (error) {
      print('Error fetching lost items: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching lost items: $error')),
      );
    });

    // Fetch found items
    _database.child('found').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      final List<_LostFoundItem> loadedFoundItems = [];
      if (data != null) {
        data.forEach((key, value) {
          try {
            // Skip items with missing or invalid data
            if (value['title'] == null || value['uid'] == null) {
              print('Skipping invalid found item $key: missing required fields');
              return;
            }
            loadedFoundItems.add(_LostFoundItem(
              id: key,
              title: value['title'] ?? '',
              description: value['description'] ?? '',
              location: value['location'] ?? '',
              timestamp: DateTime.tryParse(value['timestamp'] ?? '') ?? DateTime.now(),
              isLost: false,
              contactName: value['contactName'],
              contactPhone: value['contactPhone'],
              uid: value['uid'] ?? '',
            ));
          } catch (e) {
            print('Error parsing found item $key: $e');
          }
        });
        // Sort by timestamp (newest first)
        loadedFoundItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      setState(() {
        _foundItems = loadedFoundItems;
      });
    }, onError: (error) {
      print('Error fetching found items: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching found items: $error')),
      );
    });
  }

  Future<void> _deleteItem(String id, bool isLost) async {
    try {
      final ref = _database.child(isLost ? 'lost' : 'found').child(id);
      await ref.remove();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting item: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: Text(
          'Admin Lost & Found',
          style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: AppTextStyles.bodyMediumBold.copyWith(fontSize: 16),
          unselectedLabelStyle: AppTextStyles.bodyMedium.copyWith(fontSize: 16),
          tabs: const [Tab(text: 'Lost Items'), Tab(text: 'Found Items')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildLostTab(context), _buildFoundTab(context)],
      ),
    );
  }

  Widget _buildLostTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        _buildSection('Recent Lost Reports', _lostItems, true),
      ],
    );
  }

  Widget _buildFoundTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        _buildSection('Recently Found', _foundItems, false),
      ],
    );
  }

  Widget _buildSection(String heading, List<_LostFoundItem> items, bool isLost) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: AppTextStyles.bodyMediumBold),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No entries yet.'),
            ),
          )
        else
          ...items.map((i) => _AdminLostFoundCard(
                item: i,
                isAdmin: _isAdmin,
                onDelete: () => _deleteItem(i.id, isLost),
              )).toList(),
      ],
    );
  }
}

class _AdminLostFoundCard extends StatelessWidget {
  final _LostFoundItem item;
  final bool isAdmin;
  final VoidCallback onDelete;

  const _AdminLostFoundCard({
    required this.item,
    required this.isAdmin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Color chipColor = item.isLost ? Colors.orange : Colors.green;
    final String chipText = item.isLost ? 'Lost' : 'Found';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded( 
                  child: Text(item.title, style: AppTextStyles.bodyMediumBold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: chipColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    chipText,
                    style: TextStyle(
                      color: chipColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (item.description.isNotEmpty)
              Text(item.description, style: AppTextStyles.bodySmall),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.location,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _formatTime(item.timestamp),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            if ((item.contactName?.isNotEmpty ?? false) ||
                (item.contactPhone?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      [
                        item.contactName,
                        item.contactPhone,
                      ].where((e) => (e ?? '').isNotEmpty).join(' • '),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (isAdmin) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: onDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Delete', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

class _LostFoundItem {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime timestamp;
  final bool isLost;
  final String? contactName;
  final String? contactPhone;
  final String? uid;

  _LostFoundItem({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.timestamp,
    required this.isLost,
    this.contactName,
    this.contactPhone,
    this.uid,
  });
}