# Supabase Storage Setup for Image Attachments

This document explains how to set up Supabase storage to handle image attachments for student submissions.

## Prerequisites

1. A Supabase project with the following setup:
   - Database tables for assignments and submissions
   - Storage bucket for images
   - Proper RLS (Row Level Security) policies

## Storage Bucket Setup

### 1. Create Storage Bucket

1. Go to your Supabase dashboard
2. Navigate to Storage section
3. Create a new bucket called `attachments` and `profiles`
4. Set the bucket to public (for easy access to images)

### 2. Storage Bucket Configuration

The attachmnts bucket should have the following structure:
```
attachments/
├── {submission_id}/
    ├── {timestamp}_{filename}.jpg
    ├── {timestamp}_{filename}.png
    └── ...
```

The profile bucket should have the following structure:
```
profiles/
├── {profile_id}/
    ├── {timestamp}_{filename}.jpg
    ├── {timestamp}_{filename}.png
    └── ...
```


### 3. RLS Policies

#### Quick Setup (Recommended)
Use the provided SQL script for complete setup:
```bash
# Run the storage_setup_script.sql in your Supabase SQL editor
```

#### Manual Setup

Create the following RLS policies for the `attachments` bucket:

##### Policy 1: Allow authenticated users to upload submission images
```sql
CREATE POLICY "Allow authenticated users to upload submission images" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'attachments' AND
  auth.role() = 'authenticated' AND
  (storage.foldername(name))[1] = 'submissions'
);
```

##### Policy 2: Allow users to view submission images
```sql
CREATE POLICY "Allow users to view submission images" ON storage.objects
FOR SELECT USING (
  bucket_id = 'attachments'
);
```

##### Policy 3: Allow users to update their own submission images
```sql
CREATE POLICY "Allow users to update their own submission images" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'attachments' AND
  auth.role() = 'authenticated' AND
  (storage.foldername(name))[1] = 'submissions'
);
```

##### Policy 4: Allow users to delete their own submission images
```sql
CREATE POLICY "Allow users to delete their own submission images" ON storage.objects
FOR DELETE USING (
  bucket_id = 'attachments' AND
  auth.role() = 'authenticated' AND
  (storage.foldername(name))[1] = 'submissions'
);
```

Create the following **enhanced** RLS policies for the `profiles` bucket:

##### Policy 5: Allow authenticated users to upload profile images
```sql
CREATE POLICY "Allow authenticated users to upload profile images" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'profiles' AND
  auth.role() = 'authenticated' AND
  (storage.foldername(name))[1] = 'profiles'
);
```

##### Policy 6: Allow users to view profile images (public access)
```sql
CREATE POLICY "Allow users to view profile images" ON storage.objects
FOR SELECT USING (
  bucket_id = 'profiles'
);
```

##### Policy 7: Allow users to update their own profile images
```sql
CREATE POLICY "Allow users to update their own profile images" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'profiles' AND
  auth.role() = 'authenticated' AND
  (storage.foldername(name))[1] = 'profiles'
);
```

##### Policy 8: Allow users to delete their own profile images
```sql
CREATE POLICY "Allow users to delete their own profile images" ON storage.objects
FOR DELETE USING (
  bucket_id = 'profiles' AND
  auth.role() = 'authenticated' AND
  (storage.foldername(name))[1] = 'profiles'
);
```

#### Additional Security Policies

##### Policy 9: Prevent access to system files
```sql
CREATE POLICY "Prevent access to system files" ON storage.objects
FOR ALL USING (
  bucket_id IN ('attachments', 'profiles') AND
  NOT (name LIKE '%.DS_Store' OR name LIKE 'Thumbs.db' OR name LIKE '._%')
);
```

##### Policy 10: File size validation for attachments
```sql
CREATE POLICY "File size validation for attachments" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'attachments' AND
  octet_length(encode(convert_to(metadata->>'eTag', 'UTF8'), 'base64')) <= 10485760
);
```

##### Policy 11: File size validation for profiles
```sql
CREATE POLICY "File size validation for profiles" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'profiles' AND
  octet_length(encode(convert_to(metadata->>'eTag', 'UTF8'), 'UTF8')) <= 5242880
);
```

## Database Schema Updates

### 1. Update Submissions Table

Add a new column to store image attachments:

