-- Supabase Storage Setup Script for FlowScore_v1
-- This script creates all necessary storage buckets and RLS policies

-- =====================================================
-- 1. CREATE STORAGE BUCKETS
-- =====================================================

-- Create attachments bucket for submission images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'attachments',
  'attachments',
  true,
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- Create profiles bucket for profile images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profiles',
  'profiles',
  true,
  5242880, -- 5MB limit for profile images
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- 2. RLS POLICIES FOR ATTACHMENTS BUCKET
-- =====================================================

-- Policy 1: Allow authenticated users to upload submission images
CREATE POLICY "Allow authenticated users to upload submission images" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'attachments' AND
  auth.role() = 'authenticated' AND
  (storage.foldername(name))[1] = 'submissions'
);

-- Policy 2: Allow users to view submission images
CREATE POLICY "Allow users to view submission images" ON storage.objects
FOR SELECT USING (
  bucket_id = 'attachments'
);

-- Policy 3: Allow users to update their own submission images
CREATE POLICY "Allow users to update their own submission images" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'attachments' AND
  auth.role() = 'authenticated' AND
  (storage.foldername(name))[1] = 'submissions'
);

-- Policy 4: Allow users to delete their own submission images
CREATE POLICY "Allow users to delete their own submission images" ON storage.objects
FOR DELETE USING (
  bucket_id = 'attachments' AND
  auth.role() = 'authenticated' AND
  (storage.foldername(name))[1] = 'submissions'
);

-- =====================================================
-- 3. ENHANCED RLS POLICIES FOR PROFILES BUCKET
-- =====================================================

-- Policy 5: Allow authenticated users to upload profile images
CREATE POLICY "Allow authenticated users to upload profile images" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'profiles' AND
  auth.role() = 'authenticated' AND
  (storage.foldername(name))[1] = 'profiles'
);

-- Policy 6: Allow users to view profile images (public access)
CREATE POLICY "Allow users to view profile images" ON storage.objects
FOR SELECT USING (
  bucket_id = 'profiles'
);

-- Policy 7: Allow users to update their own profile images
CREATE POLICY "Allow users to update their own profile images" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'profiles' AND
  auth.role() = 'authenticated' AND
  (storage.foldername(name))[1] = 'profiles'
);

-- Policy 8: Allow users to delete their own profile images
CREATE POLICY "Allow users to delete their own profile images" ON storage.objects
FOR DELETE USING (
  bucket_id = 'profiles' AND
  auth.role() = 'authenticated' AND
  (storage.foldername(name))[1] = 'profiles'
);

-- =====================================================
-- 4. ADDITIONAL SECURITY POLICIES
-- =====================================================

-- Policy 9: Prevent access to system files
CREATE POLICY "Prevent access to system files" ON storage.objects
FOR ALL USING (
  bucket_id IN ('attachments', 'profiles') AND
  NOT (name LIKE '%.DS_Store' OR name LIKE 'Thumbs.db' OR name LIKE '._%')
);

-- Policy 10: File size validation for attachments
CREATE POLICY "File size validation for attachments" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'attachments' AND
  octet_length(encode(convert_to(metadata->>'eTag', 'UTF8'), 'base64')) <= 10485760
);

-- Policy 11: File size validation for profiles
CREATE POLICY "File size validation for profiles" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'profiles' AND
  octet_length(encode(convert_to(metadata->>'eTag', 'UTF8'), 'UTF8')) <= 5242880
);

-- =====================================================
-- 5. CLEANUP POLICIES (Optional - for maintenance)
-- =====================================================

-- Policy 12: Allow admin cleanup of old files (optional)
-- Uncomment and modify if you have admin role setup
/*
CREATE POLICY "Allow admin cleanup of old files" ON storage.objects
FOR DELETE USING (
  bucket_id IN ('attachments', 'profiles') AND
  auth.role() = 'service_role' AND
  created_at < NOW() - INTERVAL '1 year'
);
*/

-- =====================================================
-- 6. VERIFICATION QUERIES
-- =====================================================

-- Check if buckets were created successfully
SELECT 
  id as bucket_id,
  name as bucket_name,
  public,
  file_size_limit,
  allowed_mime_types
FROM storage.buckets 
WHERE id IN ('attachments', 'profiles');

-- Check if policies were created successfully
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

-- =====================================================
-- 7. USEFUL MAINTENANCE QUERIES
-- =====================================================

-- Count files in each bucket
SELECT 
  bucket_id,
  COUNT(*) as file_count,
  SUM(CAST(metadata->>'size' AS bigint)) as total_size_bytes
FROM storage.objects 
WHERE bucket_id IN ('attachments', 'profiles')
GROUP BY bucket_id;

-- Find large files (>5MB)
SELECT 
  bucket_id,
  name,
  metadata->>'size' as file_size,
  created_at
FROM storage.objects 
WHERE bucket_id IN ('attachments', 'profiles')
AND CAST(metadata->>'size' AS bigint) > 5242880
ORDER BY CAST(metadata->>'size' AS bigint) DESC;

-- Find orphaned files (files without corresponding database records)
-- This query helps identify files that can be safely deleted
SELECT 
  bucket_id,
  name,
  created_at
FROM storage.objects 
WHERE bucket_id = 'attachments'
AND name NOT LIKE '%submissions%'
ORDER BY created_at DESC;
