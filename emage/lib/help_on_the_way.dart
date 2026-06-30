import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/emergency_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HelpOnTheWayScreen extends StatefulWidget {
  final String requestId;

  const HelpOnTheWayScreen({
    super.key,
    required this.requestId,
  });

  @override
  State<HelpOnTheWayScreen> createState() => _HelpOnTheWayScreenState();
}

class _HelpOnTheWayScreenState extends State<HelpOnTheWayScreen> {
  Map<String, dynamic>? requestData;
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('Help is Coming'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: EmergencyService.listenToRequestStatus(widget.requestId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64.sp, color: Colors.red),
                  SizedBox(height: 16.h),
                  Text('Error loading request status', 
                    style: TextStyle(fontSize: 16.sp)),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green.shade600),
                  SizedBox(height: 16.h),
                  Text('Loading...', style: TextStyle(fontSize: 16.sp)),
                ],
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning, size: 64.sp, color: Colors.orange),
                  SizedBox(height: 16.h),
                  Text('Request not found', style: TextStyle(fontSize: 16.sp)),
                ],
              ),
            );
          }

          requestData = snapshot.data!.data() as Map<String, dynamic>;
          final status = requestData!['status'] as String;

          if (status == 'cancelled') {
            return _buildCancelledView();
          } else if (status == 'completed') {
            return _buildCompletedView();
          } else if (status == 'accepted') {
            return _buildAcceptedView();
          } else {
            return _buildWaitingView();
          }
        },
      ),
    );
  }

  Widget _buildAcceptedView() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success animation
            Container(
              width: 120.w,
              height: 120.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.shade600,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 20.r,
                    spreadRadius: 5.r,
                  ),
                ],
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 64.sp,
                color: Colors.white,
              ),
            ),
            
            SizedBox(height: 32.h),
            
            Text(
              'Help is on the way!',
              style: TextStyle(
                fontSize: 26.sp,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 12.h),
            
            Text(
              'Emergency responder has accepted your request and is heading to your location.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 32.h),
            
            // Driver info card
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.local_taxi,
                          color: Colors.green.shade700,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              requestData!['driverName'] ?? 'Emergency Responder',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'License: ${requestData!['driverLicensePlate'] ?? 'Unknown'}',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (requestData!['driverVehicleNumber'] != null)
                              Text(
                                'Vehicle: ${requestData!['driverVehicleNumber']}',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  // Call driver button
                  if (requestData!['driverPhone'] != null && 
                      requestData!['driverPhone'].toString().isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _callDriver(requestData!['driverPhone']),
                        icon: Icon(Icons.phone, size: 18.sp),
                        label: const Text('Call Driver'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green.shade700,
                          side: BorderSide(color: Colors.green.shade300),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            SizedBox(height: 32.h),
            
            // Emergency call button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _callEmergencyServices,
                icon: Icon(Icons.phone, size: 20.sp),
                label: Text('Call Emergency Services (108)', 
                  style: TextStyle(fontSize: 15.sp)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Cancel emergency button
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _isCancelling ? null : _showCancelDialog,
                icon: _isCancelling 
                  ? SizedBox(
                      width: 16.w,
                      height: 16.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.red.shade600,
                      ),
                    )
                  : Icon(Icons.cancel, size: 18.sp),
                label: Text(
                  _isCancelling ? 'Cancelling...' : 'Cancel Emergency',
                  style: TextStyle(fontSize: 15.sp),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingView() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Waiting animation
            Container(
              width: 120.w,
              height: 120.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.shade600,
              ),
              child: Icon(
                Icons.access_time,
                size: 64.sp,
                color: Colors.white,
              ),
            ),
            
            SizedBox(height: 32.h),
            
            Text(
              'Finding nearby responders...',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 12.h),
            
            Text(
              'Please wait while we locate emergency responders in your area.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 32.h),
            
            CircularProgressIndicator(
              color: Colors.orange.shade600,
            ),
            
            SizedBox(height: 32.h),
            
            // Cancel button
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _isCancelling ? null : _showCancelDialog,
                icon: _isCancelling 
                  ? SizedBox(
                      width: 16.w,
                      height: 16.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.red.shade600,
                      ),
                    )
                  : Icon(Icons.cancel, size: 18.sp),
                label: Text(
                  _isCancelling ? 'Cancelling...' : 'Cancel Emergency',
                  style: TextStyle(fontSize: 15.sp),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelledView() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120.w,
              height: 120.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade400,
              ),
              child: Icon(
                Icons.cancel,
                size: 64.sp,
                color: Colors.white,
              ),
            ),
            
            SizedBox(height: 32.h),
            
            Text(
              'Emergency Cancelled',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 12.h),
            
            Text(
              'Your emergency request has been cancelled.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 32.h),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Back to Home', style: TextStyle(fontSize: 15.sp)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedView() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120.w,
              height: 120.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade600,
              ),
              child: Icon(
                Icons.check_circle,
                size: 64.sp,
                color: Colors.white,
              ),
            ),
            
            SizedBox(height: 32.h),
            
            Text(
              'Emergency Completed',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 12.h),
            
            Text(
              'The emergency response has been completed. We hope you are safe.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 32.h),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Back to Home', style: TextStyle(fontSize: 15.sp)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callDriver(String phoneNumber) async {
    try {
      final uri = Uri.parse('tel:$phoneNumber');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not call driver: $e')),
        );
      }
    }
  }

  Future<void> _callEmergencyServices() async {
    try {
      const phoneNumber = 'tel:108';
      final uri = Uri.parse(phoneNumber);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not call emergency services: $e')),
        );
      }
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.r),
        ),
        title: const Text('Cancel Emergency?'),
        content: const Text(
          'Are you sure you want to cancel this emergency request? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Active'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelEmergency();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Emergency'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelEmergency() async {
    setState(() {
      _isCancelling = true;
    });

    try {
      await EmergencyService.cancelRequest(widget.requestId);
      
      HapticFeedback.lightImpact();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency cancelled successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel emergency: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }
}
