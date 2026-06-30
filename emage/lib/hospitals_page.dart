import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'home_page.dart';
import 'find a donor.dart';
import 'doctors_page.dart';
import 'ambulance_page.dart' as ambulance;
import 'widgets/navigation.dart';
import 'profile_page.dart';

class HospitalsPage extends StatefulWidget {
  const HospitalsPage({super.key});

  @override
  State<HospitalsPage> createState() => _HospitalsPageState();
}

class _HospitalsPageState extends State<HospitalsPage> {
  int _currentIndex = 0; // Default to Hospitals tab (index 0)

  // Navigation to different pages
  void _navigateToPage(int index) {
    if (index == _currentIndex) return;

    HapticFeedback.lightImpact();
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DoctorPage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FindaDonor()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const ambulance.AmbulanceScreen()),
        );
        break;
    }
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
                  // Header matching HomePage style
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
                              MaterialPageRoute(builder: (context) => HomePage()),
                            );
                          },
                          child: Container(
  padding: EdgeInsets.all(8.w),
  decoration: BoxDecoration(
    color: const Color(0xFFCD1C18).withOpacity(0.1),
    borderRadius: BorderRadius.circular(8.r),
  ),
  child: Icon(
    Icons.arrow_back_ios_new, // better centered
    color: const Color(0xFFCD1C18),
    size: 18.sp,
  ),
),

                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "HOSPITALS",
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              Text(
                                "Find nearby medical facilities",
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ProfilePage()),
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

                  // Title section matching HomePage style
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      "Nearby Hospitals",
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Hospital list with modern styling
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      children: [
                        HospitalCard(
                          name: "Apollo Hospital",
                          location: "Greams Road, Chennai",
                          doctorCount: "125",
                          type: "Private",
                          doctors: [
                            Doctor("Dr. Vikram Sharma", "Cardiology", 15),
                            Doctor("Dr. Ananya Reddy", "Neurology", 12),
                            Doctor("Dr. Rajesh Patel", "Orthopedics", 18),
                            Doctor("Dr. Neha Verma", "Oncology", 10),
                            Doctor("Dr. Karthik Iyer", "Gastroenterology", 8),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        HospitalCard(
                          name: "Government Hospital",
                          location: "Park Town, Chennai",
                          doctorCount: "200",
                          type: "Government",
                          doctors: [
                            Doctor("Dr. Manoj Kumar", "General Medicine", 20),
                            Doctor("Dr. Priya Sundaram", "Pediatrics", 15),
                            Doctor("Dr. Sanjay Verma", "General Surgery", 17),
                            Doctor("Dr. Lakshmi Rao", "Gynecology", 12),
                            Doctor("Dr. Ramesh Babu", "Pulmonology", 14),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        HospitalCard(
                          name: "Fortis Malar Hospital",
                          location: "Adyar, Chennai",
                          doctorCount: "85",
                          type: "Private",
                          doctors: [
                            Doctor("Dr. Suresh Menon", "Cardiac Surgery", 22),
                            Doctor("Dr. Aarthi Ganesh", "Dermatology", 9),
                            Doctor("Dr. Vijay Nair", "Nephrology", 14),
                            Doctor("Dr. Divya Krishnan", "Endocrinology", 11),
                            Doctor("Dr. Prakash Kumar", "Urology", 13),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        HospitalCard(
                          name: "Rajiv Gandhi Govt Hospital",
                          location: "Chennai Central, Chennai",
                          doctorCount: "175",
                          type: "Government",
                          doctors: [
                            Doctor("Dr. Kavitha Rajan", "Critical Care", 16),
                            Doctor("Dr. Senthil Kumar", "Neurosurgery", 19),
                            Doctor("Dr. Meena Sundari", "Ophthalmology", 13),
                            Doctor("Dr. Gopal Rao", "Psychiatry", 11),
                            Doctor("Dr. Venkat Raman", "Hematology", 15),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        HospitalCard(
                          name: "MIOT International",
                          location: "Manapakkam, Chennai",
                          doctorCount: "110",
                          type: "Private",
                          doctors: [
                            Doctor("Dr. Arjun Sharma", "Joint Replacement", 17),
                            Doctor("Dr. Sharmila Devi", "Rheumatology", 12),
                            Doctor("Dr. Venkatesh S", "Plastic Surgery", 14),
                            Doctor("Dr. Anjana Murthy", "Diabetology", 9),
                            Doctor("Dr. Rahul Menon", "Sports Medicine", 11),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        HospitalCard(
                          name: "Kauvery Hospital",
                          location: "Alwarpet, Chennai",
                          doctorCount: "95",
                          type: "Private",
                          doctors: [
                            Doctor("Dr. Balaji Krishnan", "Interventional Cardiology", 20),
                            Doctor("Dr. Sudha Raman", "Obstetrics", 16),
                            Doctor("Dr. Mohan Raj", "ENT", 13),
                            Doctor("Dr. Pooja Iyer", "Internal Medicine", 8),
                            Doctor("Dr. Gautam Reddy", "Oncosurgery", 15),
                          ],
                        ),
                        SizedBox(height: 20.h), // Extra space at bottom
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Navigation with proper alignment
            Navigation(
              currentIndex: _currentIndex,
              onTap: _navigateToPage,
              onEmergencyTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
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

class Doctor {
  final String name;
  final String specialization;
  final int yearsOfExperience;

  Doctor(this.name, this.specialization, this.yearsOfExperience);
}

class HospitalCard extends StatelessWidget {
  final String name;
  final String location;
  final String doctorCount;
  final String type;
  final List<Doctor> doctors;

  const HospitalCard({
    super.key,
    required this.name,
    required this.location,
    required this.doctorCount,
    required this.type,
    required this.doctors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Container(
            width: 50.w,
            height: 50.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: type == "Government"
                    ? [Color(0xFF3F51B5), Color(0xFF303F9F)]
                    : [Color(0xFFCD1C18), Color(0xFFE53935)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: (type == "Government" ? Color(0xFF3F51B5) : Color(0xFFCD1C18))
                      .withOpacity(0.3),
                  blurRadius: 8.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                "assets/hospitals.png",
                width: 24.w,
                height: 24.h,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.orange,
                      size: 14.sp,
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: Colors.blue,
                      size: 14.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      "$doctorCount Doctors",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: type == "Government" 
                            ? Colors.green.withOpacity(0.1)
                            : Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: type == "Government" 
                              ? Colors.green.shade700
                              : Colors.purple.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showHospitalDetails(context, name, location, doctorCount, type, doctors);
            },
            child: Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: type == "Government"
                      ? [Color(0xFF3F51B5), Color(0xFF303F9F)]
                      : [Color(0xFFCD1C18), Color(0xFFE53935)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: (type == "Government" ? Color(0xFF3F51B5) : Color(0xFFCD1C18))
                        .withOpacity(0.3),
                    blurRadius: 8.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 18.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHospitalDetails(BuildContext context, String name, String location,
      String doctorCount, String type, List<Doctor> doctors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: type == "Government"
                            ? [Colors.green.shade100, Colors.green.shade50]
                            : [Colors.purple.shade100, Colors.purple.shade50],
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        color: type == "Government"
                            ? Colors.green.shade800
                            : Colors.purple.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.orange, size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      location,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              
              Row(
                children: [
                  Icon(Icons.people, color: Colors.blue, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    "$doctorCount Doctors working",
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              
              Text(
                "Facilities Available",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 8.h),
              
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _buildFacilityChip("Emergency"),
                  _buildFacilityChip("ICU"),
                  _buildFacilityChip("Lab Tests"),
                  _buildFacilityChip("Surgery"),
                  _buildFacilityChip("Pharmacy"),
                  _buildFacilityChip("X-Ray"),
                ],
              ),
              SizedBox(height: 16.h),
              
              Text(
                "Doctors",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 8.h),
              
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    return _buildDoctorListItem(
                      doctors[index].name,
                      doctors[index].specialization,
                      doctors[index].yearsOfExperience,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFacilityChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12.sp),
      ),
    );
  }

  Widget _buildDoctorListItem(String name, String specialization, int yearsOfExperience) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Icon(Icons.person, color: Colors.blue.shade800, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                  ),
                ),
                Text(
                  specialization,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              "$yearsOfExperience yrs exp",
              style: TextStyle(
                color: Colors.green.shade800,
                fontWeight: FontWeight.w600,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}