import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import '../providers/class_provider.dart';
import '../screens/class_detail_screen.dart';
import '../models/class_model.dart';
import '../utils/color_utils.dart';
import '../widgets/auth_guard.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ClassModel? _selectedClass;

  final appName = 'Classroom App';

  Color get _primaryColor {
    if (_selectedClass?.themeColor != null) {
      return ColorUtils.hexToColor(_selectedClass!.themeColor!);
    }
    return const Color(0xFF4285F4); // Default blue color
  }

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      child: Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text(
          appName,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.person, color: Colors.white),
        //     onPressed: () {
        //       Navigator.push(
        //         context,
        //         MaterialPageRoute(
        //           builder: (context) => const ProfileScreen(),
        //         ),
        //       );
        //     },
        //   ),
        // ],
      ),
      drawer: _buildLeftSidebar(),
      body: HomeScreen(primaryColor: _primaryColor),
      ),
    );
  }

  Widget _buildLeftSidebar() {
    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          DrawerHeader(
            decoration: BoxDecoration(
              color: _primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      appName,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'My Classes',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // Classes List
          Expanded(
            child: _buildClassesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildClassesList() {
    return Consumer<ClassProvider>(
      builder: (context, classProvider, child) {
        if (classProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final classes = classProvider.classes;

        if (classes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No classes yet',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create or join a class to get started',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final classItem = classes[index];
            final isSelected = _selectedClass?.id == classItem.id;
            final classColor = classItem.themeColor != null 
                ? ColorUtils.hexToColor(classItem.themeColor!)
                : const Color(0xFF4285F4);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              elevation: isSelected ? 4 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: isSelected 
                    ? BorderSide(color: classColor, width: 2)
                    : BorderSide.none,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: classColor,
                  child: Text(
                    classItem.name[0].toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                title: Text(
                  classItem.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isSelected ? classColor : Colors.grey[800],
                  ),
                ),
                subtitle: Text(
                  '${classItem.studentCount} students',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                trailing: isSelected 
                    ? Icon(Icons.check_circle, color: classColor, size: 20)
                    : const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  setState(() {
                    _selectedClass = classItem;
                  });
                  Navigator.pop(context); // Close drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClassDetailScreen(classModel: classItem),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
