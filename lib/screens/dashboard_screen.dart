import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:park_view_admin_panel/constants/app_colors.dart';
import 'package:park_view_admin_panel/screens/city_cards_screen.dart';
import 'package:park_view_admin_panel/screens/request_screen.dart';
import 'package:park_view_admin_panel/screens/users_screen.dart';
import 'package:park_view_admin_panel/screens/chats_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardHome(),
    const UsersScreen(),
    const ChatsScreen(),
    const PropertiesManagementScreen(),
    const RequestsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: const [
            Icon(Icons.admin_panel_settings, color: AppColors.primaryRed),
            SizedBox(width: 8),
            Text(
              'Park View Admin Panel',
              style: TextStyle(color: Colors.black87),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Inbox',
            icon: const Icon(
              Icons.chat_bubble_outline,
              color: AppColors.primaryRed,
            ),
            onPressed: () => setState(() => _selectedIndex = 2),
          ),
          IconButton(
            tooltip: 'Users',
            icon: const Icon(Icons.people_outline, color: AppColors.primaryRed),
            onPressed: () => setState(() => _selectedIndex = 1),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Users'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.chat),
                label: Text('Chats'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.location_city),
                label: Text('City Cards'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.notification_add),
                label: Text('Requests'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F8FA),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _quickAction(
                context,
                Icons.people_alt,
                'Manage Users',
                Colors.blue,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UsersScreen()),
                  );
                },
              ),
              _quickAction(
                context,
                Icons.inbox_outlined,
                'Inbox',
                Colors.green,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChatsScreen()),
                  );
                },
              ),
              _quickAction(
                context,
                Icons.group_work_outlined,
                'Manage Groups',
                Colors.purple,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChatsScreen()),
                  );
                },
              ),
              _quickAction(
                context,
                Icons.location_city,
                'City Cards',
                Colors.orange,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PropertiesManagementScreen()),
                  );
                },
              ),
              _quickAction(
                context,
                Icons.notification_add,
                'Property Requests',
                Colors.red,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RequestsScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _statTile('Total Users', Icons.people_alt, Colors.blue),
              _statTile(
                'Active Groups',
                Icons.groups_2_outlined,
                Colors.purple,
              ),
              _statTile(
                'Unread Inbox',
                Icons.mark_chat_unread_outlined,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickAction(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statTile(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '—',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  'Tap to view details',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}