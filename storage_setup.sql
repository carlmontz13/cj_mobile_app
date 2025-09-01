-- Storage Setup for Image Attachments
-- Run this in your Supabase SQL editor

-- 1. Create the attachments bucket if it doesn't exist
-- Note: You may need to create this manually in the Supabase dashboard first
-- Go to Storage > Create a new bucket called 'attachments'

-- 2. Enable RLS on storage.objects (if not already enabled)
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 3. Drop existing policies if they exist
DROP POLICY IF EXISTS "attachments_insert_authenticated" ON storage.objects;
DROP POLICY IF EXISTS "attachments_select_public" ON storage.objects;
DROP POLICY IF EXISTS "attachments_update_own" ON storage.objects;
DROP POLICY IF EXISTS "attachments_delete_own" ON storage.objects;

-- 4. Create policies for the attachments bucket

-- Allow authenticated users to upload to the attachments bucket
CREATE POLICY "attachments_insert_authenticated" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'attachments');

-- Allow anyone to read objects in the attachments bucket (public access)
CREATE POLICY "attachments_select_public" ON storage.objects
FOR SELECT
USING (bucket_id = 'attachments');

-- Allow users to update their own objects
CREATE POLICY "attachments_update_own" ON storage.objects
FOR UPDATE TO authenticated
USING (bucket_id = 'attachments' AND owner = auth.uid())
WITH CHECK (bucket_id = 'attachments' AND owner = auth.uid());

-- Allow users to delete their own objects
CREATE POLICY "attachments_delete_own" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'attachments' AND owner = auth.uid());

-- 5. Alternative: If you want to keep the bucket private and use signed URLs only,
-- comment out the "attachments_select_public" policy above and uncomment this:
-- CREATE POLICY "attachments_select_authenticated" ON storage.objects
-- FOR SELECT TO authenticated
-- USING (bucket_id = 'attachments');

-- 6. Grant necessary permissions
GRANT ALL ON storage.objects TO authenticated;

-- 7. Verify the setup
SELECT 'Storage setup completed successfully' as status;
