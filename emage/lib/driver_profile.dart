// lib/screens/driver/driver_profile.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'driver_waiting.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({Key? key}) : super(key: key);

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseNumberController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  
  String _selectedVehicleType = 'Car';
  final List<String> _vehicleTypes = ['Car', 'Van', 'Ambulance', 'Bike'];
  
  File? _licenseImage;
  bool _isUploading = false;
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickLicenseImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _licenseImage = File(image.path);
        });
      }
    } catch (e) {
      _showError('Failed to pick image: ${e.toString()}');
    }
  }

Future<String?> _uploadLicenseImageAsBase64() async {
  if (_licenseImage == null) return null;

  try {
    final bytes = await _licenseImage!.readAsBytes();
    final base64Str = base64Encode(bytes);
    return base64Str;
  } catch (e) {
    _showError('Failed to encode image: ${e.toString()}');
    return null;
  }
}


Future<void> _saveProfile() async {
  if (!_formKey.currentState!.validate()) return;

  if (_licenseImage == null) {
    _showError('Please upload your driving license photo');
    return;
  }

  setState(() => _isSaving = true);

  try {
    // Convert image → Base64
    final licenseImageBase64 = await _uploadLicenseImageAsBase64();
    if (licenseImageBase64 == null) {
      setState(() => _isSaving = false);
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;

    // Save profile data to Firestore
    await FirebaseFirestore.instance
    .collection('drivers') // ✅ keep schema consistent
    .doc(user.uid)
    .set({
      'profile': {
        'licenseNumber': _licenseNumberController.text.trim(),
        'licenseImageBase64': licenseImageBase64,   // ✅ Base64 here
        'vehicleNumber': _vehicleNumberController.text.trim().toUpperCase(),
        'vehicleType': _selectedVehicleType,
      },
      'status': 'pending_verification',
      'profileCompletedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // merge so it doesn’t overwrite

    // Navigate to waiting screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DriverWaitingScreen()),
      );
    }

  } catch (e) {
    _showError('Failed to save profile: ${e.toString()}');
  } finally {
    setState(() => _isSaving = false);
  }
}

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Complete Profile'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Indicator
              LinearProgressIndicator(
                value: 0.5,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                'Step 2 of 3: Profile Completion',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),

              // Header
              Text(
                'Driver Information',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please provide your driving license and vehicle details',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),

              // License Number Field
              TextFormField(
                controller: _licenseNumberController,
                decoration: InputDecoration(
                  labelText: 'Driving License Number',
                  prefixIcon: const Icon(Icons.credit_card),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'e.g., DL-1420110012345',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your license number';
                  }
                  if (value.trim().length < 8) {
                    return 'Please enter a valid license number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // License Photo Upload
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Driving License Photo'),
                      subtitle: const Text('Upload a clear photo of your license'),
                      trailing: const Icon(Icons.camera_alt),
                      onTap: _pickLicenseImage,
                    ),
                    if (_licenseImage != null) ...[
                      const Divider(height: 1),
                      Container(
                        height: 200,
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(_licenseImage!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Vehicle Number Field
              TextFormField(
                controller: _vehicleNumberController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Vehicle Number Plate',
                  prefixIcon: const Icon(Icons.directions_car),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'e.g., TN01AB1234',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your vehicle number';
                  }
                  if (value.trim().length < 6) {
                    return 'Please enter a valid vehicle number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Vehicle Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedVehicleType,
                decoration: InputDecoration(
                  labelText: 'Vehicle Type',
                  prefixIcon: const Icon(Icons.local_shipping),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _vehicleTypes.map((type) {
                  IconData icon;
                  switch (type) {
                    case 'Car':
                      icon = Icons.directions_car;
                      break;
                    case 'Van':
                      icon = Icons.airport_shuttle;
                      break;
                    case 'Ambulance':
                      icon = Icons.local_hospital;
                      break;
                    case 'Bike':
                      icon = Icons.motorcycle;
                      break;
                    default:
                      icon = Icons.directions_car;
                  }
                  
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(icon, size: 20),
                        const SizedBox(width: 8),
                        Text(type),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedVehicleType = value!;
                  });
                },
              ),
              const SizedBox(height: 40),

              // Save & Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isUploading || _isSaving) ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: (_isUploading || _isSaving)
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                            const SizedBox(width: 12),
                            Text(_isUploading ? 'Uploading...' : 'Saving...'),
                          ],
                        )
                      : const Text(
                          'Save & Continue',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }
}