import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/class_model.dart';
import '../models/user_model.dart';
import '../utils/color_utils.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/teacher_role_guard.dart';

class ClassCard extends StatelessWidget {
  final ClassModel classModel;
  final VoidCallback onTap;

  const ClassCard({
    super.key,
    required this.classModel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with color
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: ColorUtils.hexToColor(classModel.themeColor ?? '#4285F4'),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Stack(
                children: [
                  // Background pattern
                  Positioned.fill(
                    child: CustomPaint(
                      painter: PatternPainter(
                        color: ColorUtils.hexToColor(classModel.themeColor ?? '#4285F4'),
                      ),
                    ),
                  ),
                  // Class name overlay
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Text(
                      classModel.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
             // Content
             Expanded(
               child: Padding(
                 padding: const EdgeInsets.all(12),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     // Subject and section
                     Row(
                       children: [
                         Icon(
                           Icons.book,
                           size: 14,
                           color: Colors.grey[600],
                         ),
                         const SizedBox(width: 4),
                         Expanded(
                           child: Text(
                             classModel.subject,
                             style: GoogleFonts.poppins(
                               fontSize: 11,
                               fontWeight: FontWeight.w500,
                               color: Colors.grey[700],
                             ),
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                           ),
                         ),
                       ],
                     ),
                     const SizedBox(height: 2),
                     Row(
                       children: [
                         Icon(
                           Icons.category,
                           size: 14,
                           color: Colors.grey[600],
                         ),
                         const SizedBox(width: 4),
                         Text(
                           'Section ${classModel.section}',
                           style: GoogleFonts.poppins(
                             fontSize: 11,
                             color: Colors.grey[600],
                           ),
                         ),
                       ],
                     ),
                     const SizedBox(height: 4),
                     
                     // Room
                     Row(
                       children: [
                         Icon(
                           Icons.room,
                           size: 14,
                           color: Colors.grey[600],
                         ),
                         const SizedBox(width: 4),
                         Expanded(
                           child: Text(
                             classModel.room,
                             style: GoogleFonts.poppins(
                               fontSize: 11,
                               color: Colors.grey[600],
                             ),
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                           ),
                         ),
                       ],
                     ),
                     const SizedBox(height: 4),
                     
                     // Students count
                     Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        if (authProvider.currentUser?.role == UserRole.teacher) {
                          return TeacherRoleGuard(
                            classModel: classModel,
                            child: 
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${classModel.studentCount} students',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        );
                        }
                        return const SizedBox.shrink();
                      },
                     ),
                     const Spacer(),
                     
                     // Class code
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                       decoration: BoxDecoration(
                         color: Colors.grey[100],
                         borderRadius: BorderRadius.circular(3),
                       ),
                       child: Text(
                         'Code: ${classModel.classCode}',
                         style: GoogleFonts.poppins(
                           fontSize: 9,
                           fontWeight: FontWeight.w600,
                           color: Colors.grey[700],
                         ),
                       ),
                     ),
                   ],
                 ),
               ),
             ),
          ],
        ),
      ),
    );
  }
}

class PatternPainter extends CustomPainter {
  final Color color;

  PatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = 1;

    // Draw diagonal lines
    for (int i = 0; i < size.width + size.height; i += 20) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(0, i.toDouble()),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
