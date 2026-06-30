// lib/screens/driver/driver_dashboard.dart
import 'package:app/services/emergency_service.dart';
import 'package:app/sign_in.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({Key? key}) : super(key: key);

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  bool _isOnline = false;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _locationUpdateTimer;

  @override
  void initState() {
    super.initState();
    _pages = [
      DriverHomeTab(
        isOnline: _isOnline,
        onToggleOnlineStatus: _toggleOnlineStatus,
      ),
      const DriverHistoryTab(),
      const DriverEarningsTab(),
      const DriverProfileTab(),
    ];
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  void _toggleOnlineStatus() async {
    setState(() {
      _isOnline = !_isOnline;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .update({
        'isOnline': _isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      if (_isOnline) {
        _startLocationTracking();
      } else {
        _stopLocationTracking();
      }
    }

    // Update the home tab
    setState(() {
      _pages[0] = DriverHomeTab(
        isOnline: _isOnline,
        onToggleOnlineStatus: _toggleOnlineStatus,
      );
    });
  }

  void _startLocationTracking() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateLocation();
    });
  }

  void _stopLocationTracking() {
    _positionSubscription?.cancel();
    _locationUpdateTimer?.cancel();
  }

  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('drivers')
            .doc(user.uid)
            .update({
          'location': {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': FieldValue.serverTimestamp(),
          },
        });
      }
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade600,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stopLocationTracking();
    super.dispose();
  }
}

// Home Tab
class DriverHomeTab extends StatefulWidget {
  final bool isOnline;
  final VoidCallback onToggleOnlineStatus;

  const DriverHomeTab({
    Key? key,
    required this.isOnline,
    required this.onToggleOnlineStatus,
  }) : super(key: key);

  @override
  State<DriverHomeTab> createState() => _DriverHomeTabState();
}

