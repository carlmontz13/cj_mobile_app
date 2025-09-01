import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../models/class_model.dart';

class TeacherRoleGuard extends StatelessWidget {
  final Widget child;
  final ClassModel classModel;
  final Widget? unauthorizedWidget;

  const TeacherRoleGuard({
    super.key,
    required this.child,
    required this.classModel,
    this.unauthorizedWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final currentUser = authProvider.currentUser;
        final isTeacher = currentUser?.role == UserRole.teacher;
        final ownsClass = currentUser?.id == classModel.teacherId;
        final canManage = isTeacher && ownsClass;
        
        // Debug logging
        print('TeacherRoleGuard: Role check - User: ${currentUser?.name}, Role: ${currentUser?.role}, TeacherId: ${classModel.teacherId}, CanManage: $canManage');
        
        if (!canManage) {
          print('TeacherRoleGuard: Hiding widget - User cannot manage this class');
          return unauthorizedWidget ?? const SizedBox.shrink();
        }
        
        print('TeacherRoleGuard: Showing widget - User can manage this class');
        return child;
      },
    );
  }
}
