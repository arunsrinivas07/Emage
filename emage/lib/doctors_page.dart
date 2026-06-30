import 'package:flutter/services.dart';

import 'ambulance_page.dart';
import 'find a donor.dart';
import 'home_page.dart';
import 'package:flutter/material.dart';
import 'hospitals_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'widgets/navigation.dart';

class DoctorPage extends StatefulWidget {
  const DoctorPage({super.key});

  @override
  State<DoctorPage> createState() => _DoctorPageState();
}

class _DoctorPageState extends State<DoctorPage> {
  String? selectedCity;
  String? selectedDoctorType;
  List<Doctor> allDoctors = [];
  List<Doctor> filteredDoctors = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDoctors();
  }

  // Fetch doctors from Firebase
  Future<void> fetchDoctors() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final QuerySnapshot querySnapshot = 
          await FirebaseFirestore.instance.collection('doctors').get();
          
      final List<Doctor> loadedDoctors = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Doctor(
          name: data['name'] ?? '',
          specialist: data['specialist'] ?? '',
          phoneNumber: data['phoneNumber'] ?? '',
          location: data['location'] ?? '',
          address: data['address'] ?? '',
          experience: data['experience'] ?? '',
          rating: (data['rating'] ?? 0.0).toDouble(),
          about: data['about'] ?? '',
        );
      }).toList();
      
      setState(() {
        allDoctors = loadedDoctors;
        filteredDoctors = List.from(allDoctors);
        isLoading = false;
      });
    } catch (error) {
      print('Error fetching doctors: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterDoctors() {
    setState(() {
      filteredDoctors = allDoctors.where((doctor) {
        bool matchesCity =
            selectedCity == null || doctor.location == selectedCity;
        bool matchesType = selectedDoctorType == null ||
            doctor.specialist == selectedDoctorType;
        return matchesCity && matchesType;
      }).toList();
    });
  }

  // Get unique cities from doctor data for dropdown
  List<String> getUniqueCities() {
    final Set<String> cities = allDoctors.map((doctor) => doctor.location).toSet();
    return cities.toList();
  }

  // Get unique specialties from doctor data for dropdown
  List<String> getUniqueSpecialties() {
    final Set<String> specialties = allDoctors.map((doctor) => doctor.specialist).toSet();
    return specialties.toList();
  }

  // Navigation to different pages
  
  int _currentIndex = 1; // Default to Hospitals tab (index 0)

  // Navigation to different pages
  void _navigateToPage(int index) {
    if (index == _currentIndex) return;

    HapticFeedback.lightImpact();
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HospitalsPage()),
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
              builder: (context) => const AmbulanceScreen()),
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
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main content container with modern styling
                    Container(
                      margin: EdgeInsets.all(16.w),
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 15.r,
                            spreadRadius: 1.r,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title section
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCD1C18).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(
                                  Icons.medical_services_outlined,
                                  color: Color(0xFFCD1C18),
                                  size: 24.sp,
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Find Your Doctor',
                                      style: TextStyle(
                                        fontSize: 22.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      'Search for specialists in your area and book appointments',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.grey.shade600,
                                        height: 1.3.h,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 24.h),
                          
                          // Search filters
                          _buildModernDropdown(
                            hint: 'Select Your City',
                            value: selectedCity,
                            onChanged: (value) {
                              setState(() {
                                selectedCity = value;
                              });
                            },
                            items: getUniqueCities(),
                            icon: Icons.location_on,
                          ),
                          
                          SizedBox(height: 16.h),
                          
                          _buildModernDropdown(
                            hint: 'Select Doctor Specialty',
                            value: selectedDoctorType,
                            onChanged: (value) {
                              setState(() {
                                selectedDoctorType = value;
                              });
                            },
                            items: getUniqueSpecialties(),
                            icon: Icons.medical_services,
                          ),
                          
                          SizedBox(height: 24.h),
                          
                          _buildModernSearchButton(),
                        ],
                      ),
                    ),
                    
                    // Results section
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Available Doctors',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              Spacer(),
                             if (filteredDoctors.isNotEmpty)
  Text(
    '${filteredDoctors.length} found',
    style: TextStyle(
      fontSize: 14.sp,
      color: Colors.grey.shade600,
    ),
  ),

                            ],
                          ),
                          SizedBox(height: 16.h),
                          
                          // Doctor list
                          isLoading
                              ? Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(40.h),
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFCD1C18),
                                      strokeWidth: 3.w,
                                    ),
                                  ),
                                )
                              : filteredDoctors.isEmpty
                                  ? _buildEmptyState()
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: filteredDoctors.length,
                                      separatorBuilder: (context, index) =>
                                          SizedBox(height: 12.h),
                                      itemBuilder: (context, index) {
                                        return _buildModernDoctorCard(filteredDoctors[index]);
                                      },
                                    ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
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
                color:const Color(0xFFCD1C18),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Doctors',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFCD1C18).withOpacity(0.3),
                width: 2.w,
              ),
            ),
            child: CircleAvatar(
              radius: 20.r,
              backgroundImage: AssetImage('assets/profile.png'),
            ),
          ),
        ],
      ),
    );
  }
