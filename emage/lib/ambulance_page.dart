import 'home_page.dart';
import 'find a donor.dart' hide HospitalsPage;
import 'doctors_page.dart' hide HospitalsPage;
import 'hospitals_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/navigation.dart';
import 'services/location_service.dart';

class AmbulanceScreen extends StatefulWidget {
  const AmbulanceScreen({super.key});

  @override
  State<AmbulanceScreen> createState() => _AmbulanceScreenState();
}

class _AmbulanceScreenState extends State<AmbulanceScreen> {
  final user = FirebaseAuth.instance.currentUser;
  int _currentIndex = 4; // Default to Ambulance tab (index 4)
  String _name = "DIVYANAND";
  String _currentLocationArea = "Unknown location";
  bool _isLoading = true;
  Map<String, dynamic> userData = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadLocation();
  }

  Future<void> _loadUserData() async {
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (userDoc.exists) {
        userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _name = userData['name'] ?? "DIVYANAND";
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToPage(int index) {
    if (index == _currentIndex) return;

    HapticFeedback.lightImpact();
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HospitalsPage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DoctorPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FindaDonor()),
        );
        break;
      case 4:
        // Already on ambulance page
        break;
    }
  }

  Future<void> _loadLocation() async {
    final location = await LocationService.getCurrentLocation();
    setState(() {
      _currentLocationArea = location.area;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with location and profile - Same as homepage
                  Container(
                    margin: EdgeInsets.all(16.w),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const HomePage()),
                            );
                          },
                          child: Container(
                            width: 36.w, // 👈 fixed width for perfect square
                            height: 36.w, // 👈 same as width
                            decoration: BoxDecoration(
                              color: const Color(0xFFCD1C18).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Center(
                              child: Icon(
                                Icons
                                    .arrow_back_ios_new, // 👈 better centered version
                                color: const Color(0xFFCD1C18),
                                size: 18.sp,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Container(
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCD1C18).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: const Color(0xFFCD1C18),
                            size: 18.sp,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Current Location",
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _currentLocationArea,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ProfilePage()),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFCD1C18).withOpacity(0.3),
                                width: 2.w,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 18.r,
                              backgroundImage: AssetImage("assets/profile.png"),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Title section - Same style as homepage
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Ambulance Services",
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          "Find and contact nearby ambulance services for emergency medical transportation.",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                            height: 1.3.h,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Ambulance list section
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.w),
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Nearby Ambulances",
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Expanded(
                            child: ListView(
                              children: [
                                AmbulanceCard(
                                  name: "Maharjan",
                                  location: "Adyar, Chennai",
                                  phone: "9841234789",
                                  email: "Maharajan@gmail.com",
                                ),
                                SizedBox(height: 12.h),
                                AmbulanceCard(
                                  name: "Niraj",
                                  location: "OMR, Chennai",
                                  phone: "9841234789",
                                  email: "Niraj.kl@gmail.com",
                                ),
                                SizedBox(height: 12.h),
                                AmbulanceCard(
                                  name: "Sanjiv",
                                  location: "T Nagar, Chennai",
                                  phone: "9080642927",
                                  email: "sanjiv@gmail.com",
                                ),
                                SizedBox(height: 12.h),
                                AmbulanceCard(
                                  name: "Arun Srinivas",
                                  location: "Sowkarpet, Chennai",
                                  phone: "8807121454",
                                  email: "arunsrinivas@gmail.com",
                                ),
                                SizedBox(height: 12.h),
                                AmbulanceCard(
                                  name: "Nitish",
                                  location: "Mahabalipuram, Chennai",
                                  phone: "7810075534",
                                  email: "msnrnitish@gmail.com",
                                ),
                                SizedBox(height: 12.h),
                                AmbulanceCard(
                                  name: "Logeshwar",
                                  location: "ECR, Chennai",
                                  phone: "9786001567",
                                  email: "LOgesh@gmail.com",
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),
                ],
              ),
            ),

            // Navigation - Same as homepage
            Navigation(
              currentIndex: _currentIndex,
              onTap: _navigateToPage,
              onEmergencyTap: () {
                HapticFeedback.lightImpact();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AmbulanceCard extends StatelessWidget {
  final String name;
  final String location;
  final String phone;
  final String email;

  const AmbulanceCard({
    super.key,
    required this.name,
    required this.location,
    required this.phone,
    required this.email,
  });

  Future<void> _makePhoneCall(String phoneNumber) async {
    HapticFeedback.lightImpact();

    final String cleanedNumber = phoneNumber.replaceAll(" ", "");
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanedNumber,
    );

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        debugPrint('Could not launch $launchUri');
      }
    } catch (e) {
      debugPrint('Error making phone call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          // Ambulance icon container - matching homepage style
          Container(
            width: 50.w,
            height: 50.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFCD1C18), Color(0xFFE53935)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFCD1C18).withOpacity(0.3),
                  blurRadius: 8.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                "assets/ambulance.png",
                width: 24.w,
                height: 24.h,
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(width: 16.w),

          // Info section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: const Color(0xFFCD1C18),
                      size: 14.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      color: Colors.grey.shade600,
                      size: 14.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      phone,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      Icons.email,
                      color: Colors.grey.shade600,
                      size: 14.sp,
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        email,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Call button - matching homepage style
          GestureDetector(
            onTap: () => _makePhoneCall(phone),
            child: Container(
              width: 44.w,
              height: 44.h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFCD1C18), Color(0xFFE53935)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFCD1C18).withOpacity(0.3),
                    blurRadius: 8.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Icon(
                Icons.phone,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
