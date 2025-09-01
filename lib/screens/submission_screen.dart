import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/assignment_model.dart';
import '../models/submission_model.dart';
import '../models/image_attachment_model.dart';
import '../providers/assignment_provider.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import '../widgets/image_attachment_widget.dart';
import '../utils/color_utils.dart';

class SubmissionScreen extends StatefulWidget {
  final AssignmentModel assignment;
  final SubmissionModel? submission;

  const SubmissionScreen({
    super.key,
    required this.assignment,
    this.submission,
  });

  @override
  State<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends State<SubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _storageService = StorageService();
  
  List<ImageAttachmentModel> _imageAttachments = [];
  bool _isUploadingImage = false;
  bool _isSubmitting = false;
  AssignmentModel? _assignmentWithClassDetails;
  Color? _primaryColor;

  bool get isEditing => widget.submission != null;
  bool get isDraft => widget.submission?.status == SubmissionStatus.draft;
  bool get isSubmitted => widget.submission?.status == SubmissionStatus.submitted;
  bool get canUnsubmit => isSubmitted && !widget.submission!.isGraded;
  bool get isEditable => isDraft || !isEditing; // Editable if draft or new submission

  @override
  void initState() {
    super.initState();
    _loadAssignmentWithClassDetails();
    if (isEditing) {
      _contentController.text = widget.submission!.content;
      _imageAttachments = widget.submission!.imageAttachments ?? [];
      // Refresh image URLs for existing images
      _refreshImageUrls();
    }
  }

