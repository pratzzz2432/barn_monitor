import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barn_air_monitor/models/alert.dart';

class AlertsScreen extends StatefulWidget {
  final String barnId;

  const AlertsScreen({super.key, required this.barnId});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool _isLoading = true;
  List<Alert> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      setState(() => _isLoading = true);

      final snapshot = await FirebaseFirestore.instance
          .collection('alerts')
          .where('barnId', isEqualTo: widget.barnId)
          .orderBy('timestamp', descending: true)
          .get();

      final alerts = snapshot.docs.map((doc) {
        final data = doc.data();
        if (data.isEmpty) return null;
        return Alert.fromMap(data, doc.id);
      }).whereType<Alert>().toList();

      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading alerts: $e');
      setState(() => _isLoading = false);
      _showError('Failed to load alerts: ${e.toString()}');
    }
  }

  Future<void> _dismissAlert(String alertId) async {
    try {
      await FirebaseFirestore.instance
          .collection('alerts')
          .doc(alertId)
          .update({
        'status': 'dismissed',
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      await _loadAlerts();
    } catch (e) {
      _showError('Failed to dismiss alert: ${e.toString()}');
    }
  }

  Future<void> _markResolved(String alertId) async {
    try {
      await FirebaseFirestore.instance
          .collection('alerts')
          .doc(alertId)
          .update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      await _loadAlerts();
    } catch (e) {
      _showError('Failed to resolve alert: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_alerts.isEmpty) {
      return const Center(child: Text('No alerts found'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _alerts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) => _AlertCard(
        alert: _alerts[index],
        onDismiss: _dismissAlert,
        onResolve: _markResolved,
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Alert alert;
  final Function(String) onDismiss;
  final Function(String) onResolve;

  const _AlertCard({
    required this.alert,
    required this.onDismiss,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _getAlertStyle(alert.severity as String);
    final statusColor = _getStatusColor(alert.status as String);

    return Card(
      color: color.withAlpha(30),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(alert.message),
                    ],
                  ),
                ),
                Text(
                  _formatTimestamp(alert.timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${alert.status}',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (alert.status == 'active') _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return ButtonBar(
      alignment: MainAxisAlignment.end,
      buttonPadding: EdgeInsets.zero,
      children: [
        TextButton(
          onPressed: () => onDismiss(alert.id),
          child: const Text('Dismiss'),
        ),
        FilledButton(
          onPressed: () => onResolve(alert.id),
          child: const Text('Mark Resolved'),
        ),
      ],
    );
  }

  (Color, IconData) _getAlertStyle(String severity) {
    return switch (severity.toLowerCase()) {
      'critical' => (Colors.red, Icons.warning_rounded),
      'warning' => (Colors.orange, Icons.error_outline_rounded),
      _ => (Colors.blue, Icons.info_outline_rounded),
    };
  }

  Color _getStatusColor(String status) {
    return switch (status.toLowerCase()) {
      'active' => Colors.red,
      'dismissed' => Colors.grey,
      'resolved' => Colors.green,
      _ => Colors.grey,
    };
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}