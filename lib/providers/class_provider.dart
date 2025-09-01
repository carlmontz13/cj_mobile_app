import 'package:flutter/foundation.dart';
import '../models/class_model.dart';
import '../models/user_model.dart';
import '../services/class_service.dart';
import '../services/cache_service.dart';

class ClassProvider with ChangeNotifier {
  final ClassService _classService = ClassService();
  List<ClassModel> _classes = [];
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  List<ClassModel> get classes => _classes;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  // Update current user (called from AuthProvider)
  void updateCurrentUser(UserModel? user) {
    print('ClassProvider: updateCurrentUser called with user: ${user?.name} (${user?.id})');
    
    _currentUser = user;
    if (user != null) {
      // Always load classes when a user is provided
      loadClasses();
      _isInitialized = true;
    } else {
      // Clear classes and cache when user is null (logout)
      _classes = [];
      _isInitialized = false;
      _clearClassCache();
    }
    notifyListeners();
  }

  // Clear class cache
  void _clearClassCache() {
    try {
      print('ClassProvider: Clearing class cache...');
      CacheService.clearClassCache();
    } catch (e) {
      print('ClassProvider: Error clearing class cache: $e');
    }
  }

  // Load classes from database
  Future<void> loadClasses() async {
    if (_currentUser == null) {
      print('ClassProvider: loadClasses called but no current user');
      return;
    }

    print('ClassProvider: Loading classes for user: ${_currentUser!.name} (${_currentUser!.role})');
    setLoading(true);
    _clearError();

    try {
      // Test database connection first
      await _classService.testConnection();
      
      if (_currentUser!.role == UserRole.teacher) {
        print('ClassProvider: Loading teacher classes...');
        _classes = await _classService.getClassesByTeacher(_currentUser!.id);
        print('ClassProvider: Loaded ${_classes.length} teacher classes');
      } else {
        print('ClassProvider: Loading student classes...');
        _classes = await _classService.getClassesByStudent(_currentUser!.id);
        print('ClassProvider: Loaded ${_classes.length} student classes');
      }
    } catch (e) {
      print('ClassProvider: Error loading classes: $e');
      _setError('Failed to load classes: $e');
    } finally {
      setLoading(false);
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Create a new class
  Future<bool> createClass(ClassModel newClass) async {
    setLoading(true);
    _clearError();

    try {
      final createdClass = await _classService.createClass(newClass);
      _classes.add(createdClass);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create class: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Update an existing class
  Future<bool> updateClass(ClassModel updatedClass) async {
    // Check if current user can update this class
    if (_currentUser == null) {
      _setError('User not authenticated');
      return false;
    }
    
    final isTeacher = _currentUser!.role == UserRole.teacher;
    final ownsClass = _currentUser!.id == updatedClass.teacherId;
    
    if (!isTeacher || !ownsClass) {
      _setError('Access denied. Only the class teacher can update this class.');
      return false;
    }
    
    setLoading(true);
    _clearError();

    try {
      final updated = await _classService.updateClass(updatedClass);
      final index = _classes.indexWhere((c) => c.id == updated.id);
      if (index != -1) {
        _classes[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to update class: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Delete a class
  Future<bool> deleteClass(String classId) async {
    // Check if current user can delete this class
    if (_currentUser == null) {
      _setError('User not authenticated');
      return false;
    }
    
    // Find the class to check ownership
    final classToDelete = _classes.firstWhere(
      (c) => c.id == classId,
      orElse: () => throw Exception('Class not found'),
    );
    
    final isTeacher = _currentUser!.role == UserRole.teacher;
    final ownsClass = _currentUser!.id == classToDelete.teacherId;
    
    if (!isTeacher || !ownsClass) {
      _setError('Access denied. Only the class teacher can delete this class.');
      return false;
    }
    
    setLoading(true);
    _clearError();

    try {
      await _classService.deleteClass(classId);
      _classes.removeWhere((c) => c.id == classId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete class: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Get a class by ID
  Future<ClassModel?> getClassById(String classId) async {
    try {
      return await _classService.getClassById(classId);
    } catch (e) {
      _setError('Failed to get class: $e');
      return null;
    }
  }

  // Get a class by class code
  Future<ClassModel?> getClassByCode(String classCode) async {
    try {
      return await _classService.getClassByCode(classCode);
    } catch (e) {
      _setError('Failed to get class by code: $e');
      return null;
    }
  }

  // Join a class (for students)
  Future<bool> joinClass(String classId) async {
    if (_currentUser == null) return false;

    setLoading(true);
    _clearError();

    try {
      final updatedClass = await _classService.joinClass(classId, _currentUser!.id);
      
      // Update the class in the list if it exists
      final index = _classes.indexWhere((c) => c.id == classId);
      if (index != -1) {
        _classes[index] = updatedClass;
      } else {
        _classes.add(updatedClass);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to join class: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Leave a class (for students)
  Future<bool> leaveClass(String classId) async {
    if (_currentUser == null) return false;

    setLoading(true);
    _clearError();

    try {
      final updatedClass = await _classService.leaveClass(classId, _currentUser!.id);
      
      // Update the class in the list
      final index = _classes.indexWhere((c) => c.id == classId);
      if (index != -1) {
        _classes[index] = updatedClass;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('Failed to leave class: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Generate a unique class code
  Future<String> generateClassCode() async {
    try {
      return await _classService.generateUniqueClassCode();
    } catch (e) {
      _setError('Failed to generate class code: $e');
      return '';
    }
  }

  // Search classes
  Future<List<ClassModel>> searchClasses(String query) async {
    try {
      return await _classService.searchClasses(query);
    } catch (e) {
      _setError('Failed to search classes: $e');
      return [];
    }
  }

  // Refresh classes
  Future<void> refreshClasses() async {
    await loadClasses();
  }

  // Helper methods
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  void setCurrentUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  // Clear all provider state (for logout)
  void clearAllState() {
    print('ClassProvider: Clearing all state...');
    _classes = [];
    _currentUser = null;
    _isLoading = false;
    _isInitialized = false;
    _errorMessage = null;
    _clearClassCache();
    notifyListeners();
  }
}
