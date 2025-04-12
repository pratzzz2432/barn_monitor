import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:barn_air_monitor/models/reading.dart';
import 'package:barn_air_monitor/models/barn.dart';
import 'package:barn_air_monitor/services/database_service.dart';
import 'package:barn_air_monitor/screens/trends_screen.dart';
import 'package:barn_air_monitor/screens/alerts_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String barnId;

  const DashboardScreen({super.key, required this.barnId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _databaseService = DatabaseService();
  Barn? _currentBarn;
  Reading? _latestReading;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBarnData();
  }

  Future<void> _loadBarnData() async {
    try {
      // Get barn details
      DocumentSnapshot barnSnapshot = await FirebaseFirestore.instance
          .collection('barns')
          .doc(widget.barnId)
          .get();

      if (barnSnapshot.exists) {
        setState(() {
          _currentBarn = Barn.fromMap(
              barnSnapshot.data() as Map<String, dynamic>, barnSnapshot.id);
        });
      }

      // Get latest reading
      Reading? latestReading =
      await _databaseService.getLatestReading(widget.barnId);

      setState(() {
        _latestReading = latestReading;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: ${e.toString()}')),
      );
    }
  }

  // Emergency ventilation action
  Future<void> _triggerVentilation() async {
    try {
      // Update barn status to ventilating
      await _databaseService.updateBarnStatus(widget.barnId, 'ventilating');

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency ventilation activated!'),
          backgroundColor: Colors.red,
        ),
      );

      // Refresh data
      _loadBarnData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // Risk level determination
  String _getRiskLevel() {
    if (_latestReading == null) return 'Unknown';

    if (_latestReading!.isDangerous) {
      return 'Dangerous';
    } else if (_latestReading!.needsAttention) {
      return 'Warning';
    } else {
      return 'Normal';
    }
  }

  // Color based on risk level
  Color _getRiskColor() {
    String riskLevel = _getRiskLevel();

    switch (riskLevel) {
      case 'Dangerous':
        return Colors.red;
      case 'Warning':
        return Colors.orange;
      case 'Normal':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentBarn?.name ?? 'Barn Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AlertsScreen(barnId: widget.barnId),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDashboard(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Trends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            // Already on dashboard
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrendsScreen(barnId: widget.barnId),
              ),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AlertsScreen(barnId: widget.barnId),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildDashboard() {
    final reading = _latestReading;

    if (reading == null) {
      return const Center(
        child: Text(
          'No readings available for this barn yet',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status card
          Card(
            color: _getRiskColor().withAlpha(51),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Current Status: ${_getRiskLevel()}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getRiskColor(),
                    ),
                  ),
                  Text(
                    'Last Updated: ${_formatTimestamp(reading.timestamp)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Gas levels section
          const Text(
            'Gas Levels',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildGaugeCard(
                  'Methane',
                  '${reading.methaneLevel.toStringAsFixed(1)} ppm',
                  reading.methaneLevel / 10000,
                  reading.methaneLevel > 5000
                      ? Colors.red
                      : reading.methaneLevel > 2000
                      ? Colors.orange
                      : Colors.green,
                  Icons.cloud,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGaugeCard(
                  'Ammonia',
                  '${reading.ammoniaLevel.toStringAsFixed(1)} ppm',
                  reading.ammoniaLevel / 50,
                  reading.ammoniaLevel > 25
                      ? Colors.red
                      : reading.ammoniaLevel > 10
                      ? Colors.orange
                      : Colors.green,
                  Icons.coronavirus,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildGaugeCard(
                    'Carbon Monoxide',
                    '${reading.coLevel.toStringAsFixed(1)} ppm',
                    reading.coLevel / 100,
                    reading.coLevel > 50
                        ? Colors.red
                        : reading.coLevel > 25
                        ? Colors.orange
                        : Colors.green,
                    Icons.air),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Climate section
          const Text(
            'Climate',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildClimateCard(
                  'Temperature',
                  '${reading.temperature.toStringAsFixed(1)}°C',
                  Icons.thermostat,
                  (reading.temperature > 30 || reading.temperature < 10)
                      ? Colors.red
                      : (reading.temperature > 28 || reading.temperature < 15)
                      ? Colors.orange
                      : Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildClimateCard(
                  'Humidity',
                  '${reading.humidity.toStringAsFixed(1)}%',
                  Icons.water_drop,
                  (reading.humidity > 80 || reading.humidity < 30)
                      ? Colors.red
                      : (reading.humidity > 70 || reading.humidity < 40)
                      ? Colors.orange
                      : Colors.green,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Emergency ventilation button
          ElevatedButton.icon(
            onPressed: _triggerVentilation,
            icon: const Icon(Icons.warning),
            label: const Text('VENTILATE NOW'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeCard(String title, String value, double level, Color color,
      IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: level.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              color: color,
              minHeight: 10,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClimateCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}