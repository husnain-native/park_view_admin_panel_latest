import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:park_view_admin_panel/constants/app_colors.dart';
import 'package:park_view_admin_panel/constants/app_text_styles.dart';

class AdminIncidentScreen extends StatefulWidget {
  const AdminIncidentScreen({super.key});

  @override
  State<AdminIncidentScreen> createState() => _AdminIncidentScreenState();
}

class _AdminIncidentScreenState extends State<AdminIncidentScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<_IncidentReport> _reports = [];
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to access Admin Incident Management')),
        );
      });
    } else {
      _checkAdminStatus();
      _fetchReports();
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

  void _fetchReports() {
    _database.child('incidents').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      final List<_IncidentReport> loadedReports = [];
      if (data != null) {
        data.forEach((key, value) {
          try {
            loadedReports.add(_IncidentReport(
              id: key,
              title: value['title'] ?? '',
              details: value['details'] ?? '',
              author: value['author'] ?? 'Anonymous',
              timestamp: DateTime.tryParse(value['timestamp'] ?? '') ?? DateTime.now(),
              uid: value['uid'] ?? '',
            ));
          } catch (e) {
            print('Error parsing incident $key: $e');
          }
        });
      }
      loadedReports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      setState(() {
        _reports = loadedReports;
      });
    }, onError: (error) {
      print('Error fetching incidents: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching incidents: $error')),
      );
    });
  }

  Future<void> _addIncident() async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final detailsController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Incident Report'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: detailsController,
                    decoration: const InputDecoration(labelText: 'Details'),
                    maxLines: 3,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
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
                    const SnackBar(content: Text('Please sign in to add a report')),
                  );
                  Navigator.pop(ctx);
                  return;
                }
                final newReport = _IncidentReport(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleController.text.trim(),
                  details: detailsController.text.trim(),
                  author: user.displayName ?? 'Admin',
                  timestamp: DateTime.now(),
                  uid: user.uid,
                );

                try {
                  final ref = _database.child('incidents').child(newReport.id);
                  await ref.set({
                    'title': newReport.title,
                    'details': newReport.details,
                    'author': newReport.author,
                    'timestamp': newReport.timestamp.toIso8601String(),
                    'uid': newReport.uid,
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incident added successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding incident: $e')),
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

  Future<void> _deleteIncident(String id) async {
    try {
      final ref = _database.child('incidents').child(id);
      await ref.remove();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incident deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting incident: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: Text(
          'Admin Incident Management',
          style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Add Incident',
            onPressed: _addIncident,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Incident Reports', style: AppTextStyles.bodyMediumBold),
          const SizedBox(height: 12),
          if (_reports.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No reports yet.'),
              ),
            )
          else
            ..._reports.map((r) => _AdminReportCard(
                  report: r,
                  onDelete: () => _deleteIncident(r.id),
                )).toList(),
        ],
      ),
    );
  }
}

class _AdminReportCard extends StatelessWidget {
  final _IncidentReport report;
  final VoidCallback onDelete;

  const _AdminReportCard({required this.report, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryRed.withOpacity(0.15),
                  child: const Icon(Icons.person, color: AppColors.primaryRed),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report.author, style: AppTextStyles.bodyMediumBold),
                      Text(
                        _formatTime(report.timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete Report',
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(report.title, style: AppTextStyles.bodyMediumBold),
            const SizedBox(height: 6),
            Text(report.details, style: AppTextStyles.bodySmall),
          ],
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

class _IncidentReport {
  final String id;
  final String title;
  final String details;
  final String author;
  final DateTime timestamp;
  final String uid;

  _IncidentReport({
    required this.id,
    required this.title,
    required this.details,
    required this.author,
    required this.timestamp,
    required this.uid,
  });
}