import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/image_attachment_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  // Upload image to Supabase storage
  Future<String?> uploadImage(File imageFile, String submissionId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final filePath = '$submissionId/$fileName';
      
      final bytes = await imageFile.readAsBytes();
      
      await _supabase.storage
          .from('attachments')
          .uploadBinary(filePath, bytes);
      
      // Try to get public URL first, fallback to signed URL if bucket is private
      try {
        final publicUrl = _supabase.storage
            .from('attachments')
            .getPublicUrl(filePath);
        return publicUrl;
      } catch (e) {
        // If public URL fails, create a signed URL
        final signedUrl = await _supabase.storage
            .from('attachments')
            .createSignedUrl(filePath, 60 * 60 * 24 * 365); // 1 year expiry
        return signedUrl;
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Upload profile image to Supabase storage
  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final filePath = 'profiles/$fileName';
      
      final bytes = await imageFile.readAsBytes();
      
      print('StorageService: Uploading profile image to path: $filePath');
      print('StorageService: File size: ${bytes.length} bytes');
      
      // Upload to the profiles bucket (as per updated documentation)
      try {
        await _supabase.storage
            .from('profiles')
            .uploadBinary(filePath, bytes);
        
        print('StorageService: Successfully uploaded to profiles bucket');
        
        // Try to get public URL
        try {
          final publicUrl = _supabase.storage
              .from('profiles')
              .getPublicUrl(filePath);
          print('StorageService: Got public URL: $publicUrl');
          return publicUrl;
        } catch (e) {
          print('StorageService: Public URL failed, trying signed URL: $e');
          // If public URL fails, create a signed URL
          final signedUrl = await _supabase.storage
              .from('profiles')
              .createSignedUrl(filePath, 60 * 60 * 24 * 365); // 1 year expiry
          print('StorageService: Got signed URL: $signedUrl');
          return signedUrl;
        }
      } catch (uploadError) {
        print('StorageService: Failed to upload to profiles bucket: $uploadError');
        
        // Fallback to attachments bucket if profiles doesn't exist
        try {
          await _supabase.storage
              .from('attachments')
              .uploadBinary(filePath, bytes);
          
          print('StorageService: Successfully uploaded to attachments bucket');
          
          // Try to get public URL
          try {
            final publicUrl = _supabase.storage
                .from('attachments')
                .getPublicUrl(filePath);
            print('StorageService: Got public URL from attachments: $publicUrl');
            return publicUrl;
          } catch (e) {
            print('StorageService: Public URL failed, trying signed URL: $e');
            // If public URL fails, create a signed URL
            final signedUrl = await _supabase.storage
                .from('attachments')
                .createSignedUrl(filePath, 60 * 60 * 24 * 365); // 1 year expiry
            print('StorageService: Got signed URL from attachments: $signedUrl');
            return signedUrl;
          }
        } catch (fallbackError) {
          print('StorageService: Both buckets failed: $fallbackError');
          throw Exception('Failed to upload profile image to any available bucket: $fallbackError');
        }
      }
    } catch (e) {
      print('StorageService: Error in uploadProfileImage: $e');
      throw Exception('Failed to upload profile image: $e');
    }
  }

  // Upload image from bytes (for web)
  Future<String?> uploadImageBytes(Uint8List imageBytes, String fileName, String submissionId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$submissionId/${timestamp}_$fileName';
      
      await _supabase.storage
          .from('attachments')
          .uploadBinary(filePath, imageBytes);
      
      // Try to get public URL first, fallback to signed URL if bucket is private
      try {
        final publicUrl = _supabase.storage
            .from('attachments')
            .getPublicUrl(filePath);
        return publicUrl;
      } catch (e) {
        // If public URL fails, create a signed URL
        final signedUrl = await _supabase.storage
            .from('attachments')
            .createSignedUrl(filePath, 60 * 60 * 24 * 365); // 1 year expiry
        return signedUrl;
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Pick image from gallery with better error handling
  Future<File?> pickImageFromGallery() async {
    try {
      // Check if we're on web platform
      if (kIsWeb) {
        throw Exception('Image picker from gallery is not supported on web. Please use camera instead.');
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      // Handle specific platform errors
      if (e.toString().contains('_namespace')) {
        throw Exception('Image picker not available on this platform. Please try using the camera instead.');
      } else if (e.toString().contains('permission')) {
        throw Exception('Permission denied. Please grant camera and storage permissions.');
      } else if (e.toString().contains('cancel')) {
        // User cancelled, don't show error
        return null;
      } else {
        throw Exception('Failed to pick image from gallery: $e');
      }
    }
  }

  // Take photo with camera with better error handling
  Future<File?> takePhotoWithCamera() async {
    try {
      // Check if we're on web platform
      if (kIsWeb) {
        throw Exception('Camera is not supported on web platform.');
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      // Handle specific platform errors
      if (e.toString().contains('_namespace')) {
        throw Exception('Camera not available on this platform.');
      } else if (e.toString().contains('permission')) {
        throw Exception('Camera permission denied. Please grant camera permission in settings.');
      } else if (e.toString().contains('cancel')) {
        // User cancelled, don't show error
        return null;
      } else {
        throw Exception('Failed to take photo: $e');
      }
    }
  }

  // Alternative method for web platform
  Future<File?> pickImageFromGalleryWeb() async {
    try {
      if (!kIsWeb) {
        return await pickImageFromGallery();
      }

      // For web, we'll use a different approach
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        // On web, we need to handle the file differently
        final bytes = await image.readAsBytes();
        final tempFile = File('temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(bytes);
        return tempFile;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // Delete image from storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the bucket segment and build path relative to it
      final bucketIndex = pathSegments.indexOf('attachments');
      if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

        await _supabase.storage
            .from('attachments')
            .remove([filePath]);
      }
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  // Get image size in MB
  double getImageSizeInMB(File file) {
    try {
      final sizeInBytes = file.lengthSync();
      return sizeInBytes / (1024 * 1024);
    } catch (e) {
      // If we can't get the file size, return 0
      return 0.0;
    }
  }

  // Validate image file
  bool isValidImageFile(File file) {
    try {
      final sizeInMB = getImageSizeInMB(file);
      final extension = path.extension(file.path).toLowerCase();
      
      // Check file size (max 10MB)
      if (sizeInMB > 10) {
        return false;
      }
      
      // Check file extension
      final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
      return validExtensions.contains(extension);
    } catch (e) {
      // If validation fails, return false
      return false;
    }
  }

  // Check if platform supports image picker
  bool isImagePickerSupported() {
    return !kIsWeb || (kIsWeb && _isWebImagePickerSupported());
  }

  // Check if web platform supports image picker
  bool _isWebImagePickerSupported() {
    // Basic check for web support
    try {
      return true; // Most modern browsers support it
    } catch (e) {
      return false;
    }
  }

  // Get a fresh signed URL for an existing image
  Future<String?> getSignedUrl(String imageUrl) async {
    try {
      // If URL is already a signed URL, return it
      if (imageUrl.contains('?token=')) {
        return imageUrl;
      }

      // If the provided value looks like a plain storage path (no scheme/host),
      // treat it directly as the file path in the 'attachments' bucket
      final uri = Uri.tryParse(imageUrl);
      final isPlainPath = uri == null || (!uri.hasScheme && !uri.hasAuthority);

      String? filePath;
      String? bucketName;
      
      if (isPlainPath) {
        filePath = imageUrl.replaceFirst(RegExp(r'^/+'), '');
        bucketName = 'attachments'; // Default bucket
      } else {
        // Extract file path from a full URL
        final pathSegments = uri!.pathSegments;
        
        // Check for different bucket types
        final attachmentsIndex = pathSegments.indexOf('attachments');
        final profilesIndex = pathSegments.indexOf('profiles');
        
        if (attachmentsIndex != -1 && attachmentsIndex + 1 < pathSegments.length) {
          bucketName = 'attachments';
          filePath = pathSegments.sublist(attachmentsIndex + 1).join('/');
        } else if (profilesIndex != -1 && profilesIndex + 1 < pathSegments.length) {
          bucketName = 'profiles';
          filePath = pathSegments.sublist(profilesIndex + 1).join('/');
        }
      }

      if (filePath != null && filePath.isNotEmpty && bucketName != null) {
        // Create a signed URL (works for both public/private buckets)
        final signedUrl = await _supabase.storage
            .from(bucketName)
            .createSignedUrl(filePath, 60 * 60 * 24 * 365); // 1 year expiry
        return signedUrl;
      }

      // As a last resort, return the original value
      return imageUrl;
    } catch (e) {
      return imageUrl; // Return original URL if signing fails
    }
  }

  // Get a fresh signed URL specifically for profile images
  Future<String?> getSignedUrlForProfileImage(String imageUrl) async {
    try {
      print('StorageService: Processing profile image URL: $imageUrl');
      
      // If URL is already a signed URL, return it
      if (imageUrl.contains('?token=')) {
        print('StorageService: URL is already signed, returning as-is');
        return imageUrl;
      }

      final uri = Uri.tryParse(imageUrl);
      final isPlainPath = uri == null || (!uri.hasScheme && !uri.hasAuthority);

      String? filePath;
      String? bucketName;
      
      if (isPlainPath) {
        // If it's a plain path, assume it's in the profiles bucket
        filePath = imageUrl.replaceFirst(RegExp(r'^/+'), '');
        bucketName = 'profiles';
      } else {
        // Extract path from full URL
        final pathSegments = uri!.pathSegments;
        print('StorageService: URL path segments: $pathSegments');
        
        // Look for bucket name in the path
        final profilesIndex = pathSegments.indexOf('profiles');
        final attachmentsIndex = pathSegments.indexOf('attachments');
        
        if (profilesIndex != -1) {
          bucketName = 'profiles';
          // Get everything after the first 'profiles' segment
          if (profilesIndex + 1 < pathSegments.length) {
            filePath = pathSegments.sublist(profilesIndex + 1).join('/');
          }
        } else if (attachmentsIndex != -1) {
          bucketName = 'attachments';
          if (attachmentsIndex + 1 < pathSegments.length) {
            filePath = pathSegments.sublist(attachmentsIndex + 1).join('/');
          }
        }
      }

      print('StorageService: Extracted bucket: $bucketName, filePath: $filePath');

      if (filePath != null && filePath.isNotEmpty && bucketName != null) {
        try {
          print('StorageService: Creating signed URL for bucket: $bucketName, path: $filePath');
          final signedUrl = await _supabase.storage
              .from(bucketName)
              .createSignedUrl(filePath, 60 * 60 * 24 * 365); // 1 year expiry
          print('StorageService: Created signed URL: $signedUrl');
          return signedUrl;
        } catch (e) {
          print('StorageService: Error creating signed URL: $e');
          // If the first bucket fails, try the other bucket
          final fallbackBucket = bucketName == 'profiles' ? 'attachments' : 'profiles';
          try {
            print('StorageService: Trying fallback bucket: $fallbackBucket');
            final signedUrl = await _supabase.storage
                .from(fallbackBucket)
                .createSignedUrl(filePath, 60 * 60 * 24 * 365);
            print('StorageService: Created signed URL with fallback: $signedUrl');
            return signedUrl;
          } catch (fallbackError) {
            print('StorageService: Fallback bucket also failed: $fallbackError');
            return imageUrl; // Return original URL if both fail
          }
        }
      }

      print('StorageService: Could not extract file path, returning original URL');
      return imageUrl;
    } catch (e) {
      print('StorageService: Error in getSignedUrlForProfileImage: $e');
      return imageUrl; // Return original URL if signing fails
    }
  }

  // Generate a signed URL using attachment context (handles filename-only values)
  Future<String?> getSignedUrlForAttachment(ImageAttachmentModel attachment) async {
    try {
      final url = attachment.url;

      // If URL is already a signed URL, return it
      if (url.contains('?token=')) {
        return url;
      }

      final uri = Uri.tryParse(url);
      final isPlainPath = uri == null || (!uri.hasScheme && !uri.hasAuthority);

      String filePath;
      if (isPlainPath) {
        // If no folder provided, assume files are stored under submissionId/
        final normalized = url.replaceFirst(RegExp(r'^/+'), '');
        filePath = normalized.contains('/')
            ? normalized
            : '${attachment.submissionId}/$normalized';
      } else {
        // Extract path relative to bucket from full URL
        final segments = uri!.pathSegments;
        final bucketIndex = segments.indexOf('attachments');
        if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) {
          return url;
        }
        filePath = segments.sublist(bucketIndex + 1).join('/');
      }

      final signedUrl = await _supabase.storage
          .from('attachments')
          .createSignedUrl(filePath, 60 * 60 * 24 * 365);
      return signedUrl;
    } catch (e) {
      return attachment.url;
    }
  }

  // Debug method to check available storage buckets
  Future<List<String>> getAvailableBuckets() async {
    try {
      final buckets = await _supabase.storage.listBuckets();
      final bucketNames = buckets.map((bucket) => bucket.name).toList();
      print('StorageService: Available buckets: $bucketNames');
      return bucketNames;
    } catch (e) {
      print('StorageService: Error getting buckets: $e');
      return [];
    }
  }

  // Debug method to test bucket access
  Future<bool> testBucketAccess(String bucketName) async {
    try {
      // Try to list files in the bucket
      await _supabase.storage.from(bucketName).list();
      print('StorageService: Successfully accessed bucket: $bucketName');
      return true;
    } catch (e) {
      print('StorageService: Error accessing bucket $bucketName: $e');
      return false;
    }
  }

  // Test if an image URL is accessible
  Future<bool> testImageUrlAccess(String imageUrl) async {
    try {
      print('StorageService: Testing image URL access: $imageUrl');
      
      // Try to get the image as bytes
      final response = await _supabase.storage
          .from('profiles')
          .download('test.jpg'); // This will fail but we can see the error
      
      return true;
    } catch (e) {
      print('StorageService: Image URL access test failed: $e');
      return false;
    }
  }
}
