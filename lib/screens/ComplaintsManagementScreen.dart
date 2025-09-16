import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:park_view_admin_panel/constants/app_colors.dart';
import 'package:park_view_admin_panel/constants/app_text_styles.dart';
import 'dart:async';

class ComplaintsManagementScreen extends StatefulWidget {
  const ComplaintsManagementScreen({super.key});

  @override
  State<ComplaintsManagementScreen> createState() => _ComplaintsManagementScreenState();
}

class _ComplaintsManagementScreenState extends State<ComplaintsManagementScreen> {
  final List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<DatabaseEvent>? _complaintsSubscription;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  @override
  void dispose() {
    _complaintsSubscription?.cancel();
    super.dispose();
  }

  void _loadComplaints() {
    _complaintsSubscription = FirebaseDatabase.instance
        .ref('complaints')
        .onValue
        .listen((event) {
      if (!mounted) return;
      try {
        final Object? raw = event.snapshot.value;
        final List<Map<String, dynamic>> complaints = [];
        if (raw != null && raw is Map) {
          final Map<dynamic, dynamic> usersMap = raw;
          usersMap.forEach((userKey, userValue) {
            if (userValue is Map) {
              final Map<dynamic, dynamic> userComplaints = userValue;
              userComplaints.forEach((complaintKey, complaintValue) {
                try {
                  final data = Map<String, dynamic>.from(complaintValue as Map);
                  data['id'] = complaintKey.toString();
                  data['userId'] = userKey.toString();
                  complaints.add(data);
                } catch (e) {
                  print('Error parsing complaint $complaintKey for user $userKey: $e');
                }
              });
            }
          });
        }
        complaints.sort((a, b) {
          return DateTime.parse(b['timestamp'] ?? DateTime.now().toIso8601String()).compareTo(
            DateTime.parse(a['timestamp'] ?? DateTime.now().toIso8601String()),
          );
        });
        setState(() {
          _complaints
            ..clear()
            ..addAll(complaints);
          _isLoading = false;
          _error = null;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load complaints: $e';
        });
      }
    }, onError: (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Stream error: $e';
      });
    });
  }

  Future<void> _updateStatus(Map<String, dynamic> complaint, String newStatus) async {
    try {
      final complaintRef = FirebaseDatabase.instance.ref('complaints/${complaint['userId']}/${complaint['id']}');
      await complaintRef.update({'status': newStatus});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Complaint status updated to $newStatus'),
          backgroundColor: const Color.fromARGB(255, 6, 131, 16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update complaint status: $e')),
      );
    }
  }

  Future<void> _deleteComplaint(Map<String, dynamic> complaint) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion', style: AppTextStyles.bodyMediumBold),
        content: Text(
          'Are you sure you want to delete the complaint "${complaint['title']}"?',
          style: AppTextStyles.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: AppTextStyles.bodySmall.copyWith(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: AppTextStyles.bodySmall.copyWith(color: const Color.fromARGB(255, 139, 2, 2))),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final complaintRef = FirebaseDatabase.instance.ref('complaints/${complaint['userId']}/${complaint['id']}');
      await complaintRef.remove();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Complaint deleted successfully'),
          backgroundColor: const Color.fromARGB(255, 161, 11, 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete complaint: $e')),
      );
    }
  }

  String _formatTimestamp(String? timestamp) {
    try {
      final dt = DateTime.parse(timestamp ?? DateTime.now().toIso8601String());
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
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        title: Text(
          'Complaints Management',
          style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isLoading)
              Container(
                width: double.infinity,
                color: Colors.yellow.shade100,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Loading complaints...',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            if (_error != null)
              Container(
                width: double.infinity,
                color: Colors.red.shade100,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _complaints.isEmpty && !_isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text('No complaints found', style: AppTextStyles.bodyMediumBold),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _complaints.length,
                      itemBuilder: (context, index) {
                        final complaint = _complaints[index];
                        return _ComplaintCard(
                          complaint: complaint,
                          onResolve: () => _updateStatus(complaint, 'Resolved'),
                          onDelete: () => _deleteComplaint(complaint),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final Map<String, dynamic> complaint;
  final VoidCallback onResolve;
  final VoidCallback onDelete;

  const _ComplaintCard({
    required this.complaint,
    required this.onResolve,
    required this.onDelete,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'inprogress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(String? timestamp) {
    try {
      final dt = DateTime.parse(timestamp ?? DateTime.now().toIso8601String());
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
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = complaint['status'] ?? 'Pending';
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    complaint['title'] ?? 'Untitled',
                    style: AppTextStyles.bodyMediumBold.copyWith(fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(
                  label: complaint['category'] ?? 'Uncategorized',
                  color: AppColors.primaryRed,
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  label: complaint['priority'] ?? 'Medium',
                  color: _getPriorityColor(complaint['priority'] ?? 'Medium'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Description: ${complaint['description'] ?? 'No description'}',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.black87, height: 1.3),
            ),
            const SizedBox(height: 8),
            Text(
              'User ID: ${complaint['userId'] ?? 'Unknown'}',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
            ),
            Text(
              'Submitted: ${_formatTimestamp(complaint['timestamp'])}',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status != 'Resolved')
                  ElevatedButton(
                    onPressed: onResolve,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Mark as Resolved'),
                  ),
                if (status != 'Resolved') const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    'Delete',
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}