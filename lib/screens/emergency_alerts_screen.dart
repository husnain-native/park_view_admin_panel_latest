import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:park_view_admin_panel/constants/app_colors.dart';
import 'package:park_view_admin_panel/constants/app_text_styles.dart';

class EmergencyAlertsScreen extends StatefulWidget {
  const EmergencyAlertsScreen({super.key});

  @override
  State<EmergencyAlertsScreen> createState() => _EmergencyAlertsScreenState();
}

class _EmergencyAlertsScreenState extends State<EmergencyAlertsScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<_Alert> _alerts = [];
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    // Check authentication status
    if (FirebaseAuth.instance.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to view Emergency Alerts')),
        );
        // Optionally redirect to login screen
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
      });
    } else {
      _checkAdminStatus();
      _fetchAlerts();
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
          const SnackBar(content: Text('Only admins can add or delete alerts')),
        );
      }
    }
  }

  void _fetchAlerts() {
    _database.child('alerts').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      final List<_Alert> loadedAlerts = [];
      if (data != null) {
        data.forEach((key, value) {
          try {
            if (value['title'] == null || value['details'] == null) {
              print('Skipping invalid alert $key: missing required fields');
              return;
            }
            loadedAlerts.add(_Alert(
              id: key,
              title: value['title'] ?? '',
              details: value['details'] ?? '',
              time: DateTime.tryParse(value['timestamp'] ?? '') ?? DateTime.now(),
            ));
          } catch (e) {
            print('Error parsing alert $key: $e');
          }
        });
        // Sort by timestamp (newest first)
        loadedAlerts.sort((a, b) => b.time.compareTo(a.time));
      }
      setState(() {
        _alerts = loadedAlerts;
      });
    }, onError: (error) {
      print('Error fetching alerts: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching alerts: $error')),
      );
    });
  }

  Future<void> _addAlert() async {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admins can add alerts')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final detailsController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Emergency Alert'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: detailsController,
                    decoration: const InputDecoration(labelText: 'Details'),
                    maxLines: 3,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please sign in to add an alert')),
                  );
                  Navigator.pop(ctx);
                  return;
                }
                final newAlert = _Alert(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleController.text.trim(),
                  details: detailsController.text.trim(),
                  time: DateTime.now(),
                );

                try {
                  final ref = _database.child('alerts').child(newAlert.id);
                  await ref.set({
                    'title': newAlert.title,
                    'details': newAlert.details,
                    'timestamp': newAlert.time.toIso8601String(),
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alert added successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding alert: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
              ),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAlert(String id) async {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admins can delete alerts')),
      );
      return;
    }
    try {
      final ref = _database.child('alerts').child(id);
      await ref.remove();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting alert: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        title: Text(
          'Emergency Alerts',
          style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
        ),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.add_alert, color: Colors.white),
              tooltip: 'Add Alert',
              onPressed: _addAlert,
            ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _alerts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final _Alert alert = _alerts[index];
          return _AlertCard(
            alert: alert,
            isAdmin: _isAdmin,
            onDelete: () => _deleteAlert(alert.id),
          );
        },
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final _Alert alert;
  final bool isAdmin;
  final VoidCallback onDelete;

  const _AlertCard({
    required this.alert,
    required this.isAdmin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          leading: const Icon(
            Icons.notifications_active,
            color: Colors.red,
          ),
          title: Text(alert.title, style: AppTextStyles.bodyMediumBold),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(alert.details),
              const SizedBox(height: 4),
              Text(
                _formatTime(alert.time),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          trailing: isAdmin
              ? IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete Alert',
                  onPressed: onDelete,
                )
              : null,
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(dt.hour);
    final minutes = twoDigits(dt.minute);
    return '$hours:$minutes';
  }
}

class _Alert {
  final String id;
  final String title;
  final String details;
  final DateTime time;

  _Alert({
    required this.id,
    required this.title,
    required this.details,
    required this.time,
  });
}