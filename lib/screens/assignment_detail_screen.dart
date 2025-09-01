import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/assignment_model.dart';
import '../models/submission_model.dart';
import '../models/user_model.dart';
import '../models/image_attachment_model.dart';
import '../providers/assignment_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/image_attachment_widget.dart';
import 'submission_screen.dart';
import 'view_submissions_screen.dart';
import 'edit_assignment_screen.dart';
import '../utils/color_utils.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final AssignmentModel assignment;
  final bool isTeacher;

  const AssignmentDetailScreen({
    super.key,
    required this.assignment,
    required this.isTeacher,
  });

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  SubmissionModel? _submission;

  @override
  void initState() {
    super.initState();
    _loadSubmission();
  }

  Future<void> _loadSubmission() async {
    if (!widget.isTeacher) {
      final authProvider = context.read<AuthProvider>();
      final assignmentProvider = context.read<AssignmentProvider>();
      
      final submission = await assignmentProvider.getSubmission(
        widget.assignment.id,
        authProvider.currentUser!.id,
      );
      
      if (mounted) {
        setState(() {
          _submission = submission;
        });
      }
    }
  }

  String _getLetterGrade(double percentage) {
    if (percentage >= 93) return 'A';
    if (percentage >= 90) return 'A-';
    if (percentage >= 87) return 'B+';
    if (percentage >= 83) return 'B';
    if (percentage >= 80) return 'B-';
    if (percentage >= 77) return 'C+';
    if (percentage >= 73) return 'C';
    if (percentage >= 70) return 'C-';
    if (percentage >= 67) return 'D+';
    if (percentage >= 63) return 'D';
    if (percentage >= 60) return 'D-';
    return 'F';
  }

  Color _getGradeColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.lightGreen;
    if (percentage >= 70) return Colors.orange;
    if (percentage >= 60) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.assignment.title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: ColorUtils.hexToColor(
          widget.assignment.classDetails?.themeColor ??
          '#4285F4',
        ),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          if (widget.isTeacher)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editAssignment();
                      break;
                    case 'delete':
                      _deleteAssignment();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  _buildCustomMenuItem(
                    value: 'edit',
                    icon: Icons.edit,
                    label: 'Edit Assignment',
                    color: Colors.blue,
                  ),
                  _buildCustomMenuItem(
                    value: 'delete',
                    icon: Icons.delete,
                    label: 'Delete Assignment',
                    color: Colors.red,
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAssignmentHeader(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildAssignmentDetails(),
                  if (widget.assignment.instructions != null) ...[
                    const SizedBox(height: 16),
                    _buildInstructions(),
                  ],
                  if (widget.assignment.attachments != null && 
                      widget.assignment.attachments!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildAttachments(),
                  ],
                  if (!widget.isTeacher && _submission != null) ...[
                    const SizedBox(height: 16),
                    _buildSubmissionDetails(),
                  ],
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final classThemeColor = ColorUtils.hexToColor(
      widget.assignment.classDetails?.themeColor ?? '#4285F4',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: classThemeColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.assignment,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.assignment.title,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.assignment.description,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.schedule,
                label: DateFormat('MMM dd, yyyy').format(widget.assignment.dueDate),
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                icon: Icons.grade,
                label: '${widget.assignment.totalPoints} points',
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              _buildStatusChip(),
            ],
          ),
        ],
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

  Widget _buildStatusChip() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    Color chipColor;
    String statusText;
    IconData statusIcon;
    
    switch (widget.assignment.status) {
      case AssignmentStatus.active:
        chipColor = Colors.green;
        statusText = 'Active';
        statusIcon = Icons.check_circle;
        break;
      case AssignmentStatus.inactive:
        chipColor = Colors.grey;
        statusText = 'Inactive';
        statusIcon = Icons.pause_circle;
        break;
      case AssignmentStatus.archived:
        chipColor = Colors.orange;
        statusText = 'Archived';
        statusIcon = Icons.archive;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 16, color: chipColor),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentDetails() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _buildDetailCard(
      title: 'Assignment Details',
      subtitle: 'Important information about this assignment',
      content: Column(
        children: [
          _buildDetailRow(
            icon: Icons.schedule,
            label: 'Due Date',
            value: DateFormat('EEEE, MMMM dd, yyyy').format(widget.assignment.dueDate),
            isOverdue: widget.assignment.isOverdue,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.grade,
            label: 'Total Points',
            value: '${widget.assignment.totalPoints} points',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.calendar_today,
            label: 'Created',
            value: DateFormat('MMM dd, yyyy').format(widget.assignment.createdAt),
          ),
          if (!widget.isTeacher && _submission != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.upload,
              label: 'Submitted',
              value: DateFormat('MMM dd, yyyy').format(_submission!.submittedAt),
              isLate: _submission!.isLate,
            ),
            if (_submission!.isGraded) ...[
              const SizedBox(height: 16),
              _buildGradeSection(),
            ],
          ],
        ],
      ),
      icon: Icons.info,
      color: Colors.blue,
    );
  }

  Widget _buildGradeSection() {
    final grade = _submission!.grade!;
    final totalPoints = widget.assignment.totalPoints;
    final percentage = (grade / totalPoints) * 100;
    final letterGrade = _getLetterGrade(percentage);
    final gradeColor = _getGradeColor(percentage);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: gradeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.grade,
                size: 20,
                color: gradeColor,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Grade Results',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Grade points
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: gradeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: gradeColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Points',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$grade/$totalPoints',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: gradeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Percentage
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: gradeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: gradeColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Percentage',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: gradeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
        if (_submission!.hasFeedback) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.feedback,
                      size: 20,
                      color: Colors.blue[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Teacher Feedback:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _submission!.feedback!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
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

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isOverdue = false,
    bool isLate = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isOverdue || isLate 
              ? colorScheme.error 
              : colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isOverdue || isLate 
                      ? colorScheme.error 
                      : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return _buildDetailCard(
      title: 'Instructions',
      subtitle: 'Follow these guidelines for your submission',
      content: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          widget.assignment.instructions!,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
      ),
      icon: Icons.description,
      color: Colors.orange,
    );
  }

  Widget _buildAttachments() {
    return _buildDetailCard(
      title: 'Attachments',
      subtitle: '${widget.assignment.attachments!.length} file(s) attached',
      content: Column(
        children: widget.assignment.attachments!.map((attachment) => 
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.attach_file,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    attachment.split('/').last,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // TODO: Open attachment
                  },
                  icon: const Icon(
                    Icons.open_in_new,
                    color: Colors.blue,
                    size: 20,
                  ),
                  tooltip: 'Open attachment',
                ),
              ],
            ),
          ),
        ).toList(),
      ),
      icon: Icons.attach_file,
      color: Colors.purple,
    );
  }

  Widget _buildSubmissionDetails() {
    return _buildDetailCard(
      title: 'Your Submission',
      subtitle: _submission!.isGraded ? 'Graded submission' : 'Submitted for review',
      content: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              _submission!.content,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
          if (_submission!.imageAttachments != null && 
              _submission!.imageAttachments!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Attached Images:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            ImageAttachmentGrid(
              attachments: _submission!.imageAttachments!,
              showDeleteButton: false,
            ),
          ],
        ],
      ),
      icon: Icons.upload_file,
      color: Colors.green,
    );
  }

  Widget _buildActionButtons() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final classThemeColor = ColorUtils.hexToColor(
      widget.assignment.classDetails?.themeColor ?? '#4285F4',
    );

    if (widget.isTeacher) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewSubmissionsScreen(
                      assignment: widget.assignment,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: classThemeColor,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.people),
              label: const Text('View Submissions'),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          if (_submission == null) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: widget.assignment.isActive ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubmissionScreen(
                        assignment: widget.assignment,
                      ),
                    ),
                  ).then((_) => _loadSubmission());
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.assignment.isActive 
                      ? classThemeColor 
                      : colorScheme.surfaceVariant,
                  foregroundColor: widget.assignment.isActive 
                      ? Colors.white 
                      : colorScheme.onSurfaceVariant,
                  elevation: widget.assignment.isActive ? 2 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.upload),
                label: const Text('Submit Assignment'),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: widget.assignment.isActive && !_submission!.isGraded ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubmissionScreen(
                        assignment: widget.assignment,
                        submission: _submission,
                      ),
                    ),
                  ).then((_) => _loadSubmission());
                } : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: (widget.assignment.isActive && !_submission!.isGraded)
                      ? classThemeColor
                      : colorScheme.onSurfaceVariant,
                  side: BorderSide(
                    color: (widget.assignment.isActive && !_submission!.isGraded)
                        ? classThemeColor
                        : colorScheme.outline,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Submission'),
              ),
            ),
          ],
        ],
      );
    }
  }

  void _editAssignment() {
    // We need to get the class model from the provider or pass it as a parameter
    // For now, we'll navigate back and let the parent handle the edit
    Navigator.pop(context, 'edit');
  }

  void _deleteAssignment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: Text(
          'Are you sure you want to delete "${widget.assignment.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);
              final success = await assignmentProvider.deleteAssignment(widget.assignment.id);
              
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Assignment "${widget.assignment.title}" deleted successfully!'),
                    backgroundColor: const Color(0xFF34A853),
                  ),
                );
                Navigator.pop(context, 'deleted');
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting assignment: ${assignmentProvider.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildCustomMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color == Colors.red ? Colors.red : Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
