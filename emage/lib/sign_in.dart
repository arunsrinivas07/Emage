import 'package:app/driver_profile.dart';
import 'package:app/home_page.dart';
import 'package:flutter/material.dart';
import 'sign_up.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'forgot.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'driver_dashboard.dart';
import 'driver_waiting.dart';


class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  bool isloading = false;
  String _selectedRole = 'User'; // Default role selection
  
  Future<void> signIn() async {
  setState(() => isloading = true);

  try {
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text.trim(),
        );
    User user = userCredential.user!;

    // Check email verification
    if (!user.emailVerified) {
      Get.snackbar(
        "Email not verified",
        "Please verify your email before signing in",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      await FirebaseAuth.instance.signOut();
      setState(() => isloading = false);
      return;
    }

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      Get.snackbar("Login Failed", "User data not found.");
      await FirebaseAuth.instance.signOut();
      setState(() => isloading = false);
      return;
    }

    String storedRole = userDoc['role'];

    if (_selectedRole != storedRole) {
      Get.snackbar(
        "Login Failed",
        "Selected role does not match registered role.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      await FirebaseAuth.instance.signOut();
    } else {
      // Navigate based on role
      // Navigate based on role
if (_selectedRole.toLowerCase() == 'driver') {
  DocumentSnapshot driverDoc = await FirebaseFirestore.instance
      .collection('drivers')
      .doc(user.uid)
      .get();

  if (driverDoc.exists) {
    final status = driverDoc['status'] ?? '';

    if (status == 'pending_verification') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DriverWaitingScreen()),
        (route) => false,
      );
    } else if (status == 'approved') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DriverDashboard()),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DriverProfileScreen()),
        (route) => false,
      );
    }
  } else {
    // brand new driver → go to profile
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DriverProfileScreen()),
      (route) => false,
    );
  }
} else {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const HomePage()),
    (route) => false,
  );
}

    }
  } on FirebaseAuthException catch (e) {
    Get.snackbar(
      "Login Failed",
      e.message ?? e.code,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  } catch (e) {
    Get.snackbar(
      "Error",
      e.toString(),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  setState(() => isloading = false);
}


  bool _isPasswordVisible = false; // Track password visibility

  @override
  Widget build(BuildContext context) {
    if (isloading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80),
                // Header
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome Back to Emage!",
                      style: TextStyle(
                          fontSize: 40, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Please sign in your account.",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                
                // Role Selection Dropdown
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      hint: const Text("Select Role"),
                      isExpanded: true,
                      dropdownColor: Colors.white.withOpacity(0.95), // Opaque white
                      borderRadius: BorderRadius.circular(15), // Rounded sides
                      items: ['User', 'Driver'].map((String role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(role),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRole = newValue!;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Input fields
                TextField(
                  controller: email,
                  decoration: InputDecoration(
                    hintText: "Email",
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: password,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: "Password",
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                
                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Forgot()),
                      );
                    },
                    child: const Text(
                      "Forgot password?",
                      style: TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Sign in button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => signIn(),
                    child: const Text(
                      "Sign In",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: const Text("Sign-in with"),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 30),
                
                // Social sign-in options
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: Image.asset('assets/google.png', width: 40),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      onPressed: () {},
                      icon: Image.asset('assets/apple.png', width: 40),
                    ),
                  ],
                ),
                
                // Sign up text at bottom
                const SizedBox(height: 30),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignUpPage()),
                      );
                    },
                    child: const Text.rich(
                      TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(fontSize: 14, color: Colors.black),
                        children: [
                          TextSpan(
                            text: "Sign up",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20), // Add bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }
}