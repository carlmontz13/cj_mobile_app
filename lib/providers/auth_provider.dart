import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/cache_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _forceNavigation = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get forceNavigation => _forceNavigation;

  AuthProvider() {
    _initializeAuth();
  }

  // Initialize authentication state
  void _initializeAuth() async {
    print('AuthProvider: Initializing authentication...');
    
    // Test connection
    await _authService.testConnection();
    
    // Check if there's already a user session
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      print('AuthProvider: Found existing user session: ${currentUser.email}');
      // Load the user profile immediately
      await _loadCurrentUser();
    }
    
    // Listen to auth state changes
    _authService.authStateChanges.listen((AuthState data) {
      print('AuthProvider: Auth state changed - event: ${data.event}, user: ${data.session?.user?.email}');
      _handleAuthStateChange(data);
    });

    // Set initialized after a short delay to ensure auth state is processed
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_isInitialized) {
        _isInitialized = true;
        print('AuthProvider: Initialization complete - isInitialized: $_isInitialized, isAuthenticated: $isAuthenticated');
        notifyListeners();
      }
    });
  }

  // Handle auth state changes
  Future<void> _handleAuthStateChange(AuthState data) async {
    final event = data.event;
    final user = data.session?.user;

    print('AuthProvider: Handling auth state change - event: $event, user: ${user?.email}');

    if (event == AuthChangeEvent.signedIn && user != null) {
      print('AuthProvider: User signed in, loading profile...');
      await _loadCurrentUser();
    } else if (event == AuthChangeEvent.signedOut) {
      print('AuthProvider: User signed out');
      _currentUser = null;
      _clearError();
      notifyListeners();
    } else if (event == AuthChangeEvent.initialSession && user != null) {
      // Handle initial session restoration
      print('AuthProvider: Initial session restored for user: ${user.email}');
      await _loadCurrentUser();
    } else if (event == AuthChangeEvent.initialSession && user == null) {
      // Handle initial session with no user
      print('AuthProvider: Initial session - no user found');
      _currentUser = null;
      _clearError();
      notifyListeners();
    } else if (event == AuthChangeEvent.tokenRefreshed && user != null) {
      // Handle token refresh
      print('AuthProvider: Token refreshed for user: ${user.email}');
      await _loadCurrentUser();
    } else if (event == AuthChangeEvent.userUpdated && user != null) {
      // Handle user update
      print('AuthProvider: User updated: ${user.email}');
      await _loadCurrentUser();
    } else if (event == AuthChangeEvent.passwordRecovery) {
      // Handle password recovery
      print('AuthProvider: Password recovery event');
      // Don't change the current state for password recovery
    } else {
      print('AuthProvider: Unhandled auth event: $event');
    }
    
    // Debug: Log the current state after handling the event
    print('AuthProvider: After handling auth event - isAuthenticated: $isAuthenticated, currentUser: ${_currentUser?.name}');
  }

  // Load current user profile
  Future<void> _loadCurrentUser() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        print('AuthProvider: No current user found');
        _currentUser = null;
        _clearError();
        notifyListeners();
        return;
      }

      print('AuthProvider: Loading profile for user: ${user.email} (${user.id})');

      // Try to get or create user profile
      final userModel = await _authService.getOrCreateUserProfile(user.id);
      if (userModel != null) {
        _currentUser = userModel;
        _clearError();
        print('AuthProvider: User profile loaded successfully - ${userModel.name} (${userModel.role})');
        print('AuthProvider: Setting _currentUser to: ${userModel.name}');
        notifyListeners();
        print('AuthProvider: After notifyListeners - isAuthenticated: $isAuthenticated');
      } else {
        print('AuthProvider: Failed to load user profile - userModel is null');
        _setError('Failed to load user profile');
        notifyListeners();
      }
    } catch (e) {
      print('AuthProvider: Error loading user profile: $e');
      _setError('Failed to load user profile: $e');
      notifyListeners();
    }
  }

  // Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    UserRole role = UserRole.teacher,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      print('AuthProvider: Starting sign up for $email');
      
      final response = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );

      print('AuthProvider: Sign up completed - user: ${response.user?.email}');
      print('AuthProvider: Sign up session: ${response.session?.user?.email}');

      // Check if user was created successfully
      if (response.user != null) {
        print('AuthProvider: Sign up successful, user created');
        
        // Check if email confirmation is required
        if (response.session == null) {
          print('AuthProvider: Email confirmation required');
          // This is normal - user needs to confirm email
          // Don't set error, just return success since account was created
          return true;
        } else {
          print('AuthProvider: User signed in immediately');
          // User was signed in immediately (rare, but possible)
          return true;
        }
      } else {
        print('AuthProvider: Sign up failed - no user returned');
        _setError('Failed to create account');
        return false;
      }
    } catch (e) {
      print('AuthProvider: Sign up error: $e');
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      print('AuthProvider: Starting sign in for $email');
      
      // Clear any existing user state before attempting sign in
      _currentUser = null;
      notifyListeners();
      
      final response = await _authService.signIn(
        email: email,
        password: password,
      );

      print('AuthProvider: Sign in completed - user: ${response.user?.email}');

      if (response.user != null) {
        print('AuthProvider: Sign in successful');
        
        // Immediately load the user profile to ensure UI updates
        try {
          await _loadCurrentUser();
          print('AuthProvider: User profile loaded immediately after sign in');
        } catch (e) {
          print('AuthProvider: Immediate profile load failed: $e');
          // Even if profile loading fails, we should still consider the user authenticated
          // Create a temporary user model from the auth response
          _currentUser = UserModel.fromJson({
            'id': response.user!.id,
            'name': response.user!.userMetadata?['full_name'] ?? 'New User',
            'email': response.user!.email ?? '',
            'profileImageUrl': null,
            'role': response.user!.userMetadata?['role'] ?? 'student',
            'classIds': [],
            'createdAt': DateTime.now().toIso8601String(),
          });
          _clearError();
          notifyListeners();
        }
        
        // Force a sync to ensure state consistency
        try {
          await syncAuthStateWithSupabase();
          print('AuthProvider: Auth state synced after sign in');
        } catch (e) {
          print('AuthProvider: Sync after sign in failed: $e');
        }
        
        // Ensure we notify listeners one more time
        print('AuthProvider: Final notification after sign in - isAuthenticated: $isAuthenticated, currentUser: ${_currentUser?.name}');
        notifyListeners();
        
        // Debug: Check if the auth state change event was triggered
        print('AuthProvider: Checking if auth state change was triggered...');
        final currentSupabaseUser = _authService.currentUser;
        print('AuthProvider: Current Supabase user: ${currentSupabaseUser?.email}');
        print('AuthProvider: Current user model: ${_currentUser?.email}');
        print('AuthProvider: isAuthenticated: $isAuthenticated');
        
        return true;
      } else {
        print('AuthProvider: Sign in failed - no user returned');
        _setError('Failed to sign in');
        return false;
      }
    } catch (e) {
      print('AuthProvider: Sign in error: $e');
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      print('AuthProvider: Starting sign out');
      
      // Clear current user immediately to prevent any race conditions
      _currentUser = null;
      notifyListeners();
      
      // Clear all cache before signing out
      print('AuthProvider: Clearing all cache...');
      await CacheService.clearAllCache();
      
      await _authService.signOut();
      print('AuthProvider: Sign out completed');
      
      // Ensure user is cleared after successful sign out
      _currentUser = null;
      _clearError();
      notifyListeners();
    } catch (e) {
      print('AuthProvider: Sign out error: $e');
      _setError(_getErrorMessage(e));
      // Even if sign out fails, clear the user state and cache
      _currentUser = null;
      try {
        await CacheService.clearAllCache();
      } catch (cacheError) {
        print('AuthProvider: Error clearing cache during failed sign out: $cacheError');
      }
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? profileImageUrl,
  }) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _authService.updateUserProfile(
        userId: _currentUser!.id,
        fullName: name,
        profileImageUrl: profileImageUrl,
      );

      // If email is being updated, we need to handle it separately
      if (email != null && email != _currentUser!.email) {
        // TODO: Implement email update through Supabase auth
        // This requires additional authentication flow
        print('AuthProvider: Email update not yet implemented');
      }

      // Reload user profile
      await _loadCurrentUser();
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

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

  // Debug method to check current state
  void debugAuthState() {
    print('=== AuthProvider Debug Info ===');
    print('isInitialized: $_isInitialized');
    print('isLoading: $_isLoading');
    print('isAuthenticated: $isAuthenticated');
    print('currentUser: ${_currentUser?.name} (${_currentUser?.email})');
    print('errorMessage: $_errorMessage');
    print('Supabase currentUser: ${_authService.currentUser?.email}');
    print('Supabase isAuthenticated: ${_authService.isAuthenticated}');
    print('Supabase session: ${_authService.currentUser != null ? "Active" : "None"}');
    print('==============================');
  }

  // Check if user is actually authenticated in Supabase
  bool get isActuallyAuthenticatedInSupabase {
    return _authService.isAuthenticated;
  }

  // Sync auth state with Supabase
  Future<void> syncAuthStateWithSupabase() async {
    print('AuthProvider: Syncing auth state with Supabase...');
    
    final supabaseUser = _authService.currentUser;
    final isSupabaseAuthenticated = _authService.isAuthenticated;
    
    print('AuthProvider: Supabase user: ${supabaseUser?.email}');
    print('AuthProvider: Supabase authenticated: $isSupabaseAuthenticated');
    print('AuthProvider: Current user model: ${_currentUser?.email}');
    
    if (isSupabaseAuthenticated && supabaseUser != null) {
      if (_currentUser == null || _currentUser!.id != supabaseUser.id) {
        print('AuthProvider: Syncing - loading user profile from Supabase');
        await _loadCurrentUser();
      } else {
        print('AuthProvider: Syncing - user state is already consistent');
      }
    } else if (!isSupabaseAuthenticated && _currentUser != null) {
      print('AuthProvider: Syncing - clearing user state (not authenticated in Supabase)');
      _currentUser = null;
      _clearError();
      notifyListeners();
    } else {
      print('AuthProvider: Syncing - state is consistent (both null)');
    }
  }

  // Force refresh auth state (useful for debugging)
  Future<void> forceRefreshAuthState() async {
    print('AuthProvider: Force refreshing auth state...');
    try {
      await _loadCurrentUser();
    } catch (e) {
      print('AuthProvider: Force refresh failed: $e');
    }
  }

  // Force refresh profile image
  Future<void> forceRefreshProfileImage() async {
    print('AuthProvider: Force refreshing profile image...');
    
    try {
      if (_currentUser != null) {
        // Reload user profile to get fresh data
        await _loadCurrentUser();
        print('AuthProvider: Profile image refreshed successfully');
      }
    } catch (e) {
      print('AuthProvider: Error refreshing profile image: $e');
      _setError(_getErrorMessage(e));
    }
  }

  // Force UI refresh (useful for debugging)
  void forceUIRefresh() {
    print('AuthProvider: Forcing UI refresh...');
    notifyListeners();
  }

  // Force navigation check (useful for debugging)
  void forceNavigationCheck() {
    print('AuthProvider: Forcing navigation check...');
    print('AuthProvider: Current state - isAuthenticated: $isAuthenticated, currentUser: ${_currentUser?.name}');
    
    // Set force navigation flag
    _forceNavigation = true;
    
    // Force a sync with Supabase to ensure state consistency
    syncAuthStateWithSupabase().then((_) {
      print('AuthProvider: Navigation check sync completed');
      notifyListeners();
    }).catchError((e) {
      print('AuthProvider: Navigation check sync failed: $e');
      notifyListeners();
    });
  }

  // Clear force navigation flag
  void clearForceNavigation() {
    _forceNavigation = false;
    notifyListeners();
  }

  // Clear all provider state (for logout)
  void clearAllState() {
    print('AuthProvider: Clearing all state...');
    _currentUser = null;
    _isLoading = false;
    _isInitialized = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Test method to manually trigger auth state change
  void testAuthStateChange() {
    print('AuthProvider: Testing auth state change...');
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      print('AuthProvider: Found current user in Supabase: ${currentUser.email}');
      _loadCurrentUser().then((_) {
        print('AuthProvider: Auth state change test completed');
        notifyListeners();
      }).catchError((e) {
        print('AuthProvider: Auth state change test failed: $e');
        notifyListeners();
      });
    } else {
      print('AuthProvider: No current user in Supabase');
      notifyListeners();
    }
  }

  // Clear all auth state (for debugging)
  void clearAllAuthState() {
    print('AuthProvider: Clearing all auth state...');
    _currentUser = null;
    _clearError();
    _isLoading = false;
    notifyListeners();
  }

  // Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    if (error is AuthException) {
      switch (error.message) {
        case 'Invalid login credentials':
          return 'Invalid email or password';
        case 'Email not confirmed':
          return 'Please check your email and click the confirmation link';
        case 'User already registered':
          return 'An account with this email already exists';
        case 'Database error saving new user':
          return 'Account created successfully! Please check your email to verify your account.';
        default:
          return error.message;
      }
    }
    
    // Handle specific error messages
    final errorString = error.toString();
    if (errorString.contains('Database error saving new user')) {
      return 'Account created successfully! Please check your email to verify your account.';
    }
    
    return errorString;
  }
}
