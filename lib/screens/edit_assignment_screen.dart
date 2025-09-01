import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/assignment_model.dart';
import '../models/class_model.dart';
import '../providers/assignment_provider.dart';
import '../utils/color_utils.dart';

class EditAssignmentScreen extends StatefulWidget {
  final AssignmentModel assignment;
  final ClassModel classModel;

  const EditAssignmentScreen({
    super.key,
    required this.assignment,
    required this.classModel,
  });

  @override
  State<EditAssignmentScreen> createState() => _EditAssignmentScreenState();
}

class _EditAssignmentScreenState extends State<EditAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _totalPointsController = TextEditingController();
  
  DateTime _selectedDueDate = DateTime.now();
  AssignmentStatus _selectedStatus = AssignmentStatus.active;
  List<String> _attachments = [];

  @override
  void initState() {
    super.initState();
    // Pre-populate form with existing assignment data
    _titleController.text = widget.assignment.title;
    _descriptionController.text = widget.assignment.description;
    _instructionsController.text = widget.assignment.instructions ?? '';
    _totalPointsController.text = widget.assignment.totalPoints.toString();
    _selectedDueDate = widget.assignment.dueDate;
    _selectedStatus = widget.assignment.status;
    _attachments = widget.assignment.attachments ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _totalPointsController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDueDate),
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = DateTime(
          _selectedDueDate.year,
          _selectedDueDate.month,
          _selectedDueDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _saveAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);
    
    final updatedAssignment = AssignmentModel(
      id: widget.assignment.id,
      classId: widget.assignment.classId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dueDate: _selectedDueDate,
      totalPoints: int.parse(_totalPointsController.text),
      status: _selectedStatus,
      createdAt: widget.assignment.createdAt,
      updatedAt: DateTime.now(),
      attachments: _attachments.isNotEmpty ? _attachments : null,
      instructions: _instructionsController.text.trim().isNotEmpty 
          ? _instructionsController.text.trim() 
          : null,
    );

    final success = await assignmentProvider.updateAssignment(updatedAssignment);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating assignment: ${assignmentProvider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final classThemeColor = ColorUtils.hexToColor(widget.classModel.themeColor ?? '#4285F4');
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Edit Assignment',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: classThemeColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<AssignmentProvider>(
            builder: (context, assignmentProvider, _) {
              if (assignmentProvider.isLoading) {
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: classThemeColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Assignment',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Update assignment details and settings',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Form Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildFormSection(
                      title: 'Basic Information',
                      subtitle: 'Assignment title and description',
                      icon: Icons.info,
                      color: Colors.blue,
                      children: [
                        _buildTextField(
                          controller: _titleController,
                          label: 'Assignment Title',
                          icon: Icons.title,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an assignment title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Description',
                          icon: Icons.description,
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildFormSection(
                      title: 'Instructions',
                      subtitle: 'Guidelines for students (optional)',
                      icon: Icons.assignment,
                      color: Colors.orange,
                      children: [
                        _buildTextField(
                          controller: _instructionsController,
                          label: 'Instructions',
                          icon: Icons.assignment,
                          maxLines: 4,
                          hintText: 'Enter detailed instructions for students...',
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildFormSection(
                      title: 'Due Date & Time',
                      subtitle: 'Set assignment deadline',
                      icon: Icons.schedule,
                      color: Colors.red,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildDateButton(
                                  onPressed: _selectDueDate,
                                  icon: Icons.calendar_today,
                                  label: 'Date',
                                  value: '${_selectedDueDate.day}/${_selectedDueDate.month}/${_selectedDueDate.year}',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDateButton(
                                  onPressed: _selectTime,
                                  icon: Icons.access_time,
                                  label: 'Time',
                                  value: '${_selectedDueDate.hour.toString().padLeft(2, '0')}:${_selectedDueDate.minute.toString().padLeft(2, '0')}',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildFormSection(
                      title: 'Assignment Settings',
                      subtitle: 'Points and status configuration',
                      icon: Icons.settings,
                      color: Colors.green,
                      children: [
                        _buildTextField(
                          controller: _totalPointsController,
                          label: 'Total Points',
                          icon: Icons.score,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter total points';
                            }
                            final points = int.tryParse(value);
                            if (points == null || points <= 0) {
                              return 'Please enter a valid number of points';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildStatusDropdown(),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Consumer<AssignmentProvider>(
                        builder: (context, assignmentProvider, _) {
                          return ElevatedButton.icon(
                            onPressed: assignmentProvider.isLoading ? null : _saveAssignment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: classThemeColor,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: assignmentProvider.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: assignmentProvider.isLoading
                                ? const Text('Updating...')
                                : Text(
                                    'Update Assignment',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: GoogleFonts.poppins(
          color: Colors.grey[600],
        ),
        hintStyle: GoogleFonts.poppins(
          color: Colors.grey[400],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: ColorUtils.hexToColor(widget.classModel.themeColor ?? '#4285F4'),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[300]!),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[400]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: Icon(
          icon,
          color: Colors.grey[600],
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDateButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.grey[600],
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<AssignmentStatus>(
      value: _selectedStatus,
      decoration: InputDecoration(
        labelText: 'Status',
        labelStyle: GoogleFonts.poppins(
          color: Colors.grey[600],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: ColorUtils.hexToColor(widget.classModel.themeColor ?? '#4285F4'),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: Icon(
          Icons.info,
          color: Colors.grey[600],
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      items: AssignmentStatus.values.map((status) {
        Color statusColor;
        IconData statusIcon;
        
        switch (status) {
          case AssignmentStatus.active:
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            break;
          case AssignmentStatus.inactive:
            statusColor = Colors.grey;
            statusIcon = Icons.pause_circle;
            break;
          case AssignmentStatus.archived:
            statusColor = Colors.orange;
            statusIcon = Icons.archive;
            break;
        }
        
        return DropdownMenuItem(
          value: status,
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 16),
              const SizedBox(width: 8),
              Text(
                status.toString().split('.').last.toUpperCase(),
                style: GoogleFonts.poppins(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedStatus = value;
          });
        }
      },
    );
  }
}
