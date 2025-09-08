import 'package:firebase_database/firebase_database.dart';
// import 'package:park_chatapp/features/property/domain/models/property.dart';
import 'package:park_view_admin_panel/models/property.dart';

class PropertyService {
  static final DatabaseReference _propertiesRef = 
      FirebaseDatabase.instance.ref().child('properties');

  // Get all properties
  static Future<List<Property>> getAllProperties() async {
    try {
      DatabaseEvent event = await _propertiesRef.once();
      DataSnapshot snapshot = event.snapshot;
      
      if (snapshot.value == null) return [];
      
      Map<dynamic, dynamic> propertiesMap = snapshot.value as Map<dynamic, dynamic>;
      List<Property> properties = [];
      
      propertiesMap.forEach((key, value) {
        try {
          final map = Map<String, dynamic>.from(value as Map);
          properties.add(Property.fromMap(key.toString(), map));
        } catch (e) {
          // Skip malformed entries but don't crash the list
        }
      });
      
      return properties;
    } catch (e) {
      throw Exception('Failed to fetch properties: $e');
    }
  }

  // Add a new property
  static Future<bool> addProperty(Property property) async {
    try {
      final newPropertyRef = _propertiesRef.push();
      await newPropertyRef.set(property.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update a property
  static Future<bool> updateProperty(Property property) async {
    try {
      await _propertiesRef.child(property.id).update(property.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  // Toggle property status
  static Future<bool> togglePropertyStatus(String id, PropertyStatus newStatus) async {
    try {
      await _propertiesRef.child(id).update({
        'status': newStatus.toString().split('.').last
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete a property
  static Future<bool> deleteProperty(String id) async {
    try {
      await _propertiesRef.child(id).remove();
      return true;
    } catch (e) {
      return false;
    }
  }
}