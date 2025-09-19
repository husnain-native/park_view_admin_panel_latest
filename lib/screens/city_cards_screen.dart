import 'package:flutter/material.dart';
import 'package:park_view_admin_panel/constants/app_colors.dart';
import 'package:park_view_admin_panel/constants/app_text_styles.dart';
import 'package:park_view_admin_panel/models/property.dart';
import 'package:park_view_admin_panel/screens/AddEditPropertyScreen.dart';
import '../services/property_service.dart';

class PropertiesManagementScreen extends StatefulWidget {
  const PropertiesManagementScreen({super.key});

  @override
  State<PropertiesManagementScreen> createState() => _PropertiesManagementScreenState();
}

class _PropertiesManagementScreenState extends State<PropertiesManagementScreen> {
  List<Property> _properties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    try {
      List<Property> properties = await PropertyService.getAllProperties();
      setState(() {
        _properties = properties;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading properties: $e')),
      );
    }
  }

  Future<void> _togglePropertyStatus(Property property) async {
    bool success = await PropertyService.togglePropertyStatus(
      property.id,
      property.status == PropertyStatus.available 
        ? PropertyStatus.sold 
        : PropertyStatus.available,
    );

    if (success) {
      _loadProperties();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Property status updated successfully'),
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

  Future<void> _deleteProperty(Property property) async {
    bool confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property'),
        content: Text('Are you sure you want to delete "${property.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      bool success = await PropertyService.deleteProperty(property.id);
      if (success) {
        _loadProperties();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Property deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete property'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildImagePreview(List<String> imageUrls) {
    if (imageUrls.isNotEmpty) {
      final bool isAsset = imageUrls.first.startsWith('assets/');
      
      return Container(
        width: 120,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          // border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: isAsset
            ? Image.asset(
                imageUrls.first,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.home, color: Colors.grey),
                  );
                },
              )
            : Image.network(
                imageUrls.first,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              ),
        ),
      );
    } else {
      return Container(
        width: 120,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Icon(Icons.home, color: Colors.grey),
      );
    }
  }

  Color _getStatusColor(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.available: return Colors.green;
      case PropertyStatus.sold: return Colors.red;
      case PropertyStatus.rented: return Colors.blue;
      case PropertyStatus.underContract: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title:  Text('Properties Management',
        style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Properties Management',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    elevation: 1,
                    backgroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                      side: const BorderSide(color: AppColors.primaryBlue, width: 1),
                    ),
                  ),
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AddEditPropertyScreen(),
                      ),
                    );
                    if (result == true) _loadProperties();
                  },
                  icon: const Icon(Icons.add, color: AppColors.primaryBlue,),
                  label: const Text('Add New Property', style: TextStyle(color: AppColors.primaryBlue),),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_properties.isEmpty)
              const Center(
                child: Text(
                  'No properties found. Create your first property!',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _properties.length,
                  itemBuilder: (context, index) {
                    final property = _properties[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            _buildImagePreview(property.imageUrls),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    property.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          property.location,
                                          style: TextStyle(color: Colors.grey),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.bed, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text('${property.bedrooms}', style: TextStyle(color: Colors.grey)),
                                      const SizedBox(width: 16),
                                      Icon(Icons.bathtub_outlined, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text('${property.bathrooms}', style: TextStyle(color: Colors.grey)),
                                      const SizedBox(width: 16),
                                      Icon(Icons.square_foot, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text('${property.area.toInt()} sq ft', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        property.formattedPrice,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(property.status).withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          property.statusLabel,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Created: ${property.timeAgo}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () async {
                                    final result = await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => AddEditPropertyScreen(
                                          property: property,
                                        ),
                                      ),
                                    );
                                    if (result == true) _loadProperties();
                                  },
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.swap_horiz),
                                  onPressed: () => _togglePropertyStatus(property),
                                  tooltip: 'Toggle Status',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteProperty(property),
                                  tooltip: 'Delete',
                                  color: Colors.red,
                                ),
                              ],
                            ),
                          ],
                        ),
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