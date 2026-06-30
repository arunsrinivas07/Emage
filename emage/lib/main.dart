import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'home_page.dart';
import 'package:get/get.dart';
import 'package:app/services/voice_command_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print("🚀 App initialized, starting...");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Emergency Response App',
          theme: ThemeData(primarySwatch: Colors.red),
          home: const ServiceInitializer(),
        );
      },
    );
  }
}

// ✅ Proper service initialization after app is ready
class ServiceInitializer extends StatefulWidget {
  const ServiceInitializer({super.key});

  @override
  State<ServiceInitializer> createState() => _ServiceInitializerState();
}

class _ServiceInitializerState extends State<ServiceInitializer> {
  bool _serviceInitialized = false;
  String _statusMessage = "Initializing...";

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    print("🔧 Starting service initialization...");

    try {
      setState(() {
        _statusMessage = "Requesting permissions...";
      });

      // Wait for the widget tree to be built
      await Future.delayed(const Duration(milliseconds: 500));

      // Request permissions first
      final permissionsGranted =
          await SimpleHotwordService.requestPermissions();

      if (permissionsGranted) {
        print("✅ All permissions granted");

        setState(() {
          _statusMessage = "Starting voice detection...";
        });

        // Start the hotword service
        await SimpleHotwordService.start();

        // Wait a moment and check the status
        await Future.delayed(const Duration(milliseconds: 2000));

        final status = await SimpleHotwordService.getServiceStatus();
        print("📊 Service status: $status");

        setState(() {
          _serviceInitialized = true;
          _statusMessage = status['isRunning']
              ? "Voice detection active ✅"
              : "Voice detection failed ❌";
        });

        print("✅ Service initialization complete");

        // Navigate to home page after a brief delay
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } else {
        print("❌ Some permissions were denied");
        setState(() {
          _statusMessage = "Permissions denied ❌";
        });
      }
    } catch (e) {
      print("❌ Error initializing service: $e");
      setState(() {
        _statusMessage = "Initialization failed ❌";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mic,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            const Text(
              'Emergency Voice Service',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (!_serviceInitialized)
              const CircularProgressIndicator(
                color: Colors.red,
              ),
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              style: const TextStyle(
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (_serviceInitialized) ...[
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                },
                child: const Text('Continue to App'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ✅ Alternative: Direct initialization (if you prefer)
class DirectInitMain {
  static void runAppWithDirectInit() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize service before running the app
    print("🚀 Pre-initializing voice service...");

    // Request permissions
    final permissionsGranted = await SimpleHotwordService.requestPermissions();

    if (permissionsGranted) {
      // Start service
      await SimpleHotwordService.start();

      // Check status
      final status = await SimpleHotwordService.getServiceStatus();
      print("📊 Pre-init service status: $status");
    }

    runApp(const MyApp());
  }
}
