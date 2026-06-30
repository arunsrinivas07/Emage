import 'package:app/home_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'personal_info.dart';
import 'medical_info.dart';
import 'sign_in.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  String _name = "";
  String? _profileImageUrl;
  bool _imageError = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    super.dispose();
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
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _name = userData['name'] ?? "";
          _profileImageUrl = userData['profileImageUrl'];
          _isLoading = false;
          _imageError = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleImageError() {
    setState(() {
      _imageError = true;
    });
  }

  void signOut(BuildContext context) async {
    HapticFeedback.lightImpact();

    // Show confirmation dialog
    bool shouldSignOut = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.r),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    color: const Color(0xFFCD1C18),
                    size: 24.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text('Sign Out'),
                ],
              ),
              content: Text('Are you sure you want to sign out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await FirebaseAuth.instance.signOut();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (context) =>
                                SignInPage()), // replace with your login screen
                      );
                    } catch (e) {
                      print("Sign out failed: $e");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCD1C18),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text("Sign Out"),
                ),
              ],
            );
          },
        ) ??
        false;

    if (shouldSignOut) {
      await FirebaseAuth.instance.signOut();
      Navigator.pop(context);
    }
  }

  void _navigateBack() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  void _navigateToOption(String option) {
    HapticFeedback.lightImpact();

    switch (option) {
      case 'Personal Info':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PersonalInfoScreen()),
        );
        break;
      case 'Medical Info':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MedicalInfoScreen()),
        );
        break;
      case 'Addresses':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Addresses feature coming soon!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
        break;
      case 'FAQs':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('FAQs feature coming soon!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
        break;
      case 'Settings':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settings feature coming soon!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
        break;
    }
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
                                          borderRadius:
                                              BorderRadius.circular(8.r),
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
                                        "Profile",
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
                                        backgroundImage: _profileImageUrl !=
                                                    null &&
                                                !_imageError
                                            ? NetworkImage(_profileImageUrl!)
                                            : const AssetImage(
                                                    'assets/profile.png')
                                                as ImageProvider,
                                        onBackgroundImageError:
                                            _profileImageUrl != null
                                                ? (_, __) => _handleImageError()
                                                : null,
                                      ),
                                    ),
                                    SizedBox(width: 16.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _name.isEmpty ? "User" : _name,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 22.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12.w,
                                                vertical: 4.h),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(15.r),
                                            ),
                                            child: Text(
                                              user?.email ?? "No Email",
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.9),
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

                      // Profile Options Section
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // Personal Section
                            _buildSectionCard(
                              title: "Personal",
                              icon: Icons.person_rounded,
                              children: [
                                _buildProfileOption(
                                  icon: Icons.badge_rounded,
                                  title: 'Personal Info',
                                  subtitle: 'Manage your personal information',
                                  color: const Color(0xFF3F51B5),
                                  onTap: () =>
                                      _navigateToOption('Personal Info'),
                                ),
                                _buildProfileOption(
                                  icon: Icons.medical_services_rounded,
                                  title: 'Medical Info',
                                  subtitle: 'View your medical details',
                                  color: const Color(0xFF4CAF50),
                                  onTap: () =>
                                      _navigateToOption('Medical Info'),
                                ),
                              ],
                            ),

                            SizedBox(height: 16.h),

                            // Settings Section
                            _buildSectionCard(
                              title: "Settings",
                              icon: Icons.settings_rounded,
                              children: [
                                _buildProfileOption(
                                  icon: Icons.location_on_rounded,
                                  title: 'Addresses',
                                  subtitle: 'Manage saved addresses',
                                  color: const Color(0xFF2196F3),
                                  onTap: () => _navigateToOption('Addresses'),
                                ),
                                _buildProfileOption(
                                  icon: Icons.settings_rounded,
                                  title: 'Settings',
                                  subtitle: 'App preferences and settings',
                                  color: const Color(0xFF9C27B0),
                                  onTap: () => _navigateToOption('Settings'),
                                ),
                              ],
                            ),

                            SizedBox(height: 16.h),

                            // Support Section
                            _buildSectionCard(
                              title: "Support",
                              icon: Icons.help_rounded,
                              children: [
                                _buildProfileOption(
                                  icon: Icons.help_outline_rounded,
                                  title: 'FAQs',
                                  subtitle: 'Frequently asked questions',
                                  color: const Color(0xFFFF9800),
                                  onTap: () => _navigateToOption('FAQs'),
                                ),
                              ],
                            ),

                            SizedBox(height: 16.h),

                            // Sign Out Section
                            _buildSectionCard(
                              title: "Account",
                              icon: Icons.account_circle_rounded,
                              children: [
                                _buildProfileOption(
                                  icon: Icons.logout_rounded,
                                  title: 'Sign Out',
                                  subtitle: 'Sign out of your account',
                                  color: const Color(0xFFE53935),
                                  onTap: () => signOut(context),
                                  isDestructive: true,
                                ),
                              ],
                            ),

                            SizedBox(
                                height: 100.h), // Space for bottom navigation
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

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: onTap,
          child: Container(
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
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22.sp,
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
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: isDestructive ? color : Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: color,
                    size: 18.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
