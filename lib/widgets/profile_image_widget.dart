import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/storage_service.dart';

class ProfileImageWidget extends StatefulWidget {
  final String? imageUrl;
  final String? name;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final bool showBorder;
  final Color? borderColor;
  final double? borderWidth;

  const ProfileImageWidget({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 50,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth,
  });

  @override
  State<ProfileImageWidget> createState() => _ProfileImageWidgetState();
}

class _ProfileImageWidgetState extends State<ProfileImageWidget> {
  String? _processedImageUrl;
  bool _isLoadingUrl = false;

  @override
  void initState() {
    super.initState();
    _processImageUrl();
  }

  @override
  void didUpdateWidget(ProfileImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _processImageUrl();
    }
  }

  Future<void> _processImageUrl() async {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      setState(() {
        _processedImageUrl = null;
        _isLoadingUrl = false;
      });
      return;
    }

    // Check if it's a local file path
    if (widget.imageUrl!.startsWith('/') || widget.imageUrl!.contains('file://')) {
      setState(() {
        _processedImageUrl = widget.imageUrl;
        _isLoadingUrl = false;
      });
      return;
    }

    // Check if it's a network URL
    if (widget.imageUrl!.startsWith('http://') || widget.imageUrl!.startsWith('https://')) {
      setState(() {
        _isLoadingUrl = true;
      });

             try {
         // For Supabase URLs, try to get a fresh signed URL
         if (widget.imageUrl!.contains('supabase.co') || widget.imageUrl!.contains('storage.googleapis.com')) {
           print('ProfileImageWidget: Processing Supabase URL: ${widget.imageUrl}');
           final storageService = StorageService();
           final signedUrl = await storageService.getSignedUrlForProfileImage(widget.imageUrl!);
           print('ProfileImageWidget: Got signed URL: $signedUrl');
           
           if (mounted) {
             setState(() {
               _processedImageUrl = signedUrl;
               _isLoadingUrl = false;
             });
           }
         } else {
           // For other network URLs, use as-is
           setState(() {
             _processedImageUrl = widget.imageUrl;
             _isLoadingUrl = false;
           });
         }
       } catch (e) {
         print('ProfileImageWidget: Error processing URL: $e');
         if (mounted) {
           setState(() {
             _processedImageUrl = null; // Don't use original URL if it's causing issues
             _isLoadingUrl = false;
           });
         }
       }
    } else {
      // Invalid URL format
      print('ProfileImageWidget: Invalid URL format: ${widget.imageUrl}');
      setState(() {
        _processedImageUrl = null;
        _isLoadingUrl = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = widget.backgroundColor ?? Colors.white;
    final effectiveTextColor = widget.textColor ?? const Color(0xFF4285F4);
    final effectiveFontSize = widget.fontSize ?? (widget.radius * 0.6);
    final effectiveBorderColor = widget.borderColor ?? const Color(0xFF4285F4);
    final effectiveBorderWidth = widget.borderWidth ?? 2.0;

    return Container(
      decoration: widget.showBorder
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: effectiveBorderColor,
                width: effectiveBorderWidth,
              ),
            )
          : null,
      child: CircleAvatar(
        radius: widget.radius,
        backgroundColor: effectiveBackgroundColor,
        child: _buildImageWidget(effectiveTextColor, effectiveFontSize),
      ),
    );
  }

  Widget _buildImageWidget(Color textColor, double fontSize) {
    if (_isLoadingUrl) {
      return Container(
        width: widget.radius * 2,
        height: widget.radius * 2,
        color: Colors.grey[200],
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
          ),
        ),
      );
    }

    if (_processedImageUrl == null || _processedImageUrl!.isEmpty) {
      return _buildFallbackWidget(textColor, fontSize);
    }

    // Check if it's a local file path
    if (_processedImageUrl!.startsWith('/') || _processedImageUrl!.contains('file://')) {
      print('ProfileImageWidget: Loading local file: $_processedImageUrl');
      return ClipOval(
        child: Image.file(
          File(_processedImageUrl!),
          width: widget.radius * 2,
          height: widget.radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('ProfileImageWidget: Local file error: $error');
            return _buildFallbackWidget(textColor, fontSize);
          },
        ),
      );
    }

    // Check if it's a network URL
    if (_processedImageUrl!.startsWith('http://') || _processedImageUrl!.startsWith('https://')) {
      print('ProfileImageWidget: Loading network image: $_processedImageUrl');
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: _processedImageUrl!,
          width: widget.radius * 2,
          height: widget.radius * 2,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: widget.radius * 2,
            height: widget.radius * 2,
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
              ),
            ),
          ),
          errorWidget: (context, url, error) {
            print('ProfileImageWidget: Network image error for URL: $url');
            print('ProfileImageWidget: Error: $error');
            return _buildFallbackWidget(textColor, fontSize);
          },
          httpHeaders: {
            // Add any required headers for Supabase storage
            'User-Agent': 'FlowScore/1.0',
          },
        ),
      );
    }

    // Invalid URL format, show fallback
    print('ProfileImageWidget: Invalid URL format: $_processedImageUrl');
    return _buildFallbackWidget(textColor, fontSize);
  }

  Widget _buildFallbackWidget(Color textColor, double fontSize) {
    // Show fallback with user's initial
    String displayText = 'U';
    if (widget.name != null && widget.name!.isNotEmpty) {
      displayText = widget.name![0].toUpperCase();
    }

    return Container(
      width: widget.radius * 2,
      height: widget.radius * 2,
      decoration: BoxDecoration(
        color: const Color(0xFF4285F4).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          displayText,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