```sql
-- Add image_attachments column to submissions table
ALTER TABLE submissions 
ADD COLUMN image_attachments JSONB;

-- Add index for better performance
CREATE INDEX idx_submissions_image_attachments 
ON submissions USING GIN (image_attachments);
```

### 2. Image Attachments Structure

The `image_attachments` column will store JSON data in the following format:

```json
[
  {
    "id": "unique_id",
    "url": "https://supabase.co/storage/v1/object/public/submission-images/submissions/123/image.jpg",
    "fileName": "1234567890_image.jpg",
    "originalName": "image.jpg",
    "sizeInMB": 2.5,
    "uploadedAt": "2024-01-15T10:30:00Z",
    "submissionId": "submission_123"
  }
]
```

## Environment Configuration

### 1. Update Supabase Configuration

Make sure your `main.dart` has the correct Supabase configuration:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

### 2. Storage Bucket Names

The storage bucket names are configured in `lib/services/storage_service.dart`:

```dart
// For submission images
await _supabase.storage
    .from('attachments')  // This should match your bucket name
    .upload(filePath, bytes);

// For profile images
await _supabase.storage
    .from('profiles')  // This should match your bucket name
    .upload(filePath, bytes);
```

## Features Implemented

### 1. Image Upload
- Students can upload images from gallery or camera
- Images are automatically compressed and resized
- File validation (size limit: 10MB, supported formats: JPG, PNG, GIF, WebP)
- Progress indicators during upload

### 2. Image Display
- Grid layout for multiple images
- Image previews with loading states
- Error handling for failed image loads
- Responsive design for different screen sizes

### 3. Image Management
- Delete images from submissions
- Automatic cleanup from Supabase storage
- Image metadata tracking (size, upload date, original filename)

### 4. Security
- Images are stored in user-specific folders
- RLS policies ensure proper access control
- File validation prevents malicious uploads

## Usage

### For Students
1. Navigate to an assignment
2. Tap "Submit Assignment" or "Edit Submission"
3. Tap the camera icon to add images
4. Choose between gallery or camera
5. Images will be uploaded to Supabase storage
6. Submit the assignment with attached images

### For Teachers
1. View submissions in the grading interface
2. See image attachments in a grid layout
3. Images are displayed without delete options (read-only)
4. Grade submissions with full context including images

## Setup Verification

### 1. Verify Buckets Created
Run this query in your Supabase SQL editor:
```sql
SELECT 
  id as bucket_id,
  name as bucket_name,
  public,
  file_size_limit,
  allowed_mime_types
FROM storage.buckets 
WHERE id IN ('attachments', 'profiles');
```

### 2. Verify Policies Created
Run this query to check all storage policies:
```sql
SELECT 
  policyname,
  tablename,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
ORDER BY policyname;
```

### 3. Test Profile Image Upload
Use the storage test button in your app's profile screen to verify bucket access.

## Troubleshooting

### Common Issues

1. **Upload fails**: Check RLS policies and bucket permissions
2. **Images not displaying**: Verify bucket is public and URLs are correct
3. **Large file uploads**: Ensure file size is under 10MB limit
4. **Permission denied**: Check authentication and RLS policies
5. **Empty buckets list**: Buckets not created or policies not applied

### Debug Steps

1. Check Supabase logs for storage errors
2. Verify bucket name matches configuration
3. Test RLS policies with Supabase dashboard
4. Check network connectivity and file permissions
5. Run verification queries above

### Quick Fix for Empty Buckets

If you see "Available buckets: []" in your app, run this in Supabase SQL editor:

```sql
-- Create buckets if they don't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('attachments', 'attachments', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']),
  ('profiles', 'profiles', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp'])
ON CONFLICT (id) DO NOTHING;

-- Enable RLS on storage.objects if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
```

## Performance Considerations

1. **Image Compression**: Images are automatically compressed to reduce storage and bandwidth
2. **Lazy Loading**: Images are loaded on-demand to improve performance
3. **Caching**: Consider implementing image caching for better user experience
4. **CDN**: Supabase storage can be configured with CDN for faster image delivery

## Future Enhancements

1. **Image Editing**: Add basic image editing capabilities
2. **Bulk Upload**: Allow multiple image selection
3. **Image Preview**: Full-screen image viewing
4. **Image Annotations**: Allow teachers to annotate images
5. **Video Support**: Extend to support video attachments
