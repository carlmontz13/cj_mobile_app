import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../models/class_model.dart';
import '../services/enrollment_service.dart';

class RoleGuard extends StatelessWidget {
  final Widget child;
  final ClassModel? classModel;
  final List<UserRole> allowedRoles;
  final bool requireEnrollment;
  final Widget? unauthorizedWidget;

  const RoleGuard({
    super.key,
    required this.child,
    this.classModel,
    this.allowedRoles = const [UserRole.teacher, UserRole.student],
    this.requireEnrollment = false,
    this.unauthorizedWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final currentUser = authProvider.currentUser;
        
        if (currentUser == null) {
          return _buildUnauthorizedWidget(
            context,
            'Authentication required',
            'Please log in to access this feature.',
          );
        }

        // Check if user role is allowed
        if (!allowedRoles.contains(currentUser.role)) {
          return _buildUnauthorizedWidget(
            context,
            'Access Denied',
            'You do not have permission to access this feature.',
          );
        }

        // If class model is provided and enrollment is required, check enrollment
        if (classModel != null && requireEnrollment) {
          return FutureBuilder<bool>(
            future: _checkEnrollment(context, currentUser, classModel!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Color(0xFF4285F4),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school,
                          size: 80,
                          color: Colors.white,
                        ),
                        SizedBox(height: 24),
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildUnauthorizedWidget(
                  context,
                  'Error',
                  'Unable to verify access permissions.',
                );
              }

              final isEnrolled = snapshot.data ?? false;
              if (!isEnrolled) {
                return _buildUnauthorizedWidget(
                  context,
                  'Access Denied',
                  'You must be enrolled in this class to view its details.',
                );
              }

              return child;
            },
          );
        }

        // If no class model or enrollment not required, show the child
        return child;
      },
    );
  }

  Future<bool> _checkEnrollment(BuildContext context, UserModel user, ClassModel classModel) async {
    try {
      // If user is a teacher, check if they own the class
      if (user.role == UserRole.teacher) {
        return user.id == classModel.teacherId;
      }

      // If user is a student, check if they are enrolled
      if (user.role == UserRole.student) {
        final enrollmentService = EnrollmentService();
        return await enrollmentService.isEnrolled(classModel.id, user.id);
      }

      return false;
    } catch (e) {
      print('RoleGuard: Error checking enrollment: $e');
      return false;
    }
  }

  Widget _buildUnauthorizedWidget(BuildContext context, String title, String message) {
    if (unauthorizedWidget != null) {
      return unauthorizedWidget!;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF4285F4),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4285F4),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Go Back',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