Widget _buildModernDropdown({
  required String hint,
  required String? value,
  required Function(String?) onChanged,
  required List<String> items,
  required IconData icon,
}) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14.r),
      border: Border.all(
        color: Colors.grey.shade300,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      children: [
        Icon(
          icon,
          color:Colors.grey.shade500, // brand color
          size: 20.sp,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              borderRadius: BorderRadius.circular(12.r), // rounded popup
              dropdownColor: Colors.white, // modern light background
              isExpanded: true,
              hint: Text(
                hint,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              value: value,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.grey.shade600,
                size: 22.sp,
              ),
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    ),
  );
}


  Widget _buildModernSearchButton() {
    return SizedBox(
      width: double.infinity,
      height: 55.h,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          filterDoctors();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFCD1C18),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          shadowColor: const Color(0xFFCD1C18).withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'Search Doctors',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(40.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 40.sp,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'No doctors found',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Try adjusting your search filters',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDoctorCard(Doctor doctor) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12.r,
            spreadRadius: 1.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // Doctor image
          Container(
            // width: 60.w,
            // height: 60.h,
            // decoration: BoxDecoration(
            //   gradient: LinearGradient(
            //     colors: [
            //       Color(0xFFCD1C18),
            //       Color(0xFFE53935),
            //     ],
            //     begin: Alignment.topLeft,
            //     end: Alignment.bottomRight,
            //   ),
            //   borderRadius: BorderRadius.circular(16.r),
            // ),
            child: Center(
              child: Image.asset(
                "assets/doctorpng.png",
                width: 60.w,
                height: 60.h,
                //color: Colors.white,
              ),
            ),
          ),
          
          SizedBox(width: 16.w),
          
          // Doctor info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
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
                      Icons.medical_services_outlined,
                      color: Color(0xFF2DD4BF),
                      size: 14.sp,
                    ),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Text(
                        doctor.specialist,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 2.h),
                
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: Colors.orange.shade400,
                      size: 14.sp,
                    ),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Text(
                        doctor.location,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 8.h),
                
                // Rating
                Row(
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < doctor.rating.floor()
                              ? Icons.star_rounded
                              : (index < doctor.rating ? Icons.star_half_rounded : Icons.star_outline_rounded),
                          color: Colors.amber.shade500,
                          size: 16.sp,
                        );
                      }),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '(${doctor.rating})',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Book button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DoctorDetailsPage(doctor: doctor),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFCD1C18),
                    Color(0xFFE53935),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFCD1C18).withOpacity(0.3),
                    blurRadius: 8.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Text(
                'Book',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DoctorDetailsPage extends StatelessWidget {
  final Doctor doctor;

  const DoctorDetailsPage({super.key, required this.doctor});

  // Function to make a phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $launchUri';
    }
  }

  // Function to send a message
  Future<void> _sendMessage(BuildContext context, String phoneNumber) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: {'body': 'Hello Dr. ${doctor.name}, I would like to schedule an appointment.'},
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open messaging app'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            _buildModernHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildDoctorProfile(context),
                    _buildDoctorInfo(),
                    _buildAboutSection(),
                    _buildModernBookingButton(context),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
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
              Navigator.pop(context);
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
                'Doctor Details',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFCD1C18).withOpacity(0.3),
                width: 2.w,
              ),
            ),
            child: CircleAvatar(
              radius: 20.r,
              backgroundImage: AssetImage('assets/profile.png'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorProfile(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15.r,
            spreadRadius: 1.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 100.w,
            height: 100.h,
            // decoration: BoxDecoration(
            //   gradient: LinearGradient(
            //     colors: [
            //       Color(0xFFCD1C18),
            //       Color(0xFFE53935),
            //     ],
            //     begin: Alignment.topLeft,
            //     end: Alignment.bottomRight,
            //   ),
            //   // borderRadius: BorderRadius.circular(50.r),
            //   // boxShadow: [
            //   //   BoxShadow(
            //   //     color: Color(0xFFCD1C18).withOpacity(0.3),
            //   //     blurRadius: 20.r,
            //   //     spreadRadius: 1.r,
            //   //     offset: Offset(0, 8.h),
            //   //   ),
            //   // ],
            // ),
            child: Center(
              child: Center(
              child: Image.asset(
                "assets/doctorpng.png",
                width: 100.w,
                height: 100.h,
                //color: Colors.white,
              ),
            ),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            doctor.name,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            doctor.specialist,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRatingStars(doctor.rating),
              SizedBox(width: 8.w),
              Text(
                '(${doctor.rating})',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildModernContactButton(
                context: context,
                icon: Icons.phone_rounded,
                color: Colors.green,
                text: 'Call',
                onTap: () => _makePhoneCall(doctor.phoneNumber),
              ),
              _buildModernContactButton(
                context: context,
                icon: Icons.message_rounded,
                color: Colors.blue,
                text: 'Message',
                onTap: () => _sendMessage(context, doctor.phoneNumber),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star_rounded
              : (index < rating ? Icons.star_half_rounded : Icons.star_outline_rounded),
          color: Colors.amber.shade500,
          size: 22.sp,
        );
      }),
    );
  }

  Widget _buildModernContactButton({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1.w,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 18.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorInfo() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15.r,
            spreadRadius: 1.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Doctor Information',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 16.h),
          _buildModernInfoItem(
            icon: Icons.location_on_rounded,
            title: 'Address',
            subtitle: doctor.address,
            color: Colors.orange,
          ),
          SizedBox(height: 16.h),
          _buildModernInfoItem(
            icon: Icons.phone_rounded,
            title: 'Phone',
            subtitle: doctor.phoneNumber,
            color: Colors.red,
          ),
          SizedBox(height: 16.h),
          _buildModernInfoItem(
            icon: Icons.access_time_rounded,
            title: 'Experience',
            subtitle: doctor.experience,
            color: Colors.blue,
          ),
          SizedBox(height: 16.h),
          _buildModernInfoItem(
            icon: Icons.location_city_rounded,
            title: 'Location',
            subtitle: doctor.location,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15.sp,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15.r,
            spreadRadius: 1.r,
            offset: Offset(0, 4.h),
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
                  color: Color(0xFF2DD4BF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF2DD4BF),
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'About Doctor',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            doctor.about,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 15.sp,
              height: 1.6.h,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBookingButton(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        width: double.infinity,
        height: 60.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFCD1C18),
              Color(0xFFE53935),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFCD1C18).withOpacity(0.4),
              blurRadius: 15.r,
              spreadRadius: 1.r,
              offset: Offset(0, 6.h),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  title: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Color(0xFFCD1C18).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          color: Color(0xFFCD1C18),
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Book Appointment',
                        style: TextStyle(fontSize: 18.sp),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirm booking appointment with Dr. ${doctor.name}?',
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Specialist: ${doctor.specialist}',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              'Location: ${doctor.location}',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFCD1C18), Color(0xFFE53935)],
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Colors.white),
                                  SizedBox(width: 8.w),
                                  Text('Appointment with Dr. ${doctor.name} booked successfully!'),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Confirm Booking',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Book Your Doctor',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Doctor class definition
class Doctor {
  final String name;
  final String specialist;
  final String phoneNumber;
  final String location;
  final String address;
  final String experience;
  final double rating;
  final String about;

  Doctor({
    required this.name,
    required this.specialist,
    required this.phoneNumber,
    required this.location,
    required this.address,
    required this.experience,
    required this.rating,
    required this.about,
  });
}