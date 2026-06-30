import 'dart:async';
import 'package:app/help_on_the_way.dart';
import 'package:app/services/emergency_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:another_telephony/telephony.dart';
import 'package:app/services/voice_command_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'find a donor.dart' hide HospitalsPage;
import 'hospitals_page.dart' hide AmbulanceScreen;
import 'profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctors_page.dart' hide HospitalsPage;
import 'ambulance_page.dart' hide HospitalsPage;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'chatbot_page.dart'
    hide HospitalsPage, FindaDonor, AmbulanceScreen, DoctorPage;
import 'package:geocoding/geocoding.dart';
import 'widgets/navigation.dart';
import 'services/location_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  int _currentIndex = 2; // Set to Emergency (index 2) by default

  // Emergency information variables
  String _currentLocation = "Unknown location";
  String _currentLocationArea = "Unknown location"; 
  String _selectedEmergencyType = "Emergency"; // Default emergency type
  List<String> _emergencyContacts = []; // Will be populated from Firestore
  Position? _position; // Current GPS position

  // Initialize another_telephony
  final Telephony _telephony = Telephony.instance;

  // UI state variables
  bool _isMyselfSelected = true;
  Color _sosButtonColor = Colors.grey;

  // Variables for press and hold functionality
  bool _isSOSPressed = false;
  int _sosHoldDuration = 0;

  // SOS activation status
  bool _sosActivated = false;

  // Timer for tracking hold duration
  Timer? _sosTimer;

  // Animation controllers
  late AnimationController _sosButtonController;
  late AnimationController _toggleController;
  late Animation<double> _sosButtonAnimation;
  late Animation<double> _toggleAnimation;
  late AnimationController _sosPulseController;
  late Animation<double> _sosPulseAnimation;

  final Map<String, Color> _emergencyColors = {
    "Accident": const Color(0xFF9C27B0), // Purple - more accessible
    "Fire": const Color(0xFFE53935), // Red - high contrast
    "Medical": const Color(0xFF43A047), // Green - colorblind friendly
  };

  // Class level variales
  String _name = "DIVYANAND";
  bool _isLoading = true;
  Map<String, dynamic> userData = {};
  Map<String, dynamic> otherPersonData = {};
  
          
  // Loading states
  bool _contactsLoaded = false;
  bool _locationLoaded = false;
  bool _userDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
    //SimpleHotwordService.start();
  }

  // Initialize app in proper sequence
  Future<void> _initializeApp() async {
    try {
      print('=== STARTING APP INITIALIZATION ===');
      
      // Step 1: Request permissions first
      await _requestAllPermissions();
      
      // Step 2: Load data concurrently
      await Future.wait([
        _loadUserData(),
        _loadEmergencyContacts(),
        _loadLocation(),
      ]);
      
      print('=== APP INITIALIZATION COMPLETE ===');
      print('Contacts loaded: $_contactsLoaded (${_emergencyContacts.length} contacts)');
      print('Location loaded: $_locationLoaded');
      print('User data loaded: $_userDataLoaded');
      
    } catch (e) {
      print('Error during app initialization: $e');
    }
  }

  void _initializeAnimations() {
    _sosButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _toggleController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _sosButtonAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _sosButtonController,
      curve: Curves.easeInOut,
    ));

    _toggleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _toggleController,
      curve: Curves.easeInOut,
    ));

    _toggleController.forward();
    
    _sosPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _sosPulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _sosPulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _sosTimer?.cancel();
    _sosButtonController.dispose();
    _toggleController.dispose();
    _sosPulseController.dispose();
    super.dispose();
  }

  // Request all required permissions
  Future<void> _requestAllPermissions() async {
    print('=== REQUESTING PERMISSIONS ===');
    await _requestMicrophonePermission(); 
    await _requestLocationPermission();
    await _requestPhonePermission();
    await _requestSmsPermission();
    print('=== PERMISSIONS REQUESTED ===');
  }

  Future<void> _requestMicrophonePermission() async {
    var status = await Permission.microphone.request();    
    print("Microphone permission status: $status");
  }

  Future<void> _requestSmsPermission() async {
    var status = await Permission.sms.request();
    print("SMS permission status via permission_handler: $status");
    bool? granted = await _telephony.requestSmsPermissions;
    print("SMS permission granted via telephony: $granted");
  }

  Future<void> _requestPhonePermission() async {
    var status = await Permission.phone.request();
    print("Phone permission status: $status");
  }

  Future<void> _loadEmergencyContacts() async {
    print('=== LOADING EMERGENCY CONTACTS ===');
    try {
      if (user == null) {
        print('No authenticated user found');
        setState(() {
          _contactsLoaded = true;
        });
        return;
      }

      print('Fetching user document for UID: ${user!.uid}');
      
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      print('Document exists: ${docSnapshot.exists}');
      
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final userData = docSnapshot.data()!;
        print('Document data keys: ${userData.keys.toList()}');
        
        if (userData.containsKey('emergencyNumbers')) {
          final contacts = userData['emergencyNumbers'];
          print('Emergency contacts field type: ${contacts.runtimeType}');
          print('Emergency contacts raw data: $contacts');
          
          if (contacts is List) {
            setState(() {
              _emergencyContacts = List<String>.from(contacts);
              _contactsLoaded = true;
            });
            print('Successfully loaded ${_emergencyContacts.length} emergency contacts:');
            for (int i = 0; i < _emergencyContacts.length; i++) {
              print('  Contact ${i + 1}: ${_emergencyContacts[i]}');
            }
          } else {
            print('Emergency contacts field is not a List: ${contacts.runtimeType}');
            setState(() {
              _contactsLoaded = true;
            });
          }
        } else {
          print('No emergencyContacts field found in document');
          print('Available fields: ${userData.keys.toList()}');
          setState(() {
            _contactsLoaded = true;
          });
        }
      } else {
        print('User document does not exist or has no data');
        setState(() {
          _contactsLoaded = true;
        });
      }
    } catch (e) {
      print('DETAILED ERROR loading emergency contacts: $e');
      print('Error type: ${e.runtimeType}');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}');
        print('Firebase error message: ${e.message}');
      }
      setState(() {
        _contactsLoaded = true;
      });
    }
    print('=== EMERGENCY CONTACTS LOADING COMPLETE ===');
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      print("Location permission granted");
    } else if (status.isDenied) {
      print("Location permission denied");
    } else if (status.isPermanentlyDenied) {
      print("Location permission permanently denied");
      openAppSettings();
    }
  }

  Future<void> _loadLocation() async {
    print('=== LOADING LOCATION ===');
    try {
      final location = await LocationService.getCurrentLocation();
      print("Location service returned - Area: ${location.area}");
      print("Coordinates - Lat: ${location.latitude}, Long: ${location.longitude}");

      setState(() {
        _currentLocationArea = location.area;
        _currentLocation = "${location.latitude}, ${location.longitude}";
        _position = Position(
  latitude: location.latitude,
  longitude: location.longitude,
  timestamp: DateTime.now(),
  accuracy: 0.0,
  altitude: 0.0,
  heading: 0.0,
  speed: 0.0,
  speedAccuracy: 0.0,
  altitudeAccuracy: 0.0,   // 👈 required now
  headingAccuracy: 0.0,    // 👈 required now
);

        _locationLoaded = true;
      });
      print('Location loaded successfully');
    } catch (e) {
      print('Error loading location: $e');
      setState(() {
        _locationLoaded = true;
      });
    }
    print('=== LOCATION LOADING COMPLETE ===');
  }

  void _startSOSHold() {
    if (_selectedEmergencyType == "Emergency") {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8.w),
              Text('Please select an emergency type first'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_sosActivated) return;

    setState(() {
      _isSOSPressed = true;
      _sosHoldDuration = 0;
    });

    // Start button animation and haptic feedback
    _sosButtonController.forward();
    HapticFeedback.mediumImpact();

    _sosTimer?.cancel();
    _sosTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _sosHoldDuration++;
      });

      // Provide haptic feedback each second
      HapticFeedback.lightImpact();

      if (_sosHoldDuration >= 3) {
        _triggerSOS();
        timer.cancel();
      }
    });
  }

  void _endSOSHold() {
    setState(() {
      _isSOSPressed = false;
    });
    _sosButtonController.reverse();
    _sosTimer?.cancel();
  }

  void _showConfirmationDialog() {
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.r),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: _emergencyColors[_selectedEmergencyType],
                size: 28.sp,
              ),
              SizedBox(width: 8.w),
              const Text('Confirm Emergency'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send $_selectedEmergencyType emergency alert to your contacts?',
                style: TextStyle(fontSize: 16.sp),
              ),
              SizedBox(height: 8.h),
              Text(
                'Location: $_currentLocation',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cancelSOS();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _triggerSOS();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _emergencyColors[_selectedEmergencyType],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: const Text('Send Alert'),
            ),
          ],
        );
      },
    );
  }

  void _cancelSOS() {
    setState(() {
      _isSOSPressed = false;
      _sosHoldDuration = 0;
    });
    _sosButtonController.reverse();
  }

