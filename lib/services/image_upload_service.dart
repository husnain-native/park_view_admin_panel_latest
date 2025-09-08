import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Added for base64Encode

class ImageUploadService {
  static FirebaseStorage get _storage => FirebaseStorage.instance;

  // Pick image from file system
  static Future<dynamic> pickImage() async {
    if (kIsWeb) {
      // Web: return Uint8List
      final completer = Completer<Uint8List?>();
      final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
      uploadInput.click();
      uploadInput.onChange.listen((event) {
        final file = uploadInput.files?.first;
        if (file != null) {
          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);
          reader.onLoadEnd.listen((event) {
            completer.complete(reader.result as Uint8List);
          });
        } else {
          completer.complete(null);
        }
      });
      return completer.future;
    } else {
      // Mobile/desktop: use existing logic (FilePicker/ImagePicker)
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.isNotEmpty) {
          return File(result.files.first.path!);
        }
        return null;
      } catch (e) {
        print('Error picking image: $e');
        return null;
      }
    }
  }

  // Upload image to Firebase Storage
  static Future<String?> uploadImage(File imageFile, String fileName) async {
    try {
      print('Starting file upload...');
      print('File path: ${imageFile.path}');
      print('File size: ${await imageFile.length()} bytes');

      // Create a unique file name
      String uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';

      // Reference to the storage location
      Reference storageRef = _storage.ref().child('city_cards/$uniqueFileName');
      print('Storage reference path: ${storageRef.fullPath}');

      // Upload the file
      UploadTask uploadTask = storageRef.putFile(imageFile);
      print('Upload task started...');

      // Wait for upload to complete
      TaskSnapshot snapshot = await uploadTask;
      print(
        'Upload completed. Bytes transferred: ${snapshot.bytesTransferred}',
      );

      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      print('Download URL obtained: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      print('Error type: ${e.runtimeType}');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}');
        print('Firebase error message: ${e.message}');
      }
      return null;
    }
  }

  // Upload web image (Uint8List) to Firebase Storage
  static Future<String?> uploadWebImage(
    Uint8List imageData,
    String fileName,
  ) async {
    try {
      print('=== UPLOAD DEBUG START ===');
      print('Starting web image upload...');
      print('Image data size: ${imageData.length} bytes');
      print('File name: $fileName');

      // Get storage instance info
      final storage = FirebaseStorage.instance;
      print('Storage bucket from config: ${storage.app.options.storageBucket}');
      print('Project ID: ${storage.app.options.projectId}');
      print('App name: ${storage.app.name}');

      // Create a unique file name
      String uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      print('Unique file name: $uniqueFileName');

      // Reference to the storage location
      Reference storageRef = _storage.ref().child('city_cards/$uniqueFileName');
      print('Storage reference path: ${storageRef.fullPath}');
      print('Storage reference bucket: ${storageRef.bucket}');
      print('Storage reference name: ${storageRef.name}');

      // Upload the data with increased timeout and better error handling
      return await Future.any([
        Future.delayed(const Duration(seconds: 120), () {
          print('Upload timeout after 120 seconds');
          throw Exception('Upload timeout - please try again');
        }),
        Future(() async {
          print('Creating upload task...');

          // Upload the data with metadata
          UploadTask uploadTask = storageRef.putData(
            imageData,
            SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {
                'uploaded-by': 'flutter-web-app',
                'timestamp': DateTime.now().toIso8601String(),
              },
            ),
          );
          print('Upload task created successfully');
          print('Upload task started...');

          // Monitor upload progress
          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            print(
              'Upload progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes} bytes (${(snapshot.bytesTransferred / snapshot.totalBytes * 100).toStringAsFixed(1)}%)',
            );
            print('Upload state: ${snapshot.state}');
          });

          print('Waiting for upload to complete...');
          // Wait for upload to complete
          TaskSnapshot snapshot = await uploadTask;
          print(
            'Upload completed. Bytes transferred: ${snapshot.bytesTransferred}',
          );
          print('Upload state: ${snapshot.state}');

          // Get download URL
          print('Getting download URL...');
          String downloadUrl = await snapshot.ref.getDownloadURL();
          print('Download URL obtained: $downloadUrl');
          print('=== UPLOAD DEBUG END ===');

          return downloadUrl;
        }),
      ]);
    } catch (e) {
      print('=== UPLOAD ERROR ===');
      print('Error uploading web image: $e');
      print('Error type: ${e.runtimeType}');

      // Check for network blocking
      if (e.toString().contains('ERR_CONNECTION_RESET') ||
          e.toString().contains('retry-limit-exceeded') ||
          e.toString().contains('network')) {
        print('Network blocking detected - using fallback method');
        final fallbackResult = await handleNetworkBlockedUpload(
          imageData,
          fileName,
        );
        if (fallbackResult['success']) {
          // Return the data URL as a fallback
          return fallbackResult['dataUrl'];
        }
      }

      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}');
        print('Firebase error message: ${e.message}');
      }
      print('=== ERROR END ===');
      return null;
    }
  }

  // Download image from URL and upload to Firebase Storage
  static Future<String?> uploadImageFromUrl(
    String imageUrl,
    String fileName,
  ) async {
    try {
      print('Starting URL image upload...');
      print('Source URL: $imageUrl');

      // Download image from URL
      http.Response response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        print(
          'Image downloaded successfully. Size: ${response.bodyBytes.length} bytes',
        );

        // Create unique file name
        String uniqueFileName =
            '${DateTime.now().millisecondsSinceEpoch}_$fileName';

        // Reference to storage location
        Reference storageRef = _storage.ref().child(
          'city_cards/$uniqueFileName',
        );
        print('Storage reference path: ${storageRef.fullPath}');

        // Upload bytes to Firebase Storage
        UploadTask uploadTask = storageRef.putData(response.bodyBytes);
        print('Upload task started...');

        // Wait for upload to complete
        TaskSnapshot snapshot = await uploadTask;
        print(
          'Upload completed. Bytes transferred: ${snapshot.bytesTransferred}',
        );

        // Get download URL
        String downloadUrl = await snapshot.ref.getDownloadURL();
        print('Download URL obtained: $downloadUrl');

        return downloadUrl;
      } else {
        print('Failed to download image from URL: ${response.statusCode}');
        print('Response headers: ${response.headers}');
        return null;
      }
    } catch (e) {
      print('Error uploading image from URL: $e');
      print('Error type: ${e.runtimeType}');

      // Check for CORS error
      if (e.toString().contains('CORS') ||
          e.toString().contains('Access-Control-Allow-Origin')) {
        print(
          'CORS error detected - this URL cannot be accessed from web browsers',
        );
        throw Exception(
          'CORS Error: This image URL cannot be accessed due to cross-origin restrictions. Please use a different image URL or upload the image directly.',
        );
      }

      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}');
        print('Firebase error message: ${e.message}');
      }
      return null;
    }
  }

  // Delete image from Firebase Storage
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extract file path from URL
      Uri uri = Uri.parse(imageUrl);
      String filePath = uri.pathSegments.last;

      // Reference to the file
      Reference storageRef = _storage.ref().child('city_cards/$filePath');

      // Delete the file
      await storageRef.delete();

      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  // Validate image URL
  static Future<bool> isValidImageUrl(String url) async {
    try {
      http.Response response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Test Firebase Storage connectivity
  static Future<Map<String, dynamic>> testStorageConnection() async {
    try {
      print('Testing Firebase Storage connection...');

      // Get storage instance info
      final storage = FirebaseStorage.instance;
      print('Storage bucket: ${storage.app.options.storageBucket}');
      print('Storage app name: ${storage.app.name}');

      // Try to create a reference
      final testRef = storage.ref().child('test/connection_test.txt');
      print('Test reference path: ${testRef.fullPath}');

      // Try to upload a small test file with timeout
      final testData = Uint8List.fromList([72, 101, 108, 108, 111]); // "Hello"

      print('Starting simple test upload...');
      final result = await Future.any([
        Future.delayed(const Duration(seconds: 30), () {
          print('Test upload timeout after 30 seconds');
          throw Exception('Test upload timeout');
        }),
        Future(() async {
          final uploadTask = testRef.putData(testData);
          print('Test upload task started...');

          // Monitor progress
          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            print(
              'Test upload progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes} bytes',
            );
          });

          final snapshot = await uploadTask;
          print('Test upload successful. Bytes: ${snapshot.bytesTransferred}');

          // Get download URL
          final downloadUrl = await snapshot.ref.getDownloadURL();
          print('Test download URL: $downloadUrl');

          // Clean up - delete test file
          await snapshot.ref.delete();
          print('Test file cleaned up');

          return {
            'success': true,
            'message': 'Firebase Storage is working correctly',
            'bucket': storage.app.options.storageBucket,
            'downloadUrl': downloadUrl,
          };
        }),
      ]);

      return result;
    } catch (e) {
      print('Firebase Storage test failed: $e');
      if (e is FirebaseException) {
        return {
          'success': false,
          'message': 'Firebase Storage error: ${e.message}',
          'code': e.code,
          'error': e.toString(),
        };
      }
      return {
        'success': false,
        'message': 'Test failed: $e',
        'error': e.toString(),
      };
    }
  }

  // Diagnostic method to check Firebase Storage configuration
  static Future<Map<String, dynamic>> diagnoseStorageIssues() async {
    try {
      print('=== FIREBASE STORAGE DIAGNOSTIC ===');

      final storage = FirebaseStorage.instance;
      final app = storage.app;
      final options = app.options;

      print('App name: ${app.name}');
      print('Project ID: ${options.projectId}');
      print('Storage bucket: ${options.storageBucket}');
      print('API key: ${options.apiKey}');
      print('Auth domain: ${options.authDomain}');

      // Test basic connectivity
      try {
        final testRef = storage.ref().child('diagnostic/test.txt');
        print('✓ Storage reference created successfully');
        print('Reference path: ${testRef.fullPath}');
        print('Reference bucket: ${testRef.bucket}');

        // Try to get metadata (this should work even if upload doesn't)
        try {
          await testRef.getMetadata();
          print('✓ Metadata access works');
        } catch (e) {
          print('⚠ Metadata access failed: $e');
        }

        return {
          'success': true,
          'message': 'Firebase Storage configuration looks correct',
          'details': {
            'projectId': options.projectId,
            'storageBucket': options.storageBucket,
            'referenceCreated': true,
          },
        };
      } catch (e) {
        print('✗ Storage reference creation failed: $e');
        return {
          'success': false,
          'message': 'Storage reference creation failed',
          'error': e.toString(),
        };
      }
    } catch (e) {
      print('✗ Diagnostic failed: $e');
      return {
        'success': false,
        'message': 'Diagnostic failed',
        'error': e.toString(),
      };
    }
  }

  // Test storage bucket configuration specifically
  static Future<Map<String, dynamic>> testStorageBucket() async {
    try {
      print('=== STORAGE BUCKET TEST ===');

      final storage = FirebaseStorage.instance;
      final bucket = storage.app.options.storageBucket;

      print('Configured bucket: $bucket');
      print('Expected bucket: chatapp-bb0e2.firebasestorage.app');

      if (bucket == 'chatapp-bb0e2.firebasestorage.app') {
        print('✓ Bucket configuration matches');
      } else {
        print('✗ Bucket configuration mismatch');
        return {
          'success': false,
          'message': 'Storage bucket configuration mismatch',
          'configured': bucket,
          'expected': 'chatapp-bb0e2.firebasestorage.app',
        };
      }

      // Test creating a reference
      final testRef = storage.ref().child('test/bucket_test.txt');
      print('Test reference bucket: ${testRef.bucket}');
      print('Test reference path: ${testRef.fullPath}');

      return {
        'success': true,
        'message': 'Storage bucket configuration is correct',
        'bucket': bucket,
      };
    } catch (e) {
      print('✗ Bucket test failed: $e');
      return {
        'success': false,
        'message': 'Bucket test failed',
        'error': e.toString(),
      };
    }
  }

  // Test network connectivity to Firebase Storage
  static Future<Map<String, dynamic>> testNetworkConnectivity() async {
    try {
      print('=== NETWORK CONNECTIVITY TEST ===');

      // Test basic HTTP connectivity
      final testUrls = [
        'https://firebasestorage.googleapis.com',
        'https://www.googleapis.com',
        'https://googleapis.com',
      ];

      for (String url in testUrls) {
        try {
          print('Testing connectivity to: $url');
          final response = await http.get(Uri.parse(url));
          print(
            '✓ Successfully connected to $url (Status: ${response.statusCode})',
          );
        } catch (e) {
          print('✗ Failed to connect to $url: $e');
        }
      }

      // Test Firebase Storage specific endpoint
      try {
        final storageUrl =
            'https://firebasestorage.googleapis.com/v0/b/chatapp-bb0e2.firebasestorage.app/o';
        print('Testing Firebase Storage endpoint: $storageUrl');
        final response = await http.get(Uri.parse(storageUrl));
        print(
          '✓ Firebase Storage endpoint accessible (Status: ${response.statusCode})',
        );
      } catch (e) {
        print('✗ Firebase Storage endpoint not accessible: $e');
        if (e.toString().contains('ERR_CONNECTION_RESET')) {
          return {
            'success': false,
            'message':
                'Network connection reset detected. This may be due to firewall, VPN, or network restrictions.',
            'error': e.toString(),
            'suggestions': [
              'Check if you\'re using a VPN that might be blocking the connection',
              'Try disabling any corporate firewall or proxy',
              'Check if your ISP is blocking the domain',
              'Try using a different network connection',
            ],
          };
        }
      }

      return {
        'success': true,
        'message': 'Network connectivity appears normal',
      };
    } catch (e) {
      print('✗ Network test failed: $e');
      return {
        'success': false,
        'message': 'Network test failed',
        'error': e.toString(),
      };
    }
  }

  // Fallback method for network-blocked uploads
  static Future<Map<String, dynamic>> handleNetworkBlockedUpload(
    Uint8List imageData,
    String fileName,
  ) async {
    try {
      print('=== NETWORK BLOCKED UPLOAD HANDLER ===');

      // Create a data URL for the image
      final base64Data = base64Encode(imageData);
      final dataUrl = 'data:image/jpeg;base64,$base64Data';

      print('Image size: ${imageData.length} bytes');
      print('Data URL created successfully');

      return {
        'success': true,
        'message': 'Network blocked - using data URL as fallback',
        'dataUrl': dataUrl,
        'fileSize': imageData.length,
        'instructions': [
          'Firebase Storage is blocked by your network',
          'The image has been saved as a data URL',
          'You can manually upload this image later',
          'Try using a different network to upload to Firebase Storage',
        ],
      };
    } catch (e) {
      print('✗ Fallback upload failed: $e');
      return {
        'success': false,
        'message': 'Fallback upload failed',
        'error': e.toString(),
      };
    }
  }
}
