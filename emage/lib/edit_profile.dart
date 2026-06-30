import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  File? _image;
  XFile? _xFile;
  Uint8List? _webImage;
  String? _currentImageUrl;
  bool _isLoading = false;
  bool _isSaving = false;
  double _uploadProgress = 0.0;
  bool _isUploading = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final picker = ImagePicker();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
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
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          nameController.text = userData['name'] ?? "";
          phoneController.text = userData['phone'] ?? "";

          if (userData.containsKey('profileImageUrl') &&
              userData['profileImageUrl'] != null) {
            setState(() {
              _currentImageUrl = userData['profileImageUrl'];
            });
          }
        } else {
          nameController.text = "";
          phoneController.text = "";
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading profile: $e"),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      HapticFeedback.lightImpact();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        setState(() {
          _xFile = pickedFile;
        });

        if (kIsWeb) {
          try {
            _webImage = await pickedFile.readAsBytes();
            if (_webImage!.length / 1024 > 1000) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Large image (${(_webImage!.length / 1024).toStringAsFixed(0)} KB) may take longer to upload",
                  ),
                  backgroundColor: const Color(0xFFFF9800),
                ),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error processing image: $e"),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          _image = File(pickedFile.path);
          final fileSize = await _image!.length();
          if (fileSize / 1024 > 1000) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Large image (${(fileSize / 1024).toStringAsFixed(0)} KB) may take longer to upload",
                ),
                backgroundColor: const Color(0xFFFF9800),
              ),
            );
          }
        }

        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error selecting image: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _uploadImageToFirebase() async {
    if (_xFile == null && _image == null && _webImage == null) {
      return null;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      String fileName = 'profile_${user!.uid}_${DateTime.now().millisecondsSinceEpoch}';
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(fileName);

      UploadTask uploadTask;
      Uint8List? imageBytes;

      if (kIsWeb && _webImage != null) {
        imageBytes = _webImage;
      } else if (!kIsWeb && _xFile != null) {
        imageBytes = await _xFile!.readAsBytes();
      } else if (!kIsWeb && _image != null) {
        imageBytes = await _image!.readAsBytes();
      }

      if (imageBytes == null) {
        throw Exception("Could not get image data");
      }

      uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        setState(() {
          _uploadProgress = progress;
        });
      });

      TaskSnapshot snapshot = await uploadTask.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Upload timed out. Please try again with a smaller image."),
              backgroundColor: Colors.red,
            ),
          );
          throw TimeoutException("Image upload timed out");
        },
      );

      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Upload failed: ${e.toString().substring(0, min(50, e.toString().length))}..."),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      return null;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _saveProfile(BuildContext context) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You need to be logged in to save profile"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate phone number
    String phone = phoneController.text.trim();
    if (phone.isNotEmpty && (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Phone number must be exactly 10 digits"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String? imageUrl = _currentImageUrl;

      if (_xFile != null || _image != null || _webImage != null) {
        imageUrl = await _uploadImageToFirebase();
        if (imageUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to upload image. Profile will be saved without new image."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      Map<String, dynamic> userData = {
        'name': nameController.text.trim(),
        'phone': phone,
        'email': user!.email,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (imageUrl != null) {
        userData['profileImageUrl'] = imageUrl;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set(userData, SetOptions(merge: true))
          .timeout(const Duration(seconds: 30));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating profile: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _navigateBack() {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
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
                                        "Edit Profile",
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

                              // Profile Image Section
                              Container(
                                padding: EdgeInsets.only(
                                  left: 20.w,
                                  right: 20.w,
                                  bottom: 20.w,
                                ),
                                child: Column(
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
                                              radius: 50.r,
                                              backgroundImage: _getProfileImage(),
                                              backgroundColor: Colors.grey.shade200,
                                            ),
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: Container(
                                                width: 32.w,
                                                height: 32.w,
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
                                                  size: 16.sp,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 12.h),
                                    if (_xFile != null)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12.w, vertical: 4.h),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(15.r),
                                        ),
                                        child: Text(
                                          "New image selected",
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    if (_isUploading)
                                      Container(
                                        margin: EdgeInsets.only(top: 8.h),
                                        padding: EdgeInsets.all(12.w),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10.r),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              "Uploading: ${(_uploadProgress * 100).toStringAsFixed(1)}%",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12.sp,
                                              ),
                                            ),
                                            SizedBox(height: 5.h),
                                            LinearProgressIndicator(
                                              value: _uploadProgress,
                                              backgroundColor: Colors.white.withOpacity(0.3),
                                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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
                                  "Full Name",
                                  nameController,
                                  Icons.badge_rounded,
                                  const Color(0xFF3F51B5),
                                ),
                                SizedBox(height: 16.h),
                                _buildTextField(
                                  "Phone Number",
                                  phoneController,
                                  Icons.phone_rounded,
                                  const Color(0xFF4CAF50),
                                  keyboardType: TextInputType.phone,
                                  hint: "10 digit phone number",
                                ),
                              ],
                            ),

                            SizedBox(height: 16.h),

                            // Account Information Section
                            _buildSectionCard(
                              title: "Account Information",
                              icon: Icons.account_circle_rounded,
                              children: [
                                _buildInfoTile(
                                  Icons.email_rounded,
                                  "Email Address",
                                  user?.email ?? "No email",
                                  const Color(0xFF2196F3),
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
                                onPressed: (_isSaving || _isUploading) ? null : () => _saveProfile(context),
                                child: _isSaving
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
                                            "SAVE PROFILE",
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

  ImageProvider _getProfileImage() {
    if (kIsWeb && _webImage != null) {
      return MemoryImage(_webImage!);
    } else if (!kIsWeb && _image != null) {
      return FileImage(_image!);
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      try {
        return NetworkImage(_currentImageUrl!);
      } catch (e) {
        return const AssetImage("assets/profile.png");
      }
    } else {
      return const AssetImage("assets/profile.png");
    }
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

  Widget _buildTextField(
    String title,
    TextEditingController controller,
    IconData icon,
    Color color, {
    TextInputType? keyboardType,
    String hint = "",
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
                  SizedBox(height: 4.h),
                  TextField(
                    controller: controller,
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

  Widget _buildInfoTile(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
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
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
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
}