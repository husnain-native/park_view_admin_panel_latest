import 'package:flutter/material.dart';
import 'package:park_view_admin_panel/models/property.dart';
import 'dart:io';
import 'dart:typed_data'; // Added for Uint8List
import '../models/city_card.dart';
import '../services/property_service.dart';
import '../services/image_upload_service.dart';
import 'package:http/http.dart' as http; // Added for http

// Move enum to top-level
enum ImageInputType { upload, url }

class AddEditCityCardScreen extends StatefulWidget {
  final CityCard? cityCard;

  const AddEditCityCardScreen({super.key, this.cityCard});

  @override
  State<AddEditCityCardScreen> createState() => _AddEditCityCardScreenState();
}

class _AddEditCityCardScreenState extends State<AddEditCityCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _buttonTextController = TextEditingController();
  final _imagePathController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isLoading = false;
  bool _isActive = true;
  bool _isUploadingImage = false;
  String? _selectedImageUrl;
  File? _selectedImageFile;
  ImageInputType _imageInputType = ImageInputType.upload;
  dynamic _selectedImageData; // Can be File or Uint8List

  @override
  void initState() {
    super.initState();
    if (widget.cityCard != null) {
      _titleController.text = widget.cityCard!.title;
      _subtitleController.text = widget.cityCard!.subtitle;
      _buttonTextController.text = widget.cityCard!.buttonText;
      _imagePathController.text = widget.cityCard!.imagePath;
      _imageUrlController.text = widget.cityCard!.imageUrl;
      _isActive = widget.cityCard!.isActive;
      _selectedImageUrl =
          widget.cityCard!.imageUrl.isNotEmpty
              ? widget.cityCard!.imageUrl
              : null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _buttonTextController.dispose();
    _imagePathController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      dynamic picked = await ImageUploadService.pickImage();
      if (picked != null) {
        setState(() {
          _selectedImageData = picked;
          _selectedImageFile = picked is File ? picked : null;
          _selectedImageUrl = null;
          if (picked is File) {
            _imagePathController.text = picked.path;
          } else {
            _imagePathController.text = 'Web image selected';
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _uploadImageFromUrl() async {
    String url = _imageUrlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an image URL')),
      );
      return;
    }

    setState(() {
      _isUploadingImage = true;
    });

    try {
      // Validate URL first
      bool isValid = await ImageUploadService.isValidImageUrl(url);
      if (!isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Invalid image URL. Please check the URL and try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check for potential CORS issues
      if (url.contains('zameen.com') || url.contains('content-cdn')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Warning: This URL may have CORS restrictions. If upload fails, please use a different image URL or upload the image directly.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }

      // Upload image from URL with timeout
      String? uploadedUrl = await Future.any([
        Future.delayed(const Duration(seconds: 30), () {
          throw Exception('Upload timeout - please try again');
        }),
        ImageUploadService.uploadImageFromUrl(
          url,
          'city_card_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      ]);

      if (uploadedUrl != null) {
        setState(() {
          _selectedImageUrl = uploadedUrl;
          _selectedImageFile = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload image from URL'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Error uploading image: ';

      if (e.toString().contains('CORS')) {
        errorMessage +=
            'This URL has CORS restrictions. Please upload the image directly instead.';
      } else if (e.toString().contains('timeout')) {
        errorMessage +=
            'Upload timed out. Please check your internet connection and try again.';
      } else {
        errorMessage += e.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _testStorageConnection() async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final result = await ImageUploadService.testStorageConnection();

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Storage test successful: ${result['message']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Storage test failed: ${result['message']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Storage test error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 10),
        ),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _diagnoseStorageIssues() async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final result = await ImageUploadService.diagnoseStorageIssues();

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Diagnostic successful: ${result['message']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Diagnostic failed: ${result['message']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Diagnostic error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 10),
        ),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _testStorageBucket() async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final result = await ImageUploadService.testStorageBucket();

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bucket test successful: ${result['message']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bucket test failed: ${result['message']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bucket test error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 10),
        ),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  void _testNetworkConnectivity() async {
    try {
      final result = await ImageUploadService.testNetworkConnectivity();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 10),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _quickUploadTest() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Starting quick upload test...'),
          backgroundColor: Colors.blue,
        ),
      );

      // Create a small test image (1x1 pixel)
      final testImageData = Uint8List.fromList([
        0xFF,
        0xD8,
        0xFF,
        0xE0,
        0x00,
        0x10,
        0x4A,
        0x46,
        0x49,
        0x46,
        0x00,
        0x01,
        0x01,
        0x01,
        0x00,
        0x48,
        0x00,
        0x48,
        0x00,
        0x00,
        0xFF,
        0xDB,
        0x00,
        0x43,
        0x00,
        0x08,
        0x06,
        0x06,
        0x07,
        0x06,
        0x05,
        0x08,
        0x07,
        0x07,
        0x07,
        0x09,
        0x09,
        0x08,
        0x0A,
        0x0C,
        0x14,
        0x0D,
        0x0C,
        0x0B,
        0x0B,
        0x0C,
        0x19,
        0x12,
        0x13,
        0x0F,
        0x14,
        0x1D,
        0x1A,
        0x1F,
        0x1E,
        0x1D,
        0x1A,
        0x1C,
        0x1C,
        0x20,
        0x24,
        0x2E,
        0x27,
        0x20,
        0x22,
        0x2C,
        0x23,
        0x1C,
        0x1C,
        0x28,
        0x37,
        0x29,
        0x2C,
        0x30,
        0x31,
        0x34,
        0x34,
        0x34,
        0x1F,
        0x27,
        0x39,
        0x3D,
        0x38,
        0x32,
        0x3C,
        0x2E,
        0x33,
        0x34,
        0x32,
        0xFF,
        0xC0,
        0x00,
        0x11,
        0x08,
        0x00,
        0x01,
        0x00,
        0x01,
        0x01,
        0x01,
        0x11,
        0x00,
        0x02,
        0x11,
        0x01,
        0x03,
        0x11,
        0x01,
        0xFF,
        0xC4,
        0x00,
        0x14,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x08,
        0xFF,
        0xC4,
        0x00,
        0x14,
        0x10,
        0x01,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0xFF,
        0xDA,
        0x00,
        0x0C,
        0x03,
        0x01,
        0x00,
        0x02,
        0x11,
        0x03,
        0x11,
        0x00,
        0x3F,
        0x00,
        0x8A,
        0x00,
        0x00,
        0xFF,
        0xD9,
      ]);

      final result = await ImageUploadService.uploadWebImage(
        testImageData,
        'quick_test_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Upload test successful!\nURL: ${result.substring(0, 50)}...',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 8),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Upload test failed - check console for details'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Upload test error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  void _testImageUrl() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Testing image URL accessibility...'),
          backgroundColor: Colors.blue,
        ),
      );

      // Test the existing image URL
      final testUrl =
          'https://firebasestorage.googleapis.com/v0/b/chatapp-bb0e2.firebasestorage.app/o/city_cards%2F1753891208330_city_card_1753891208329.jpg?alt=media&token=bf5accc7-829b-4f5b-815c-55bece63d062';

      final response = await http.get(Uri.parse(testUrl));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Image URL accessible! Status: ${response.statusCode}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 8),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Image URL not accessible. Status: ${response.statusCode}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Image URL test error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  Future<void> _uploadSelectedImage() async {
    if (_selectedImageData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    setState(() {
      _isUploadingImage = true;
    });

    try {
      print('Starting image upload...');
      print('Selected image data type: ${_selectedImageData.runtimeType}');

      String? uploadedUrl;
      if (_selectedImageData is File) {
        print('Uploading File: ${_selectedImageData.path}');
        uploadedUrl = await ImageUploadService.uploadImage(
          _selectedImageData,
          'city_card_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      } else if (_selectedImageData is Uint8List) {
        print('Uploading Uint8List with ${_selectedImageData.length} bytes');
        uploadedUrl = await ImageUploadService.uploadWebImage(
          _selectedImageData,
          'city_card_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      print('Upload result: $uploadedUrl');

      if (uploadedUrl != null) {
        setState(() {
          _selectedImageUrl = uploadedUrl;
          _selectedImageData = null;
          _selectedImageFile = null;
        });
        print('Image uploaded successfully. URL: $uploadedUrl');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('Upload failed - no URL returned');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error during upload: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _saveCityCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String finalImageUrl = '';
      String finalImagePath = '';

      print('=== SAVE DEBUG INFO ===');
      print('_selectedImageFile: $_selectedImageFile');
      print('_selectedImageUrl: $_selectedImageUrl');
      print('_imageUrlController.text: ${_imageUrlController.text}');
      print('_imageInputType: $_imageInputType');

      // Handle image based on input type
      if (_imageInputType == ImageInputType.upload) {
        // For upload option, we need either a selected image or an uploaded URL
        if (_selectedImageData != null) {
          // Upload the selected image first
          print('Uploading selected image before saving...');
          String? uploadedUrl;
          try {
            // Add timeout to prevent endless loading
            uploadedUrl = await Future.any([
              Future.delayed(const Duration(seconds: 30), () {
                throw Exception('Upload timeout - please try again');
              }),
              Future(() async {
                if (_selectedImageData is File) {
                  return await ImageUploadService.uploadImage(
                    _selectedImageData,
                    'city_card_${DateTime.now().millisecondsSinceEpoch}.jpg',
                  );
                } else if (_selectedImageData is Uint8List) {
                  return await ImageUploadService.uploadWebImage(
                    _selectedImageData,
                    'city_card_${DateTime.now().millisecondsSinceEpoch}.jpg',
                  );
                }
                return null;
              }),
            ]);
          } catch (e) {
            print('Upload error: $e');
            String errorMessage = 'Image upload failed. ';

            if (e.toString().contains('CORS')) {
              errorMessage +=
                  'The image URL has CORS restrictions. Please upload the image directly instead of using a URL.';
            } else if (e.toString().contains('timeout')) {
              errorMessage +=
                  'Upload timed out. Please check your internet connection and try again.';
            } else {
              errorMessage +=
                  'Please ensure Firebase Storage is enabled. Error: $e';
            }

            // Show user-friendly error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 8),
              ),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }

          if (uploadedUrl != null) {
            finalImageUrl = uploadedUrl;
            finalImagePath = _imagePathController.text.trim();
            print('Image uploaded successfully during save: $finalImageUrl');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Failed to upload image. Please try again or use a URL instead.',
                ),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
        } else if (_selectedImageUrl != null) {
          // Use already uploaded URL
          finalImageUrl = _selectedImageUrl!;
          finalImagePath = _imagePathController.text.trim();
          print('Using existing uploaded URL: $finalImageUrl');
        } else {
          // No image selected for upload
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select an image to upload'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      } else {
        // For URL option, use the URL from text field
        finalImageUrl = _imageUrlController.text.trim();
        finalImagePath = _imagePathController.text.trim();
        print('Using URL from text field: $finalImageUrl');
      }

      print('Final imageUrl: $finalImageUrl');
      print('Final imagePath: $finalImagePath');

      CityCard cityCard = CityCard(
        id:
            widget.cityCard?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim(),
        buttonText: _buttonTextController.text.trim(),
        imagePath: finalImagePath,
        imageUrl: finalImageUrl,
        isActive: _isActive,
        createdAt: widget.cityCard?.createdAt ?? DateTime.now(),
        updatedAt: widget.cityCard != null ? DateTime.now() : null,
      );

      bool success;
      if (widget.cityCard != null) {
        success = await PropertyService.updateProperty(cityCard as Property);
      } else {
        success = await PropertyService.addProperty(cityCard as Property);
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.cityCard != null
                    ? 'City card updated successfully!'
                    : 'City card created successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save city card'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildImagePreview() {
    if (_selectedImageFile != null) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(_selectedImageFile!, fit: BoxFit.cover),
        ),
      );
    } else if (_selectedImageUrl != null) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            _selectedImageUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value:
                      loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.error, size: 50, color: Colors.red),
              );
            },
          ),
        ),
      );
    } else if (_selectedImageData != null && _selectedImageData is Uint8List) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(_selectedImageData, fit: BoxFit.cover),
        ),
      );
    } else {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 50, color: Colors.grey),
              SizedBox(height: 8),
              Text('No image selected', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.cityCard != null ? 'Edit City Card' : 'Add City Card',
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _subtitleController,
                  decoration: const InputDecoration(
                    labelText: 'Subtitle',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.subtitles),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a subtitle';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _buttonTextController,
                  decoration: const InputDecoration(
                    labelText: 'Button Text',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.smart_button),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter button text';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _imagePathController,
                  decoration: const InputDecoration(
                    labelText: 'Image Path (assets/images/...)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.image),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter image path';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Image Source',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Radio<ImageInputType>(
                      value: ImageInputType.upload,
                      groupValue: _imageInputType,
                      onChanged: (val) {
                        setState(() {
                          _imageInputType = val!;
                          _selectedImageFile = null;
                          _selectedImageUrl = null;
                          _imageUrlController.clear();
                        });
                      },
                    ),
                    const Text('Upload File'),
                    Radio<ImageInputType>(
                      value: ImageInputType.url,
                      groupValue: _imageInputType,
                      onChanged: (val) {
                        setState(() {
                          _imageInputType = val!;
                          _selectedImageFile = null;
                          _selectedImageUrl = null;
                        });
                      },
                    ),
                    const Text('Paste Image URL'),
                  ],
                ),
                const SizedBox(height: 16),
                if (_imageInputType == ImageInputType.upload) ...[
                  GestureDetector(
                    onTap: _isUploadingImage ? null : _pickImage,
                    child: _buildImagePreview(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              _isUploadingImage ? null : _uploadSelectedImage,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload to Firebase'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          // Test buttons for debugging
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _testStorageConnection,
                                  icon: const Icon(Icons.storage),
                                  label: const Text('Test Storage'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _diagnoseStorageIssues,
                                  icon: const Icon(Icons.bug_report),
                                  label: const Text('Diagnose'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _testStorageBucket,
                                  icon: const Icon(Icons.folder),
                                  label: const Text('Test Bucket'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _testNetworkConnectivity,
                                  icon: const Icon(Icons.wifi),
                                  label: const Text('Test Network'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Quick upload test button
                          ElevatedButton.icon(
                            onPressed: _quickUploadTest,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Quick Upload Test'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Test image URL button
                          ElevatedButton.icon(
                            onPressed: _testImageUrl,
                            icon: const Icon(Icons.link),
                            label: const Text('Test Image URL'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else ...[
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Image URL',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                      helperText:
                          'Paste a direct image URL (avoid URLs from content delivery networks that may have CORS restrictions)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _isUploadingImage ? null : _uploadImageFromUrl,
                    icon: const Icon(Icons.link),
                    label: const Text('Upload from URL'),
                  ),
                  if (_selectedImageUrl != null) ...[
                    const SizedBox(height: 16),
                    _buildImagePreview(),
                  ],
                ],
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text('Show this card to users'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveCityCard,
                    child:
                        _isLoading
                            ? const CircularProgressIndicator()
                            : Text(
                              widget.cityCard != null
                                  ? 'Update Card'
                                  : 'Create Card',
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
