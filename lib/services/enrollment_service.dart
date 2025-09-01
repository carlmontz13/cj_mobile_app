import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/class_enrollment_model.dart';

class EnrollmentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all enrollments for a class
  Future<List<ClassEnrollmentModel>> getClassEnrollments(String classId) async {
    try {
      final response = await _supabase
          .rpc('get_class_students', params: {'class_id_param': classId});

      if (response is List) {
        return response.map((json) => ClassEnrollmentModel.fromJson(json)).toList();
      } else {
        // Fallback to direct query if RPC fails
        final directResponse = await _supabase
            .from('class_enrollments')
            .select('*')
            .eq('class_id', classId)
            .eq('status', 'active');

        return directResponse.map((json) => ClassEnrollmentModel.fromJson(json)).toList();
      }
    } catch (e) {
      // Fallback to direct query
      try {
        final directResponse = await _supabase
            .from('class_enrollments')
            .select('*')
            .eq('class_id', classId)
            .eq('status', 'active');

        return directResponse.map((json) => ClassEnrollmentModel.fromJson(json)).toList();
      } catch (fallbackError) {
        throw Exception('Failed to fetch class enrollments: $fallbackError');
      }
    }
  }

  // Join a class using class code
  Future<bool> joinClass(String classCode, String studentId) async {
    try {
      final response = await _supabase
          .rpc('join_class', params: {
            'class_code_param': classCode,
            'student_id_param': studentId,
          });

      if (response['success'] == true) {
        return true;
      } else {
        throw Exception(response['error'] ?? 'Failed to join class');
      }
    } catch (e) {
      throw Exception('Failed to join class: $e');
    }
  }

  // Leave a class
  Future<bool> leaveClass(String classId, String studentId) async {
    try {
      final response = await _supabase
          .rpc('leave_class', params: {
            'class_id_param': classId,
            'student_id_param': studentId,
          });

      if (response['success'] == true) {
        return true;
      } else {
        throw Exception(response['error'] ?? 'Failed to leave class');
      }
    } catch (e) {
      throw Exception('Failed to leave class: $e');
    }
  }

  // Check if student is enrolled in a class
  Future<bool> isEnrolled(String classId, String studentId) async {
    try {
      final response = await _supabase
          .from('class_enrollments')
          .select('id')
          .eq('class_id', classId)
          .eq('student_id', studentId)
          .eq('status', 'active')
          .single();

      return response.isNotEmpty;
    } catch (e) {
      // If no enrollment found, return false
      return false;
    }
  }

  // Get enrollment count for a class
  Future<int> getClassEnrollmentCount(String classId) async {
    try {
      final response = await _supabase
          .from('class_enrollments')
          .select('id')
          .eq('class_id', classId)
          .eq('status', 'active');

      return response.length;
    } catch (e) {
      return 0;
    }
  }

  // Update enrollment status
  Future<bool> updateEnrollmentStatus(String enrollmentId, String status) async {
    try {
      await _supabase
          .from('class_enrollments')
          .update({'status': status})
          .eq('id', enrollmentId);

      return true;
    } catch (e) {
      throw Exception('Failed to update enrollment status: $e');
    }
  }

  // Get all classes a student is enrolled in
  Future<List<String>> getStudentClassIds(String studentId) async {
    try {
      final response = await _supabase
          .from('class_enrollments')
          .select('class_id')
          .eq('student_id', studentId)
          .eq('status', 'active');

      return response.map((json) => json['class_id'] as String).toList();
    } catch (e) {
      return [];
    }
  }
}
