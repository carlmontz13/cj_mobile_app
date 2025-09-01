import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/class_model.dart';
import '../models/assignment_model.dart';
import '../models/submission_model.dart';
import '../models/user_model.dart';
import '../providers/assignment_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/assignment_card.dart';
import 'assignment_detail_screen.dart';
import 'edit_assignment_screen.dart';

class AssignmentsListScreen extends StatefulWidget {
  final ClassModel classModel;

  const AssignmentsListScreen({
    super.key,
    required this.classModel,
  });

  @override
  State<AssignmentsListScreen> createState() => _AssignmentsListScreenState();
}

class _AssignmentsListScreenState extends State<AssignmentsListScreen> {
  List<Map<String, dynamic>> _assignmentsWithStatus = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      final assignmentProvider = context.read<AssignmentProvider>();
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser!;

      // First load assignments to the provider
      await assignmentProvider.loadAssignments(widget.classModel.id);
      
      // Then get assignments with submission status
      final assignmentsWithStatus = await assignmentProvider.getAssignmentsWithSubmissionStatus(
        widget.classModel.id,
        currentUser.id,
      );

      if (mounted) {
        setState(() {
          _assignmentsWithStatus = assignmentsWithStatus;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading assignments: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Assignments - ${widget.classModel.name}',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAssignments,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _assignmentsWithStatus.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _assignmentsWithStatus.length,
                itemBuilder: (context, index) {
                  final assignmentData = _assignmentsWithStatus[index];
                  
                  // Add null safety and type checking
                  if (assignmentData == null || !assignmentData.containsKey('assignment')) {
                    return const SizedBox.shrink();
                  }
                  
                  final assignment = assignmentData['assignment'];
                  if (assignment == null || assignment is! AssignmentModel) {
                    return const SizedBox.shrink();
                  }
                  
                  final submission = assignmentData['submission'] as SubmissionModel?;
                  final isSubmitted = assignmentData['isSubmitted'] as bool? ?? false;
                  final isGraded = assignmentData['isGraded'] as bool? ?? false;

                  return Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      final currentUser = authProvider.currentUser;
                      final isTeacher = currentUser?.role == UserRole.teacher;
                      final ownsClass = currentUser?.id == widget.classModel.teacherId;
                      
                      return AssignmentCard(
                        assignment: assignment,
                        submission: submission,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AssignmentDetailScreen(
                                assignment: assignment,
                                isTeacher: isTeacher && ownsClass,
                              ),
                            ),
                          );
                          
                          if (result == 'edit') {
                            _editAssignment(context, assignment);
                          } else if (result == 'deleted') {
                            // Assignment was deleted, refresh the list
                            _loadAssignments();
                          } else {
                            // Refresh assignments after returning from detail screen
                            _loadAssignments();
                          }
                        },
                        isTeacher: isTeacher && ownsClass,
                        showSubmissionStatus: !isTeacher || !ownsClass,
                        onEdit: isTeacher && ownsClass ? () => _editAssignment(context, assignment) : null,
                        onDelete: isTeacher && ownsClass ? () => _deleteAssignment(context, assignment) : null,
                      );
                    },
                  );
                },
              ),
      ),
    );
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
        _loadAssignments();
      }
    });
  }

  void _deleteAssignment(BuildContext context, AssignmentModel assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: Text(
          'Are you sure you want to delete "${assignment.title}"? This action cannot be undone.',
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
              final success = await assignmentProvider.deleteAssignment(assignment.id);
              
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Assignment "${assignment.title}" deleted successfully!'),
                    backgroundColor: const Color(0xFF34A853),
                  ),
                );
                _loadAssignments();
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

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No assignments yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your teacher will create assignments here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
