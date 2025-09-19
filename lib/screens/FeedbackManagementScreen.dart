import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:park_view_admin_panel/constants/app_colors.dart';
import 'package:park_view_admin_panel/constants/app_text_styles.dart';
import 'dart:async';

class FeedbackManagementScreen extends StatefulWidget {
  const FeedbackManagementScreen({super.key});

  @override
  State<FeedbackManagementScreen> createState() =>
      _FeedbackManagementScreenState();
}

class _FeedbackManagementScreenState extends State<FeedbackManagementScreen> {
  final List<Map<String, dynamic>> _feedbacks = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<DatabaseEvent>? _feedbackSubscription;

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  @override
  void dispose() {
    _feedbackSubscription?.cancel();
    super.dispose();
  }

  Future<String> _fetchUserDisplayName(String userId) async {
    try {
      final snapshot =
          await FirebaseDatabase.instance.ref('users/$userId/name').get();
      if (snapshot.exists && snapshot.value != null) {
        return snapshot.value.toString();
      }
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null &&
          currentUser.uid == userId &&
          currentUser.displayName != null) {
        return currentUser.displayName!;
      }
      return 'Unknown';
    } catch (e) {
      print('Error fetching display name for user $userId: $e');
      return 'Unknown';
    }
  }

  void _loadFeedback() {
    _feedbackSubscription = FirebaseDatabase.instance
        .ref('feedback')
        .onValue
        .listen(
          (event) async {
            if (!mounted) return;
            try {
              final Object? raw = event.snapshot.value;
              final List<Map<String, dynamic>> feedbacks = [];
              if (raw != null && raw is Map) {
                final Map<dynamic, dynamic> usersMap = raw;
                for (var userKey in usersMap.keys) {
                  if (usersMap[userKey] is Map) {
                    final Map<dynamic, dynamic> userFeedbacks =
                        usersMap[userKey];
                    final displayName = await _fetchUserDisplayName(
                      userKey.toString(),
                    );
                    for (var feedbackKey in userFeedbacks.keys) {
                      try {
                        final data = Map<String, dynamic>.from(
                          userFeedbacks[feedbackKey] as Map,
                        );
                        data['id'] = feedbackKey.toString();
                        data['userId'] = userKey.toString();
                        data['displayName'] = displayName;
                        feedbacks.add(data);
                      } catch (e) {
                        print(
                          'Error parsing feedback $feedbackKey for user $userKey: $e',
                        );
                      }
                    }
                  }
                }
              }
              feedbacks.sort((a, b) {
                return DateTime.parse(
                  b['timestamp'] ?? DateTime.now().toIso8601String(),
                ).compareTo(
                  DateTime.parse(
                    a['timestamp'] ?? DateTime.now().toIso8601String(),
                  ),
                );
              });
              setState(() {
                _feedbacks
                  ..clear()
                  ..addAll(feedbacks);
                _isLoading = false;
                _error = null;
              });
            } catch (e) {
              setState(() {
                _isLoading = false;
                _error = 'Failed to load feedback: $e';
              });
            }
          },
          onError: (e) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _error = 'Stream error: $e';
            });
          },
        );
  }

  Future<void> _replyToFeedback(
    Map<String, dynamic> feedback,
    String reply,
  ) async {
    try {
      final feedbackRef = FirebaseDatabase.instance.ref(
        'feedback/${feedback['userId']}/${feedback['id']}',
      );
      await feedbackRef.update({
        'reply': reply,
        'replyTimestamp': DateTime.now().toIso8601String(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reply added successfully'),
          backgroundColor: Color.fromARGB(255, 48, 120, 6) ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add reply: $e')));
    }
  }

  Future<void> _deleteFeedback(Map<String, dynamic> feedback) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Confirm Deletion',
              style: AppTextStyles.bodyMediumBold,
            ),
            content: Text(
              'Are you sure you want to delete this feedback from ${feedback['displayName']}?',
              style: AppTextStyles.bodySmall,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Delete',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryRed,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      final feedbackRef = FirebaseDatabase.instance.ref(
        'feedback/${feedback['userId']}/${feedback['id']}',
      );
      await feedbackRef.remove();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Feedback deleted successfully'),
          backgroundColor: const Color.fromARGB(255, 131, 13, 13),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete feedback: $e')));
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
        backgroundColor: AppColors.primaryBlue,
        title: Text(
          'Feedback Management',
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
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(width: 4),
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Loading feedback...',
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
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child:
                  _feedbacks.isEmpty && !_isLoading
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No feedback found',
                              style: AppTextStyles.bodyMediumBold,
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _feedbacks.length,
                        itemBuilder: (context, index) {
                          final feedback = _feedbacks[index];
                          return _FeedbackCard(
                            feedback: feedback,
                            onReply:
                                (reply) => _replyToFeedback(feedback, reply),
                            onDelete: () => _deleteFeedback(feedback),
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

class _FeedbackCard extends StatelessWidget {
  final Map<String, dynamic> feedback;
  final Function(String) onReply;
  final VoidCallback onDelete;

  const _FeedbackCard({
    required this.feedback,
    required this.onReply,
    required this.onDelete,
  });

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

  void _showReplyDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Reply to Feedback',
              style: AppTextStyles.bodyMediumBold,
            ),
            content: TextField(
              controller: controller,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter your reply',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    onReply(controller.text.trim());
                    Navigator.of(context).pop();
                  }
                },
                child: Text(
                  'Submit',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryRed,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Feedback from ${feedback['displayName'] ?? 'Unknown'}',
                    style: AppTextStyles.bodyMediumBold.copyWith(fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _RatingChip(
                  label:
                      '${feedback['overallRating']?.toStringAsFixed(1) ?? '3.0'}/5',
                  color: AppColors.primaryRed,
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                _RatingChip(
                  label:
                      'Maintenance: ${feedback['maintenanceRating']?.toStringAsFixed(1) ?? '3.0'}/5',
                  color: Colors.blue,
                ),
                SizedBox(width: 8),
                _RatingChip(
                  label:
                      'Security: ${feedback['securityRating']?.toStringAsFixed(1) ?? '3.0'}/5',
                  color: Colors.green,
                ),
                SizedBox(width: 8),
                _RatingChip(
                  label:
                      'Cleanliness: ${feedback['cleanlinessRating']?.toStringAsFixed(1) ?? '3.0'}/5',
                  color: Colors.orange,
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Comments: ${feedback['comments'] ?? 'No comments'}',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.black87,
                height: 1.3,
              ),
            ),
            if (feedback['reply'] != null) ...[
              SizedBox(height: 8),
              Text(
                'Reply: ${feedback['reply']}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryRed,
                  height: 1.3,
                ),
              ),
              Text(
                'Replied: ${_formatTimestamp(feedback['replyTimestamp'])}',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
              ),
            ],
            SizedBox(height: 8),
            Text(
              'User: ${feedback['displayName'] ?? 'Unknown'}',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
            ),
            Text(
              'Submitted: ${_formatTimestamp(feedback['timestamp'])}',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => _showReplyDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text('Reply', style: TextStyle(fontSize: 14)),
                ),
                SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

class _RatingChip extends StatelessWidget {
  final String label;
  final Color color;

  const _RatingChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}
