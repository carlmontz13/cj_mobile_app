import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/class_provider.dart';
import '../providers/auth_provider.dart';
import '../models/class_model.dart';
import '../models/user_model.dart';
import '../widgets/class_card.dart';
import '../widgets/auth_guard.dart';
import '../widgets/profile_image_widget.dart';
import 'create_class_screen.dart';
import 'class_detail_screen.dart';
import 'join_class_screen.dart';
import 'profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  final Color? primaryColor;
  
  const HomeScreen({super.key, this.primaryColor});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Color get _primaryColor {
    return widget.primaryColor ?? const Color(0xFF4285F4);
  }

  @override
  void initState() {
    super.initState();
    // Refresh classes when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final classProvider = context.read<ClassProvider>();
      if (classProvider.currentUser != null) {
        print('HomeScreen: Refreshing classes on init');
        classProvider.refreshClasses();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _primaryColor,
          elevation: 0,
          toolbarHeight: 64,
          automaticallyImplyLeading: false,
          title: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final user = authProvider.currentUser;
              return Text(
                user != null ? 'Hi, ${user.name.split(' ').first}' : 'Home',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  final user = authProvider.currentUser;
                  if (user == null) {
                    return const SizedBox.shrink();
                  }
                  return InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                    child: ProfileImageWidget(
                      imageUrl: user.profileImageUrl,
                      name: user.name,
                      radius: 20,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[50],
        body: Consumer2<AuthProvider, ClassProvider>(
          builder: (context, authProvider, classProvider, child) {
            if (classProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Show error if there's an error message
            if (classProvider.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load classes',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      classProvider.errorMessage!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        classProvider.clearError();
                        classProvider.refreshClasses();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            final classes = classProvider.classes;
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

            // Filter classes based on search query
            final List<ClassModel> filteredClasses = _searchQuery.trim().isEmpty
                ? classes
                : classes.where((c) {
                    final q = _searchQuery.toLowerCase();
                    return c.name.toLowerCase().contains(q) ||
                        c.subject.toLowerCase().contains(q) ||
                        c.teacherName.toLowerCase().contains(q);
                  }).toList();

            return RefreshIndicator(
              onRefresh: () async {
                print('HomeScreen: Refreshing classes...');
                await classProvider.refreshClasses();
              },
              child: Column(
                children: [
                  // Header section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back!',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'You have ${classes.length} class${classes.length != 1 ? 'es' : ''}'
                                  : 'Showing ${filteredClasses.length} of ${classes.length} class${classes.length != 1 ? 'es' : ''}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Search field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            style: GoogleFonts.poppins(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search classes by name, subject, or teacher',
                              hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                              border: InputBorder.none,
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchQuery.isEmpty
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                          _searchController.clear();
                                        });
                                      },
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Classes section
                  Expanded(
                    child: classes.isEmpty
                        ? _buildEmptyState()
                        : (filteredClasses.isEmpty
                            ? _buildEmptySearchState()
                            : _buildClassesGrid(filteredClasses)),
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final currentUser = authProvider.currentUser;
            
            if (currentUser?.role == UserRole.teacher) {
              return FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateClassScreen(),
                    ),
                  );
                },
                backgroundColor: _primaryColor,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  'Create Class',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            } else {
              return FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const JoinClassScreen(),
                    ),
                  );
                },
                backgroundColor: const Color(0xFF34A853),
                icon: const Icon(Icons.group_add, color: Colors.white),
                label: Text(
                  'Join Class',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildUserAvatar(UserModel user) {
    String initials = '';
    if (user.name.trim().isNotEmpty) {
      final parts = user.name.trim().split(' ');
      if (parts.isNotEmpty) {
        initials += parts.first.isNotEmpty ? parts.first[0] : '';
        if (parts.length > 1) {
          initials += parts.last.isNotEmpty ? parts.last[0] : '';
        }
      }
    }

    final String? resolvedUrl = _resolveProfileImageUrl(user.profileImageUrl);
    if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: Colors.white24,
        foregroundImage: NetworkImage(resolvedUrl),
        onForegroundImageError: (exception, stackTrace) {
          // Silently fall back to initials
        },
        child: Text(
          initials.toUpperCase(),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.white24,
      child: Text(
        initials.toUpperCase(),
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String? _resolveProfileImageUrl(String? rawUrl) {
    final String url = (rawUrl ?? '').trim();
    if (url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // Treat as Supabase Storage path. Assume bucket 'profiles'.
    // Normalize path to avoid duplicate 'profiles/' when building public URL.
    String path = url;
    if (path.startsWith('profiles/')) {
      path = path.substring('profiles/'.length);
    }

    try {
      final publicUrl = Supabase.instance.client.storage.from('profiles').getPublicUrl(path);
      return publicUrl;
    } catch (_) {
      return null;
    }
  }

  Widget _buildEmptyState() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final currentUser = authProvider.currentUser;
        final isTeacher = currentUser?.role == UserRole.teacher;
        
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isTeacher ? Icons.school_outlined : Icons.group_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                isTeacher ? 'No classes yet' : 'No classes joined',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isTeacher 
                    ? 'Create your first class to get started'
                    : 'Join a class using a class code',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => isTeacher 
                          ? const CreateClassScreen()
                          : const JoinClassScreen(),
                    ),
                  );
                },
                icon: Icon(isTeacher ? Icons.add : Icons.group_add),
                label: Text(isTeacher ? 'Create Class' : 'Join Class'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isTeacher ? _primaryColor : const Color(0xFF34A853),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              // Debug button to manually refresh classes
              Consumer<ClassProvider>(
                builder: (context, classProvider, child) {
                  return TextButton.icon(
                    onPressed: () {
                      print('HomeScreen: Manual refresh triggered');
                      classProvider.refreshClasses();
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh Classes'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No matching classes',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term or clear your filter',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear search'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesGrid(List<ClassModel> classes) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: classes.length,
        itemBuilder: (context, index) {
          final classItem = classes[index];
          return ClassCard(
            classModel: classItem,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClassDetailScreen(classModel: classItem),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
