import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/class_model.dart';
import '../models/material_model.dart';
import '../utils/color_utils.dart';

class MaterialDetailScreen extends StatefulWidget {
  final MaterialModel material;
  final ClassModel classModel;
  final bool isTeacher;

  const MaterialDetailScreen({
    super.key,
    required this.material,
    required this.classModel,
    required this.isTeacher,
  });

  @override
  State<MaterialDetailScreen> createState() => _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends State<MaterialDetailScreen> {
  String _selectedContentType = 'standard';
  late MaterialModel _material;

  @override
  void initState() {
    super.initState();
    // Set initial content type to the selected one or default to standard
    _material = widget.material;
    _selectedContentType = _material.selectedContentType ?? 'standard';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Material Details',
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
        actions: [
          if (widget.isTeacher) ...[
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteConfirmation();
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Material header
            Container(
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
                              _material.title,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Created ${_formatDate(_material.createdAt)}',
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
                  // Content type selector
                  if (_hasMultipleContentTypes()) ...[
                    Text(
                      'Content Type',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildContentTypeSelector(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Material content
            Container(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Content',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      if (widget.isTeacher)
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Edit ${_selectedContentType} content',
                              icon: const Icon(Icons.edit_outlined),
                              color: Colors.grey[700],
                              onPressed: _showEditContentDialog,
                            ),
                            IconButton(
                              tooltip: 'Delete ${_selectedContentType} content',
                              icon: const Icon(Icons.delete_outline),
                              color: Colors.red[400],
                              onPressed: _showDeleteContentConfirmation,
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildContentDisplay(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTypeSelector() {
    return Row(
      children: [
        if (_material.simplifiedContent != null && _material.simplifiedContent!.isNotEmpty)
          _buildContentTypeChip('simplified', 'Simplified', Colors.green),
        if (_material.standardContent != null && _material.standardContent!.isNotEmpty) ...[
          const SizedBox(width: 8),
          _buildContentTypeChip('standard', 'Standard', Colors.blue),
        ],
        if (_material.advancedContent != null && _material.advancedContent!.isNotEmpty) ...[
          const SizedBox(width: 8),
          _buildContentTypeChip('advanced', 'Advanced', Colors.purple),
        ],
      ],
    );
  }

  Widget _buildContentTypeChip(String type, String label, Color color) {
    final isSelected = _selectedContentType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedContentType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Widget _buildContentDisplay() {
    String? content;
    
    switch (_selectedContentType) {
      case 'simplified':
        content = _material.simplifiedContent;
        break;
      case 'standard':
        content = _material.standardContent;
        break;
      case 'advanced':
        content = _material.advancedContent;
        break;
    }

    if (content == null || content.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.content_paste_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No content available',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return MarkdownBody(
      data: content,
      styleSheet: MarkdownStyleSheet(
        h1: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.grey[800],
        ),
        h2: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
        h3: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
        p: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.grey[700],
          height: 1.6,
        ),
        listBullet: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.grey[700],
        ),
        code: GoogleFonts.poppins(
          fontSize: 14,
          backgroundColor: Colors.grey[100],
          color: Colors.grey[800],
        ),
        codeblockDecoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  bool _hasMultipleContentTypes() {
    int count = 0;
    if (_material.simplifiedContent != null && _material.simplifiedContent!.isNotEmpty) count++;
    if (_material.standardContent != null && _material.standardContent!.isNotEmpty) count++;
    if (_material.advancedContent != null && _material.advancedContent!.isNotEmpty) count++;
    return count > 1;
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Material',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete "${_material.title}"? This action cannot be undone.',
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
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, 'deleted');
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
  
  void _showEditContentDialog() {
    String currentContent = _getContentForType(_selectedContentType) ?? '';
    final TextEditingController controller = TextEditingController(text: currentContent);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit ${_selectedContentType} content',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: 600,
          child: TextField(
            controller: controller,
            maxLines: 12,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter markdown content...'
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          FilledButton(
            onPressed: () {
              _updateContentForType(_selectedContentType, controller.text.trim());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Content updated')),
              );
            },
            child: Text('Save', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showDeleteContentConfirmation() {
    final String label = _selectedContentType;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete $label content',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete the $label content only? This cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () {
              _updateContentForType(_selectedContentType, '');
              _ensureValidSelectedTypeAfterDeletion();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${label[0].toUpperCase()}${label.substring(1)} content deleted')),
              );
            },
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String? _getContentForType(String type) {
    switch (type) {
      case 'simplified':
        return _material.simplifiedContent;
      case 'standard':
        return _material.standardContent;
      case 'advanced':
        return _material.advancedContent;
    }
    return null;
  }

  void _updateContentForType(String type, String? newContent) {
    setState(() {
      switch (type) {
        case 'simplified':
          _material = _material.copyWith(simplifiedContent: newContent);
          break;
        case 'standard':
          _material = _material.copyWith(standardContent: newContent);
          break;
        case 'advanced':
          _material = _material.copyWith(advancedContent: newContent);
          break;
      }
    });
  }

  void _ensureValidSelectedTypeAfterDeletion() {
    final String? content = _getContentForType(_selectedContentType);
    if (content != null && content.isNotEmpty) return;

    // Pick the first available content type with content
    final orderedTypes = ['simplified', 'standard', 'advanced'];
    for (final t in orderedTypes) {
      final c = _getContentForType(t);
      if (c != null && c.isNotEmpty) {
        setState(() {
          _selectedContentType = t;
        });
        return;
      }
    }
    // none available; keep current but it's empty; UI will show empty state
  }
}
