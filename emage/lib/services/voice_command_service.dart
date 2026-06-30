import 'package:app/services/emergency_service.dart';
import 'package:app/services/location_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:porcupine_flutter/porcupine.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:porcupine_flutter/porcupine_error.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'dart:isolate';

// Simple emergency service without complex foreground tasks
class WorkingEmergencyService {
  static const String _accessKey = "tYXe+hzd+1mQO2hw2rEOQkSWKW+xPSd5vZLqz675Q26VobkUkIjwqQ==";
  static PorcupineManager? _porcupineManager;
  static final FlutterTts _tts = FlutterTts();
  static bool _isRunning = false;
  static bool _useBuiltInKeywords = true;

  static Future<void> start() async {
    if (_isRunning) {
      print("Service already running");
      return;
    }

    print("Starting emergency voice service...");

    // Request permissions
    if (!await _requestPermissions()) {
      print("Permissions not granted");
      return;
    }

    try {
      // Initialize TTS
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.5);
      print("TTS initialized");

      // Try to initialize Porcupine with different methods
      bool initialized = false;

      if (_useBuiltInKeywords) {
        initialized = await _initializeWithBuiltInKeywords();
      }

      if (!initialized) {
        initialized = await _initializeWithCustomKeyword();
      }

      if (!initialized) {
        throw Exception("Failed to initialize voice detection");
      }

      await _porcupineManager?.start();
      _isRunning = true;

      // Start a minimal foreground service to keep app alive
      await _startMinimalForegroundService();

      await _tts.speak("Voice detection activated");
      print("Emergency voice service started successfully");

    } catch (e) {
      print("Error starting service: $e");
      _isRunning = false;
    }
  }

  static Future<bool> _initializeWithBuiltInKeywords() async {
    final keywords = [
      BuiltInKeyword.HEY_GOOGLE,
      BuiltInKeyword.ALEXA,
      BuiltInKeyword.HEY_SIRI,
      BuiltInKeyword.OK_GOOGLE,
    ];

    for (var keyword in keywords) {
      try {
        print("Trying built-in keyword: $keyword");
        
        _porcupineManager = await PorcupineManager.fromBuiltInKeywords(
          _accessKey,
          [keyword],
          (keywordIndex) async {
            print("Built-in hotword detected: $keyword");
            await _handleEmergency();
          },
          errorCallback: (PorcupineException error) {
            print("Porcupine error: ${error.message}");
          },
        );

        print("Successfully initialized with: $keyword");
        return true;
        
      } catch (e) {
        print("Failed with keyword $keyword: $e");
        await _porcupineManager?.delete();
        _porcupineManager = null;
        continue;
      }
    }
    return false;
  }

  static Future<bool> _initializeWithCustomKeyword() async {
    try {
      print("Trying custom keyword...");
      final ppnPath = await _loadPpnFile('assets/hey.ppn');
      
      _porcupineManager = await PorcupineManager.fromKeywordPaths(
        _accessKey,
        [ppnPath],
        (keywordIndex) async {
          print("Custom hotword detected");
          await _handleEmergency();
        },
        errorCallback: (PorcupineException error) {
          print("Custom keyword error: ${error.message}");
        },
      );

      print("Custom keyword initialized successfully");
      return true;
      
    } catch (e) {
      print("Custom keyword failed: $e");
      return false;
    }
  }

  static Future<String> _loadPpnFile(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    final tempFile = File('${Directory.systemTemp.path}/hey.ppn');
    await tempFile.writeAsBytes(bytes, flush: true);
    return tempFile.path;
  }

  static Future<void> _startMinimalForegroundService() async {
    try {
      // Try to start foreground service, but don't fail if it doesn't work
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'emergency_service',
          channelName: 'Emergency Service',
          channelDescription: 'Emergency voice detection service',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: true,
          playSound: false,
        ),
          //eventAction: ForegroundTaskEventAction.nothing(),
          foregroundTaskOptions: const ForegroundTaskOptions(
  interval: 5000, // check every 5 seconds (or whatever you need)
  autoRunOnBoot: true,
  allowWakeLock: true,
  allowWifiLock: true,
),

        
      );

      await FlutterForegroundTask.startService(
       // serviceId: 256,
        notificationTitle: "Emergency Service",
        notificationText: "Voice detection active",
      );

      print("Minimal foreground service started");
    } catch (e) {
      print("Foreground service failed, but voice detection may still work: $e");
      // Continue anyway - the main functionality might still work
    }
  }

  static Future<void> _handleEmergency() async {
    try {
      print("EMERGENCY TRIGGERED");
      await _tts.speak("Emergency mode activated. Sending alert.");

      final position = await LocationService.getCurrentLocation();
      final user = FirebaseAuth.instance.currentUser;

      Map<String, dynamic> userInfo = {
        'name': 'Unknown',
        'phone': 'Unknown',
        'dob': 'Unknown',
        'bloodGroup': 'Unknown',
        'medicalConditions': 'Unknown',
      };

      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          userInfo = doc.data()!;
        }
      }

      await EmergencyService.sendEmergencyRequest(
        emergencyType: "Medical",
        latitude: position.latitude,
        longitude: position.longitude,
        userInfo: userInfo,
        isMyselfSelected: true,
      );

      await _tts.speak("Emergency alert sent successfully");
      print("Emergency request sent successfully");

    } catch (e) {
      print("Error handling emergency: $e");
      await _tts.speak("Error sending emergency alert");
    }
  }

  static Future<bool> _requestPermissions() async {
    final permissions = [
      Permission.microphone,
      Permission.locationWhenInUse,
      Permission.notification,
    ];

    bool allGranted = true;
    for (var permission in permissions) {
      final status = await permission.request();
      if (!status.isGranted) {
        print("Permission denied: $permission");
        allGranted = false;
      }
    }

    return allGranted;
  }

  static Future<void> stop() async {
    if (!_isRunning) return;

    print("Stopping emergency service...");
    
    try {
      await _porcupineManager?.stop();
      await _porcupineManager?.delete();
      _porcupineManager = null;
      _isRunning = false;

      await FlutterForegroundTask.stopService();
      print("Emergency service stopped");
    } catch (e) {
      print("Error stopping service: $e");
    }
  }

  static bool isRunning() => _isRunning;

  // Manual trigger for testing
  static Future<void> testEmergency() async {
    print("MANUAL TEST TRIGGER");
    await _handleEmergency();
  }
}

// Main service wrapper
class HotwordService {
  static Future<void> start() async {
    await WorkingEmergencyService.start();
  }

  static Future<void> stop() async {
    await WorkingEmergencyService.stop();
  }

  static Future<bool> isRunning() async {
    return WorkingEmergencyService.isRunning();
  }

  static Future<bool> requestPermissions() async {
    return await WorkingEmergencyService._requestPermissions();
  }

  static Future<void> testEmergency() async {
    await WorkingEmergencyService.testEmergency();
  }
}

// Keep the SimpleHotwordService for compatibility
class SimpleHotwordService {
  static Future<void> start() async => await WorkingEmergencyService.start();
  static Future<void> stop() async => await WorkingEmergencyService.stop();
  static bool isRunning() => WorkingEmergencyService.isRunning();
  static Future<bool> requestPermissions() async => await WorkingEmergencyService._requestPermissions();
  
  static Future<Map<String, dynamic>> getServiceStatus() async {
    return {
      'isRunning': WorkingEmergencyService.isRunning(),
      'internalState': WorkingEmergencyService.isRunning(),
      'taskHandlerActive': WorkingEmergencyService.isRunning(),
    };
  }
}