import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barn_air_monitor/models/barn.dart';
import 'package:barn_air_monitor/models/reading.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user barns
  Stream<List<Barn>> getUserBarns(String userId) {
    return _firestore
        .collection('barns')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Barn.fromMap(doc.data(), doc.id)).toList()
    );
  }

  // Add a new barn
  Future<String> addBarn(Barn barn) async {
    try {
      DocumentReference docRef = await _firestore.collection('barns').add(barn.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding barn: ${e.toString()}');
      rethrow;
    }
  }

  // Get latest reading for a barn
  Future<Reading?> getLatestReading(String barnId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('readings')
          .where('barnId', isEqualTo: barnId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Reading.fromMap(
            snapshot.docs.first.data() as Map<String, dynamic>,
            snapshot.docs.first.id
        );
      }
      return null;
    } catch (e) {
      print('Error getting latest reading: ${e.toString()}');
      rethrow;
    }
  }

  // Get readings for a specific time period
  Stream<List<Reading>> getBarnReadings(String barnId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) {
    Query query = _firestore
        .collection('readings')
        .where('barnId', isEqualTo: barnId)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) =>
            Reading.fromMap(doc.data() as Map<String, dynamic>, doc.id)
        ).toList()
    );
  }

  // Update barn status
  Future<void> updateBarnStatus(String barnId, String status) async {
    try {
      await _firestore.collection('barns').doc(barnId).update({
        'status': status,
      });
    } catch (e) {
      print('Error updating barn status: ${e.toString()}');
      rethrow;
    }
  }

  // Add a reading
  Future<String> addReading(Reading reading) async {
    try {
      DocumentReference docRef = await _firestore.collection('readings').add(reading.toMap());

      // Update barn status based on reading
      String status = 'normal';
      if (reading.isDangerous) {
        status = 'danger';
      } else if (reading.needsAttention) {
        status = 'warning';
      }

      await updateBarnStatus(reading.barnId, status);

      return docRef.id;
    } catch (e) {
      print('Error adding reading: ${e.toString()}');
      rethrow;
    }
  }
}