import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Navigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onEmergencyTap;

  const Navigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onEmergencyTap,
  });

  Widget _buildNavItem(String iconPath, {required int index}) {
    final bool isSelected = index == currentIndex;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(15.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFCD1C18).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              iconPath,
              width: 24.w,
              height: 24.h,
              color: isSelected ? const Color(0xFFCD1C18) : Colors.black54,
            ),
            // if (isSelected)
            //   Container(
            //     margin: EdgeInsets.only(top: 4.h),
            //     width: 6.w,
            //     height: 6.h,
            //     // decoration: const BoxDecoration(
            //     //   color: Color(0xFFCD1C18),
            //     //  // shape: BoxShape.circle,
            //     // ),
            //   ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 80.h,
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(25.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20.r,
                spreadRadius: 0.r,
                offset: Offset(0, 5.h),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem('assets/hospitals.png', index: 0),
              _buildNavItem('assets/doctors.png', index: 1),
              SizedBox(width: 50.w), // space for FAB
              _buildNavItem('assets/blood_donor.png', index: 3),
              _buildNavItem('assets/ambulance.png', index: 4),
            ],
          ),
        ),

        // Floating Emergency Button
        Positioned(
          top: 5.h,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15.r,
                  spreadRadius: 0.r,
                  offset: Offset(0.w, 5.h),
                ),
              ],
            ),
            child: FloatingActionButton(
              backgroundColor: const Color(0xFFCD1C18),
              elevation: 0,
              onPressed: () {
                HapticFeedback.lightImpact();
                onEmergencyTap();
              },
              child: Image.asset(
                'assets/emergency.png',
                width: 28.w,
                height: 28.h,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
