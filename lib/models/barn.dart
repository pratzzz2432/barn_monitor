import 'package:cloud_firestore/cloud_firestore.dart';

class Barn {
  final String id;
  final String name;
  final String ownerId;
  final String location;
  final String type; // e.g., "Dairy", "Swine", "Poultry"
  final String status; // e.g., "normal", "warning", "danger", "ventilating"
  final int capacity;
  final Timestamp createdAt;

  Barn({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.location,
    required this.type,
    required this.status,
    required this.capacity,
    required this.createdAt,
  });

  // Convert Firestore document to Barn object
  factory Barn.fromMap(Map<String, dynamic> data, String id) {
    return Barn(
      id: id,
      name: data['name'] ?? 'Unnamed Barn',
      ownerId: data['ownerId'] ?? '',
      location: data['location'] ?? 'Unknown',
      type: data['type'] ?? 'General',
      status: data['status'] ?? 'normal',
      capacity: data['capacity'] ?? 0,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  // Convert Barn object to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerId': ownerId,
      'location': location,
      'type': type,
      'status': status,
      'capacity': capacity,
      'createdAt': createdAt,
    };
  }
}