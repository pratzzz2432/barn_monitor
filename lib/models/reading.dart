import 'package:cloud_firestore/cloud_firestore.dart';

class Reading {
  final String id;
  final String barnId;
  final double methaneLevel;
  final double ammoniaLevel;
  final double coLevel;
  final double temperature;
  final double humidity;
  final Timestamp timestamp;

  Reading({
    required this.id,
    required this.barnId,
    required this.methaneLevel,
    required this.ammoniaLevel,
    required this.coLevel,
    required this.temperature,
    required this.humidity,
    required this.timestamp,
  });

  // Convert Firestore document to Reading object
  factory Reading.fromMap(Map<String, dynamic> data, String id) {
    return Reading(
      id: id,
      barnId: data['barnId'] ?? '',
      methaneLevel: (data['methaneLevel'] ?? 0).toDouble(),
      ammoniaLevel: (data['ammoniaLevel'] ?? 0).toDouble(),
      coLevel: (data['coLevel'] ?? 0).toDouble(),
      temperature: (data['temperature'] ?? 0).toDouble(),
      humidity: (data['humidity'] ?? 0).toDouble(),
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  // Convert Reading object to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'barnId': barnId,
      'methaneLevel': methaneLevel,
      'ammoniaLevel': ammoniaLevel,
      'coLevel': coLevel,
      'temperature': temperature,
      'humidity': humidity,
      'timestamp': timestamp,
    };
  }

  // Determine if conditions are dangerous
  bool get isDangerous {
    return methaneLevel > 5000 ||
        ammoniaLevel > 25 ||
        coLevel > 50 ||
        temperature > 35 ||
        temperature < 5 ||
        humidity > 90 ||
        humidity < 20;
  }

  // Determine if conditions need attention
  bool get needsAttention {
    return methaneLevel > 2000 ||
        ammoniaLevel > 10 ||
        coLevel > 25 ||
        temperature > 30 ||
        temperature < 10 ||
        humidity > 80 ||
        humidity < 30;
  }
}