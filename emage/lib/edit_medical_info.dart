import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditMedicalInfoScreen extends StatefulWidget {
  final String age;
  final String dob;
  final List<String> emergencyNumbers;
  final String bloodGroup;
  final String medicalConditions;
  final String name;

  const EditMedicalInfoScreen({
    super.key,
    required this.age,
    required this.dob,
    required this.emergencyNumbers,
    required this.bloodGroup,
    required this.medicalConditions,
    required this.name,
  });

  @override
  _EditMedicalInfoScreenState createState() => _EditMedicalInfoScreenState();
}

class _EditMedicalInfoScreenState extends State<EditMedicalInfoScreen>
    with TickerProviderStateMixin {
  late TextEditingController nameController;
  late TextEditingController medicalConditionsController;
  
  List<TextEditingController> emergencyNumberControllers = [];
  DateTime? selectedDate;
  String selectedBloodGroup = '';
  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeControllers();
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

  void _initializeControllers() {
    nameController = TextEditingController(text: widget.name);
    medicalConditionsController = TextEditingController(text: widget.medicalConditions);
    
    // Initialize emergency number controllers
    if (widget.emergencyNumbers.isEmpty) {
      emergencyNumberControllers.add(TextEditingController());
    } else {
      for (String number in widget.emergencyNumbers) {
        emergencyNumberControllers.add(TextEditingController(text: number));
      }
    }
    
    // Validate blood group
    if (bloodGroups.contains(widget.bloodGroup)) {
      selectedBloodGroup = widget.bloodGroup;
    } else {
      selectedBloodGroup = '';
    }

    // Parse existing date
    if (widget.dob.isNotEmpty) {
      try {
        List<String> parts = widget.dob.split("-");
        selectedDate = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      } catch (e) {
        selectedDate = null;
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    nameController.dispose();
    medicalConditionsController.dispose();
    for (var controller in emergencyNumberControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addEmergencyNumber() {
    if (emergencyNumberControllers.length < 5) {
      setState(() {
        emergencyNumberControllers.add(TextEditingController());
      });
    }
  }

  void _removeEmergencyNumber(int index) {
    if (emergencyNumberControllers.length > 1) {
      setState(() {
        emergencyNumberControllers[index].dispose();
        emergencyNumberControllers.removeAt(index);
      });
    }
  }

  bool _validateEmergencyNumbers() {
    for (var controller in emergencyNumberControllers) {
      String number = controller.text.trim();
      if (number.isNotEmpty && number.length != 10) {
        return false;
      }
      if (number.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(number)) {
        return false;
      }
    }
    return true;
  }

  Future<void> _selectDate() async {
    HapticFeedback.lightImpact();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFFCD1C18),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFCD1C18),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _saveInfo() async {
    // Validate emergency numbers
    if (!_validateEmergencyNumbers()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency numbers must be exactly 10 digits'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        String dobString = '';
        if (selectedDate != null) {
          dobString = DateFormat('dd-MM-yyyy').format(selectedDate!);
        }

        List<String> validEmergencyNumbers = emergencyNumberControllers
            .map((controller) => controller.text.trim())
            .where((number) => number.isNotEmpty)
            .toList();

        // Prepare data to save
        Map<String, dynamic> dataToSave = {
          'name': nameController.text.trim(),
          'dob': dobString,
          'emergencyNumbers': validEmergencyNumbers,
          'bloodGroup': selectedBloodGroup,
          'medicalConditions': medicalConditionsController.text.trim(),
        };

        // Save to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(dataToSave, SetOptions(merge: true));

        String updatedAge = _calculateAge(dobString);

        // Return updated data
        Navigator.pop(context, {
          'name': nameController.text.trim(),
          'age': updatedAge,
          'dob': dobString,
          'emergencyNumbers': validEmergencyNumbers,
          'bloodGroup': selectedBloodGroup,
          'medicalConditions': medicalConditionsController.text.trim(),
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving information: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
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

  String get formattedDate {
    if (selectedDate == null) return 'Select Date of Birth';
    return DateFormat('dd-MM-yyyy').format(selectedDate!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                // Header Section
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
                        // Header Row
                        Container(
                          padding: EdgeInsets.all(20.w),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.pop(context);
                                },
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
                                  "Edit Medical Information",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: 46.w),
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
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: EdgeInsets.all(3.w),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 2.w,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 35.r,
                                        backgroundImage: _selectedImage != null
                                            ? FileImage(_selectedImage!)
                                            : const AssetImage('assets/profile.png') as ImageProvider,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width: 24.w,
                                          height: 24.w,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFFCD1C18),
                                              width: 2.w,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.camera_alt,
                                            color: const Color(0xFFCD1C18),
                                            size: 12.sp,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Edit Profile",
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
                                        "Update your medical information",
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

                // Form Fields Section
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Personal Details Section
                      _buildSectionCard(
                        title: "Personal Details",  
                        icon: Icons.person_rounded,
                        children: [
                          _buildTextField(
                            "Name",
                            nameController,
                            Icons.person,
                            const Color(0xFF3F51B5),
                          ),
                          SizedBox(height: 16.h),
                          _buildDateField(),
                          SizedBox(height: 16.h),
                          _buildBloodGroupField(),
                        ],
                      ),

                      SizedBox(height: 16.h),

                      // Emergency Contact Section
                      _buildSectionCard(
                        title: "Emergency Contacts",
                        icon: Icons.emergency_rounded,
                        children: [
                          ...List.generate(emergencyNumberControllers.length, (index) {
                            return Container(
                              margin: EdgeInsets.only(bottom: 12.h),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      "Emergency Number ${index + 1}",
                                      emergencyNumberControllers[index],
                                      Icons.phone_rounded,
                                      const Color(0xFFFF9800),
                                      keyboardType: TextInputType.phone,
                                      hint: "10 digit phone number",
                                    ),
                                  ),
                                  if (emergencyNumberControllers.length > 1)
                                    GestureDetector(
                                      onTap: () => _removeEmergencyNumber(index),
                                      child: Container(
                                        margin: EdgeInsets.only(left: 8.w),
                                        padding: EdgeInsets.all(8.w),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8.r),
                                        ),
                                        child: Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.red,
                                          size: 20.sp,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                          if (emergencyNumberControllers.length < 5)
                            GestureDetector(
                              onTap: _addEmergencyNumber,
                              child: Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9800).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(
                                    color: const Color(0xFFFF9800).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline,
                                      color: const Color(0xFFFF9800),
                                      size: 20.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      "Add Another Emergency Number",
                                      style: TextStyle(
                                        color: const Color(0xFFFF9800),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: 16.h),

                      // Medical Information Section
                      _buildSectionCard(
                        title: "Medical Information",
                        icon: Icons.medical_services_rounded,
                        children: [
                          _buildTextField(
                            "Medical Conditions",
                            medicalConditionsController,
                            Icons.local_hospital_rounded,
                            const Color(0xFF9C27B0),
                            maxLines: 4,
                            hint: "Enter any medical conditions, allergies, or important medical notes...",
                          ),
                        ],
                      ),

                      SizedBox(height: 32.h),

                      // Save Button
                      Container(
                        width: double.infinity,
                        height: 56.h,
                        margin: EdgeInsets.symmetric(horizontal: 8.w),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFCD1C18),
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: const Color(0xFFCD1C18).withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                          onPressed: _isLoading ? null : _saveInfo,
                          child: _isLoading
                              ? SizedBox(
                                  width: 24.w,
                                  height: 24.w,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.save_rounded,
                                      size: 20.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      "SAVE CHANGES",
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      SizedBox(height: 32.h),
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

  Widget _buildDateField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: _selectDate,
          child: Container(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    color: const Color(0xFF4CAF50),
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "DATE OF BIRTH",
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4CAF50),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: selectedDate == null 
                              ? Colors.grey.shade600 
                              : Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: const Color(0xFF4CAF50),
                  size: 24.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBloodGroupField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE91E63).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFFE91E63).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.bloodtype_rounded,
                color: const Color(0xFFE91E63),
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "BLOOD GROUP",
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE91E63),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    // padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                    // decoration: BoxDecoration(
                    //   color: const Color(0xFFE91E63).withOpacity(0.1),
                    //   borderRadius: BorderRadius.circular(8.r),
                    //   // border: Border.all(
                    //   //   color: const Color(0xFFE91E63),
                    //   //   width: 1,
                    //   // ),
                    // ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedBloodGroup.isEmpty ? null : selectedBloodGroup,
                        hint: Text(
                          "Select Blood Group",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        isExpanded: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFFE91E63),
                          size: 24.sp,
                        ),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                        ),
                                            borderRadius: BorderRadius.circular(12.r),

                        dropdownColor: Colors.white,
                        items: bloodGroups.map((String bloodGroup) {
                          return DropdownMenuItem<String>(
                            value: bloodGroup,
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              child: Text(
                                bloodGroup,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            HapticFeedback.lightImpact();
                            setState(() {
                              selectedBloodGroup = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String title,
    TextEditingController controller,
    IconData icon,
    Color color, {
    int maxLines = 1,
    String hint = "",
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(16.w),
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
                  TextField(
                    controller: controller,
                    maxLines: maxLines,
                    keyboardType: keyboardType,
                    inputFormatters: keyboardType == TextInputType.phone
                        ? [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ]
                        : null,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: hint.isEmpty ? "Enter $title" : hint,
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16.sp,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}