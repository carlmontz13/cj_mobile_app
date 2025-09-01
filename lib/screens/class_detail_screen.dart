import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../models/class_model.dart';
import '../models/class_enrollment_model.dart';
import '../models/user_model.dart';
import '../models/assignment_model.dart';
import '../models/submission_model.dart';
import '../utils/color_utils.dart';
import '../widgets/auth_guard.dart';
import '../widgets/role_guard.dart';
import '../widgets/teacher_role_guard.dart';
import '../providers/class_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/assignment_provider.dart';
import '../providers/material_provider.dart';
import '../services/enrollment_service.dart';
import '../widgets/assignment_card.dart';
import '../widgets/profile_image_widget.dart';
import 'profile_screen.dart';
import 'edit_class_screen.dart';
import 'create_assignment_screen.dart';
import 'edit_assignment_screen.dart';
import 'assignment_detail_screen.dart';
import 'assignments_list_screen.dart';
import 'create_material_screen.dart';
import 'materials_list_screen.dart';
import 'material_detail_screen.dart';

class ClassDetailScreen extends StatefulWidget {
  final ClassModel classModel;

  const ClassDetailScreen({
    super.key,
    required this.classModel,
  });

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  bool _isStudentsExpanded = false;
  bool _isAssignmentsExpanded = true;
  bool _isMaterialsExpanded = false;
  List<ClassEnrollmentModel>? _enrollments;
  String? _enrollmentsError;
  int? _studentCount;

