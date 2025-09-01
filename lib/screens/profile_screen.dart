import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import '../providers/class_provider.dart';
import '../providers/auth_provider.dart';
import '../services/cache_service.dart';
import '../widgets/auth_guard.dart';
import '../widgets/profile_image_widget.dart';
import '../models/user_model.dart';
import 'edit_profile_screen.dart';
import 'email_settings_screen.dart';
import 'privacy_security_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Consumer2<AuthProvider, ClassProvider>(
          builder: (context, authProvider, classProvider, child) {
            final currentUser = authProvider.currentUser;
            
            if (currentUser == null) {
              return const Scaffold(
                backgroundColor: Color(0xFF4285F4),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.white,
                      ),
                      SizedBox(height: 24),
                      Text(
                        'User profile not found',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Please try logging in again',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header with back button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4285F4),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Back button and title row
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                'Profile',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EditProfileScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                                                 // Profile Picture
                         ProfileImageWidget(
                           imageUrl: currentUser.profileImageUrl,
                           name: currentUser.name,
                           radius: 50,
                           fontSize: 32,
                         ),
                        const SizedBox(height: 16),
                        
                        // User Name
                        Text(
                          currentUser.name,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        
                        // User Email
                        Text(
                          currentUser.email,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Role Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            currentUser.role.toString().split('.').last.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Stats Section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.school,
                            title: 'Classes',
                            value: classProvider.classes.length.toString(),
                            color: const Color(0xFF4285F4),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.people,
                            title: 'Total Students',
                            value: _getTotalStudents(classProvider.classes).toString(),
                            color: const Color(0xFF34A853),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Menu Items
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildMenuSection(
                          title: 'Account',
                          items: [
                            _buildMenuItem(
                              icon: Icons.person,
                              title: 'Edit Profile',
                              subtitle: 'Update your personal information',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EditProfileScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.email,
                              title: 'Email Settings',
                              subtitle: 'Manage email notifications',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EmailSettingsScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.lock,
                              title: 'Privacy & Security',
                              subtitle: 'Manage your privacy settings',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PrivacySecurityScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // _buildMenuSection(
                        //   title: 'Classroom',
                        //   items: [
                        //     _buildMenuItem(
                        //       icon: Icons.archive,
                        //       title: 'Archived Classes',
                        //       subtitle: 'View your archived classes',
                        //       onTap: () {
                        //         // TODO: Navigate to archived classes
                        //       },
                        //     ),
                        //     _buildMenuItem(
                        //       icon: Icons.settings,
                        //       title: 'Classroom Settings',
                        //       subtitle: 'Manage classroom preferences',
                        //       onTap: () {
                        //         // TODO: Navigate to classroom settings
                        //       },
                        //     ),
                        //   ],
                        // ),
                        // const SizedBox(height: 24),
                        
                        _buildMenuSection(
                          title: 'Support',
                          items: [
                            // _buildMenuItem(
                            //   icon: Icons.help,
                            //   title: 'Help Center',
                            //   subtitle: 'Get help and support',
                            //   onTap: () {
                            //     // TODO: Navigate to help center
                            //   },
                            // ),
                            // _buildMenuItem(
                            //   icon: Icons.feedback,
                            //   title: 'Send Feedback',
                            //   subtitle: 'Share your thoughts with us',
                            //   onTap: () {
                            //     // TODO: Navigate to feedback
                            //   },
                            // ),
                            _buildMenuItem(
                              icon: Icons.info,
                              title: 'About',
                              subtitle: 'App version and information',
                              onTap: () {
                                _showAboutDialog(context);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Logout Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showLogoutDialog(context);
                            },
                            icon: const Icon(Icons.logout),
                            label: Text(
                              'Logout',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF4285F4).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF4285F4), size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  int _getTotalStudents(List<dynamic> classes) {
    int total = 0;
    for (var classItem in classes) {
      total += (classItem.studentCount as int);
    }
    return total;
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'About Classroom',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Developer Image
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF4285F4),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/Montz.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // App Title
              Text(
                'Classroom App',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4285F4),
                ),
              ),
              const SizedBox(height: 8),
              
              // Version
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Version 1.0.0',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4285F4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Description
              Text(
                'A Google Classroom-like application for teachers to create and manage classes with a modern, intuitive interface.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Developer Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Developed by',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Carl Ohmar T. Montoya',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4285F4),
              ),
            ),
          ),
        ],
      ),
    );
  }



  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to logout?',
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
              
              // Show loading indicator with cache clearing message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Logging out...',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Clearing cache and data',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.blue,
                  duration: const Duration(seconds: 3),
                ),
              );
              
              try {
                final authProvider = context.read<AuthProvider>();
                
                // Clear cache first
                try {
                  await CacheService.clearAllCache();
                  print('ProfileScreen: Cache cleared successfully');
                } catch (cacheError) {
                  print('ProfileScreen: Error clearing cache: $cacheError');
                  // Continue with logout even if cache clearing fails
                }
                
                // Then sign out
                await authProvider.signOut();
                
                if (mounted) {
                  // Clear any existing snackbars
                  ScaffoldMessenger.of(context).clearSnackBars();
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Logged out successfully! All data cleared.',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  
                  // AuthGuard will automatically redirect to login screen
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error logging out: ${e.toString()}',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
