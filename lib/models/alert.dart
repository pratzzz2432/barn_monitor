// models/alert.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum AlertStatus { active, dismissed, resolved }
enum AlertSeverity { critical, warning, info }

class Alert {
  final String id;
  final String title;
  final String message;
  final AlertSeverity severity;
  final AlertStatus status;
  final Timestamp timestamp;

  Alert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.status,
    required this.timestamp,
  });

  factory Alert.fromMap(Map<String, dynamic> data, String id) {
    return Alert(
      id: id,
      title: data['title'] ?? 'New Alert',
      message: data['message'] ?? 'No details available',
      severity: _parseSeverity(data['severity']),
      status: _parseStatus(data['status']),
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'severity': severity.name,
      'status': status.name,
      'timestamp': timestamp,
    };
  }

  static AlertSeverity _parseSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical':
        return AlertSeverity.critical;
      case 'warning':
        return AlertSeverity.warning;
      default:
        return AlertSeverity.info;
    }
  }

  static AlertStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'dismissed':
        return AlertStatus.dismissed;
      case 'resolved':
        return AlertStatus.resolved;
      default:
        return AlertStatus.active;
    }
  }

  @override
  String toString() {
    return 'Alert($id): $title - ${severity.name} (${status.name})';
  }
}