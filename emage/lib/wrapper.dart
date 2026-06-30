import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'sign_in.dart';
import 'verifyemail.dart';
import 'driver_profile.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});
  
  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Future<Widget> _checkUserRoleAndEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print('No user logged in');
        return const SignInPage();
      }
      
      if (!user.emailVerified) {
        print('Email not verified');
        return const Verify();
      }
      
      print('Checking user role for: ${user.uid}');
      
      // Get role from Firestore
      final DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
          
      if (!snapshot.exists) {
        print('User document does not exist in Firestore');
        return const SignInPage();
      }
      
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) {
        print('User document data is null');
        return const SignInPage();
      }
      
      final String role = data['role'] ?? 'user';
      print('User role retrieved: $role');
      
      if (role.toLowerCase() == 'driver') {
        print('Navigating to EmergencyCasesPage');
        return const DriverProfileScreen();
      } else {
        print('Navigating to HomePage');
        return const HomePage();
      }
    } catch (e) {
      print('Error in _checkUserRoleAndEmail: $e');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $e'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasData) {
            return FutureBuilder<Widget>(
              future: _checkUserRoleAndEmail(),
              builder: (context, AsyncSnapshot<Widget> futureSnapshot) {
                if (futureSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (futureSnapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text("Error: ${futureSnapshot.error}"),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else {
                  return futureSnapshot.data!;
                }
              },
            );
          } else {
            return const SignInPage();
          }
        },
      ),
    );
  }
}