Future<void> _triggerSOS() async {
  // Prevent multiple triggers
  if (_sosActivated) return;
  
  setState(() {
    _sosButtonColor = _emergencyColors[_selectedEmergencyType] ?? Colors.red;
    _sosActivated = true;
    _isSOSPressed = false;
  });

  HapticFeedback.heavyImpact();

  try {
    // Send SMS to emergency contacts first
    _sendEmergencyMessages();

    // Then send to nearby drivers
    if (_position != null) {
      final requestId = await EmergencyService.sendEmergencyRequest(
        emergencyType: _selectedEmergencyType,
        latitude: _position!.latitude,
        longitude: _position!.longitude,
        userInfo: userData,
        isMyselfSelected: _isMyselfSelected,
      );

      // Navigate to Help on the Way screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HelpOnTheWayScreen(requestId: requestId),
          ),
        ).then((_) {
          // Reset SOS state when returning from help screen
          setState(() {
            _sosActivated = false;
            _sosButtonColor = Colors.grey;
            _selectedEmergencyType = "Emergency";
          });
        });
      }
    } else {
      throw Exception('Unable to get your location');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8.w),
              Text('SOS ACTIVATED for $_selectedEmergencyType emergency!'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }

  } catch (e) {
    setState(() {
      _sosActivated = false;
      _sosButtonColor = Colors.grey;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send emergency alert: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
    }
  }
}

  void _setEmergencyType(String type) {
    HapticFeedback.lightImpact();

    setState(() {
      if (_selectedEmergencyType == type) {
        _selectedEmergencyType = "Emergency";
        _sosButtonColor = Colors.grey;
        _sosActivated = false;
      } else {
        _selectedEmergencyType = type;
        _sosButtonColor = _emergencyColors[type] ?? Colors.grey;
        _sosActivated = false;
      }
    });
  }

  Future<void> _loadUserData() async {
    print('=== LOADING USER DATA ===');
    if (user == null) {
      print('No authenticated user');
      setState(() {
        _isLoading = false;
        _userDataLoaded = true;
      });
      return;
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (userDoc.exists) {
        userData = userDoc.data() as Map<String, dynamic>;
        print('User data loaded: ${userData.keys.toList()}');
        setState(() {
          _name = userData['name'] ?? "DIVYANAND";
          _isLoading = false;
          _userDataLoaded = true;
        });
      } else {
        print('User document does not exist');
        setState(() {
          _isLoading = false;
          _userDataLoaded = true;
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
      setState(() {
        _isLoading = false;
        _userDataLoaded = true;
      });
    }
    print('=== USER DATA LOADING COMPLETE ===');
  }

  
  void _sendEmergencyMessages() async {
    print('Starting emergency message sending process...');

    // Make sure we have SMS permissions
    bool? permissionGranted = await _telephony.requestSmsPermissions;
    print('SMS permissions granted: $permissionGranted');

    // Check if we have a valid position
    
    // Compose message based on current settings
    String who = _isMyselfSelected ? "Myself" : "Someone else";
    int age = calculateAgeFromDob(userData['dob'] ?? '');
    String message;
    if (who == "Myself") {
      message = "EMERGENCY ALERT: $who \n"
          "T: $_selectedEmergencyType \n"
          "L: $_currentLocation \n"
          "BG:${userData['bloodGroup']}\n"
          "MedCond: ${userData['medicalConditions']}\n"
          "Age: $age\n"
          "Map: https://maps.google.com/?q=${_position?.latitude ?? 0},${_position?.longitude ?? 0}";

      print('Emergency message content: $message');
    } else {
      message = "EMERGENCY ALERT: $who \n"
          "T: $_selectedEmergencyType \n"
          "L: $_currentLocation \n"
          "Map: https://maps.google.com/?q=${_position?.latitude ?? 0},${_position?.longitude ?? 0}";

      print('Emergency message content: $message');
    }

    // Send SMS if we have emergency contacts using another_telephony
    if (_emergencyContacts.isNotEmpty) {
      try {
        // Send to each emergency contact
        for (String contact in _emergencyContacts) {
          print('Attempting to send SMS to: $contact');

          // Format phone number correctly (sometimes + can cause issues)
          String formattedNumber = contact;
          if (contact.startsWith('+')) {
            formattedNumber = contact; // Keep + for SMS
          }

          _telephony.sendSms(
            to: formattedNumber,
            message: message,
            statusListener: (SendStatus status) {
              print('SMS to $contact - Status: $status');
              if (status == SendStatus.SENT) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("SMS sent to $contact")),
                );
              } else if (status == SendStatus.DELIVERED) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("SMS delivered to $contact")),
                );
              }
            },
          );
        }
      } catch (e) {
        print('Detailed SMS error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error sending SMS: ${e.toString()}")),
        );
      }
    } else {
      print('No emergency contacts found');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "No emergency contacts found. Add contacts in your profile.")),
      );
    }

    // Also send via WhatsApp to the first contact if available
    if (_emergencyContacts.isNotEmpty) {
      for (String contact in _emergencyContacts) {
        _sendWhatsAppMessage(contact, message);
        // Add a small delay between sends to avoid overwhelming the system
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }
  String _formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters except +
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // If it doesn't start with + and is 10 digits, assume it's Indian number
    if (!cleaned.startsWith('+') && cleaned.length == 10) {
      cleaned = '+91$cleaned';
    }
    
    return cleaned;
  }

  void _openChatbot() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatbotPage()),
    );
  }

  Future<void> _sendWhatsAppMessage(String phoneNumber, String message) async {
    try {
      String formattedNumber = _formatPhoneNumber(phoneNumber);
      
      // Remove + for WhatsApp URL
      if (formattedNumber.startsWith('+')) {
        formattedNumber = formattedNumber.substring(1);
      }

      String encodedMessage = Uri.encodeComponent(message);
      Uri whatsappUri = Uri.parse("https://wa.me/$formattedNumber?text=$encodedMessage");

      print('Attempting WhatsApp to: $formattedNumber');
      
      if (await canLaunchUrl(whatsappUri)) {
        bool launched = await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        if (launched) {
          print('WhatsApp launched successfully for $formattedNumber');
          return;
        }
      }

      // Try alternate WhatsApp URL scheme
      Uri alternateUri = Uri.parse("whatsapp://send?phone=$formattedNumber&text=$encodedMessage");
      if (await canLaunchUrl(alternateUri)) {
        await launchUrl(alternateUri, mode: LaunchMode.externalApplication);
        print('WhatsApp (alternate) launched for $formattedNumber');
      }
    } catch (e) {
      print('WhatsApp error for $phoneNumber: $e');
    }
  }

  int calculateAgeFromDob(String dobString) {
    if (dobString.isEmpty) return 0;

    try {
      List<String> parts = dobString.split('-');
      if (parts.length != 3) return 0;

      int day = int.parse(parts[0]);
      int month = int.parse(parts[1]);
      int year = int.parse(parts[2]);

      DateTime dob = DateTime(year, month, day);
      DateTime now = DateTime.now();

      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    } catch (e) {
      print("Error calculating age: $e");
      return 0;
    }
  }

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
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DoctorPage()),
        );
        break;
      case 2:
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
          MaterialPageRoute(builder: (context) => const AmbulanceScreen()),
        );
        break;
    }
  }

  Widget buildModernToggleSwitch() {
    return Container(
      height: 60.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Sliding background
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: _isMyselfSelected
                ? 4.w
                : (MediaQuery.of(context).size.width / 2) - 20.w,
            top: 4.h,
            child: Container(
              width: (MediaQuery.of(context).size.width / 2) - 20.w,
              height: 52.h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFCD1C18), Color(0xFFE53935)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFCD1C18).withOpacity(0.4),
                    blurRadius: 12.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
            ),
          ),
          // Text labels
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _isMyselfSelected = true;
                    });
                  },
                  child: Container(
                    height: 60.h,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_rounded,
                            color: _isMyselfSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                            size: 22.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            "Myself",
                            style: TextStyle(
                              color: _isMyselfSelected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _isMyselfSelected = false;
                    });
                  },
                  child: Container(
                    height: 60.h,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_rounded,
                            color: !_isMyselfSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                            size: 22.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            "Someone Else",
                            style: TextStyle(
                              color: !_isMyselfSelected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget emergencyButton(String title, String iconPath, Color bgColor) {
    final bool isSelected = _selectedEmergencyType == title;

    return GestureDetector(
      onTap: () => _setEmergencyType(title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : bgColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: bgColor.withOpacity(0.4),
                blurRadius: 12.r,
                spreadRadius: 1.r,
                offset: Offset(0, 4.h),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8.r,
                offset: Offset(0, 2.h),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              iconPath,
              width: 22.w,
              height: 28.h,
            ),
            SizedBox(width: 2.w), // spacing between icon and text
            Flexible(
              child: AutoSizeText(
                title,
                style: TextStyle(
                  fontSize: 15.sp, // starting font size
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : bgColor,
                ),
                maxLines: 1, // keep in one line
                minFontSize: 10, // shrink but not too tiny
                stepGranularity: 1, // smooth shrinking
                overflow: TextOverflow.ellipsis, // avoid overflow
                textAlign: TextAlign.center, // keeps it centered
              ),
            ),
          ],
        ),
      ),
    );
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
                  // Header with location and profile - Made more compact
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
                                "Current Location",
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

                  // Title section with chatbot - Made more compact
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Emergency Assistance",
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                "Press and hold the SOS button to alert your emergency contacts with your location.",
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey.shade600,
                                  height: 1.3.h,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        // Chatbot button - Made smaller
                        Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: GestureDetector(
                            onTap: _openChatbot,
                            child: Container(
                              width: 50.w,
                              height: 50.h,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2DD4BF),
                                    Color(0xFF0D9488),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF2DD4BF).withOpacity(0.3),
                                    blurRadius: 15.r,
                                    spreadRadius: 1.r,
                                    offset: Offset(0, 4.h),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 24.sp,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Flexible space for SOS button
                  Flexible(
                    flex: 3,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: Listenable.merge(
                            [_sosButtonAnimation, _sosPulseAnimation]),
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _sosButtonAnimation.value *
                                _sosPulseAnimation.value,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Saturn Ring 1 - Made smaller
                                Transform.rotate(
                                  angle: 0.4,
                                  child: Container(
                                    width: 200.w,
                                    height: 200.h,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            _sosButtonColor.withOpacity(0.25),
                                        width: 4.w,
                                      ),
                                    ),
                                  ),
                                ),

                                // Saturn Ring 2 - Made smaller
                                Transform.rotate(
                                  angle: -0.3,
                                  child: Container(
                                    width: 230.w,
                                    height: 230.h,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            _sosButtonColor.withOpacity(0.15),
                                        width: 3.w,
                                      ),
                                    ),
                                  ),
                                ),

                                // Main SOS Button - Made smaller
                                Container(
                                  width: 230.w,
                                  height: 230.h,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        _sosButtonColor.withOpacity(0.1),
                                        _sosButtonColor.withOpacity(0.05),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.7, 1.0],
                                    ),
                                  ),
                                  child: Container(
                                    margin: EdgeInsets.all(30.w),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _sosButtonColor,
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              _sosButtonColor.withOpacity(0.3),
                                          blurRadius:
                                              (_isSOSPressed ? 20 : 12) *
                                                  _sosPulseAnimation.value,
                                          spreadRadius:
                                              (_isSOSPressed ? 6 : 1) *
                                                  _sosPulseAnimation.value,
                                        ),
                                      ],
                                    ),
                                    child: GestureDetector(
                                      onLongPressStart: (_) => _startSOSHold(),
                                      onLongPressEnd: (_) => _endSOSHold(),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _sosActivated
                                                  ? "ACTIVATED"
                                                  : "SOS",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 22.sp,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 2,
                                              ),
                                            ),
                                            SizedBox(height: 6.h),
                                            if (!_sosActivated)
                                              _isSOSPressed
                                                  ? Column(
                                                      children: [
                                                        Text(
                                                          "$_sosHoldDuration / 3",
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16.sp,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                        SizedBox(height: 3.h),
                                                        Container(
                                                          width: 60.w,
                                                          height: 3.h,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white
                                                                .withOpacity(
                                                                    0.3),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        2),
                                                          ),
                                                          child:
                                                              FractionallySizedBox(
                                                            alignment: Alignment
                                                                .centerLeft,
                                                            widthFactor:
                                                                _sosHoldDuration /
                                                                    3,
                                                            child: Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .white,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            2.r),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : Text(
                                                      "Hold for 3 seconds",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12.sp,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Emergency type selection - Made more compact
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Select Emergency Type",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: emergencyButton(
                                  "Accident",
                                  "assets/accident.png",
                                  _emergencyColors["Accident"]!),
                            ),
                            Flexible(
                              child: emergencyButton("Fire", "assets/fire.png",
                                  _emergencyColors["Fire"]!),
                            ),
                            Flexible(
                              child: emergencyButton(
                                  "Medical",
                                  "assets/medical.png",
                                  _emergencyColors["Medical"]!),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Modern toggle switch - Made more compact
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Who needs help?",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        buildModernToggleSwitch(),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h), // Reduced bottom space
                ],
              ),
            ),

            // Bottom section with navigation
            Navigation(
              currentIndex: _currentIndex,
              onTap: _navigateToPage,
              onEmergencyTap: () {
                HapticFeedback.lightImpact();
                // Already on emergency page
              },
            ),
          ],
        ),
      ),
    );
  }
}