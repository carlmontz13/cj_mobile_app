import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;
  
  // Debug method to check connection
  Future<void> testConnection() async {
    try {
      print('AuthService: Testing Supabase connection...');
      print('AuthService: Current user: ${currentUser?.email}');
      print('AuthService: Is authenticated: $isAuthenticated');
      
      if (currentUser != null) {
        // Test if we can access the profiles table
        try {
          final response = await _supabase.from('profiles').select('count').limit(1);
          print('AuthService: Database connection test successful');
          
          // Test if current user has a profile
          try {
            final userProfile = await _supabase
                .from('profiles')
                .select()
                .eq('id', currentUser!.id)
                .single();
            print('AuthService: User profile exists in database');
          } catch (e) {
            print('AuthService: User profile does not exist in database: $e');
          }
        } catch (e) {
          print('AuthService: Database access test failed: $e');
        }
      }
      
      // Test RPC function
      try {
        final rpcTest = await _supabase.rpc('create_user_profile', params: {
          'user_id': '00000000-0000-0000-0000-000000000000',
          'user_email': 'test@example.com',
          'user_full_name': 'Test User',
          'user_role': 'student',
        });
        print('AuthService: RPC function test result: $rpcTest');
      } catch (e) {
        print('AuthService: RPC function test failed: $e');
      }
    } catch (e) {
      print('AuthService: Database connection test failed: $e');
    }
  }

  // Get auth state stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    UserRole role = UserRole.teacher,
  }) async {
    try {
      print('AuthService: Starting sign up for $email');
      
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role.toString().split('.').last,
        },
        // Note: If you want to auto-confirm users, you need to configure this in Supabase dashboard
        // Go to Authentication > Settings > Email Auth and disable "Confirm email"
      );

      print('AuthService: Sign up response received - user: ${response.user?.email}');
      print('AuthService: Sign up session: ${response.session?.user?.email}');

      // If user was created successfully, try to create profile manually as fallback
      if (response.user != null) {
        print('AuthService: User created, attempting to create profile...');
        try {
          // Wait a moment for the trigger to potentially run
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Check if profile was created by trigger
          final existingProfile = await getUserProfile(response.user!.id);
          if (existingProfile == null) {
            print('AuthService: Profile not found, creating manually...');
            await _createUserProfile(response.user!, fullName, role);
            print('AuthService: Profile created manually');
          } else {
            print('AuthService: Profile already exists (created by trigger)');
          }
        } catch (profileError) {
          print('AuthService: Error creating profile: $profileError');
          // Don't fail the signup if profile creation fails
        }
      }
      
      return response;
    } catch (e) {
      print('AuthService: Sign up failed: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('AuthService: Attempting sign in for $email');
      
      // Check if there's already a session
      final currentSession = _supabase.auth.currentSession;
      if (currentSession != null) {
        print('AuthService: Found existing session for: ${currentSession.user.email}');
        // Sign out first to clear any existing session
        await _supabase.auth.signOut();
        print('AuthService: Cleared existing session');
      }
      
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      print('AuthService: Sign in successful for ${response.user?.email}');
      print('AuthService: Session created: ${response.session != null}');
      
      return response;
    } catch (e) {
      print('AuthService: Sign in failed: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('AuthService: Attempting sign out');
      
      // Check current session before signing out
      final currentSession = _supabase.auth.currentSession;
      if (currentSession != null) {
        print('AuthService: Signing out user: ${currentSession.user.email}');
      } else {
        print('AuthService: No active session found');
      }
      
      await _supabase.auth.signOut();
      print('AuthService: Sign out successful');
      
      // Verify session is cleared
      final sessionAfterSignOut = _supabase.auth.currentSession;
      if (sessionAfterSignOut == null) {
        print('AuthService: Session successfully cleared');
      } else {
        print('AuthService: Warning - session still exists after sign out');
      }
    } catch (e) {
      print('AuthService: Sign out failed: $e');
      rethrow;
    }
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      if (response.isNotEmpty) {
        return UserModel.fromJson({
          'id': response['id'],
          'name': response['full_name'],
          'email': response['email'],
          'profileImageUrl': response['profile_image_url'],
          'role': response['role'],
          'classIds': response['class_ids'] ?? [],
          'createdAt': response['created_at'],
        });
      }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      // If profile doesn't exist, try to create it
      if (e.toString().contains('PGRST116') || e.toString().contains('0 rows')) {
        print('Profile not found, attempting to create default profile...');
        return await _createDefaultProfile(userId);
      }
      return null;
    }
  }

  // Alternative method to get or create user profile
  Future<UserModel?> getOrCreateUserProfile(String userId) async {
    try {
      print('AuthService: Getting or creating profile for user: $userId');
      
      // First try to get existing profile
      final existingProfile = await getUserProfile(userId);
      if (existingProfile != null) {
        print('AuthService: Found existing profile for user: ${existingProfile.name}');
        return existingProfile;
      }

      // If no profile exists, create a temporary one in memory
      final user = currentUser;
      if (user == null) {
        print('AuthService: No current user found, cannot create profile');
        return null;
      }

      print('AuthService: Creating temporary profile for user: ${user.email}');
      
      // Create a temporary profile that doesn't require database access
      final tempProfile = UserModel.fromJson({
        'id': userId,
        'name': user.userMetadata?['full_name'] ?? 'New User',
        'email': user.email ?? '',
        'profileImageUrl': null,
        'role': user.userMetadata?['role'] ?? 'student',
        'classIds': [],
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      print('AuthService: Created temporary profile: ${tempProfile.name} (${tempProfile.role})');
      return tempProfile;
    } catch (e) {
      print('AuthService: Error in getOrCreateUserProfile: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    String? profileImageUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (profileImageUrl != null) updates['profile_image_url'] = profileImageUrl;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Create user profile in database
  Future<void> _createUserProfile(User user, String fullName, UserRole role) async {
    try {
      print('Creating user profile for: ${user.email}');
      
      // Try using the RPC function first (bypasses RLS)
      try {
        final result = await _supabase.rpc('create_user_profile', params: {
          'user_id': user.id,
          'user_email': user.email,
          'user_full_name': fullName,
          'user_role': role.toString().split('.').last,
        });
        
        print('Profile created via RPC: $result');
        
        // Check if RPC was successful
        if (result is Map && result['success'] == true) {
          print('Profile creation verified successfully');
          return;
        } else {
          print('Profile creation failed, trying direct insert');
        }
      } catch (rpcError) {
        print('RPC failed, trying direct insert: $rpcError');
      }
      
      // Fallback to direct insert with conflict handling
      try {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'email': user.email,
          'full_name': fullName,
          'role': role.toString().split('.').last,
          'class_ids': [],
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'id');
        
        print('User profile created/updated via direct insert');
        
        // Verify the profile was created
        final verification = await getUserProfile(user.id);
        if (verification != null) {
          print('Profile creation verified successfully');
        } else {
          print('Profile creation failed verification');
          throw Exception('Profile creation failed verification');
        }
      } catch (insertError) {
        print('Direct insert failed: $insertError');
        throw insertError;
      }
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }

  // Create default profile for existing users
  Future<UserModel?> _createDefaultProfile(String userId) async {
    try {
      final user = currentUser;
      if (user == null) return null;

      print('Creating default profile for user: ${user.email}');

      // Try to create profile using RPC function to bypass RLS issues
      try {
        final result = await _supabase.rpc('create_user_profile', params: {
          'user_id': userId,
          'user_email': user.email,
          'user_full_name': user.userMetadata?['full_name'] ?? 'New User',
          'user_role': user.userMetadata?['role'] ?? 'student',
        });
        
        print('Profile created via RPC: $result');
        
        // Check if RPC was successful
        if (result is Map && result['success'] == true) {
          // Try to fetch the created profile
          final response = await _supabase
              .from('profiles')
              .select()
              .eq('id', userId)
              .single();

          if (response.isNotEmpty) {
            return UserModel.fromJson({
              'id': response['id'],
              'name': response['full_name'],
              'email': response['email'],
              'profileImageUrl': response['profile_image_url'],
              'role': response['role'],
              'classIds': response['class_ids'] ?? [],
              'createdAt': response['created_at'],
            });
          }
        }
      } catch (rpcError) {
        print('RPC failed: $rpcError');
      }

      // If RPC failed, create a temporary profile in memory
      print('Creating temporary profile for user: ${user.email}');
      return UserModel.fromJson({
        'id': userId,
        'name': user.userMetadata?['full_name'] ?? 'New User',
        'email': user.email ?? '',
        'profileImageUrl': null,
        'role': user.userMetadata?['role'] ?? 'student',
        'classIds': [],
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating default profile: $e');
      return null;
    }
  }

  // Get current user as UserModel
  Future<UserModel?> getCurrentUserModel() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      return await getOrCreateUserProfile(user.id);
    } catch (e) {
      print('Error getting current user model: $e');
      return null;
    }
  }
}
