import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class EmergencyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Calculate distance between two points using Haversine formula
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convert to km
  }

  // Send emergency request to nearby drivers
  static Future<String> sendEmergencyRequest({
    required String emergencyType,
    required double latitude,
    required double longitude,
    required Map<String, dynamic> userInfo,
    required bool isMyselfSelected,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get address from coordinates
      String address = 'Unknown location';
      try {
        final placemarks = await placemarkFromCoordinates(latitude, longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          address = '${place.name ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}';
        }
      } catch (e) {
        print('Error getting address: $e');
      }

      // Prepare medical info based on selection
      Map<String, dynamic> medicalInfo = {};
      if (isMyselfSelected) {
        medicalInfo = {
          'bloodGroup': userInfo['bloodGroup'] ?? '',
          'medicalConditions': userInfo['medicalConditions'] ?? '',
          'age': _calculateAge(userInfo['dob'] ?? ''),
        };
      }

      // Create emergency request
      final requestData = {
        'userId': user.uid,
        'emergencyType': emergencyType,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
        },
        'status': 'pending',
        'userName': userInfo['name'] ?? 'Unknown User',
        'userPhone': userInfo['phone'] ?? '',
        'pickupAddress': address,
        'medicalInfo': medicalInfo,
        'isMyselfSelected': isMyselfSelected,
        'createdAt': FieldValue.serverTimestamp(),
        'driverId': null,
        'driverLicensePlate': null,
        'acceptedAt': null,
      };

      final docRef = await _firestore.collection('requests').add(requestData);
      print('Emergency request created with ID: ${docRef.id}');
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to send emergency request: $e');
    }
  }

  // Accept emergency request (for drivers)
  static Future<void> acceptRequest(String requestId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Driver not authenticated');

      // Get driver data
      final driverDoc = await _firestore.collection('drivers').doc(user.uid).get();
      if (!driverDoc.exists) {
        throw Exception('Driver profile not found');
      }

      final driverData = driverDoc.data()!;
      final driverProfile = driverData['profile'] as Map<String, dynamic>? ?? {};

      // Use transaction to prevent multiple drivers accepting same request
      await _firestore.runTransaction((transaction) async {
        final requestRef = _firestore.collection('requests').doc(requestId);
        final requestDoc = await transaction.get(requestRef);
        
        if (!requestDoc.exists) {
          throw Exception('Request not found');
        }
        
        final requestData = requestDoc.data()!;
        if (requestData['status'] != 'pending') {
          throw Exception('Request already accepted or cancelled');
        }

        // Update request with driver info
        transaction.update(requestRef, {
          'status': 'accepted',
          'driverId': user.uid,
          'driverName': driverData['fullName'] ?? 'Unknown Driver',
          'driverPhone': driverData['phone'] ?? '',
          'driverLicensePlate': driverProfile['licenseNumber'] ?? 'Unknown',
          'driverVehicleNumber': driverProfile['vehicleNumber'] ?? 'Unknown',
          'acceptedAt': FieldValue.serverTimestamp(),
        });
      });

      print('Request $requestId accepted successfully');
    } catch (e) {
      throw Exception('Failed to accept request: $e');
    }
  }

  // Cancel emergency request (for users)
  static Future<void> cancelRequest(String requestId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('requests').doc(requestId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      print('Request $requestId cancelled successfully');
    } catch (e) {
      throw Exception('Failed to cancel request: $e');
    }
  }

  // Get nearby requests for drivers
  static Stream<List<Map<String, dynamic>>> getNearbyRequestsForDriver({
    required double driverLatitude,
    required double driverLongitude,
    double maxRadiusKm = 5.0,
  }) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> nearbyRequests = [];

      for (var doc in snapshot.docs) {
        // Check if driver has rejected this request
        final rejectedDoc = await _firestore
            .collection('requests')
            .doc(doc.id)
            .collection('rejectedBy')
            .doc(user.uid)
            .get();

        if (rejectedDoc.exists) continue;

        final data = doc.data();
        final location = data['location'] as Map<String, dynamic>?;
        
        if (location != null) {
          final requestLat = (location['latitude'] ?? 0.0).toDouble();
          final requestLng = (location['longitude'] ?? 0.0).toDouble();
          
          // Try different radius levels: 1km, 2km, 5km
          double distance = calculateDistance(
            driverLatitude, driverLongitude, requestLat, requestLng);
          
          if (distance <= maxRadiusKm) {
            nearbyRequests.add({
              'id': doc.id,
              'data': data,
              'distance': distance,
            });
          }
        }
      }

      // Sort by priority: Medical > Fire > Accident, then by distance, then by time
      nearbyRequests.sort((a, b) {
        final aData = a['data'] as Map<String, dynamic>;
        final bData = b['data'] as Map<String, dynamic>;
        
        // Priority by emergency type
        final urgencyOrder = {'Medical': 3, 'Fire': 2, 'Accident': 1};
        final aUrgency = urgencyOrder[aData['emergencyType']] ?? 0;
        final bUrgency = urgencyOrder[bData['emergencyType']] ?? 0;
        
        if (aUrgency != bUrgency) {
          return bUrgency.compareTo(aUrgency);
        }
        
        // Then by distance
        final aDist = a['distance'] as double;
        final bDist = b['distance'] as double;
        
        if ((aDist - bDist).abs() > 0.1) { // If distance difference > 100m
          return aDist.compareTo(bDist);
        }
        
        // Then by time (newer first)
        final aTime = aData['createdAt'] as Timestamp?;
        final bTime = bData['createdAt'] as Timestamp?;
        if (aTime != null && bTime != null) {
          return bTime.compareTo(aTime);
        }
        
        return 0;
      });

      return nearbyRequests;
    });
  }

  // Listen for request status changes (for users)
  static Stream<DocumentSnapshot> listenToRequestStatus(String requestId) {
    return _firestore.collection('requests').doc(requestId).snapshots();
  }

  // Reject emergency request (for drivers)
  static Future<void> rejectRequest(String requestId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Driver not authenticated');

      // Add to rejected drivers subcollection
      await _firestore
          .collection('requests')
          .doc(requestId)
          .collection('rejectedBy')
          .doc(user.uid)
          .set({
        'rejectedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to reject request: $e');
    }
  }

  // Helper method to calculate age
  static int _calculateAge(String dobString) {
    if (dobString.isEmpty) return 0;

    try {
      List<String> parts = dobString.split('-');
      if (parts.length != 3) return 0;

      int day = int.parse(parts[0]);
      int month = int.parse(parts[1]);
      int year = int.parse(parts[2]);

      DateTime dob = DateTime(year, month, day);
      DateTime now = DateTime.now();

      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }
}