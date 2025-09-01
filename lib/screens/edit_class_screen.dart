import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/class_provider.dart';
import '../providers/auth_provider.dart';
import '../models/class_model.dart';
import '../models/user_model.dart';
import '../utils/color_utils.dart';
import '../widgets/auth_guard.dart';
import '../widgets/role_guard.dart';

class EditClassScreen extends StatefulWidget {
  final ClassModel classModel;

  const EditClassScreen({
    super.key,
    required this.classModel,
  });

  @override
  State<EditClassScreen> createState() => _EditClassScreenState();
}

class _EditClassScreenState extends State<EditClassScreen> {
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
  void initState() {
    super.initState();
    _nameController.text = widget.classModel.name;
    _descriptionController.text = widget.classModel.description;
    _sectionController.text = widget.classModel.section;
    _subjectController.text = widget.classModel.subject;
    _roomController.text = widget.classModel.room;
    _selectedColor = widget.classModel.themeColor ?? '#4285F4';
  }

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
        classModel: widget.classModel,
        allowedRoles: [UserRole.teacher],
        requireEnrollment: false,
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(
              'Edit Class',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: ColorUtils.hexToColor(_selectedColor),
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
                    'Edit class details',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Update the information below to modify your class',
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

                  // Update Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateClass,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorUtils.hexToColor(_selectedColor),
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
                              'Update Class',
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
              borderSide: BorderSide(color: ColorUtils.hexToColor(_selectedColor), width: 2),
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

  void _updateClass() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional role check before updating
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final isTeacher = currentUser?.role == UserRole.teacher;
    final ownsClass = currentUser?.id == widget.classModel.teacherId;
    
    if (!isTeacher || !ownsClass) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Access denied. Only the class teacher can update this class.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final classProvider = context.read<ClassProvider>();

      final updatedClass = widget.classModel.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        section: _sectionController.text.trim(),
        subject: _subjectController.text.trim(),
        room: _roomController.text.trim(),
        themeColor: _selectedColor,
      );

      final success = await classProvider.updateClass(updatedClass);

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Class "${updatedClass.name}" updated successfully!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: const Color(0xFF34A853),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error updating class: ${classProvider.errorMessage}',
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
              'Error updating class: $e',
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
