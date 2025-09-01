import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/class_model.dart';
import 'enrollment_service.dart';

class ClassService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Test database connection and table existence
  Future<void> testConnection() async {
    try {
      print('ClassService: Testing database connection...');
      
      // Test if classes table exists
      final testResponse = await _supabase
          .from('classes')
          .select('count')
          .limit(1);
      
      print('ClassService: Database connection successful');
      print('ClassService: classes table is accessible');
      
      // Test if class_enrollments table exists
      final enrollmentTest = await _supabase
          .from('class_enrollments')
          .select('count')
          .limit(1);
      
      print('ClassService: class_enrollments table is accessible');
      
    } catch (e) {
      print('ClassService: Database connection test failed: $e');
      throw Exception('Database connection failed: $e');
    }
  }

  // Create a new class
  Future<ClassModel> createClass(ClassModel classModel) async {
    try {
      final response = await _supabase
          .from('classes')
          .insert({
            'name': classModel.name,
            'description': classModel.description,
            'teacher_id': classModel.teacherId,
            'teacher_name': classModel.teacherName,
            'section': classModel.section,
            'subject': classModel.subject,
            'room': classModel.room,
            'class_code': classModel.classCode,
            'created_at': classModel.createdAt.toIso8601String(),
            'banner_image_url': classModel.bannerImageUrl,
            'theme_color': classModel.themeColor,
          })
          .select()
          .single();

      // New classes start with 0 students
      return ClassModel.fromJson({
        ...response,
        'student_count': 0,
      });
    } catch (e) {
      throw Exception('Failed to create class: $e');
    }
  }

  // Get all classes for a teacher
  Future<List<ClassModel>> getClassesByTeacher(String teacherId) async {
    try {
      print('ClassService: Getting classes for teacher: $teacherId');
      
      final response = await _supabase
          .from('classes')
          .select()
          .eq('teacher_id', teacherId)
          .order('created_at', ascending: false);

      print('ClassService: Retrieved ${response.length} classes for teacher');
      print('ClassService: Response data: $response');
      
      if (response.isEmpty) {
        return [];
      }
      
      // Get all class IDs
      final classIds = response.map((c) => c['id'] as String).toList();
      
      // Get student counts for all classes in one query
      final studentCounts = await _getStudentCountsForClasses(classIds);
      
      // Create class models with student counts
      final classesWithCount = response.map((classData) {
        final studentCount = studentCounts[classData['id'] as String] ?? 0;
        return ClassModel.fromJson({
          ...classData,
          'student_count': studentCount,
        });
      }).toList();
      
      print('ClassService: Parsed ${classesWithCount.length} classes with student counts');
      
      return classesWithCount;
    } catch (e) {
      print('ClassService: Error fetching teacher classes: $e');
      throw Exception('Failed to fetch classes: $e');
    }
  }

  // Get all classes for a student
  Future<List<ClassModel>> getClassesByStudent(String studentId) async {
    try {
      print('ClassService: Getting classes for student: $studentId');
      
      // First get the class IDs from enrollments
      final enrollmentResponse = await _supabase
          .from('class_enrollments')
          .select('class_id')
          .eq('student_id', studentId)
          .eq('status', 'active');

      print('ClassService: Found ${enrollmentResponse.length} enrollments for student');

      if (enrollmentResponse.isEmpty) {
        return [];
      }

      final classIds = enrollmentResponse.map((e) => e['class_id'] as String).toList();
      print('ClassService: Class IDs: $classIds');

      // Get classes from classes table
      final response = await _supabase
          .from('classes')
          .select()
          .inFilter('id', classIds)
          .order('created_at', ascending: false);

      print('ClassService: Retrieved ${response.length} classes from database');
      print('ClassService: Response data: $response');
      
      if (response.isEmpty) {
        return [];
      }
      
      // Get student counts for all classes in one query
      final studentCounts = await _getStudentCountsForClasses(classIds);
      
      // Create class models with student counts
      final classesWithCount = response.map((classData) {
        final studentCount = studentCounts[classData['id'] as String] ?? 0;
        return ClassModel.fromJson({
          ...classData,
          'student_count': studentCount,
        });
      }).toList();
      
      print('ClassService: Parsed ${classesWithCount.length} classes for student');
      
      return classesWithCount;
    } catch (e) {
      print('ClassService: Error fetching student classes: $e');
      throw Exception('Failed to fetch student classes: $e');
    }
  }

  // Get a single class by ID
  Future<ClassModel?> getClassById(String classId) async {
    try {
      final response = await _supabase
          .from('classes')
          .select()
          .eq('id', classId)
          .single();

      // Get student count for this class
      final studentCountResponse = await _supabase
          .from('class_enrollments')
          .select('id')
          .eq('class_id', classId)
          .eq('status', 'active');
      
      final studentCount = studentCountResponse.length;
      
      return ClassModel.fromJson({
        ...response,
        'student_count': studentCount,
      });
    } catch (e) {
      if (e.toString().contains('No rows found')) {
        return null;
      }
      throw Exception('Failed to fetch class: $e');
    }
  }

  // Get a class by class code
  Future<ClassModel?> getClassByCode(String classCode) async {
    try {
      print('ClassService: Searching for class code: $classCode');
      
      final response = await _supabase
          .from('classes')
          .select()
          .eq('class_code', classCode)
          .single();

      print('ClassService: Found class: ${response['name']}');
      
      // Get student count for this class
      final studentCountResponse = await _supabase
          .from('class_enrollments')
          .select('id')
          .eq('class_id', response['id'])
          .eq('status', 'active');
      
      final studentCount = studentCountResponse.length;
      
      return ClassModel.fromJson({
        ...response,
        'student_count': studentCount,
      });
    } catch (e) {
      print('ClassService: Error searching for class code $classCode: $e');
      if (e.toString().contains('No rows found')) {
        print('ClassService: No class found with code: $classCode');
        return null;
      }
      throw Exception('Failed to fetch class by code: $e');
    }
  }

  // Update a class
  Future<ClassModel> updateClass(ClassModel classModel) async {
    try {
      final response = await _supabase
          .from('classes')
          .update({
            'name': classModel.name,
            'description': classModel.description,
            'section': classModel.section,
            'subject': classModel.subject,
            'room': classModel.room,
            'banner_image_url': classModel.bannerImageUrl,
            'theme_color': classModel.themeColor,
          })
          .eq('id', classModel.id)
          .select()
          .single();

      // Get student count for this class
      final studentCountResponse = await _supabase
          .from('class_enrollments')
          .select('id')
          .eq('class_id', classModel.id)
          .eq('status', 'active');
      
      final studentCount = studentCountResponse.length;
      
      return ClassModel.fromJson({
        ...response,
        'student_count': studentCount,
      });
    } catch (e) {
      throw Exception('Failed to update class: $e');
    }
  }

  // Delete a class
  Future<void> deleteClass(String classId) async {
    try {
      await _supabase
          .from('classes')
          .delete()
          .eq('id', classId);
    } catch (e) {
      throw Exception('Failed to delete class: $e');
    }
  }

  // Join a class (add student to class)
  Future<ClassModel> joinClass(String classId, String studentId) async {
    try {
      print('ClassService: Joining class $classId for student $studentId');
      
      // First get the current class
      final currentClass = await getClassById(classId);
      if (currentClass == null) {
        throw Exception('Class not found');
      }

      // Use the enrollment service to join the class
      final enrollmentService = EnrollmentService();
      final success = await enrollmentService.joinClass(currentClass.classCode, studentId);
      
      if (!success) {
        throw Exception('Failed to join class');
      }

      // Get the updated class
      final updatedClass = await getClassById(classId);
      if (updatedClass == null) {
        throw Exception('Failed to retrieve updated class');
      }

      print('ClassService: Successfully joined class ${updatedClass.name}');
      return updatedClass;
    } catch (e) {
      print('ClassService: Error joining class: $e');
      throw Exception('Failed to join class: $e');
    }
  }

  // Leave a class (remove student from class)
  Future<ClassModel> leaveClass(String classId, String studentId) async {
    try {
      // First get the current class
      final currentClass = await getClassById(classId);
      if (currentClass == null) {
        throw Exception('Class not found');
      }

      // Use the enrollment service to leave the class
      final enrollmentService = EnrollmentService();
      final success = await enrollmentService.leaveClass(classId, studentId);
      
      if (!success) {
        throw Exception('Failed to leave class');
      }

      // Get the updated class
      final updatedClass = await getClassById(classId);
      if (updatedClass == null) {
        throw Exception('Failed to retrieve updated class');
      }

      return updatedClass;
    } catch (e) {
      throw Exception('Failed to leave class: $e');
    }
  }

  // Generate a unique class code
  Future<String> generateUniqueClassCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    
    for (int attempt = 0; attempt < 10; attempt++) {
      String code = '';
      for (int i = 0; i < 6; i++) {
        code += chars[(random + attempt + i) % chars.length];
      }
      
      // Check if code is unique
      try {
        await _supabase
            .from('classes')
            .select('id')
            .eq('class_code', code)
            .single();
        // If we get here, code exists, try again
        continue;
      } catch (e) {
        // Code doesn't exist, we can use it
        return code;
      }
    }
    
    throw Exception('Failed to generate unique class code');
  }

  // Search classes by name or subject
  Future<List<ClassModel>> searchClasses(String query) async {
    try {
      final response = await _supabase
          .from('classes')
          .select()
          .or('name.ilike.%$query%,subject.ilike.%$query%')
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        return [];
      }
      
      // Get all class IDs
      final classIds = response.map((c) => c['id'] as String).toList();
      
      // Get student counts for all classes in one query
      final studentCounts = await _getStudentCountsForClasses(classIds);
      
      // Create class models with student counts
      final classesWithCount = response.map((classData) {
        final studentCount = studentCounts[classData['id'] as String] ?? 0;
        return ClassModel.fromJson({
          ...classData,
          'student_count': studentCount,
        });
      }).toList();
      
      return classesWithCount;
    } catch (e) {
      throw Exception('Failed to search classes: $e');
    }
  }

  // Helper method to get student counts for multiple classes
  Future<Map<String, int>> _getStudentCountsForClasses(List<String> classIds) async {
    try {
      final Map<String, int> studentCounts = {};
      
      // Get counts for each class individually since we need to count enrollments
      for (final classId in classIds) {
        try {
          final response = await _supabase
              .from('class_enrollments')
              .select('id')
              .eq('class_id', classId)
              .eq('status', 'active');
          
          studentCounts[classId] = response.length;
        } catch (e) {
          print('ClassService: Error getting count for class $classId: $e');
          studentCounts[classId] = 0;
        }
      }
      
      return studentCounts;
    } catch (e) {
      print('ClassService: Error getting student counts: $e');
      // Return empty counts if query fails
      return {for (final classId in classIds) classId: 0};
    }
  }
}
