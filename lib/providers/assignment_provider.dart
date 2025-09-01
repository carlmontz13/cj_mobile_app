import 'package:flutter/foundation.dart';
import '../models/assignment_model.dart';
import '../models/submission_model.dart';
import '../services/assignment_service.dart';

class AssignmentProvider extends ChangeNotifier {
  final AssignmentService _assignmentService = AssignmentService();
  
  List<AssignmentModel> _assignments = [];
  List<SubmissionModel> _submissions = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<AssignmentModel> get assignments => _assignments;
  List<SubmissionModel> get submissions => _submissions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  // Load assignments for a class
  Future<void> loadAssignments(String classId) async {
    try {
      _setLoading(true);
      _assignments = await _assignmentService.getAssignmentsByClass(classId);
      _error = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Create a new assignment
  Future<bool> createAssignment(AssignmentModel assignment) async {
    try {
      _setLoading(true);
      final newAssignment = await _assignmentService.createAssignment(assignment);
      _assignments.insert(0, newAssignment);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Update an assignment
  Future<bool> updateAssignment(AssignmentModel assignment) async {
    try {
      _setLoading(true);
      final updatedAssignment = await _assignmentService.updateAssignment(assignment);
      final index = _assignments.indexWhere((a) => a.id == assignment.id);
      if (index != -1) {
        _assignments[index] = updatedAssignment;
      }
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Delete an assignment
  Future<bool> deleteAssignment(String assignmentId) async {
    try {
      _setLoading(true);
      await _assignmentService.deleteAssignment(assignmentId);
      _assignments.removeWhere((a) => a.id == assignmentId);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Load submissions for an assignment
  Future<void> loadSubmissions(String assignmentId) async {
    try {
      _setLoading(true);
      _submissions = await _assignmentService.getSubmissionsByAssignment(assignmentId);
      _error = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Submit an assignment (student)
  Future<bool> submitAssignment(SubmissionModel submission) async {
    try {
      _setLoading(true);
      final newSubmission = await _assignmentService.submitAssignment(submission);
      _submissions.insert(0, newSubmission);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Update a submission
  Future<bool> updateSubmission(SubmissionModel submission) async {
    try {
      _setLoading(true);
      final updatedSubmission = await _assignmentService.updateSubmission(submission);
      final index = _submissions.indexWhere((s) => s.id == submission.id);
      if (index != -1) {
        _submissions[index] = updatedSubmission;
      }
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Unsubmit a submission
  Future<bool> unsubmitSubmission(String submissionId) async {
    try {
      _setLoading(true);
      final updatedSubmission = await _assignmentService.unsubmitSubmission(submissionId);
      final index = _submissions.indexWhere((s) => s.id == submissionId);
      if (index != -1) {
        _submissions[index] = updatedSubmission;
      }
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Grade a submission (teacher)
  Future<bool> gradeSubmission(String submissionId, int grade, String feedback) async {
    try {
      _setLoading(true);
      final gradedSubmission = await _assignmentService.gradeSubmission(submissionId, grade, feedback);
      final index = _submissions.indexWhere((s) => s.id == submissionId);
      if (index != -1) {
        _submissions[index] = gradedSubmission;
      }
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Get assignment with submission status for a student
  Future<List<Map<String, dynamic>>> getAssignmentsWithSubmissionStatus(
    String classId,
    String studentId,
  ) async {
    try {
      return await _assignmentService.getAssignmentsWithSubmissionStatus(classId, studentId);
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  // Get assignment statistics
  Future<Map<String, dynamic>> getAssignmentStats(String assignmentId) async {
    try {
      return await _assignmentService.getAssignmentStats(assignmentId);
    } catch (e) {
      _setError(e.toString());
      return {};
    }
  }

  // Get a single assignment by ID
  Future<AssignmentModel?> getAssignmentById(String assignmentId) async {
    try {
      return await _assignmentService.getAssignmentById(assignmentId);
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  // Get submission for a student and assignment
  Future<SubmissionModel?> getSubmission(String assignmentId, String studentId) async {
    try {
      return await _assignmentService.getSubmission(assignmentId, studentId);
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  // Clear all data
  void clear() {
    _assignments.clear();
    _submissions.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