  Future<void> _refreshImageUrls() async {
    if (_imageAttachments.isEmpty) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final refreshedAttachments = <ImageAttachmentModel>[];
      
      for (final attachment in _imageAttachments) {
        if (attachment.url.isNotEmpty) {
          try {
            // Get a fresh signed URL for the image
            final freshUrl = await _storageService.getSignedUrl(attachment.url);
            if (freshUrl != null && freshUrl != attachment.url) {
              refreshedAttachments.add(attachment.copyWith(url: freshUrl));
            } else {
              refreshedAttachments.add(attachment);
            }
          } catch (e) {
            // If refresh fails, keep the original attachment
            refreshedAttachments.add(attachment);
          }
        } else {
          refreshedAttachments.add(attachment);
        }
      }

      if (mounted) {
        setState(() {
          _imageAttachments = refreshedAttachments;
        });
        
        // Small delay to ensure UI updates properly
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (mounted) {
          setState(() {
            _isUploadingImage = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
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

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitAssignment({bool asDraft = false}) async {
    if (!asDraft && !_formKey.currentState!.validate()) return;

    final assignmentProvider = context.read<AssignmentProvider>();
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser!;

    final isLate = DateTime.now().isAfter(widget.assignment.dueDate);

    // Upload any pending (not yet uploaded) images
    try {
      setState(() {
        _isUploadingImage = true;
        _isSubmitting = true;
      });

      final effectiveSubmissionId = isEditing
          ? widget.submission!.id
          : 'submission_${currentUser.id}_${widget.assignment.id}';

      for (int i = 0; i < _imageAttachments.length; i++) {
        final img = _imageAttachments[i];
        if (!img.isUploaded && img.previewPath != null && img.previewPath!.isNotEmpty) {
          try {
            final file = File(img.previewPath!);
            final url = await _storageService.uploadImage(file, effectiveSubmissionId);
            if (url == null || url.isEmpty) {
              throw Exception('No URL returned from storage.');
            }
            _imageAttachments[i] = img.copyWith(
              url: url,
              submissionId: effectiveSubmissionId,
              isUploaded: true,
            );
          } catch (e) {
            if (mounted) {
              setState(() {
                _isUploadingImage = false;
                _isSubmitting = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Image upload failed: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }

    if (isEditing) {
      // Update existing submission
      final updatedSubmission = widget.submission!.copyWith(
        content: _contentController.text.trim(),
        imageAttachments: _imageAttachments.isEmpty ? null : _imageAttachments,
        submittedAt: DateTime.now(),
        isLate: isLate,
        status: asDraft ? SubmissionStatus.draft : SubmissionStatus.submitted, // Mark as draft or submitted
      );

      final success = await assignmentProvider.updateSubmission(updatedSubmission);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(asDraft ? 'Draft saved successfully!' : 'Assignment handed in successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(assignmentProvider.error ?? (asDraft ? 'Failed to save draft' : 'Failed to hand in assignment')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Create new submission
      final submission = SubmissionModel(
        id: '', // Will be generated by the database
        assignmentId: widget.assignment.id,
        studentId: currentUser.id,
        studentName: currentUser.name,
        content: _contentController.text.trim(),
        imageAttachments: _imageAttachments.isEmpty ? null : _imageAttachments,
        submittedAt: DateTime.now(),
        status: asDraft ? SubmissionStatus.draft : SubmissionStatus.submitted,
        isLate: isLate,
      );

      final success = await assignmentProvider.submitAssignment(submission);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(asDraft ? 'Draft saved successfully!' : 'Assignment handed in successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(assignmentProvider.error ?? (asDraft ? 'Failed to save draft' : 'Failed to hand in assignment')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _addImage() async {
    final theme = Theme.of(context);
    
    // Check if image picker is supported
    if (!_storageService.isImagePickerSupported()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image picker is not supported on this platform.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Add Image',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.photo_library, size: 20),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _takePhotoWithCamera();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt, size: 20),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Make sure you have granted camera and storage permissions.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final imageFile = await _storageService.pickImageFromGallery();
      if (imageFile != null) {
        _addLocalPreview(imageFile);
      }
    } catch (e) {
      if (mounted) {
        // Show a more user-friendly error message
        String errorMessage = 'Failed to pick image from gallery.';
        
        if (e.toString().contains('_namespace')) {
          errorMessage = 'Image picker not available on this platform. Please try using the camera instead.';
        } else if (e.toString().contains('permission')) {
          errorMessage = 'Permission denied. Please grant storage permissions in your device settings.';
        } else if (e.toString().contains('not supported')) {
          errorMessage = 'Gallery access is not supported on this platform. Please use camera instead.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Try Camera',
              onPressed: () => _takePhotoWithCamera(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _takePhotoWithCamera() async {
    try {
      final imageFile = await _storageService.takePhotoWithCamera();
      if (imageFile != null) {
        _addLocalPreview(imageFile);
      }
    } catch (e) {
      if (mounted) {
        // Show a more user-friendly error message
        String errorMessage = 'Failed to take photo.';
        
        if (e.toString().contains('_namespace')) {
          errorMessage = 'Camera not available on this platform.';
        } else if (e.toString().contains('permission')) {
          errorMessage = 'Camera permission denied. Please grant camera permission in your device settings.';
        } else if (e.toString().contains('not supported')) {
          errorMessage = 'Camera is not supported on this platform.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Try Gallery',
              onPressed: () => _pickImageFromGallery(),
            ),
          ),
        );
      }
    }
  }

  void _addLocalPreview(File imageFile) {
    // Validate image file
    if (!_storageService.isValidImageFile(imageFile)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid image file. Please select a valid image under 10MB.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final imageAttachment = ImageAttachmentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: '',
      fileName: '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}',
      originalName: imageFile.path.split('/').last,
      sizeInMB: _storageService.getImageSizeInMB(imageFile),
      uploadedAt: DateTime.now(),
      submissionId: '',
      previewPath: imageFile.path,
      isUploaded: false,
    );

    setState(() {
      _imageAttachments.add(imageAttachment);
    });
  }

  Future<void> _removeImage(int index) async {
    try {
      final imageAttachment = _imageAttachments[index];
      
      // Delete from Supabase storage
      if (imageAttachment.url.isNotEmpty) {
        await _storageService.deleteImage(imageAttachment.url);
      }
      
      setState(() {
        _imageAttachments.removeAt(index);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image removed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _unsubmitAssignment() async {
    if (widget.submission == null) return;

    final assignmentProvider = context.read<AssignmentProvider>();

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Unsubmit Assignment'),
        content: const Text(
          'Are you sure you want to unsubmit this assignment? '
          'You can edit it and submit again before the due date.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unsubmit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSubmitting = true;
    });

    final success = await assignmentProvider.unsubmitSubmission(widget.submission!.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment unsubmitted successfully! You can now edit and resubmit.'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(assignmentProvider.error ?? 'Failed to unsubmit assignment'),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Use the assignment with class details if available, otherwise use the original assignment
    final assignment = _assignmentWithClassDetails ?? widget.assignment;
    
    // Get the class theme color from the assignment's class details
    final classThemeColor = assignment.classDetails?.themeColor;
    _primaryColor = classThemeColor != null 
        ? ColorUtils.hexToColor(classThemeColor)
        : colorScheme.primary;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          isEditing 
              ? (isSubmitted ? 'View Submission' : (isDraft ? 'Edit Draft' : 'Edit Submission'))
              : 'Submit Assignment',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<AssignmentProvider>(
        builder: (context, assignmentProvider, child) {
          return Form(
            key: _formKey,
            child: CustomScrollView(
              slivers: [
                if (_isUploadingImage || assignmentProvider.isLoading || _isSubmitting)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: LinearProgressIndicator(
                        backgroundColor: colorScheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(_primaryColor!),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Assignment Details Card
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _primaryColor!.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.assignment,
                                      color: _primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      assignment.title,
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                assignment.description,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceVariant.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.schedule_outlined,
                                            size: 18,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Due Date',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: colorScheme.onSurfaceVariant,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                '${assignment.dueDate.day}/${assignment.dueDate.month}/${assignment.dueDate.year}',
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: colorScheme.outline.withOpacity(0.3),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.grade_outlined,
                                            size: 18,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Points',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: colorScheme.onSurfaceVariant,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                '${assignment.totalPoints} pts',
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isEditing) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSubmitted 
                                        ? Colors.green.withOpacity(0.1)
                                        : _primaryColor!.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSubmitted 
                                          ? Colors.green.withOpacity(0.3)
                                          : _primaryColor!.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isSubmitted ? Icons.check_circle : Icons.edit,
                                        size: 16,
                                        color: isSubmitted ? Colors.green : _primaryColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isSubmitted ? 'Submitted' : 'Draft',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: isSubmitted ? Colors.green : _primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (isSubmitted && widget.submission!.isLate) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.warning_amber,
                                                size: 12,
                                                color: Colors.red,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Late',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Grade & Feedback Card (if graded)
                      if (isEditing && widget.submission?.isGraded == true) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.grade,
                                        color: colorScheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Grade & Feedback',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 24,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Grade: ${widget.submission!.grade}/${widget.assignment.totalPoints}',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (widget.submission!.hasFeedback) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    'Feedback',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceVariant.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      widget.submission!.feedback!,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      // Submission Content Card
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _primaryColor!.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.edit_note,
                                      color: _primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Your Submission',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (!isEditable) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceVariant,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Read Only',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _contentController,
                                decoration: InputDecoration(
                                  labelText: 'Submission Content',
                                  hintText: 'Write your submission here...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: colorScheme.outline.withOpacity(0.3),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: colorScheme.outline.withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: _primaryColor!,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                                ),
                                maxLines: 8,
                                readOnly: !isEditable,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your submission content';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Image Attachments Card
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _primaryColor!.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.image,
                                      color: _primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Images',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_isUploadingImage)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  else ...[
                                    if (isEditing && _imageAttachments.isNotEmpty)
                                      IconButton(
                                        onPressed: _refreshImageUrls,
                                        icon: Icon(Icons.refresh, color: _primaryColor),
                                        tooltip: 'Refresh images',
                                      ),
                                    if (isEditable)
                                      FilledButton.icon(
                                        onPressed: _addImage,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: _primaryColor,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        icon: const Icon(Icons.add_photo_alternate, size: 18),
                                        label: const Text('Add'),
                                      ),
                                  ],
                                ],
                              ),
                              if (_imageAttachments.isNotEmpty) ...[
                                if (_isUploadingImage && isEditing) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Refreshing images...',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 16),
                                ImageAttachmentGrid(
                                  key: ValueKey(_imageAttachments.map((img) => img.url).join('|')),
                                  attachments: _imageAttachments,
                                  onDelete: (index) => _removeImage(index),
                                  showDeleteButton: isEditable,
                                ),
                              ] else ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceVariant.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: colorScheme.outline.withOpacity(0.2),
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.image_outlined,
                                        size: 48,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No images added',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Add images to support your submission',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Action Buttons
                      if (isEditing && isSubmitted && canUnsubmit) ...[
                        // Unsubmit button for submitted assignments that can be unsubmitted
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: (assignmentProvider.isLoading || _isUploadingImage || _isSubmitting) ? null : _unsubmitAssignment,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.undo),
                            label: (assignmentProvider.isLoading || _isUploadingImage || _isSubmitting)
                                ? const Text('Unsubmitting...')
                                : const Text('Unsubmit Assignment'),
                          ),
                        ),
                      ] else if (isEditing && (isSubmitted || widget.submission?.isGraded == true)) ...[
                        // No buttons for submitted or graded submissions (read-only view)
                        const SizedBox.shrink(),
                      ] else ...[
                        // Submit button for new submissions or draft submissions
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton.icon(
                            onPressed: (assignmentProvider.isLoading || _isUploadingImage || _isSubmitting) ? null : () => _submitAssignment(),
                            style: FilledButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            icon: (assignmentProvider.isLoading || _isUploadingImage || _isSubmitting)
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.send),
                            label: (assignmentProvider.isLoading || _isUploadingImage || _isSubmitting)
                                ? const Text('Submitting...')
                                : Text(isEditing ? 'Hand in Assignment' : 'Submit Assignment'),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
