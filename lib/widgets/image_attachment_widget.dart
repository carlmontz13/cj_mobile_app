import 'dart:io';
import 'package:flutter/material.dart';
import '../models/image_attachment_model.dart';
import '../services/storage_service.dart';

class ImageAttachmentWidget extends StatefulWidget {
  final ImageAttachmentModel attachment;
  final VoidCallback? onDelete;
  final bool showDeleteButton;

  const ImageAttachmentWidget({
    super.key,
    required this.attachment,
    this.onDelete,
    this.showDeleteButton = true,
  });

  @override
  State<ImageAttachmentWidget> createState() => _ImageAttachmentWidgetState();
}

class _ImageAttachmentWidgetState extends State<ImageAttachmentWidget> {
  final _storageService = StorageService();
  String? _currentUrl;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(ImageAttachmentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the URL changed, reload the image
    if (oldWidget.attachment.url != widget.attachment.url) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.attachment.previewPath != null && 
        widget.attachment.previewPath!.isNotEmpty && 
        !widget.attachment.isUploaded) {
      // Use local preview path
      setState(() {
        _currentUrl = null;
        _isLoading = false;
        _hasError = false;
      });
      return;
    }

    // Try to get a fresh signed URL if the original URL might be expired
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final freshUrl = await _storageService.getSignedUrlForAttachment(widget.attachment);
      if (mounted) {
        setState(() {
          _currentUrl = freshUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentUrl = widget.attachment.url; // Fallback to original URL
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _retryLoad() async {
    await _loadImage();
  }

  void _openFullImageDialog(BuildContext context) {
    final imageUrl = _currentUrl ?? widget.attachment.url;
    final isLocalPreview = widget.attachment.previewPath != null &&
        widget.attachment.previewPath!.isNotEmpty &&
        !widget.attachment.isUploaded;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: isLocalPreview
                        ? Image.file(
                            File(widget.attachment.previewPath!),
                            fit: BoxFit.contain,
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                          ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Close',
                    color: Colors.white,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageWidget(ThemeData theme, ColorScheme colorScheme) {
    // Show local preview if available
    if (widget.attachment.previewPath != null && 
        widget.attachment.previewPath!.isNotEmpty && 
        !widget.attachment.isUploaded) {
      return Image.file(
        File(widget.attachment.previewPath!),
        fit: BoxFit.cover,
      );
    }

    // Show loading state
    if (_isLoading) {
      return Container(
        color: colorScheme.surfaceVariant,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error state with retry button
    if (_hasError) {
      return Container(
        color: colorScheme.errorContainer,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: colorScheme.error,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Failed to load image',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _retryLoad,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                  minimumSize: const Size(80, 32),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show network image
    final imageUrl = _currentUrl ?? widget.attachment.url;
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: colorScheme.surfaceVariant,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: colorScheme.errorContainer,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: colorScheme.error,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Failed to load image',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _retryLoad,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                    minimumSize: const Size(80, 32),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview
          Flexible(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: GestureDetector(
                onTap: () => _openFullImageDialog(context),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: _buildImageWidget(theme, colorScheme),
                ),
              ),
            ),
          ),
          // Image info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.attachment.originalName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.attachment.sizeInMB.toStringAsFixed(2)} MB • ${_formatDate(widget.attachment.uploadedAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.showDeleteButton && widget.onDelete != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: 'Delete image',
                    color: colorScheme.error,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class ImageAttachmentGrid extends StatelessWidget {
  final List<ImageAttachmentModel> attachments;
  final Function(int)? onDelete;
  final bool showDeleteButton;

  const ImageAttachmentGrid({
    super.key,
    required this.attachments,
    this.onDelete,
    this.showDeleteButton = true,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Images (${attachments.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            // More vertical space to accommodate title/metadata
            childAspectRatio: 0.8,
          ),
          itemCount: attachments.length,
          itemBuilder: (context, index) {
            final attachment = attachments[index];
            return ImageAttachmentWidget(
              attachment: attachment,
              onDelete: onDelete != null ? () => onDelete!(index) : null,
              showDeleteButton: showDeleteButton,
            );
          },
        ),
      ],
    );
  }
}
