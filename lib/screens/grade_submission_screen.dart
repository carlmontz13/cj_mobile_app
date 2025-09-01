import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/assignment_model.dart';
import '../models/submission_model.dart';
import '../models/image_attachment_model.dart';
import '../providers/assignment_provider.dart';
import '../widgets/image_attachment_widget.dart';
import '../services/storage_service.dart';
import '../services/mlkit_service.dart';
import '../services/gemini_service.dart';
import '../utils/color_utils.dart';

class GradeSubmissionScreen extends StatefulWidget {
  final AssignmentModel assignment;
  final SubmissionModel submission;

  const GradeSubmissionScreen({
    super.key,
    required this.assignment,
    required this.submission,
  });

  @override
  State<GradeSubmissionScreen> createState() => _GradeSubmissionScreenState();
}

class _GradeSubmissionScreenState extends State<GradeSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gradeController = TextEditingController();
  final _feedbackController = TextEditingController();
  final _storageService = StorageService();

  // Injected Gemini API key (requested by user)
  static const String _geminiApiKey = 'AIzaSyAviP7TuRqXA2G3fLsIMEkBT46jMShLFrA';

  List<ImageAttachmentModel> _imageAttachments = [];
  bool _isRefreshingImages = false;
  bool _isAiGrading = false;
  AssignmentModel? _assignmentWithClassDetails;

  @override
  void initState() {
    super.initState();
    if (widget.submission.grade != null) {
      _gradeController.text = widget.submission.grade.toString();
    }
    if (widget.submission.feedback != null) {
      _feedbackController.text = widget.submission.feedback!;
    }
    _imageAttachments = widget.submission.imageAttachments ?? [];
    _refreshImageUrls();
    _loadAssignmentWithClassDetails();
  }

  @override
  void dispose() {
    _gradeController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadAssignmentWithClassDetails() async {
    final assignmentProvider = context.read<AssignmentProvider>();
    final assignmentWithDetails = await assignmentProvider.getAssignmentById(widget.assignment.id);
    if (mounted && assignmentWithDetails != null) {
      setState(() {
        _assignmentWithClassDetails = assignmentWithDetails;
      });
    }
  }

  // Get the class theme color
  Color _getPrimaryColor(ThemeData theme) {
    final assignment = _assignmentWithClassDetails ?? widget.assignment;
    final classThemeColor = assignment.classDetails?.themeColor;
    return classThemeColor != null 
        ? ColorUtils.hexToColor(classThemeColor)
        : theme.colorScheme.primary;
  }

  Future<void> _refreshImageUrls() async {
    if (_imageAttachments.isEmpty) return;

    setState(() {
      _isRefreshingImages = true;
    });

    try {
      final refreshed = <ImageAttachmentModel>[];
      for (final attachment in _imageAttachments) {
        if (attachment.url.isNotEmpty) {
          try {
            final freshUrl = await _storageService.getSignedUrl(attachment.url);
            if (freshUrl != null && freshUrl != attachment.url) {
              refreshed.add(attachment.copyWith(url: freshUrl));
            } else {
              refreshed.add(attachment);
            }
          } catch (_) {
            refreshed.add(attachment);
          }
        } else {
          refreshed.add(attachment);
        }
      }

      if (mounted) {
        setState(() {
          _imageAttachments = refreshed;
          _isRefreshingImages = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isRefreshingImages = false;
        });
      }
    }
  }

  Future<void> _gradeSubmission() async {
    if (!_formKey.currentState!.validate()) return;

    final assignmentProvider = context.read<AssignmentProvider>();
    final grade = int.parse(_gradeController.text);
    final feedback = _feedbackController.text.trim();

    final success = await assignmentProvider.gradeSubmission(
      widget.submission.id,
      grade,
      feedback,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Submission graded successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Text(assignmentProvider.error ?? 'Failed to grade submission'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _aiGradeAndSave() async {
    final geminiKey = _geminiApiKey;
    if (geminiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Text('Missing Gemini API key'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() { _isAiGrading = true; });

    try {
      // Collect submission text + OCR from images (OCR only on non-web)
      String ocrText = '';
      if (!kIsWeb) {
        try {
          final imageFiles = await _downloadImageFilesFromAttachments(_imageAttachments);
          if (imageFiles.isNotEmpty) {
            print('AI Grading: Processing ${imageFiles.length} images with ML Kit');
            final ml = MlKitService();
            ocrText = await ml.extractTextFromImageFiles(imageFiles);
            ml.dispose();
            print('AI Grading: OCR extracted ${ocrText.length} characters');
          }
        } catch (e) {
          print('AI Grading: OCR failed, continuing with text only: $e');
          // Continue with text-only grading
        }
      }

      final combinedSubmission = StringBuffer()
        ..writeln(widget.submission.content.trim())
        ..writeln()
        ..writeln(ocrText.trim());

      print('AI Grading: Sending ${combinedSubmission.length} characters to Gemini');
      
      final gemini = GeminiService(apiKey: geminiKey);
      final result = await gemini.gradeSubmission(
        assignmentTitle: widget.assignment.title,
        assignmentInstructions: widget.assignment.instructions ?? widget.assignment.description,
        totalPoints: widget.assignment.totalPoints,
        submissionText: combinedSubmission.toString().trim(),
      );

      _gradeController.text = result.grade.toString();
      _feedbackController.text = result.feedback;

      await _gradeSubmission();
    } catch (e) {
      print('AI Grading: Failed with error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Text('AI grading failed: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() { _isAiGrading = false; });
      }
    }
  }

  Future<List<File>> _downloadImageFilesFromAttachments(List<ImageAttachmentModel> attachments) async {
    final files = <File>[];
    if (attachments.isEmpty) return files;

    // Skip on web where file APIs and ML Kit are not available
    if (kIsWeb) return files;

    final tempDir = Directory.systemTemp;
    for (final a in attachments) {
      try {
        final url = a.url;
        if (url.isEmpty) continue;
        final resp = await http.get(Uri.parse(url));
        if (resp.statusCode == 200) {
          final safeName = (a.fileName.isNotEmpty ? a.fileName : a.id).replaceAll('/', '_');
          final file = File('${tempDir.path}/$safeName');
          await file.writeAsBytes(resp.bodyBytes);
          files.add(file);
        }
      } catch (_) {
        // Skip failed download
      }
    }
    return files;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = _getPrimaryColor(theme);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Grade Submission',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStudentInfo(),
                    SizedBox(height: 24),
                    _buildSubmissionContent(),
                    SizedBox(height: 24),
                    _buildGradingForm(),
                    SizedBox(height: 32),
                    _buildActionButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfo() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = _getPrimaryColor(theme);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: primaryColor,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Student Information',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      widget.submission.studentName[0].toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.submission.studentName,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        textHeightBehavior: const TextHeightBehavior(
                          applyHeightToFirstAscent: false,
                          applyHeightToLastDescent: false,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Submitted ${DateFormat('MMM dd, yyyy').format(widget.submission.submittedAt)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textHeightBehavior: const TextHeightBehavior(
                          applyHeightToFirstAscent: false,
                          applyHeightToLastDescent: false,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.submission.isLate)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: colorScheme.onErrorContainer,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'LATE',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onErrorContainer,
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
    );
  }

  Widget _buildSubmissionContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = _getPrimaryColor(theme);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  color: primaryColor,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Submission Content',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                  strutStyle: const StrutStyle(
                    height: 1.0,
                    forceStrutHeight: true,
                    leading: 0,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                widget.submission.content,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  height: 1.5,
                  color: colorScheme.onSurface,
                ),
                textHeightBehavior: const TextHeightBehavior(
                  applyHeightToFirstAscent: false,
                  applyHeightToLastDescent: false,
                ),
                strutStyle: const StrutStyle(
                  height: 1.3,
                  forceStrutHeight: true,
                  leading: 0,
                ),
              ),
            ),
            if (_imageAttachments.isNotEmpty) ...[
              SizedBox(height: 20),
              if (_isRefreshingImages) ...[
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Loading images...',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
              ],
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ImageAttachmentGrid(
                    key: ValueKey(_imageAttachments.map((e) => e.url).join('|')),
                    attachments: _imageAttachments,
                    showDeleteButton: false,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGradingForm() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = _getPrimaryColor(theme);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.grade_outlined,
                  color: primaryColor,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'AI Grading',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: primaryColor,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'AI will analyze the submission and provide grading',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _gradeController,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'AI Generated Grade',
                hintText: 'Grade will be generated automatically',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                suffixText: '/${widget.assignment.totalPoints}',
                suffixStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: primaryColor,
                ),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Grade will be generated by AI';
                }
                final grade = int.tryParse(value);
                if (grade == null || grade < 0 || grade > widget.assignment.totalPoints) {
                  return 'Grade must be between 0 and ${widget.assignment.totalPoints}';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _feedbackController,
              readOnly: true,
              enableInteractiveSelection: true,
              decoration: InputDecoration(
                labelText: 'AI Generated Feedback',
                hintText: 'Press "AI Grade & Save" to generate detailed feedback...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
              style: GoogleFonts.poppins(
                fontSize: 15,
                height: 1.5,
                color: colorScheme.onSurface,
              ),
              minLines: 5,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
            ),
            if (widget.submission.isGraded) ...[
              SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: primaryColor,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Previously graded on ${DateFormat('MMM dd, yyyy').format(widget.submission.gradedAt!)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                        textHeightBehavior: const TextHeightBehavior(
                          applyHeightToFirstAscent: false,
                          applyHeightToLastDescent: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = _getPrimaryColor(theme);

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isAiGrading ? null : _aiGradeAndSave,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isAiGrading) ...[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                ] else ...[
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                ],
                Text(
                  _isAiGrading 
                    ? 'Processing...' 
                    : (widget.submission.isGraded ? 'Recheck with AI' : 'AI Grade & Save'),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
