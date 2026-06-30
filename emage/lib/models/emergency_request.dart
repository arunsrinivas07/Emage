import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyRequest {
  final String id;
  final String userId;
  final String emergencyType;
  final double latitude;
  final double longitude;
  final String status; // pending, accepted, completed
  final String? driverId;
  final String? driverLicensePlate;
  final String userName;
  final String pickupAddress;
  final Map<String, dynamic> medicalInfo;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  EmergencyRequest({
    required this.id,
    required this.userId,
    required this.emergencyType,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.driverId,
    this.driverLicensePlate,
    required this.userName,
    required this.pickupAddress,
    required this.medicalInfo,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
  });

  factory EmergencyRequest.fromFirestore(String id, Map<String, dynamic> data) {
    return EmergencyRequest(
      id: id,
      userId: data['userId'] ?? '',
      emergencyType: data['emergencyType'] ?? 'Emergency',
      latitude: (data['location']?['latitude'] ?? 0.0).toDouble(),
      longitude: (data['location']?['longitude'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      driverId: data['driverId'],
      driverLicensePlate: data['driverLicensePlate'],
      userName: data['userName'] ?? 'Unknown User',
      pickupAddress: data['pickupAddress'] ?? 'Unknown location',
      medicalInfo: Map<String, dynamic>.from(data['medicalInfo'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'emergencyType': emergencyType,
      'location': {
        'latitude': latitude,
        'longitude': longitude,
      },
      'status': status,
      'driverId': driverId,
      'driverLicensePlate': driverLicensePlate,
      'userName': userName,
      'pickupAddress': pickupAddress,
      'medicalInfo': medicalInfo,
      'createdAt': FieldValue.serverTimestamp(),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
}
