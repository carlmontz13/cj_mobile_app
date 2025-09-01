# Image Upload Troubleshooting Guide

This guide helps resolve common issues with image upload functionality in the FlowScore app.

## Common Error: "unsupported operation: _namespace"

### What This Error Means
The `_namespace` error typically occurs when:
1. The platform doesn't support the image picker functionality
2. Required permissions are not granted
3. The image_picker plugin is not properly configured
4. Running on an unsupported platform (like web without proper setup)

### Solutions

#### 1. **Check Platform Support**
- **Android**: ✅ Fully supported
- **iOS**: ✅ Fully supported  
- **Web**: ⚠️ Limited support (may need additional setup)
- **Windows/macOS/Linux**: ⚠️ Limited support

#### 2. **Grant Permissions**

**Android:**
1. Go to Settings → Apps → FlowScore V1 → Permissions
2. Enable:
   - Camera
   - Storage
   - Photos and videos

**iOS:**
1. Go to Settings → Privacy & Security → Camera
2. Enable FlowScore V1
3. Go to Settings → Privacy & Security → Photos
4. Enable FlowScore V1

#### 3. **Restart the App**
After granting permissions, completely close and restart the app.

#### 4. **Try Alternative Methods**
If gallery doesn't work, try:
- Using the camera instead
- Restarting the device
- Reinstalling the app

## Other Common Issues

### "Permission denied"
**Solution:**
1. Check device settings for app permissions
2. Grant camera and storage permissions
3. Restart the app

### "Camera not available"
**Solution:**
1. Check if device has a camera
2. Ensure no other app is using the camera
3. Try using gallery instead

### "File too large"
**Solution:**
- Images must be under 10MB
- Try compressing the image before uploading
- Use a lower resolution image

### "Invalid file format"
**Solution:**
- Supported formats: JPG, JPEG, PNG, GIF, WebP
- Convert your image to a supported format

## Platform-Specific Solutions

### Android
1. **Check Android Manifest**: Ensure permissions are properly declared
2. **Runtime Permissions**: Grant permissions when prompted
3. **Storage Access**: Enable "Allow management of all files" if needed

### iOS
1. **Privacy Settings**: Enable camera and photo library access
2. **Simulator Issues**: Camera may not work in iOS Simulator, use a real device
3. **iOS Version**: Ensure iOS 11.0 or later

### Web
1. **Browser Support**: Use Chrome, Firefox, or Safari
2. **HTTPS Required**: Must be served over HTTPS for camera access
3. **User Interaction**: Must be triggered by user action (click/tap)

## Debug Steps

### 1. Check Platform
```dart
import 'package:flutter/foundation.dart';

if (kIsWeb) {
  print('Running on web - limited image picker support');
} else if (Platform.isAndroid) {
  print('Running on Android - full support');
} else if (Platform.isIOS) {
  print('Running on iOS - full support');
}
```

### 2. Test Image Picker
Try this simple test:
```dart
import 'package:image_picker/image_picker.dart';

final picker = ImagePicker();
try {
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  if (image != null) {
    print('Image picked successfully: ${image.path}');
  }
} catch (e) {
  print('Error picking image: $e');
}
```

### 3. Check Permissions
- Android: Check `android/app/src/main/AndroidManifest.xml`
- iOS: Check `ios/Runner/Info.plist`

## Alternative Solutions

### If Image Picker Fails Completely

1. **Use File Picker Instead**
   ```dart
   import 'package:file_picker/file_picker.dart';
   
   FilePickerResult? result = await FilePicker.platform.pickFiles(
     type: FileType.image,
   );
   ```

2. **Manual File Selection**
   - Allow users to manually select files from their device
   - Provide clear instructions for supported formats

3. **Web Alternative**
   - Use HTML file input for web platforms
   - Implement drag-and-drop functionality

## Prevention

### Best Practices
1. **Always check platform support** before using image picker
2. **Handle errors gracefully** with user-friendly messages
3. **Provide fallback options** when image picker fails
4. **Test on multiple devices** and platforms
5. **Request permissions early** in the app lifecycle

### Code Example
```dart
Future<void> pickImage() async {
  try {
    if (!_storageService.isImagePickerSupported()) {
      throw Exception('Image picker not supported on this platform');
    }
    
    final imageFile = await _storageService.pickImageFromGallery();
    if (imageFile != null) {
      await uploadImage(imageFile);
    }
  } catch (e) {
    showErrorDialog('Failed to pick image: ${e.toString()}');
  }
}
```

## Getting Help

If you're still experiencing issues:

1. **Check the console logs** for detailed error messages
2. **Test on a different device** to isolate platform-specific issues
3. **Verify Supabase storage** is properly configured
4. **Check network connectivity** for upload issues
5. **Review the SUPABASE_STORAGE_SETUP.md** file for storage configuration

## Common Error Messages and Solutions

| Error Message | Solution |
|---------------|----------|
| `unsupported operation: _namespace` | Check platform support, grant permissions |
| `Permission denied` | Enable camera/storage permissions in device settings |
| `Camera not available` | Use gallery instead, check device camera |
| `File too large` | Compress image to under 10MB |
| `Invalid format` | Convert to JPG, PNG, GIF, or WebP |
| `Upload failed` | Check network connection and Supabase configuration |
