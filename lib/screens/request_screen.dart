import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:park_chatapp/constants/app_colors.dart';
// import 'package:park_chatapp/constants/app_text_styles.dart';
// import 'package:park_chatapp/core/services/property_service.dart';
// import 'package:park_chatapp/features/property/domain/models/property.dart';
// import 'package:park_chatapp/features/property/presentation/screens/property_detail_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:park_view_admin_panel/constants/app_colors.dart';
import 'package:park_view_admin_panel/constants/app_text_styles.dart';
import 'package:park_view_admin_panel/models/property.dart';
import 'package:park_view_admin_panel/services/property_service.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final List<Property> _properties = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<DatabaseEvent>? _propertiesSubscription;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  @override
  void dispose() {
    _propertiesSubscription?.cancel();
    super.dispose();
  }

  void _loadProperties() {
    _propertiesSubscription = PropertyService.getPropertiesStream().listen((event) {
      if (!mounted) return;
      try {
        final Object? raw = event.snapshot.value;
        if (raw == null) {
          setState(() {
            _properties.clear();
            _isLoading = false;
          });
          return;
        }
        final Map<dynamic, dynamic> map = raw as Map<dynamic, dynamic>;
        final List<Property> pendingProperties = [];
        map.forEach((key, value) {
          try {
            final Property p = Property.fromMap(key.toString(), Map<String, dynamic>.from(value as Map));
            if (p.approvalStatus == PropertyApprovalStatus.pending && p.createdBy != 'admin' && p.imageUrls.isNotEmpty) {
              pendingProperties.add(p);
            }
          } catch (e) {
            print('Error parsing property $key: $e');
          }
        });
        pendingProperties.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        setState(() {
          _properties
            ..clear()
            ..addAll(pendingProperties);
          _isLoading = false;
          _error = null;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load requests: $e';
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

  Future<void> _updateStatus(Property property, PropertyApprovalStatus status) async {
    final updatedProperty = Property(
      id: property.id,
      title: property.title,
      description: property.description,
      price: property.price,
      type: property.type,
      status: property.status,
      location: property.location,
      bedrooms: property.bedrooms,
      bathrooms: property.bathrooms,
      area: property.area,
      imageUrls: property.imageUrls,
      agentName: property.agentName,
      agentId: property.agentId,
      createdAt: property.createdAt,
      isFeatured: property.isFeatured,
      amenities: property.amenities,
      approvalStatus: status,
      createdBy: property.createdBy,
    );
    final success = await PropertyService.updateProperty(updatedProperty);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Property ${status == PropertyApprovalStatus.approved ? 'approved' : 'rejected'} successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update property status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        title: Text(
          'Property Requests',
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
                padding: EdgeInsets.symmetric(horizontal: 12  , vertical: 8 ),
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8  ),
                    Expanded(
                      child: Text(
                        'Loading requests...',
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
                padding: EdgeInsets.symmetric(horizontal: 12  , vertical: 8 ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: Colors.red),
                    SizedBox(width: 8  ),
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
              child: _properties.isEmpty && !_isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16 ),
                          Text('No pending requests', style: AppTextStyles.bodyMediumBold),
                          SizedBox(height: 8 ),
                          Text(
                            'No user-submitted properties to review',
                            style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16  ),
                      itemCount: _properties.length,
                      itemBuilder: (context, index) {
                        final property = _properties[index];
                        return Card(
                          child: ListTile(
                            leading: property.imageUrls.isNotEmpty
                                ? Image.asset(
                                    property.imageUrls[0],
                                    width: 60,
                                    height: 60 ,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 24),
                                  )
                                : Icon(Icons.image, size: 24),
                            title: Text(property.title, style: AppTextStyles.bodyMediumBold),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Created by: ${property.agentName}', style: AppTextStyles.bodySmall),
                                Text(property.formattedPrice, style: AppTextStyles.bodySmall),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.check, color: Colors.green, size: 24),
                                  onPressed: () => _updateStatus(property, PropertyApprovalStatus.approved),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.red, size: 24),
                                  onPressed: () => _updateStatus(property, PropertyApprovalStatus.rejected),
                                ),
                              ],
                            ),
                            // onTap: () {
                            //   Navigator.push(
                            //     context,
                            //     MaterialPageRoute(
                            //       builder: (_) => PropertyDetailScreen(property: property),
                            //     ),
                            //   );
                            // },
                          ),
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