class _DriverHomeTabState extends State<DriverHomeTab> {
  final user = FirebaseAuth.instance.currentUser;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    if (widget.isOnline) {
      _getCurrentLocation();
    }
  }

  @override
  void didUpdateWidget(DriverHomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOnline && !oldWidget.isOnline) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Status Toggle
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color:
                  widget.isOnline ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isOnline
                    ? Colors.green.shade200
                    : Colors.red.shade200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: widget.isOnline ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.isOnline ? 'You are Online' : 'You are Offline',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: widget.isOnline
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                ),
                Switch(
                  value: widget.isOnline,
                  onChanged: (_) => widget.onToggleOnlineStatus(),
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),

          // Location status
          if (widget.isOnline && _currentPosition != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on,
                      color: Colors.blue.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Location: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Requests List
          Expanded(
            child: widget.isOnline && _currentPosition != null
                ? StreamBuilder<List<Map<String, dynamic>>>(
                    stream: EmergencyService.getNearbyRequestsForDriver(
                      driverLatitude: _currentPosition!.latitude,
                      driverLongitude: _currentPosition!.longitude,
                      maxRadiusKm: 5.0, // Start with 5km radius
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error,
                                  size: 48, color: Colors.red.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading requests',
                                style: TextStyle(color: Colors.red.shade600),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => setState(() {}),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Looking for nearby requests...'),
                            ],
                          ),
                        );
                      }

                      final requests = snapshot.data ?? [];

                      if (requests.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No emergency requests nearby',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'We\'ll notify you when someone needs help',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: requests.length,
                        itemBuilder: (context, index) {
                          final request = requests[index];
                          final requestId = request['id'] as String;
                          final data = request['data'] as Map<String, dynamic>;
                          final distance = request['distance'] as double;

                          return _buildRequestCard(requestId, data, distance);
                        },
                      );
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.isOnline
                              ? Icons.location_searching
                              : Icons.power_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.isOnline
                              ? 'Getting your location...'
                              : 'Go online to receive requests',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        if (widget.isOnline) ...[
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _getCurrentLocation,
                            child: const Text('Refresh Location'),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(
      String requestId, Map<String, dynamic> data, double distance) {
    // Priority colors
    final emergencyColors = {
      'Medical': Colors.red.shade600,
      'Fire': Colors.orange.shade600,
      'Accident': Colors.purple.shade600,
    };

    final emergencyColor =
        emergencyColors[data['emergencyType']] ?? Colors.grey.shade600;

    // Time since request
    String timeAgo = 'Just now';
    if (data['createdAt'] != null) {
      final createdTime = (data['createdAt'] as Timestamp).toDate();
      final now = DateTime.now();
      final difference = now.difference(createdTime);

      if (difference.inMinutes < 1) {
        timeAgo = 'Just now';
      } else if (difference.inMinutes < 60) {
        timeAgo = '${difference.inMinutes}m ago';
      } else {
        timeAgo = '${difference.inHours}h ago';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: emergencyColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: emergencyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    data['emergencyType'] == 'Medical'
                        ? Icons.medical_services
                        : data['emergencyType'] == 'Fire'
                            ? Icons.local_fire_department
                            : Icons.car_crash,
                    color: emergencyColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data['emergencyType']} Emergency',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: emergencyColor,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'URGENT',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // User info
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  data['userName'] ?? 'Unknown User',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (data['userPhone'] != null &&
                    data['userPhone'].toString().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _callUser(data['userPhone']),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.phone,
                        size: 14,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Location info
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    data['pickupAddress'] ?? 'Location not specified',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Distance and medical info
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: distance <= 1
                        ? Colors.green.shade100
                        : distance <= 2
                            ? Colors.orange.shade100
                            : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${distance.toStringAsFixed(1)} km away',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: distance <= 1
                          ? Colors.green.shade700
                          : distance <= 2
                              ? Colors.orange.shade700
                              : Colors.red.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (data['isMyselfSelected'] == true &&
                    data['medicalInfo'] != null) ...[
                  const Icon(Icons.medical_information,
                      size: 14, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    'Medical info available',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ],
            ),

            // Medical info details (if available)
            if (data['isMyselfSelected'] == true &&
                data['medicalInfo'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Medical Information:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (data['medicalInfo']['bloodGroup']?.isNotEmpty ==
                            true) ...[
                          Text(
                            'Blood: ${data['medicalInfo']['bloodGroup']}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          const SizedBox(width: 16),
                        ],
                        if (data['medicalInfo']['age'] != null &&
                            data['medicalInfo']['age'] > 0)
                          Text(
                            'Age: ${data['medicalInfo']['age']}',
                            style: const TextStyle(fontSize: 11),
                          ),
                      ],
                    ),
                    if (data['medicalInfo']['medicalConditions']?.isNotEmpty ==
                        true) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Conditions: ${data['medicalInfo']['medicalConditions']}',
                        style: const TextStyle(fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectRequest(requestId),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptRequest(requestId, data),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Accept & Respond'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: emergencyColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callUser(String phoneNumber) async {
    try {
      final uri = Uri.parse('tel:$phoneNumber');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not call user: $e')),
        );
      }
    }
  }

  Future<void> _navigateToUser(Map<String, dynamic> requestData) async {
    final location = requestData['location'] as Map<String, dynamic>?;
    if (location == null) return;

    final lat = location['latitude'];
    final lng = location['longitude'];

    try {
      // Try Google Maps first
      final googleMapsUrl =
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
      final googleUri = Uri.parse(googleMapsUrl);

      if (await canLaunchUrl(googleUri)) {
        await launchUrl(googleUri, mode: LaunchMode.externalApplication);
        return;
      }

      // Fallback to generic maps URL
      final fallbackUrl = 'https://maps.google.com/?q=$lat,$lng';
      final fallbackUri = Uri.parse(fallbackUrl);

      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open navigation: $e')),
        );
      }
    }
  }

  Future<void> _acceptRequest(
      String requestId, Map<String, dynamic> data) async {
    try {
      // Get driver profile info first
      DocumentSnapshot driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user!.uid)
          .get();

      Map<String, dynamic> driverData = {};
      Map<String, dynamic> driverProfile = {};

      if (driverDoc.exists) {
        driverData = driverDoc.data() as Map<String, dynamic>;
        driverProfile = driverData['profile'] as Map<String, dynamic>? ?? {};
      }

      // Use a transaction to prevent multiple drivers accepting the same request
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference requestRef =
            FirebaseFirestore.instance.collection('requests').doc(requestId);

        DocumentSnapshot requestSnapshot = await transaction.get(requestRef);

        if (!requestSnapshot.exists) {
          throw Exception('Request not found');
        }

        Map<String, dynamic> requestData =
            requestSnapshot.data() as Map<String, dynamic>;

        // Check if already accepted
        if (requestData['status'] != 'pending') {
          throw Exception('Request already accepted by another driver');
        }

        // Update with driver info
        transaction.update(requestRef, {
          'status': 'accepted',
          'driverId': user!.uid,
          'driverName': driverData['fullName'] ?? 'Unknown Driver',
          'driverPhone': driverData['phone'] ?? '',
          'driverLicensePlate': driverProfile['licenseNumber'] ?? 'Unknown',
          'driverVehicleNumber': driverProfile['vehicleNumber'] ?? 'Unknown',
          'acceptedAt': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'Request accepted successfully! Navigate to user location.'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Navigate',
              textColor: Colors.white,
              onPressed: () => _navigateToLocation(requestId),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToLocation(String requestId) async {
    try {
      // Get the request data to find user location
      DocumentSnapshot requestDoc = await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) return;

      Map<String, dynamic> data = requestDoc.data() as Map<String, dynamic>;
      Map<String, dynamic>? location =
          data['location'] as Map<String, dynamic>?;

      if (location == null) return;

      double lat = location['latitude']?.toDouble() ?? 0.0;
      double lng = location['longitude']?.toDouble() ?? 0.0;

      // Launch Google Maps navigation
      String googleMapsUrl =
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
      Uri uri = Uri.parse(googleMapsUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to basic maps URL
        String fallbackUrl = 'https://maps.google.com/?q=$lat,$lng';
        Uri fallbackUri = Uri.parse(fallbackUrl);

        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open navigation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .collection('rejectedBy')
          .doc(user!.uid)
          .set({
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// History Tab
class DriverHistoryTab extends StatelessWidget {
  const DriverHistoryTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('driverId', isEqualTo: user?.uid)
            .where('status', isEqualTo: 'completed')
            .orderBy('completedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading history'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final trips = snapshot.data?.docs ?? [];

          if (trips.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No completed trips yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.check, color: Colors.white),
                  ),
                  title: Text(trip['emergencyType'] ?? 'Emergency Trip'),
                  subtitle: Text(trip['pickupAddress'] ?? 'Unknown location'),
                  trailing: Text(
                    '₹${trip['fare'] ?? '0'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Earnings Tab
class DriverEarningsTab extends StatelessWidget {
  const DriverEarningsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('driverId', isEqualTo: user?.uid)
            .where('status', isEqualTo: 'completed')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading earnings'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final trips = snapshot.data?.docs ?? [];
          double totalEarnings = 0;

          for (var trip in trips) {
            final data = trip.data() as Map<String, dynamic>;
            totalEarnings += (data['fare'] as num?)?.toDouble() ?? 0;
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text(
                          'Total Earnings',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${totalEarnings.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Trips',
                                style: TextStyle(color: Colors.grey)),
                            Text(
                              '${trips.length}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Avg per Trip',
                                style: TextStyle(color: Colors.grey)),
                            Text(
                              '₹${trips.isNotEmpty ? (totalEarnings / trips.length).toStringAsFixed(2) : '0.00'}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Profile Tab
class DriverProfileTab extends StatelessWidget {
  const DriverProfileTab({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignInPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('drivers')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading profile'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final profile = data['profile'] as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue.shade600,
                          child: Text(
                            (data['fullName'] as String?)
                                    ?.substring(0, 1)
                                    .toUpperCase() ??
                                'D',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['fullName'] ?? 'Driver Name',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                data['email'] ?? '',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              Text(
                                data['phone'] ?? '',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Vehicle Information
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vehicle Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Vehicle Type',
                            profile['vehicleType'] ?? 'Not specified'),
                        _buildInfoRow('Vehicle Number',
                            profile['vehicleNumber'] ?? 'Not specified'),
                        _buildInfoRow('License Number',
                            profile['licenseNumber'] ?? 'Not specified'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Status Information
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildStatusRow(
                            'Verification Status', data['status'] ?? 'pending'),
                        _buildStatusRow('Online Status',
                            data['isOnline'] == true ? 'Online' : 'Offline'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    Color statusColor;
    switch (value.toLowerCase()) {
      case 'approved':
      case 'online':
        statusColor = Colors.green;
        break;
      case 'pending_verification':
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'rejected':
      case 'offline':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: statusColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
