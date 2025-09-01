import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/class_model.dart';
import '../models/material_model.dart';
import '../utils/color_utils.dart';
import '../services/gemini_service.dart';
import '../services/material_service.dart';
import '../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateMaterialScreen extends StatefulWidget {
  final ClassModel classModel;

  const CreateMaterialScreen({
    super.key,
    required this.classModel,
  });

  @override
  State<CreateMaterialScreen> createState() => _CreateMaterialScreenState();
}

class _CreateMaterialScreenState extends State<CreateMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();

  String _selectedLanguageCode = 'en';

  bool _isSaving = false;
  bool _isGenerating = false;
  Map<String, String>? _generated;
  Map<String, bool> _selectedResponses = {};

  // Match grading screen behavior: use a static const API key
  static const String _geminiApiKey = 'AIzaSyAviP7TuRqXA2G3fLsIMEkBT46jMShLFrA';

  @override
  void initState() {
    super.initState();
    // Refresh UI as the user types so the AI button enable/disable state updates
    _titleController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _saveMaterial() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if any content is selected
    final selectedKeys = _selectedResponses.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    
    if (selectedKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one content type to publish', 
            style: GoogleFonts.poppins()),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final materialService = MaterialService();
      
      // Get the selected content
      final selectedContentType = selectedKeys.first; // For now, use the first selected
      final selectedContent = _generated![selectedContentType];
      
             // Get current user ID
       final currentUser = Supabase.instance.client.auth.currentUser;
       if (currentUser == null) {
         throw Exception('User not authenticated');
       }
       
       // Create material model
       final material = MaterialModel(
         classId: widget.classModel.id!,
         title: _titleController.text.trim(),
         languageCode: _selectedLanguageCode,
         simplifiedContent: _generated!['simplified'],
         standardContent: _generated!['standard'],
         advancedContent: _generated!['advanced'],
         selectedContentType: selectedContentType,
         selectedContent: selectedContent,
         createdAt: DateTime.now(),
         updatedAt: DateTime.now(),
         createdBy: currentUser.id,
         isActive: true,
       );
      
      await materialService.createMaterial(material);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Material published successfully!', 
            style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to publish material: $e', 
            style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _generateWithAI() async {
    final topic = _titleController.text.trim().isEmpty ? 'General topic' : _titleController.text.trim();
    setState(() {
      _isGenerating = true;
    });
    try {
      // Use same key sourcing approach as grade_submission_screen.dart
      if (_geminiApiKey.isEmpty) {
        throw Exception('Missing Gemini API key');
      }
      final gemini = GeminiService(apiKey: _geminiApiKey);
      final result = await gemini.generateMaterialContent(topic: topic, languageCode: _selectedLanguageCode);
      if (!mounted) return;
      setState(() {
        _generated = result;
        // Initialize selection state
        _selectedResponses = {
          'simplified': false,
          'standard': false,
          'advanced': false,
        };
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI generation failed: $e', style: GoogleFonts.poppins())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _applyGenerated(String content) {
    // TODO: Handle applying generated content when description field is implemented
    // For now, we can show a snackbar or handle it differently
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Content applied: ${content.substring(0, content.length > 50 ? 50 : content.length)}...', 
          style: GoogleFonts.poppins()),
      ),
    );
  }

  void _toggleResponseSelection(String key) {
    setState(() {
      _selectedResponses[key] = !(_selectedResponses[key] ?? false);
    });
  }

  bool get _canPublish {
    return _generated != null && 
           _selectedResponses.values.any((selected) => selected);
  }



  Widget _buildAiButton() {
    final themeColor = ColorUtils.hexToColor(widget.classModel.themeColor ?? '#4285F4');
    final hasPrompt = _titleController.text.trim().isNotEmpty;
    return SizedBox(
      width: double.infinity,
      child: Tooltip(
        message: _isGenerating
            ? 'Generating content…'
            : (hasPrompt ? 'Let AI draft material' : 'Enter a topic to enable'),
        child: ElevatedButton.icon(
        onPressed: (_isGenerating || !hasPrompt) ? null : _generateWithAI,
        icon: _isGenerating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.auto_awesome_rounded),
        label: Text(
          _isGenerating ? 'Generating…' : 'AI Generate',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: _isGenerating ? themeColor.withOpacity(0.85) : themeColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ).merge(
          ButtonStyle(
            overlayColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.pressed)) {
                return Colors.white.withOpacity(0.14);
              }
              if (states.contains(MaterialState.hovered)) {
                return Colors.white.withOpacity(0.08);
              }
              return null;
            }),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildRtlChip(bool isRtl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: (isRtl ? Colors.green : Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isRtl ? Icons.format_textdirection_r_to_l : Icons.format_textdirection_l_to_r, size: 18, color: isRtl ? Colors.green[700] : Colors.grey[700]),
          const SizedBox(width: 6),
          Text(isRtl ? 'RTL' : 'LTR', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[800])),
        ],
      ),
    );
  }

  Widget _buildGeneratedCard(String label, String content, String keyName) {
    final isSelected = _selectedResponses[keyName] ?? false;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (value) => _toggleResponseSelection(keyName),
                activeColor: Colors.blue[600],
              ),
              Icon(Icons.auto_awesome, color: Colors.amber[700]),
              const SizedBox(width: 8),
              Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  final edited = await _openInlineEditor(label, content);
                  if (edited != null) {
                    setState(() {
                      _generated = {
                        ...?_generated,
                        keyName: edited,
                      };
                    });
                  }
                },
                child: Text('Edit', style: GoogleFonts.poppins()),
              ),
              FilledButton.tonal(
                onPressed: () {
                  _applyGenerated(_generated?[keyName] ?? content);
                },
                child: Text('Use', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: (_selectedLanguageCode == 'ar' || _selectedLanguageCode == 'he' || _selectedLanguageCode == 'fa' || _selectedLanguageCode == 'ur')
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: Markdown(
              data: _generated?[keyName] ?? content,
              shrinkWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _openInlineEditor(String label, String content) async {
    final controller = TextEditingController(text: content);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $label', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: 600,
          child: TextField(
            controller: controller,
            maxLines: null,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.poppins())),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text('Save', style: GoogleFonts.poppins())),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = ColorUtils.hexToColor(widget.classModel.themeColor ?? '#4285F4');
    final bool isRtl = _selectedLanguageCode == 'ar' || _selectedLanguageCode == 'he' || _selectedLanguageCode == 'fa' || _selectedLanguageCode == 'ur';
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Create Material',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: themeColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: themeColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.menu_book_rounded, color: themeColor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Instructional Material',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[900],
                                      ),
                                    ),
                                    Text(
                                      'Share readings, slides, links, or notes with your class',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Language selection (responsive)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final bool isNarrow = constraints.maxWidth < 420;
                              if (isNarrow) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    DropdownButtonFormField<String>(
                                      value: _selectedLanguageCode,
                                      decoration: InputDecoration(
                                        labelText: 'Language',
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'en', child: Text('English')),
                                        DropdownMenuItem(value: 'es', child: Text('Español')),
                                        DropdownMenuItem(value: 'fr', child: Text('Français')),
                                        DropdownMenuItem(value: 'ar', child: Text('العربية (RTL)')),
                                        DropdownMenuItem(value: 'he', child: Text('עברית (RTL)')),
                                      ],
                                      onChanged: (val) {
                                        if (val == null) return;
                                        setState(() {
                                          _selectedLanguageCode = val;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    _buildRtlChip(isRtl),
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedLanguageCode,
                                      decoration: InputDecoration(
                                        labelText: 'Language',
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'en', child: Text('English')),
                                        DropdownMenuItem(value: 'es', child: Text('Español')),
                                        DropdownMenuItem(value: 'fr', child: Text('Français')),
                                        DropdownMenuItem(value: 'ar', child: Text('العربية (RTL)')),
                                        DropdownMenuItem(value: 'he', child: Text('עברית (RTL)')),
                                      ],
                                      onChanged: (val) {
                                        if (val == null) return;
                                        setState(() {
                                          _selectedLanguageCode = val;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(child: _buildRtlChip(isRtl)),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                             controller: _titleController,
                             decoration: InputDecoration(
                               labelText: 'Prompt your topic',
                               hintText: 'e.g., Create a lesson on the history of the internet',
                               filled: true,
                               fillColor: Colors.grey[50],
                               prefixIcon: const Icon(Icons.lightbulb_rounded),
                               border: OutlineInputBorder(
                                 borderRadius: BorderRadius.circular(12),
                               ),
                             ),
                             validator: (value) => (value == null || value.trim().isEmpty) ? 'Topic is required' : null,
                           ),
                          const SizedBox(height: 12),
                            // AI Generate button below topic
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _buildAiButton(),
                            ),
                           const SizedBox(height: 12),
                           // AI Generated Content Section
                           if (_generated != null) ...[
                             const SizedBox(height: 16),
                             Container(
                               width: double.infinity,
                               decoration: BoxDecoration(
                                 color: Colors.blue[50],
                                 borderRadius: BorderRadius.circular(12),
                                 border: Border.all(color: Colors.blue[200]!),
                               ),
                               child: Padding(
                                 padding: const EdgeInsets.all(16),
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Row(
                                       children: [
                                         Icon(Icons.auto_awesome, color: Colors.blue[700]),
                                         const SizedBox(width: 8),
                                         Text(
                                           'AI Generated Content',
                                           style: GoogleFonts.poppins(
                                             fontSize: 16,
                                             fontWeight: FontWeight.w600,
                                             color: Colors.blue[800],
                                           ),
                                         ),
                                       ],
                                     ),
                                     const SizedBox(height: 8),
                                     Text(
                                       'Select the content you want to save to the database:',
                                       style: GoogleFonts.poppins(
                                         fontSize: 13,
                                         color: Colors.blue[700],
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                             ),
                             const SizedBox(height: 12),
                             _buildGeneratedCard('Simplified', _generated!['simplified'] ?? '', 'simplified'),
                             const SizedBox(height: 12),
                             _buildGeneratedCard('Standard', _generated!['standard'] ?? '', 'standard'),
                             const SizedBox(height: 12),
                             _buildGeneratedCard('Advanced', _generated!['advanced'] ?? '', 'advanced'),
                           ],
                          // Row(
                          //   children: [
                          //     Expanded(
                          //       child: OutlinedButton.icon(
                          //         onPressed: () {
                          //           // TODO: Implement file picker/link attach
                          //         },
                          //         icon: const Icon(Icons.attach_file_rounded),
                          //         label: Text('Add attachment', style: GoogleFonts.poppins()),
                          //         style: OutlinedButton.styleFrom(
                          //           padding: const EdgeInsets.symmetric(vertical: 14),
                          //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          //         ),
                          //       ),
                          //     ),
                          //     const SizedBox(width: 12),
                          //     Expanded(
                          //       child: OutlinedButton.icon(
                          //         onPressed: () {
                          //           // TODO: Implement link input
                          //         },
                          //         icon: const Icon(Icons.link_rounded),
                          //         label: Text('Add link', style: GoogleFonts.poppins()),
                          //         style: OutlinedButton.styleFrom(
                          //           padding: const EdgeInsets.symmetric(vertical: 14),
                          //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          //         ),
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          const SizedBox(height: 16),
                          // Editors removed per request
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
                         child: ElevatedButton.icon(
               onPressed: (_isSaving || !_canPublish) ? null : _saveMaterial,
               icon: _isSaving
                   ? const SizedBox(
                       width: 18,
                       height: 18,
                       child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                     )
                   : const Icon(Icons.cloud_upload_rounded),
               label: Text(
                 _isSaving ? 'Publishing…' : 'Publish Material',
                 style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
               ),
                             style: ElevatedButton.styleFrom(
                 backgroundColor: _canPublish ? themeColor : Colors.grey[400],
                 foregroundColor: Colors.white,
                 padding: const EdgeInsets.symmetric(vertical: 16),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               ),
            ),
          ),
        ),
      ),
    );
  }
}


