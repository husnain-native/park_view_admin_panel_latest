import 'package:flutter/material.dart';
import 'package:park_view_admin_panel/constants/app_colors.dart';
import 'package:park_view_admin_panel/constants/app_text_styles.dart';
import 'package:park_view_admin_panel/models/property.dart';
import 'package:park_view_admin_panel/services/auth_service.dart';
import 'package:park_view_admin_panel/services/property_service.dart';

class AddEditPropertyScreen extends StatefulWidget {
  final Property? property;

  const AddEditPropertyScreen({super.key, this.property});

  @override
  State<AddEditPropertyScreen> createState() => _AddEditPropertyScreenState();
}

class _AddEditPropertyScreenState extends State<AddEditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _areaController = TextEditingController();
  final _agentNameController = TextEditingController();
  final _agentIdController = TextEditingController();
  PropertyType _selectedType = PropertyType.residential;
  PropertyStatus _selectedStatus = PropertyStatus.available;
  bool _isFeatured = false;
  final Map<String, dynamic> _amenities = {
    'Parking': false,
    'Pool': false,
    'Garden': false,
    'Security': false,
    'Lift': false,
  };
  List<String> _selectedImages = [];

  final List<String> _availableAssets = [
    'assets/images/house4.jpg',
    'assets/images/house3.webp',
    'assets/images/house5.jpeg',
    'assets/images/apr1.jpg',
    'assets/images/apr2.jpg',
    'assets/images/apr3.jpg',
    'assets/images/plot.jpeg',
    'assets/images/retail1.jpg',
    'assets/images/1kan.jpg',
    'assets/images/1kan1.jpg',
    'assets/images/1kan2.jpg',
    'assets/images/10mar.jpg',
    'assets/images/10mar1.jpg',
  ];

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _setDefaultAgentInfo();
    if (widget.property != null) {
      _titleController.text = widget.property!.title;
      _descriptionController.text = widget.property!.description;
      _priceController.text = widget.property!.price.toString();
      _locationController.text = widget.property!.location;
      _bedroomsController.text = widget.property!.bedrooms.toString();
      _bathroomsController.text = widget.property!.bathrooms.toString();
      _areaController.text = widget.property!.area.toString();
      _agentNameController.text = widget.property!.agentName;
      _agentIdController.text = widget.property!.agentId;
      _selectedType = widget.property!.type;
      _selectedStatus = widget.property!.status;
      _isFeatured = widget.property!.isFeatured;
      _amenities.clear();
      _amenities.addAll(Map<String, dynamic>.from(widget.property!.amenities));
      _selectedImages = widget.property!.imageUrls;
    }
  }

  void _setDefaultAgentInfo() {
    final user = _authService.currentUser;
    if (user != null) {
      _agentNameController.text = user.displayName ?? 'Anonymous';
      _agentIdController.text = user.uid;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _areaController.dispose();
    _agentNameController.dispose();
    _agentIdController.dispose();
    super.dispose();
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one image'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please sign in to save property'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final property = Property(
        id: widget.property?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        type: _selectedType,
        status: _selectedStatus,
        location: _locationController.text,
        bedrooms: int.parse(_bedroomsController.text),
        bathrooms: int.parse(_bathroomsController.text),
        area: double.parse(_areaController.text),
        imageUrls: _selectedImages,
        agentName: _agentNameController.text,
        agentId: _agentIdController.text,
        createdAt: widget.property?.createdAt ?? DateTime.now(),
        isFeatured: _isFeatured,
        amenities: _amenities,
        approvalStatus: widget.property?.approvalStatus ?? PropertyApprovalStatus.pending,
        createdBy: user.uid,
      );

      bool success;
      if (widget.property == null) {
        success = await PropertyService.addProperty(property);
      } else {
        success = await PropertyService.updateProperty(property);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.property == null ? 'Property submitted for approval' : 'Property updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save property'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save property: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _openAllAssetsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.8,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16  )),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Asset Images',
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableAssets.map((assetPath) {
                            final isSelected = _selectedImages.contains(assetPath);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedImages.remove(assetPath);
                                  } else {
                                    _selectedImages.add(assetPath);
                                  }
                                });
                              },
                              child: Container(
                                width: 90,
                                height: 70,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected ? AppColors.primaryRed : Colors.grey,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8  ),
                                  child: Image.asset(
                                    assetPath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 90,
                                        height: 70,
                                        color: Colors.grey.shade200,
                                        child: Icon(Icons.broken_image, color: Colors.grey, size: 24  ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(Icons.close, size: 24  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        title: Text(
          widget.property == null ? 'Add Property' : 'Edit Property',
          style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _buildTextField('Title', _titleController, 'Enter property title'),
                SizedBox(height: 16),
                _buildTextField('Description', _descriptionController, 'Enter property description', maxLines: 3),
                SizedBox(height: 16),
                _buildTextField('Price (Rs)', _priceController, 'Enter price', keyboardType: TextInputType.number),
                SizedBox(height: 16),
                _buildTextField('Location', _locationController, 'Enter location'),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField('Bedrooms', _bedroomsController, 'Enter number of bedrooms', keyboardType: TextInputType.number),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField('Bathrooms', _bathroomsController, 'Enter number of bathrooms', keyboardType: TextInputType.number),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _buildTextField('Area (sq ft)', _areaController, 'Enter area', keyboardType: TextInputType.number),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<PropertyType>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Property Type',
                          labelStyle: AppTextStyles.bodyMedium,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8  )),
                        ),
                        items: PropertyType.values.map((type) {
                          return DropdownMenuItem<PropertyType>(
                            value: type,
                            child: Text(type.label, style: AppTextStyles.bodyMedium),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<PropertyStatus>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          labelStyle: AppTextStyles.bodyMedium,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8  )),
                        ),
                        items: PropertyStatus.values.map((status) {
                          return DropdownMenuItem<PropertyStatus>(
                            value: status,
                            child: Text(status.label, style: AppTextStyles.bodyMedium),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _buildTextField('Agent Name', _agentNameController, 'Enter agent name'),
                SizedBox(height: 16),
                _buildTextField('Agent ID', _agentIdController, 'Enter agent ID'),
                SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _isFeatured,
                      onChanged: (value) {
                        setState(() {
                          _isFeatured = value!;
                        });
                      },
                      activeColor: AppColors.primaryRed,
                    ),
                    Text('Featured Property', style: AppTextStyles.bodyMedium),
                  ],
                ),
                SizedBox(height: 16),
                Text('Amenities', style: AppTextStyles.bodyMediumBold),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _amenities.keys.map((amenity) {
                    return FilterChip(
                      label: Text(amenity, style: AppTextStyles.bodySmall),
                      selected: _amenities[amenity] == true,
                      onSelected: (selected) {
                        setState(() {
                          _amenities[amenity] = selected;
                        });
                      },
                      selectedColor: AppColors.primaryRed.withOpacity(0.2),
                      checkmarkColor: AppColors.primaryRed,
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),
                Text('Select Asset Images', style: AppTextStyles.bodyMediumBold),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._availableAssets.take(4).map((assetPath) {
                      final isSelected = _selectedImages.contains(assetPath);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedImages.remove(assetPath);
                            } else {
                              _selectedImages.add(assetPath);
                            }
                          });
                        },
                        child: Container(
                          width: 80,
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected ? AppColors.primaryRed : Colors.grey,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8  ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8  ),
                            child: Image.asset(
                              assetPath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 80,
                                  height: 60,
                                  color: Colors.grey.shade200,
                                  child: Icon(Icons.broken_image, color: Colors.grey, size: 24  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    if (_availableAssets.length > 4)
                      GestureDetector(
                        onTap: _openAllAssetsSheet,
                        child: Container(
                          width: 80,
                          height: 60,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey, width: 1),
                            borderRadius: BorderRadius.circular(8  ),
                            color: Colors.grey.shade100,
                          ),
                          child: Text('View\nMore', textAlign: TextAlign.center, style: AppTextStyles.bodySmall),
                        ),
                      ),
                  ],
                ),
                if (_selectedImages.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text('Selected: ${_selectedImages.length} image(s)', style: AppTextStyles.bodySmall),
                ],
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveProperty,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8  )),
                  ),
                  child: Text(
                    widget.property == null ? 'Submit Property' : 'Update Property',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: AppTextStyles.bodyMedium,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label.toLowerCase()';
        }
        if (keyboardType == TextInputType.number && (double.tryParse(value) == null && controller != _bedroomsController && controller != _bathroomsController)) {
          return 'Please enter a valid number';
        }
        if ((controller == _bedroomsController || controller == _bathroomsController) && int.tryParse(value) == null) {
          return 'Please enter a valid integer';
        }
        return null;
      },
    );
  }
}