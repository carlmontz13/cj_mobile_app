import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/class_model.dart';
import '../models/material_model.dart';
import '../models/user_model.dart';
import '../providers/material_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/color_utils.dart';
import 'material_detail_screen.dart';

class MaterialsListScreen extends StatefulWidget {
  final ClassModel classModel;

  const MaterialsListScreen({
    super.key,
    required this.classModel,
  });

  @override
  State<MaterialsListScreen> createState() => _MaterialsListScreenState();
}

class _MaterialsListScreenState extends State<MaterialsListScreen> {
  @override
  void initState() {
    super.initState();
    // Load materials when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final materialProvider = Provider.of<MaterialProvider>(context, listen: false);
      materialProvider.loadMaterials(widget.classModel.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Materials',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: ColorUtils.hexToColor(widget.classModel.themeColor ?? '#4285F4'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final materialProvider = Provider.of<MaterialProvider>(context, listen: false);
          await materialProvider.loadMaterials(widget.classModel.id);
        },
        child: Consumer2<MaterialProvider, AuthProvider>(
          builder: (context, materialProvider, authProvider, child) {
            if (materialProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (materialProvider.error != null) {
              return _buildErrorState(materialProvider.error!);
            }

            if (materialProvider.materials.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: materialProvider.materials.length,
              itemBuilder: (context, index) {
                final material = materialProvider.materials[index];
                return _buildMaterialCard(material, authProvider.currentUser);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMaterialCard(MaterialModel material, UserModel? currentUser) {
    final isTeacher = currentUser?.role == UserRole.teacher;
    final ownsClass = currentUser?.id == widget.classModel.teacherId;
    final canManage = isTeacher && ownsClass;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MaterialDetailScreen(
                material: material,
                classModel: widget.classModel,
                isTeacher: canManage,
              ),
            ),
          ).then((result) {
            if (result == 'deleted') {
              // Material was deleted, refresh the list
              final materialProvider = Provider.of<MaterialProvider>(context, listen: false);
              materialProvider.loadMaterials(widget.classModel.id);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ColorUtils.hexToColor(widget.classModel.themeColor ?? '#4285F4').withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: ColorUtils.hexToColor(widget.classModel.themeColor ?? '#4285F4'),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          material.title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created ${_formatDate(material.createdAt)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (canManage) ...[
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          _showDeleteConfirmation(material);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: GoogleFonts.poppins(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              if (material.selectedContentType != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getContentTypeColor(material.selectedContentType!).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getContentTypeLabel(material.selectedContentType!),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: _getContentTypeColor(material.selectedContentType!),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No materials yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first material to get started',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading materials',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.red[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(MaterialModel material) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Material',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete "${material.title}"? This action cannot be undone.',
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
              final materialProvider = Provider.of<MaterialProvider>(context, listen: false);
              final success = await materialProvider.deleteMaterial(material.id!);
              
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Material "${material.title}" deleted successfully!',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: const Color(0xFF34A853),
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error deleting material: ${materialProvider.error}',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getContentTypeColor(String contentType) {
    switch (contentType) {
      case 'simplified':
        return Colors.green;
      case 'standard':
        return Colors.blue;
      case 'advanced':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getContentTypeLabel(String contentType) {
    switch (contentType) {
      case 'simplified':
        return 'Simplified';
      case 'standard':
        return 'Standard';
      case 'advanced':
        return 'Advanced';
      default:
        return 'Unknown';
    }
  }
}
