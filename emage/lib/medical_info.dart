import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'edit_medical_info.dart';
import 'profile_page.dart';

class MedicalInfoScreen extends StatefulWidget {
  const MedicalInfoScreen({super.key});

  @override
  _MedicalInfoScreenState createState() => _MedicalInfoScreenState();
}

class _MedicalInfoScreenState extends State<MedicalInfoScreen> with TickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  String name = "";
  String age = "";
  String dob = "";
List<String> emergencyNumbers = [];
  String bloodGroup = "";
  String medicalConditions = "";
  bool _isLoading = true;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchMedicalInfo();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _fetchMedicalInfo() async {
    if (user != null) {
      try {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          setState(() {
            name = data['name'] ?? "";
            dob = data['dob'] ?? "";
            age = _calculateAge(dob);
emergencyNumbers = List<String>.from(data['emergencyNumbers'] ?? []);
            bloodGroup = data['bloodGroup'] ?? "";
            medicalConditions = data['medicalConditions'] ?? "";
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error fetching medical info: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _calculateAge(String dob) {
    if (dob.isEmpty) return "";
    try {
      List<String> parts = dob.split("-");
      int birthYear = int.parse(parts[2]);
      int birthMonth = int.parse(parts[1]);
      int birthDay = int.parse(parts[0]);

      DateTime birthDate = DateTime(birthYear, birthMonth, birthDay);
      DateTime today = DateTime.now();
      int age = today.year - birthDate.year;

      if (today.month < birthMonth ||
          (today.month == birthMonth && today.day < birthDay)) {
        age--;
      }
      return age.toString();
    } catch (e) {
      return "";
    }
  }

  void _navigateToEditScreen() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMedicalInfoScreen(
          age: age,
          dob: dob,
          emergencyNumbers: emergencyNumbers,
          bloodGroup: bloodGroup,
          medicalConditions: medicalConditions,
          name:name,
        ),
      ),
    );
    if (result != null) {
      _fetchMedicalInfo(); // Refresh after editing
    }
  }

  void _navigateBack() {
    HapticFeedback.lightImpact();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: const Color(0xFFCD1C18),
                ),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: CustomScrollView(
                    slivers: [
                      // Scrollable header section
                      SliverToBoxAdapter(
                        child: Container(
                          margin: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFCD1C18), Color(0xFFE53935)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFCD1C18).withOpacity(0.3),
                                blurRadius: 15.r,
                                spreadRadius: 1.r,
                                offset: Offset(0, 8.h),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Header Row with ambulance-style back button
                              Container(
                                padding: EdgeInsets.all(20.w),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: _navigateBack,
                                      child: Container(
                                        width: 36.w,
                                        height: 36.w,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8.r),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.arrow_back_ios_new,
                                            color: Colors.white,
                                            size: 18.sp,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: Text(
                                        "Medical Information",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    GestureDetector(
                                      onTap: _navigateToEditScreen,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16.w, vertical: 8.h),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20.r),
                                        ),
                                        child: Text(
                                          "EDIT",
                                          style: TextStyle(
                                            color: const Color(0xFFCD1C18),
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Profile Section
                              Container(
                                padding: EdgeInsets.only(
                                  left: 20.w,
                                  right: 20.w,
                                  bottom: 20.w,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(3.w),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 2.w,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 35.r,
                                        backgroundImage: AssetImage('assets/profile.png'),
                                      ),
                                    ),
                                    SizedBox(width: 16.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name.isEmpty ? "User" : name,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 22.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12.w, vertical: 4.h),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(15.r),
                                            ),
                                            child: Text(
                                              user?.email ?? "No Email",
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.9),
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Medical Information Cards - Now scrollable
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // Personal Details Section
                            // Personal Details Section
_buildSectionCard(
  title: "Personal Details",
  icon: Icons.person_rounded,
  children: [
    _buildInfoTile(
      Icons.badge_rounded,
      "Name",
      name.isEmpty ? "Not specified" : name,
      const Color(0xFF3F51B5), // Indigo shade for name
    ),
    _buildInfoTile(
      Icons.cake_rounded,
      "Age",
      age.isEmpty ? "Not specified" : "$age years",
      const Color(0xFF2196F3),
    ),
    _buildInfoTile(
      Icons.calendar_today_rounded,
      "Date of Birth",
      dob.isEmpty ? "Not specified" : dob,
      const Color(0xFF4CAF50),
    ),
  ],
),


                            SizedBox(height: 16.h),

                            // Emergency Contact Section
                            _buildInfoTile(
                              Icons.phone_rounded,
                              "Emergency Numbers",
                              emergencyNumbers.isEmpty ? "Not specified" : emergencyNumbers.join(", "),
                              const Color(0xFFFF9800),
                            ),


                            SizedBox(height: 16.h),

                            // Medical Information Section
                            _buildSectionCard(
                              title: "Medical Information",
                              icon: Icons.medical_services_rounded,
                              children: [
                                _buildInfoTile(
                                  Icons.bloodtype_rounded,
                                  "Blood Group",
                                  bloodGroup.isEmpty ? "Not specified" : bloodGroup,
                                  const Color(0xFFE91E63),
                                ),
                                _buildInfoTile(
                                  Icons.local_hospital_rounded,
                                  "Medical Conditions",
                                  medicalConditions.isEmpty
                                      ? "None specified"
                                      : medicalConditions,
                                  const Color(0xFF9C27B0),
                                  isLarge: true,
                                ),
                              ],
                            ),

                            SizedBox(height: 100.h), // Space for bottom navigation
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCD1C18).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFFCD1C18),
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          
          // Section Content
          Padding(
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              bottom: 20.w,
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String title,
    String value,
    Color color, {
    bool isLarge = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isLarge ? 14.sp : 16.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                    height: isLarge ? 1.4.h : 1.2.h,
                  ),
                  maxLines: isLarge ? null : 1,
                  overflow: isLarge ? null : TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}