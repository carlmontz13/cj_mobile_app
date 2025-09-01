import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/assignment_model.dart';
import '../models/submission_model.dart';
import '../models/image_attachment_model.dart';

class AssignmentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create a new assignment
  Future<AssignmentModel> createAssignment(AssignmentModel assignment) async {
    try {
      final response = await _supabase
          .from('assignments')
          .insert({
            'class_id': assignment.classId,
            'title': assignment.title,
            'description': assignment.description,
            'due_date': assignment.dueDate.toIso8601String(),
            'total_points': assignment.totalPoints,
            'status': assignment.status.toString().split('.').last,
            'created_at': assignment.createdAt.toIso8601String(),
            'attachments': assignment.attachments,
            'instructions': assignment.instructions,
          })
          .select()
          .single();

      return AssignmentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create assignment: $e');
    }
  }

  // Get all assignments for a class
  Future<List<AssignmentModel>> getAssignmentsByClass(String classId) async {
    try {
      final response = await _supabase
          .from('assignments')
          .select('''
            *,
            class:classes!inner(
              id,
              name,
              description,
              teacher_id,
              teacher_name,
              section,
              subject,
              room,
              class_code,
              banner_image_url,
              theme_color,
              created_at
            )
          ''')
          .eq('class_id', classId)
          .order('created_at', ascending: false);

      final assignments = response.map((json) => AssignmentModel.fromJson(json)).toList();
      return assignments;
    } catch (e) {
      throw Exception('Failed to fetch assignments: $e');
    }
  }

  // Get a single assignment by ID
  Future<AssignmentModel?> getAssignmentById(String assignmentId) async {
    try {
      final response = await _supabase
          .from('assignments')
          .select('''
            *,
            class:classes!inner(
              id,
              name,
              description,
              teacher_id,
              teacher_name,
              section,
              subject,
              room,
              class_code,
              banner_image_url,
              theme_color,
              created_at
            )
          ''')
          .eq('id', assignmentId)
          .single();

      return AssignmentModel.fromJson(response);
    } catch (e) {
      if (e.toString().contains('No rows found')) {
        return null;
      }
      throw Exception('Failed to fetch assignment: $e');
    }
  }

  // Update an assignment
  Future<AssignmentModel> updateAssignment(AssignmentModel assignment) async {
    try {
      final response = await _supabase
          .from('assignments')
          .update({
            'title': assignment.title,
            'description': assignment.description,
            'due_date': assignment.dueDate.toIso8601String(),
            'total_points': assignment.totalPoints,
            'status': assignment.status.toString().split('.').last,
            'updated_at': DateTime.now().toIso8601String(),
            'attachments': assignment.attachments,
            'instructions': assignment.instructions,
          })
          .eq('id', assignment.id)
          .select()
          .single();

      return AssignmentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update assignment: $e');
    }
  }

  // Delete an assignment
  Future<void> deleteAssignment(String assignmentId) async {
    try {
      await _supabase
          .from('assignments')
          .delete()
          .eq('id', assignmentId);
    } catch (e) {
      throw Exception('Failed to delete assignment: $e');
    }
  }

  // Submit an assignment (student)
  Future<SubmissionModel> submitAssignment(SubmissionModel submission) async {
    try {
      final response = await _supabase
          .from('submissions')
          .insert({
            'assignment_id': submission.assignmentId,
            'student_id': submission.studentId,
            'student_name': submission.studentName,
            'content': submission.content,
            'image_attachments': submission.imageAttachments?.map((img) => img.toJson()).toList(),
            'submitted_at': submission.submittedAt.toIso8601String(),
            'status': submission.status.toString().split('.').last,
            'is_late': submission.isLate,
          })
          .select()
          .single();

      return SubmissionModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to submit assignment: $e');
    }
  }

  // Get submission for a student and assignment
  Future<SubmissionModel?> getSubmission(String assignmentId, String studentId) async {
    try {
      final response = await _supabase
          .from('submissions')
          .select()
          .eq('assignment_id', assignmentId)
          .eq('student_id', studentId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return SubmissionModel.fromJson(response);
    } catch (e) {
      // If there's an error, just return null instead of throwing
      return null;
    }
  }

  // Get all submissions for an assignment (teacher view)
  Future<List<SubmissionModel>> getSubmissionsByAssignment(String assignmentId) async {
    try {
      print('Fetching submissions for assignment: $assignmentId');
      
      final response = await _supabase
          .from('submissions')
          .select()
          .eq('assignment_id', assignmentId)
          .order('submitted_at', ascending: false);

      print('Raw response from database: $response');
      print('Response type: ${response.runtimeType}');
      print('Response length: ${response.length}');

      final submissions = response.map((json) => SubmissionModel.fromJson(json)).toList();
      print('Parsed ${submissions.length} submissions');
      
      return submissions;
    } catch (e) {
      print('Error in getSubmissionsByAssignment: $e');
      throw Exception('Failed to fetch submissions: $e');
    }
  }

  // Grade a submission (teacher)
  Future<SubmissionModel> gradeSubmission(
    String submissionId,
    int grade,
    String feedback,
  ) async {
    try {
      final response = await _supabase
          .from('submissions')
          .update({
            'grade': grade,
            'feedback': feedback,
            'graded_at': DateTime.now().toIso8601String(),
            'status': SubmissionStatus.graded.toString().split('.').last,
          })
          .eq('id', submissionId)
          .select()
          .single();

      return SubmissionModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to grade submission: $e');
    }
  }

  // Update a submission (student can edit before due date)
  Future<SubmissionModel> updateSubmission(SubmissionModel submission) async {
    try {
      final response = await _supabase
          .from('submissions')
          .update({
            'content': submission.content,
            'image_attachments': submission.imageAttachments?.map((img) => img.toJson()).toList(),
            'submitted_at': submission.submittedAt.toIso8601String(),
            'is_late': submission.isLate,
            'status': submission.status.toString().split('.').last,
          })
          .eq('id', submission.id)
          .select()
          .single();

      return SubmissionModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update submission: $e');
    }
  }

  // Unsubmit a submission (change status back to draft)
  Future<SubmissionModel> unsubmitSubmission(String submissionId) async {
    try {
      final response = await _supabase
          .from('submissions')
          .update({
            'status': SubmissionStatus.draft.toString().split('.').last,
            'submitted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', submissionId)
          .select()
          .single();

      return SubmissionModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to unsubmit submission: $e');
    }
  }

  // Get assignments with submission status for a student
  Future<List<Map<String, dynamic>>> getAssignmentsWithSubmissionStatus(
    String classId,
    String studentId,
  ) async {
    try {
      // Get all assignments for the class
      final assignments = await getAssignmentsByClass(classId);
      final List<Map<String, dynamic>> result = [];

      for (final assignment in assignments) {
        try {
          final submission = await getSubmission(assignment.id, studentId);
          result.add({
            'assignment': assignment,
            'submission': submission,
            'isSubmitted': submission != null,
            'isGraded': submission?.isGraded ?? false,
          });
        } catch (submissionError) {
          // If there's an error getting submission for this assignment, 
          // still include the assignment but with no submission
          result.add({
            'assignment': assignment,
            'submission': null,
            'isSubmitted': false,
            'isGraded': false,
          });
        }
      }

      return result;
    } catch (e) {
      throw Exception('Failed to fetch assignments with submission status: $e');
    }
  }

  // Get assignment statistics for a class
  Future<Map<String, dynamic>> getAssignmentStats(String assignmentId) async {
    try {
      final submissions = await getSubmissionsByAssignment(assignmentId);
      final totalSubmissions = submissions.length;
      final gradedSubmissions = submissions.where((s) => s.isGraded).length;
      final lateSubmissions = submissions.where((s) => s.isLate).length;
      
      double averageGrade = 0;
      if (gradedSubmissions > 0) {
        final totalGrade = submissions
            .where((s) => s.grade != null)
            .fold(0, (sum, s) => sum + (s.grade ?? 0));
        averageGrade = totalGrade / gradedSubmissions;
      }

      return {
        'totalSubmissions': totalSubmissions,
        'gradedSubmissions': gradedSubmissions,
        'lateSubmissions': lateSubmissions,
        'averageGrade': averageGrade,
        'submissionRate': totalSubmissions > 0 ? (totalSubmissions / totalSubmissions) * 100 : 0,
      };
    } catch (e) {
      throw Exception('Failed to fetch assignment statistics: $e');
    }
  }
}
