// lib/screens/driver/driver_waiting.dart
import 'package:app/sign_in.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'driver_onboarding.dart';
import 'dart:async';

class DriverWaitingScreen extends StatefulWidget {
  const DriverWaitingScreen({Key? key}) : super(key: key);

  @override
  State<DriverWaitingScreen> createState() => _DriverWaitingScreenState();
}

class _DriverWaitingScreenState extends State<DriverWaitingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  StreamSubscription<DocumentSnapshot>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _listenToVerificationStatus();
  }

  void _listenToVerificationStatus() {
    // Navigator.pushReplacement(
    //           context,
    //           MaterialPageRoute(builder: (context) => const DriverOnboardingScreen()),
    //         );
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _statusSubscription = FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final status = snapshot.data()?['status'] as String?;
          
          if (status == 'approved' && mounted) {
            // Navigate to onboarding
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DriverOnboardingScreen()),
            );
          } else if (status == 'rejected' && mounted) {
            _showRejectionDialog();
          }
        }
      });
    }
  }

  void _showRejectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Application Rejected'),
        content: const Text(
          'Unfortunately, your application has been rejected. Please contact support for more information.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              FirebaseAuth.instance.signOut();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SignInPage()),
    );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.blue.shade50,
    appBar: AppBar(
      title: const Text('Verification in Progress'),
      backgroundColor: Colors.blue.shade600,
      foregroundColor: Colors.white,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          onPressed: _logout,
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
        ),
      ],
    ),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Progress Indicator
                    LinearProgressIndicator(
                      value: 0.75,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Step 3 of 3: Document Verification',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 40),

                    // Animated Icon
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.hourglass_empty,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Main Message
                    Text(
                      'Verification in Progress',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'Your documents are being verified by our team.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'You\'ll be notified once your account is approved.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade500,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Info Cards
                    _buildInfoCard(
                      icon: Icons.timer,
                      title: 'Verification Time',
                      subtitle: 'Usually takes 24-48 hours',
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.verified_user,
                      title: 'What we verify',
                      subtitle: 'Driving license and vehicle documents',
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.notifications,
                      title: 'Stay updated',
                      subtitle: 'We\'ll send you a notification when approved',
                      color: Colors.blue,
                    ),
                    const Spacer(), // pushes button to bottom if space available
                    const SizedBox(height: 32),

                    // Contact Support Button
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Contact support: support@emage.app'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.support_agent),
                      label: const Text('Contact Support'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade600,
                        side: BorderSide(color: Colors.blue.shade600),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _statusSubscription?.cancel();
    super.dispose();
  }
}