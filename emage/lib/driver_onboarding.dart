// lib/screens/driver/driver_onboarding.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'driver_dashboard.dart';

class DriverOnboardingScreen extends StatefulWidget {
  const DriverOnboardingScreen({Key? key}) : super(key: key);

  @override
  State<DriverOnboardingScreen> createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends State<DriverOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isNavigating = false;

  final List<OnboardingData> _onboardingData = [
    OnboardingData(
      title: 'Accept Emergency Requests',
      description: 'Receive real-time emergency requests from users in need. You can accept or decline based on your availability and location.',
      icon: Icons.emergency,
      color: Colors.red,
    ),
    OnboardingData(
      title: 'Live GPS Tracking',
      description: 'Your location is tracked in real-time to help users find you quickly. Navigate efficiently using integrated maps.',
      icon: Icons.location_on,
      color: Colors.blue,
    ),
    OnboardingData(
      title: 'Emergency Response Rules',
      description: 'Always prioritize safety. Follow traffic rules, communicate with users, and ensure quick response times.',
      icon: Icons.rule,
      color: Colors.green,
    ),
  ];

  void _nextPage() {
    if (_isNavigating) return;
    
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _getStarted();
    }
  }

  void _previousPage() {
    if (_isNavigating) return;
    
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _getStarted() async {
    if (_isNavigating || !mounted) return;
    
    setState(() {
      _isNavigating = true;
    });

    try {
      // Mark onboarding as completed in Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('drivers')
            .doc(user.uid)
            .update({
          'hasCompletedOnboarding': true,
          'onboardingCompletedAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Small delay to ensure Firebase write completes
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        // Use pushAndRemoveUntil to clear navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const DriverDashboard()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing onboarding: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Welcome to Emage',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  TextButton(
                    onPressed: _isNavigating ? null : _getStarted,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: _isNavigating ? Colors.grey : Colors.blue.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: List.generate(
                  _onboardingData.length,
                  (index) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Colors.blue.shade600
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  if (!_isNavigating) {
                    setState(() {
                      _currentPage = index;
                    });
                  }
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  final data = _onboardingData[index];
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: data.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            data.icon,
                            size: 60,
                            color: data.color,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Title
                        Text(
                          data.title,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Text(
                          data.description,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous Button
                  _currentPage > 0
                      ? TextButton.icon(
                          onPressed: _isNavigating ? null : _previousPage,
                          icon: Icon(
                            Icons.arrow_back,
                            color: _isNavigating ? Colors.grey : null,
                          ),
                          label: Text(
                            'Previous',
                            style: TextStyle(
                              color: _isNavigating ? Colors.grey : null,
                            ),
                          ),
                        )
                      : const SizedBox(width: 100),

                  // Next/Get Started Button
                  ElevatedButton(
                    onPressed: _isNavigating ? null : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isNavigating 
                          ? Colors.grey.shade400 
                          : Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isNavigating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentPage == _onboardingData.length - 1
                                    ? 'Get Started'
                                    : 'Next',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_currentPage < _onboardingData.length - 1) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 18),
                              ],
                            ],
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}