  @override
  void initState() {
    super.initState();
    // Load assignments when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);
      assignmentProvider.loadAssignments(widget.classModel.id);
      // Preload materials
      final materialProvider = Provider.of<MaterialProvider>(context, listen: false);
      materialProvider.loadMaterials(widget.classModel.id);
      // Preload enrollments
      EnrollmentService().getClassEnrollments(widget.classModel.id).then((list) {
        if (!mounted) return;
        setState(() {
          _enrollments = list;
          _studentCount = list.length;
          _enrollmentsError = null;
        });
      }).catchError((e) {
        if (!mounted) return;
        setState(() {
          _enrollmentsError = e.toString();
          _enrollments = const [];
        });
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when dependencies change (e.g., when navigating back to this screen)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // Method to refresh student count
  void _refreshStudentCount() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      child: RoleGuard(
        classModel: widget.classModel,
        requireEnrollment: true,
        child: Consumer<ClassProvider>(
          builder: (context, classProvider, child) {
            // Get the updated class model from provider if available
            final updatedClass = classProvider.classes.firstWhere(
              (c) => c.id == widget.classModel.id,
              orElse: () => widget.classModel,
            );
            
            return Scaffold(
              backgroundColor: Colors.grey[50],
              appBar: AppBar(
                title: Text(
                  updatedClass.name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: ColorUtils.hexToColor(updatedClass.themeColor ?? '#4285F4'),
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      final currentUser = authProvider.currentUser;
                      if (currentUser == null) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            );
                          },
                          child: ProfileImageWidget(
                            imageUrl: currentUser.profileImageUrl,
                            name: currentUser.name,
                            radius: 16,
                            showBorder: true,
                            borderWidth: 1.5,
                          ),
                        ),
                      );
                    },
                  ),
                  TeacherRoleGuard(
                    classModel: widget.classModel,
                    child: IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () {
                        _showOptionsDialog(context, updatedClass);
                      },
                    ),
                  ),
                ],
              ),
              body: RefreshIndicator(
                onRefresh: () async {
                  // Refresh assignments
                  final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);
                  await assignmentProvider.loadAssignments(updatedClass.id);
                  
                  // Refresh materials
                  final materialProvider = Provider.of<MaterialProvider>(context, listen: false);
                  await materialProvider.loadMaterials(updatedClass.id);
                  
                  // Refresh enrollments
                  try {
                    final list = await EnrollmentService().getClassEnrollments(updatedClass.id);
                    if (mounted) {
                      setState(() {
                        _enrollments = list;
                        _studentCount = list.length;
                        _enrollmentsError = null;
                      });
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        _enrollmentsError = e.toString();
                        _enrollments = const [];
                      });
                    }
                  }
                  
                  // Force rebuild to refresh student count
                  setState(() {});
                },
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header with class info
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: ColorUtils.hexToColor(widget.classModel.themeColor ?? '#4285F4'),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              updatedClass.name,
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              updatedClass.description,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildInfoChip(
                                  icon: Icons.person,
                                  label: updatedClass.teacherName,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 12),
                                _buildInfoChip(
                                  icon: Icons.category,
                                  label: 'Section ${updatedClass.section}',
                                  color: Colors.white,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Role indicator
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, _) {
                                final currentUser = authProvider.currentUser;
                                final isTeacher = currentUser?.role == UserRole.teacher;
                                final ownsClass = currentUser?.id == widget.classModel.teacherId;
                                
                                if (isTeacher && ownsClass) {
                                  return _buildInfoChip(
                                    icon: Icons.admin_panel_settings,
                                    label: 'Class Owner',
                                    color: Colors.amber,
                                  );
                                } else if (isTeacher) {
                                  return _buildInfoChip(
                                    icon: Icons.school,
                                    label: 'Teacher',
                                    color: Colors.lightBlue,
                                  );
                                } else {
                                  return _buildInfoChip(
                                    icon: Icons.person,
                                    label: 'Student',
                                    color: Colors.lightGreen,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      // Class details cards
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Class Code Card
                            _buildDetailCard(
                              title: 'Class Code',
                              subtitle: 'Share this code with your students',
                              content: _buildClassCodeSection(),
                              icon: Icons.code,
                              color: ColorUtils.hexToColor(widget.classModel.themeColor ?? '#4285F4'),
                            ),
                            const SizedBox(height: 16),

                            // Class Information Card
                            _buildDetailCard(
                              title: 'Class Information',
                              subtitle: 'Details about this class',
                              content: _buildClassInfoSection(),
                              icon: Icons.info,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 16),

                            // Students Chip
                            _buildExpandableChip(
                              title: 'Students',
                              subtitle: '${_studentCount ?? updatedClass.studentCount} students enrolled',
                              icon: Icons.people,
                              color: Colors.green,
                              isExpanded: _isStudentsExpanded,
                              onTap: () {
                                setState(() {
                                  _isStudentsExpanded = !_isStudentsExpanded;
                                });
                              },
                              expandedContent: _buildStudentsSectionFromCache(),
                            ),
                            const SizedBox(height: 16),

                            // Assignments Chip
                            _buildExpandableChip(
                              title: 'Assignments',
                              subtitle: 'Manage class assignments',
                              icon: Icons.assignment,
                              color: Colors.orange,
                              isExpanded: _isAssignmentsExpanded,
                              onTap: () {
                                setState(() {
                                  _isAssignmentsExpanded = !_isAssignmentsExpanded;
                                });
                              },
                              expandedContent: _buildAssignmentsSection(updatedClass),
                            ),
                            const SizedBox(height: 16),

                            // Materials Chip
                            _buildMaterialsChip(updatedClass),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              floatingActionButton: Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  final currentUser = authProvider.currentUser;
                  final isTeacher = currentUser?.role == UserRole.teacher;
                  final ownsClass = currentUser?.id == updatedClass.teacherId;
                  
                  if (isTeacher && ownsClass) {
                    return FloatingActionButton(
                      onPressed: () async {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (ctx) {
                            final Color accent = ColorUtils.hexToColor(updatedClass.themeColor ?? '#4285F4');
                            return SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Center(
                                      child: Container(
                                        width: 40,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Quick actions',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    FilledButton.icon(
                                      onPressed: () async {
                                        Navigator.pop(ctx);
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CreateAssignmentScreen(classModel: updatedClass),
                                          ),
                                        );
                                        if (result == true) {
                                          final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);
                                          await assignmentProvider.loadAssignments(updatedClass.id);
                                        }
                                      },
                                      icon: const Icon(Icons.assignment_outlined),
                                      label: Text('Create assignment', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: accent,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    FilledButton.tonalIcon(
                                      onPressed: () async {
                                        Navigator.pop(ctx);
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CreateMaterialScreen(classModel: updatedClass),
                                          ),
                                        );
                                        if (result == true) {
                                          // Reload materials if added
                                          final materialProvider = Provider.of<MaterialProvider>(context, listen: false);
                                          await materialProvider.loadMaterials(updatedClass.id);
                                        }
                                      },
                                      icon: const Icon(Icons.menu_book_rounded),
                                      label: Text('Create material', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      backgroundColor: ColorUtils.hexToColor(updatedClass.themeColor ?? '#4285F4'),
                      child: const Icon(Icons.add, color: Colors.white),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required String subtitle,
    required Widget content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildExpandableChip({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget expandedContent,
  }) {
    return Container(
      width: double.infinity,
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
        children: [
          // Clickable header
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey[600],
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable content with smooth animation
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 1,
                  color: Colors.grey[200],
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  child: expandedContent,
                ),
              ],
            ),
            crossFadeState: isExpanded 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeIn,
          ),
        ],
      ),
    );
  }

  Widget _buildClassCodeSection() {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Class Code',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.classModel.classCode,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.classModel.classCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Class code copied to clipboard!',
                          style: GoogleFonts.poppins(),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF34A853),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.copy, color: Colors.blue),
              tooltip: 'Copy class code',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassInfoSection() {
    return Column(
      children: [
        _buildInfoRow('Subject', widget.classModel.subject),
        const SizedBox(height: 12),
        _buildInfoRow('Room', widget.classModel.room),
        const SizedBox(height: 12),
        _buildInfoRow('Created', _formatDate(widget.classModel.createdAt)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentsSection(ClassModel classModel) {
    return Consumer2<AssignmentProvider, AuthProvider>(
      builder: (context, assignmentProvider, authProvider, child) {
        final currentUser = authProvider.currentUser;
        final isTeacher = currentUser?.role == UserRole.teacher;
        final ownsClass = currentUser?.id == classModel.teacherId;
        
        if (assignmentProvider.isLoading) {
          return const SizedBox.shrink();
        }

        if (assignmentProvider.error != null) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'Error loading assignments',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.red[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  assignmentProvider.error!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.red[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final assignments = assignmentProvider.assignments;

        if (assignments.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'No assignments yet',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first assignment to get started',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        // For students, load assignments with submission status
        if (!isTeacher || !ownsClass) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: assignmentProvider.getAssignmentsWithSubmissionStatus(
              classModel.id,
              currentUser!.id,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }

              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Error loading assignments',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.red[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              final assignmentsWithStatus = snapshot.data ?? [];
              final displayAssignments = assignmentsWithStatus.take(3).toList();

              return Column(
                children: [
                  ...displayAssignments.map((assignmentData) {
                    final assignment = assignmentData['assignment'] as AssignmentModel;
                    final submission = assignmentData['submission'] as SubmissionModel?;
                    
                    return AssignmentCard(
                      assignment: assignment,
                      submission: submission,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AssignmentDetailScreen(
                              assignment: assignment,
                              isTeacher: isTeacher && ownsClass,
                            ),
                          ),
                        ).then((result) {
                          if (result == 'edit') {
                            _editAssignment(context, assignment);
                          } else if (result == 'deleted') {
                            // Assignment was deleted, refresh the list
                            final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);
                            assignmentProvider.loadAssignments(widget.classModel.id);
                          }
                        });
                      },
                      isTeacher: isTeacher && ownsClass,
                      showSubmissionStatus: true,
                      onEdit: () => _editAssignment(context, assignment),
                      onDelete: () => _deleteAssignment(context, assignment),
                    );
                  }),
                  if (assignmentsWithStatus.length > 3) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AssignmentsListScreen(classModel: widget.classModel),
                            ),
                          );
                        },
                        child: const Text('View All Assignments'),
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        }

        // For teachers, show assignments without submission status
        return Column(
          children: [
            ...assignments.take(3).map((assignment) {
              return AssignmentCard(
                assignment: assignment,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssignmentDetailScreen(
                        assignment: assignment,
                        isTeacher: isTeacher && ownsClass,
                      ),
                    ),
                  ).then((result) {
                    if (result == 'edit') {
                      _editAssignment(context, assignment);
                    } else if (result == 'deleted') {
                      // Assignment was deleted, refresh the list
                      final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);
                      assignmentProvider.loadAssignments(widget.classModel.id);
                    }
                  });
                },
                isTeacher: isTeacher && ownsClass,
                showSubmissionStatus: false,
                onEdit: () => _editAssignment(context, assignment),
                onDelete: () => _deleteAssignment(context, assignment),
              );
            }),
            if (assignments.length > 3) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AssignmentsListScreen(classModel: widget.classModel),
                      ),
                    );
                  },
                  child: const Text('View All Assignments'),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStudentsSection(String classId) {
    return FutureBuilder<List<ClassEnrollmentModel>>(
      future: EnrollmentService().getClassEnrollments(classId),
      builder: (context, snapshot) {
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildStudentsSectionFromCache() {
    if (_enrollmentsError != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Error loading students',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.red[600],
              ),
            ),
          ],
        ),
      );
    }

    final enrollments = _enrollments ?? const <ClassEnrollmentModel>[];

    if (enrollments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No students yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Students can join using the class code',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: enrollments.map((enrollment) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[300],
            child: Text(
              enrollment.studentName.isNotEmpty 
                  ? enrollment.studentName[0].toUpperCase()
                  : 'S',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          title: Text(
            enrollment.studentName.isNotEmpty 
                ? enrollment.studentName 
                : 'Student ${enrollment.studentId.substring(0, 8)}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            enrollment.studentEmail,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: enrollment.status == 'active' 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              enrollment.status,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: enrollment.status == 'active' 
                    ? Colors.green[700]
                    : Colors.grey[600],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _editAssignment(BuildContext context, AssignmentModel assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAssignmentScreen(
          assignment: assignment,
          classModel: widget.classModel,
        ),
      ),
    ).then((result) {
      // Refresh assignments if assignment was updated successfully
      if (result == true) {
        final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);
        assignmentProvider.loadAssignments(widget.classModel.id);
      }
    });
  }

  void _deleteAssignment(BuildContext context, AssignmentModel assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Assignment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete "${assignment.title}"? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);
              final success = await assignmentProvider.deleteAssignment(assignment.id);
              
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Assignment "${assignment.title}" deleted successfully!',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: const Color(0xFF34A853),
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error deleting assignment: ${assignmentProvider.error}',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsDialog(BuildContext context, ClassModel classModel) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    // Check if user is a teacher and owns this class
    final isTeacher = currentUser?.role == UserRole.teacher;
    final ownsClass = currentUser?.id == classModel.teacherId;
    final canManage = isTeacher && ownsClass;
    
    // Double-check role guard - if user cannot manage, show error and return
    if (!canManage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Access denied. Only the class teacher can manage this class.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Class Options',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canManage) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: Text(
                  'Edit Class',
                  style: GoogleFonts.poppins(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditClassScreen(classModel: classModel),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.people, color: Colors.green),
                title: Text(
                  'Manage Students',
                  style: GoogleFonts.poppins(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to manage students screen
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'Delete Class',
                  style: GoogleFonts.poppins(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context);
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.info, color: Colors.blue),
                title: Text(
                  'View Class Info',
                  style: GoogleFonts.poppins(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Already viewing class info
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Class',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.classModel.name}"? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final classProvider = Provider.of<ClassProvider>(context, listen: false);
              final success = await classProvider.deleteClass(widget.classModel.id);
              
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Class "${widget.classModel.name}" deleted successfully!',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: const Color(0xFF34A853),
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error deleting class: ${classProvider.errorMessage}',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsChip(ClassModel classModel) {
    return Consumer2<MaterialProvider, AuthProvider>(
      builder: (context, materialProvider, authProvider, child) {
        final currentUser = authProvider.currentUser;
        final isTeacher = currentUser?.role == UserRole.teacher;
        final ownsClass = currentUser?.id == classModel.teacherId;
        
        // Load materials if not already loaded
        if (materialProvider.materials.isEmpty && !materialProvider.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            materialProvider.loadMaterials(classModel.id);
          });
        }

        String subtitle = 'View class materials';
        if (materialProvider.isLoading) {
          subtitle = 'Loading materials...';
        } else if (materialProvider.error != null) {
          subtitle = 'Error loading materials';
        } else {
          final count = materialProvider.materials.length;
          subtitle = '$count material${count == 1 ? '' : 's'} available';
        }

        return _buildExpandableChip(
          title: 'Materials',
          subtitle: subtitle,
          icon: Icons.menu_book_rounded,
          color: Colors.purple,
          isExpanded: _isMaterialsExpanded,
          onTap: () {
            setState(() {
              _isMaterialsExpanded = !_isMaterialsExpanded;
            });
          },
          expandedContent: _buildMaterialsSection(classModel),
        );
      },
    );
  }

  Widget _buildMaterialsSection(ClassModel classModel) {
    return Consumer2<MaterialProvider, AuthProvider>(
      builder: (context, materialProvider, authProvider, child) {
        final currentUser = authProvider.currentUser;
        final isTeacher = currentUser?.role == UserRole.teacher;
        final ownsClass = currentUser?.id == classModel.teacherId;
        
        if (materialProvider.isLoading) {
          return const SizedBox.shrink();
        }

        if (materialProvider.error != null) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'Error loading materials',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.red[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  materialProvider.error!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.red[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final materials = materialProvider.materials;

        if (materials.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.menu_book_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'No materials yet',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first material to get started',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        // Show first 3 materials
        final displayMaterials = materials.take(3).toList();

        return Column(
          children: [
            ...displayMaterials.map((material) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.purple,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    material.title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    'Created ${_formatDate(material.createdAt)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: material.selectedContentType != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getContentTypeColor(material.selectedContentType!).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getContentTypeLabel(material.selectedContentType!),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: _getContentTypeColor(material.selectedContentType!),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MaterialDetailScreen(
                          material: material,
                          classModel: classModel,
                          isTeacher: isTeacher && ownsClass,
                        ),
                      ),
                    ).then((result) {
                      if (result == 'deleted') {
                        // Material was deleted, refresh the list
                        materialProvider.loadMaterials(classModel.id);
                      }
                    });
                  },
                ),
              );
            }),
            if (materials.length > 3) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MaterialsListScreen(classModel: classModel),
                      ),
                    );
                  },
                  child: const Text('View All Materials'),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Color _getContentTypeColor(String contentType) {
    switch (contentType) {
      case 'simplified':
        return Colors.green;
      case 'standard':
        return Colors.blue;
      case 'advanced':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getContentTypeLabel(String contentType) {
    switch (contentType) {
      case 'simplified':
        return 'Simplified';
      case 'standard':
        return 'Standard';
      case 'advanced':
        return 'Advanced';
      default:
        return 'Unknown';
    }
  }
}
