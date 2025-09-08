import 'package:flutter/material.dart';
// import 'package:park_chatapp/features/property/domain/models/property.dart';
import 'package:park_view_admin_panel/models/property.dart';
import '../services/property_service.dart';

class AddEditPropertyScreen extends StatefulWidget {
  final Property? property;

  const AddEditPropertyScreen({super.key, this.property});

  @override
  State<AddEditPropertyScreen> createState() => _AddEditPropertyScreenState();
}

class _AddEditPropertyScreenState extends State<AddEditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
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


    // Add more asset paths as needed
  ];
  
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _areaController = TextEditingController();
  final _agentNameController = TextEditingController();
  final _agentIdController = TextEditingController();
  
  List<String> _selectedImages = [];
  PropertyType _selectedType = PropertyType.residential;
  PropertyStatus _selectedStatus = PropertyStatus.available;
  bool _isFeatured = false;

  @override
  void initState() {
    super.initState();
    
    // Pre-fill form if editing existing property
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
      _selectedImages = widget.property!.imageUrls;
      _selectedType = widget.property!.type;
      _selectedStatus = widget.property!.status;
      _isFeatured = widget.property!.isFeatured;
    } else {
      // Set default values for new property
      _agentNameController.text = 'Admin';
      _agentIdController.text = 'admin-001';
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
    if (_formKey.currentState!.validate() && _selectedImages.isNotEmpty) {
      final property = Property(
        id: widget.property?.id ?? '',
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
        amenities: widget.property?.amenities ?? {},
      );

      bool success;
      if (widget.property == null) {
        success = await PropertyService.addProperty(property);
      } else {
        success = await PropertyService.updateProperty(property);
      }

      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.property == null 
                ? 'Property added successfully' 
                : 'Property updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save property'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one image'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.property == null ? 'Add Property' : 'Edit Property'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _bedroomsController,
                      decoration: const InputDecoration(labelText: 'Bedrooms'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter number of bedrooms';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _bathroomsController,
                      decoration: const InputDecoration(labelText: 'Bathrooms'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter number of bathrooms';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(labelText: 'Area (sq ft)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the area';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<PropertyType>(
                      value: _selectedType,
                      decoration: const InputDecoration(labelText: 'Property Type'),
                      items: PropertyType.values.map((type) {
                        return DropdownMenuItem<PropertyType>(
                          value: type,
                          child: Text(type.label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<PropertyStatus>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: PropertyStatus.values.map((status) {
                        return DropdownMenuItem<PropertyStatus>(
                          value: status,
                          child: Text(status.label),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _agentNameController,
                decoration: const InputDecoration(labelText: 'Agent Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter agent name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _agentIdController,
                decoration: const InputDecoration(labelText: 'Agent ID'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter agent ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _isFeatured,
                    onChanged: (value) {
                      setState(() {
                        _isFeatured = value!;
                      });
                    },
                  ),
                  const Text('Featured Property'),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Select Asset Images:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
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
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            assetPath,
                            width: 80,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 60,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  if (_availableAssets.length >= 4)
                    GestureDetector(
                      onTap: _openAllAssetsSheet,
                      child: Container(
                        width: 80,
                        height: 60,
                        margin: const EdgeInsets.all(4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 1),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade100,
                        ),
                        child: const Text('View\nMore', textAlign: TextAlign.center),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_selectedImages.isNotEmpty) 
                Text('Selected: ${_selectedImages.length} image(s)'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveProperty,
                child: const Text('Save Property'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on _AddEditPropertyScreenState {
  void _openAllAssetsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final height = MediaQuery.of(ctx).size.height * 0.8;
        return Container(
          height: height,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Asset Images', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
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
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected ? Colors.blue : Colors.grey,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    assetPath,
                                    width: 90,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 90,
                                        height: 70,
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.broken_image, color: Colors.grey),
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
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}