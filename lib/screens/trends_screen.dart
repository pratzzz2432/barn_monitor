import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barn_air_monitor/models/reading.dart';
import 'package:barn_air_monitor/services/database_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class TrendsScreen extends StatefulWidget {
  final String barnId;

  const TrendsScreen({Key? key, required this.barnId}) : super(key: key);

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;
  List<Reading> _readings = [];
  bool _isLoading = true;
  String _dataType = 'methane'; // Default data type to display

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReadingsData('day');

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        String timeRange;
        switch (_tabController.index) {
          case 0:
            timeRange = 'day';
            break;
          case 1:
            timeRange = 'week';
            break;
          case 2:
            timeRange = 'month';
            break;
          default:
            timeRange = 'day';
        }
        _loadReadingsData(timeRange);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReadingsData(String timeRange) async {
    setState(() {
      _isLoading = true;
    });

    try {
      DateTime now = DateTime.now();
      DateTime? startDate;

      // Set time range based on selected tab
      switch (timeRange) {
        case 'day':
          startDate = now.subtract(const Duration(days: 1));
          break;
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = now.subtract(const Duration(days: 30));
          break;
      }

      // Get readings within the time range
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('readings')
          .where('barnId', isEqualTo: widget.barnId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate!))
          .orderBy('timestamp', descending: false)
          .get();

      List<Reading> readings = snapshot.docs
          .map((doc) => Reading.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      setState(() {
        _readings = readings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading trends data: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: ${e.toString()}')),
      );
    }
  }

  // This is a placeholder for where we would implement AI recommendations
  List<String> _getAIRecommendations() {
    // In a real implementation, this would come from an ML model
    return [
      "Clean barn every Tuesday based on ammonia pattern",
      "Ventilate in morning hours to reduce methane build-up",
      "Consider humidity control system based on daily fluctuations"
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trends & Analysis'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Day'),
            Tab(text: 'Week'),
            Tab(text: 'Month'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Data type selector
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'methane', label: Text('Methane')),
                ButtonSegment(value: 'ammonia', label: Text('Ammonia')),
                ButtonSegment(value: 'co', label: Text('CO')),
                ButtonSegment(value: 'temperature', label: Text('Temp')),
                ButtonSegment(value: 'humidity', label: Text('Humidity')),
              ],
              selected: {_dataType},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _dataType = selection.first;
                });
              },
            ),
          ),

          // Chart placeholder
          Expanded(
            flex: 3,
            child: _readings.isEmpty
                ? const Center(child: Text('No data available for selected period'))
                : Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildChart(),
            ),
          ),

          // AI Recommendations
          Expanded(
            flex: 2,
            child: Card(
              margin: const EdgeInsets.all(16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'AI Recommendations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _getAIRecommendations().length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const Icon(Icons.check_circle, color: Colors.green),
                            title: Text(_getAIRecommendations()[index]),
                            dense: true,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    // Placeholder for the actual chart
    // In a real implementation, you would use fl_chart or another charting library
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'Chart data for $_dataType will be displayed here',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}