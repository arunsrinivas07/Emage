import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'donorlist.dart';
import 'profile_page.dart';
import 'services/location_service.dart';

class BecomeADonor extends StatefulWidget {
  const BecomeADonor({super.key});
  
  @override
  _BecomeADonorState createState() => _BecomeADonorState();
}

class _BecomeADonorState extends State<BecomeADonor> {
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  String? selectedBloodGroup;
  String _currentLocationArea = "Unknown location"; 
  String _name = "DIVYANAND";
  bool _isLoading = false;
  Map<String, dynamic> userData = {};
  
List<Map<String, dynamic>> donorData = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadLocation();

  }

  Future<void> _loadUserData() async {
    if (user == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (userDoc.exists) {
        userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _name = userData['name'] ?? "DIVYANAND";
          // Pre-fill fields with user data if available
          nameController.text = userData['name'] ?? '';
          emailController.text = userData['email'] ?? '';
          phoneController.text = userData['phone'] ?? '';
          selectedBloodGroup = userData['bloodGroup'];
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  Future<void> _submitDonorForm() async {
    if (nameController.text.isEmpty ||
        locationController.text.isEmpty ||
        phoneController.text.isEmpty ||
        selectedBloodGroup == null) {
      
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8.w),
              Text('Please fill all required fields'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

     try {
      donorData.add({
      "name": nameController?.text ?? '',
      "location": locationController?.text ?? '',
      "phone": phoneController?.text ?? '',
      "email": emailController?.text ?? '',
      "bloodType": selectedBloodGroup ?? 'Unknown',
    });


      // Optional: Save to Firestore as well
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('donors')
            .doc(user!.uid)
            .set({
          "name": nameController.text,
          "location": locationController.text,
          "phone": phoneController.text,
          "email": emailController.text,
          "bloodType": selectedBloodGroup!,
          "userId": user!.uid,
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8.w),
              Text('Thank you for registering as a donor!'),
            ],
          ),
          backgroundColor: const Color(0xFFCD1C18),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );

      // Delay to show success message
      await Future.delayed(const Duration(seconds: 1));
      Navigator.pop(context);

    } catch (e) {
      print("Error submitting donor form: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error registering. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
              child: SingleChildScrollView(
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
          Navigator.pop(context);

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
              Icons.arrow_back_ios_new, // 👈 better centered version
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
                              color: Color(0xFFCD1C18),
                              size: 18.sp,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Become A Donor",
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

                    // Title section
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Blood Donor Registration",
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            "Register as a blood donor and help save lives in your community.",
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

                    // Form section
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.w),
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
                          Text(
                            "Personal Information",
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(height: 20.h),
                          
                          _buildModernTextField(
                            nameController, 
                            "Full Name", 
                            Icons.person_outline,
                            isRequired: true,
                          ),
                          SizedBox(height: 16.h),
                          
                          _buildModernTextField(
                            locationController, 
                            "Location", 
                            Icons.location_on_outlined,
                            isRequired: true,
                          ),
                          SizedBox(height: 16.h),
                          
                          _buildModernTextField(
                            phoneController, 
                            "Phone Number", 
                            Icons.phone_outlined,
                            isRequired: true,
                            keyboardType: TextInputType.phone,
                          ),
                          SizedBox(height: 16.h),
                          
                          _buildModernTextField(
                            emailController, 
                            "Email (Optional)", 
                            Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: 16.h),
                          
                          _buildModernDropdown(),
                          SizedBox(height: 24.h),
                          
                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            height: 50.h,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitDonorForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFCD1C18),
                                disabledBackgroundColor: Colors.grey.shade400,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 20.w,
                                      height: 20.h,
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      "Register as Donor",
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField(
    TextEditingController controller,
    String hintText,
    IconData icon, {
    bool isRequired = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              hintText,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            if (isRequired) ...[
              SizedBox(width: 4.w),
              Text(
                "*",
                style: TextStyle(
                  color: const Color(0xFFCD1C18),
                  fontSize: 14.sp,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1.w,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade800,
            ),
            decoration: InputDecoration(
              prefixIcon: Container(
                margin: EdgeInsets.all(12.w),
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFCD1C18).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFCD1C18),
                  size: 20.sp,
                ),
              ),
              hintText: "Enter $hintText",
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14.sp,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
            ),
            onTap: () => HapticFeedback.lightImpact(),
          ),
        ),
      ],
    );
  }

  Widget _buildModernDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Blood Group",
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(width: 4.w),
            Text(
              "*",
              style: TextStyle(
                color: const Color(0xFFCD1C18),
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8.r,
                offset: Offset(0, 3.h),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                margin: EdgeInsets.only(right: 12.w),
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFCD1C18).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.bloodtype_outlined,
                  color: const Color(0xFFCD1C18),
                  size: 20.sp,
                ),
              ),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    borderRadius: BorderRadius.circular(12.r),
                    dropdownColor: Colors.white,
                    isExpanded: true,
                    hint: Text(
                      "Select your blood group",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    value: selectedBloodGroup,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade600,
                      size: 22.sp,
                    ),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                    items: ["A+", "O+", "B+", "AB+", "A-", "O-", "B-", "AB-"]
                        .map((bloodType) {
                      return DropdownMenuItem<String>(
                        value: bloodType,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 6.h),
                          child: Row(
                            children: [
                              // Container(
                              //   width: 28.w,
                              //   height: 28.h,
                              //   decoration: BoxDecoration(
                              //     color: const Color(0xFFCD1C18),
                              //     borderRadius: BorderRadius.circular(8.r),
                              //   ),
                              //   child: Center(
                              //     child: Text(
                              //       bloodType,
                              //       style: TextStyle(
                              //         color: Colors.white,
                              //         fontSize: 11.sp,
                              //         fontWeight: FontWeight.bold,
                              //       ),
                              //     ),
                              //   ),
                              // ),
                              SizedBox(width: 12.w),
                              Text(
                                bloodType,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      setState(() => selectedBloodGroup = value);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }
}