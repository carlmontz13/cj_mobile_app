import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/class_provider.dart';
import '../models/class_model.dart';
import '../models/user_model.dart';
import '../utils/color_utils.dart';
import '../widgets/auth_guard.dart';
import '../widgets/role_guard.dart';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sectionController = TextEditingController();
  final _subjectController = TextEditingController();
  final _roomController = TextEditingController();
  
  String _selectedColor = '#4285F4';
  bool _isLoading = false;

  final List<String> _colors = [
    '#4285F4', // Blue
    '#EA4335', // Red
    '#FBBC04', // Yellow
    '#34A853', // Green
    '#FF6D01', // Orange
    '#46BDC6', // Teal
    '#7B1FA2', // Purple
    '#E67C73', // Pink
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _sectionController.dispose();
    _subjectController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      child: RoleGuard(
        allowedRoles: [UserRole.teacher],
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(
              'Create Class',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF4285F4),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Create a new class',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fill in the details below to create your class',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Class Name
                  _buildTextField(
                    controller: _nameController,
                    label: 'Class Name',
                    hint: 'e.g., Mathematics 101',
                    icon: Icons.school,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a class name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Section
                  _buildTextField(
                    controller: _sectionController,
                    label: 'Section',
                    hint: 'e.g., A, B, C',
                    icon: Icons.category,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a section';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Subject
                  _buildTextField(
                    controller: _subjectController,
                    label: 'Subject',
                    hint: 'e.g., Mathematics, Physics',
                    icon: Icons.book,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a subject';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Room
                  _buildTextField(
                    controller: _roomController,
                    label: 'Room',
                    hint: 'e.g., Room 101, Lab 205',
                    icon: Icons.room,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a room';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Description
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Brief description of the class',
                    icon: Icons.description,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),

                  // Theme Color
                  Text(
                    'Theme Color',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildColorPicker(),
                  const SizedBox(height: 32),

                  // Create Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createClass,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4285F4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Create Class',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey[400],
            ),
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4285F4), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _colors.map((color) {
        final isSelected = _selectedColor == color;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedColor = color;
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ColorUtils.hexToColor(color),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.grey[800]! : Colors.transparent,
                width: 3,
              ),
            ),
            child: isSelected
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  void _createClass() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final classProvider = context.read<ClassProvider>();
      final currentUser = classProvider.currentUser;

      if (currentUser == null) {
        throw Exception('User not found');
      }

      // Generate a unique class code
      final classCode = await classProvider.generateClassCode();
      if (classCode.isEmpty) {
        throw Exception('Failed to generate class code');
      }

      final newClass = ClassModel(
        id: '', // Let the database generate the UUID
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        teacherId: currentUser.id,
        teacherName: currentUser.name,
        section: _sectionController.text.trim(),
        subject: _subjectController.text.trim(),
        room: _roomController.text.trim(),
        classCode: classCode,
        createdAt: DateTime.now(),
        studentCount: 0,
        themeColor: _selectedColor,
      );

      final success = await classProvider.createClass(newClass);

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Class "${newClass.name}" created successfully!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: const Color(0xFF34A853),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error creating class: ${classProvider.errorMessage}',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error creating class: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
