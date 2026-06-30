import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'donorlist.dart';
import 'become a donor.dart';
import 'doctors_page.dart';
import 'ambulance_page.dart';
import 'home_page.dart';
import 'hospitals_page.dart';
import 'widgets/navigation.dart';

class FindaDonor extends StatefulWidget {
  const FindaDonor({super.key});

  @override
  _FindADonorScreenState createState() => _FindADonorScreenState();
}

class _FindADonorScreenState extends State<FindaDonor> {
  TextEditingController locationController = TextEditingController();
  String selectedBloodGroup = "";
  int _currentIndex = 3;

  void _navigateToPage(int index) {
    if (index == _currentIndex) return;
    
    HapticFeedback.lightImpact();
    setState(() {
      _currentIndex = index;
    });
    
    switch (index) {
      case 0:
        Navigator.push(context, MaterialPageRoute(builder: (context) => const HospitalsPage()));
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (context) => DoctorPage()));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (context) => const HomePage()));
        break;
      case 4:
        Navigator.push(context, MaterialPageRoute(builder: (context) => const AmbulanceScreen()));
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
          // Header - same structure as DoctorPage
          _buildHeader(),
          
          // Main content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Blood Group Selection Section
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.w),
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
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCD1C18).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  "🩸",
                                  style: TextStyle(fontSize: 16.sp),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                "Select Blood Group",
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20.h),
                          Wrap(
                            spacing: 12.w,
                            runSpacing: 12.h,
                            alignment: WrapAlignment.center,
                            children: ["A+", "O+", "B+", "AB+", "A-", "O-", "B-", "AB-"].map((bloodType) {
                              return BloodGroupButton(
                                bloodType: bloodType,
                                isSelected: selectedBloodGroup == bloodType,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    selectedBloodGroup = bloodType;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Location Input Section
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.w),
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
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCD1C18).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  color: const Color(0xFFCD1C18),
                                  size: 20.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                "Enter Location",
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1.5.w,
                              ),
                            ),
                            child: TextField(
                              controller: locationController,
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: Colors.grey.shade800,
                              ),
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.grey.shade400,
                                  size: 20.sp,
                                ),
                                hintText: "Enter your location or area",
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 14.sp,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 14.h,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Action Buttons Section
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.w),
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
                        children: [
                          // Search Button
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DonorList(
                                    bloodGroup: selectedBloodGroup,
                                    location: locationController.text.trim(),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
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
                                    color: const Color(0xFFCD1C18).withOpacity(0.4),
                                    blurRadius: 12.r,
                                    offset: Offset(0, 4.h),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_rounded,
                                    color: Colors.white,
                                    size: 24.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    "Search Donors",
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 12.h),

                          // All Donors Button
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DonorList(),
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              height: 50.h,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: const Color(0xFFCD1C18),
                                  width: 2.w,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8.r,
                                    offset: Offset(0, 2.h),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline_rounded,
                                    color: const Color(0xFFCD1C18),
                                    size: 24.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    "View All Donors",
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: const Color(0xFFCD1C18),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ),
          // Navigation widget placed here (same as DoctorPage)
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
    // Remove bottomNavigationBar property completely
  );
}

  Widget _buildHeader() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
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
                Icons.arrow_back_ios_rounded,
                size: 18.sp,
                color: const Color(0xFFCD1C18),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Find Blood Donor',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),
          // Become a Donor Button
          GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BecomeADonor()),
              );
              setState(() {});
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    "Donor",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BloodGroupButton extends StatelessWidget {
  final String bloodType;
  final bool isSelected;
  final VoidCallback onTap;

  const BloodGroupButton({
    super.key,
    required this.bloodType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFCD1C18), Color(0xFFE53935)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected 
                ? Colors.transparent 
                : Colors.grey.shade200,
            width: 1.5.w,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFFCD1C18).withOpacity(0.3),
                blurRadius: 8.r,
                offset: Offset(0, 2.h),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4.r,
                offset: Offset(0, 1.h),
              ),
          ],
        ),
        child: Text(
          bloodType,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}