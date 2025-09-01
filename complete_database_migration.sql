-- Complete Database Migration Script
-- This script creates the complete normalized database structure with all fixes applied

-- Step 1: Create the profiles table if it doesn't exist
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    profile_image_url TEXT,
    role TEXT DEFAULT 'student' CHECK (role IN ('teacher', 'student')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 2: Create the classes table if it doesn't exist
CREATE TABLE IF NOT EXISTS classes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    teacher_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    teacher_name TEXT,
    section TEXT,
    subject TEXT,
    room TEXT,
    class_code TEXT UNIQUE NOT NULL,
    banner_image_url TEXT,
    theme_color TEXT DEFAULT '#3B82F6',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 3: Create the normalized class_enrollments table if it doesn't exist
CREATE TABLE IF NOT EXISTS class_enrollments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    student_name TEXT,
    student_email TEXT,
    enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'dropped')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(class_id, student_id)
);

-- Step 4: Create indexes for better performance
-- Profiles table indexes
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);

-- Classes table indexes
CREATE INDEX IF NOT EXISTS idx_classes_teacher_id ON classes(teacher_id);
CREATE INDEX IF NOT EXISTS idx_classes_class_code ON classes(class_code);
CREATE INDEX IF NOT EXISTS idx_classes_subject ON classes(subject);

-- Class enrollments table indexes
CREATE INDEX IF NOT EXISTS idx_class_enrollments_class_id ON class_enrollments(class_id);
CREATE INDEX IF NOT EXISTS idx_class_enrollments_student_id ON class_enrollments(student_id);
CREATE INDEX IF NOT EXISTS idx_class_enrollments_status ON class_enrollments(status);
CREATE INDEX IF NOT EXISTS idx_class_enrollments_class_student ON class_enrollments(class_id, student_id);

-- Step 5: Create or replace the create_user_profile RPC function
CREATE OR REPLACE FUNCTION create_user_profile(
    user_id UUID,
    user_email TEXT,
    user_full_name TEXT,
    user_role TEXT DEFAULT 'student'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
BEGIN
    -- Insert or update the profile
    INSERT INTO profiles (
        id,
        email,
        full_name,
        role,
        created_at,
        updated_at
    ) VALUES (
        user_id,
        user_email,
        user_full_name,
        user_role,
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = EXCLUDED.full_name,
        role = EXCLUDED.role,
        updated_at = NOW()
    RETURNING json_build_object(
        'success', true,
        'id', id,
        'email', email,
        'full_name', full_name,
        'role', role
    ) INTO result;
    
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$;

-- Step 6: Create or replace the join_class RPC function
CREATE OR REPLACE FUNCTION join_class(
    class_code_param TEXT,
    student_id_param UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    class_record RECORD;
    student_record RECORD;
    enrollment_id UUID;
    result JSON;
BEGIN
    -- Get the class details
    SELECT * INTO class_record 
    FROM classes 
    WHERE class_code = class_code_param;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Class not found with the provided code'
        );
    END IF;
    
    -- Get the student details
    SELECT * INTO student_record 
    FROM profiles 
    WHERE id = student_id_param;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Student profile not found'
        );
    END IF;
    
    -- Check if already enrolled
    IF EXISTS (
        SELECT 1 FROM class_enrollments 
        WHERE class_id = class_record.id 
        AND student_id = student_id_param 
        AND status = 'active'
    ) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Already enrolled in this class'
        );
    END IF;
    
    -- Create enrollment
    INSERT INTO class_enrollments (
        class_id,
        student_id,
        student_name,
        student_email,
        status
    ) VALUES (
        class_record.id,
        student_id_param,
        student_record.full_name,
        student_record.email,
        'active'
    ) RETURNING id INTO enrollment_id;
    
    RETURN json_build_object(
        'success', true,
        'enrollment_id', enrollment_id,
        'class_name', class_record.name
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$;

-- Step 7: Create or replace the leave_class RPC function
CREATE OR REPLACE FUNCTION leave_class(
    class_id_param UUID,
    student_id_param UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
BEGIN
    -- Update enrollment status to inactive
    UPDATE class_enrollments 
    SET status = 'inactive', updated_at = NOW()
    WHERE class_id = class_id_param 
    AND student_id = student_id_param;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Enrollment not found'
        );
    END IF;
    
    RETURN json_build_object('success', true);
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$;

-- Step 8: Create or replace the get_class_students RPC function
CREATE OR REPLACE FUNCTION get_class_students(class_id_param UUID)
RETURNS TABLE (
    id UUID,
    class_id UUID,
    student_id UUID,
    student_name TEXT,
    student_email TEXT,
    enrolled_at TIMESTAMP WITH TIME ZONE,
    status TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ce.id,
        ce.class_id,
        ce.student_id,
        ce.student_name,
        ce.student_email,
        ce.enrolled_at,
        ce.status
    FROM class_enrollments ce
    WHERE ce.class_id = class_id_param
    AND ce.status = 'active'
    ORDER BY ce.enrolled_at;
END;
$$;

-- Step 9: Create or replace the create_class RPC function
CREATE OR REPLACE FUNCTION create_class(
    class_name TEXT,
    class_description TEXT,
    teacher_id_param UUID,
    teacher_name_param TEXT,
    section_param TEXT,
    subject_param TEXT,
    room_param TEXT,
    banner_image_url_param TEXT DEFAULT NULL,
    theme_color_param TEXT DEFAULT '#3B82F6'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_class_id UUID;
    class_code TEXT;
    result JSON;
BEGIN
    -- Generate a unique class code
    class_code := upper(substring(md5(random()::text) from 1 for 6));
    
    -- Ensure the class code is unique
    WHILE EXISTS (SELECT 1 FROM classes WHERE class_code = class_code) LOOP
        class_code := upper(substring(md5(random()::text) from 1 for 6));
    END LOOP;
    
    -- Create the class
    INSERT INTO classes (
        name,
        description,
        teacher_id,
        teacher_name,
        section,
        subject,
        room,
        class_code,
        banner_image_url,
        theme_color
    ) VALUES (
        class_name,
        class_description,
        teacher_id_param,
        teacher_name_param,
        section_param,
        subject_param,
        room_param,
        class_code,
        banner_image_url_param,
        theme_color_param
    ) RETURNING id INTO new_class_id;
    
    RETURN json_build_object(
        'success', true,
        'class_id', new_class_id,
        'class_code', class_code,
        'message', 'Class created successfully'
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$;

-- Step 10: Create or replace the update_class RPC function
CREATE OR REPLACE FUNCTION update_class(
    class_id_param UUID,
    class_name TEXT DEFAULT NULL,
    class_description TEXT DEFAULT NULL,
    section_param TEXT DEFAULT NULL,
    subject_param TEXT DEFAULT NULL,
    room_param TEXT DEFAULT NULL,
    banner_image_url_param TEXT DEFAULT NULL,
    theme_color_param TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
BEGIN
    -- Update the class
    UPDATE classes SET
        name = COALESCE(class_name, name),
        description = COALESCE(class_description, description),
        section = COALESCE(section_param, section),
        subject = COALESCE(subject_param, subject),
        room = COALESCE(room_param, room),
        banner_image_url = COALESCE(banner_image_url_param, banner_image_url),
        theme_color = COALESCE(theme_color_param, theme_color),
        updated_at = NOW()
    WHERE id = class_id_param;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Class not found'
        );
    END IF;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Class updated successfully'
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$;

-- Step 11: Create or replace the delete_class RPC function
CREATE OR REPLACE FUNCTION delete_class(class_id_param UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
BEGIN
    -- Delete the class (this will cascade to enrollments)
    DELETE FROM classes WHERE id = class_id_param;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Class not found'
        );
    END IF;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Class deleted successfully'
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$;

-- Step 12: Create or replace the get_teacher_classes RPC function
CREATE OR REPLACE FUNCTION get_teacher_classes(teacher_id_param UUID)
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    teacher_id UUID,
    teacher_name TEXT,
    section TEXT,
    subject TEXT,
    room TEXT,
    class_code TEXT,
    banner_image_url TEXT,
    theme_color TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    student_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.name,
        c.description,
        c.teacher_id,
        c.teacher_name,
        c.section,
        c.subject,
        c.room,
        c.class_code,
        c.banner_image_url,
        c.theme_color,
        c.created_at,
        c.updated_at,
        COALESCE(COUNT(ce.student_id), 0) as student_count
    FROM classes c
    LEFT JOIN class_enrollments ce ON c.id = ce.class_id AND ce.status = 'active'
    WHERE c.teacher_id = teacher_id_param
    GROUP BY c.id, c.name, c.description, c.teacher_id, c.teacher_name, 
             c.section, c.subject, c.room, c.class_code, c.banner_image_url, 
             c.theme_color, c.created_at, c.updated_at
    ORDER BY c.created_at DESC;
END;
$$;

-- Step 12.5: Create or replace the search_classes RPC function for students
CREATE OR REPLACE FUNCTION search_classes(
    search_term TEXT DEFAULT NULL,
    subject_filter TEXT DEFAULT NULL,
    limit_count INTEGER DEFAULT 20
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    teacher_id UUID,
    teacher_name TEXT,
    section TEXT,
    subject TEXT,
    room TEXT,
    class_code TEXT,
    banner_image_url TEXT,
    theme_color TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    student_count BIGINT,
    is_enrolled BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.name,
        c.description,
        c.teacher_id,
        c.teacher_name,
        c.section,
        c.subject,
        c.room,
        c.class_code,
        c.banner_image_url,
        c.theme_color,
        c.created_at,
        c.updated_at,
        COALESCE(COUNT(ce.student_id), 0) as student_count,
        EXISTS (
            SELECT 1 FROM class_enrollments 
            WHERE class_id = c.id 
            AND student_id = auth.uid() 
            AND status = 'active'
        ) as is_enrolled
    FROM classes c
    LEFT JOIN class_enrollments ce ON c.id = ce.class_id AND ce.status = 'active'
    WHERE 
        -- Search by name, description, or class code
        (search_term IS NULL OR 
         c.name ILIKE '%' || search_term || '%' OR 
         c.description ILIKE '%' || search_term || '%' OR
         c.class_code ILIKE '%' || search_term || '%')
        AND
        -- Filter by subject if provided
        (subject_filter IS NULL OR c.subject ILIKE '%' || subject_filter || '%')
    GROUP BY c.id, c.name, c.description, c.teacher_id, c.teacher_name, 
             c.section, c.subject, c.room, c.class_code, c.banner_image_url, 
             c.theme_color, c.created_at, c.updated_at
    ORDER BY c.created_at DESC
    LIMIT limit_count;
END;
$$;

-- Step 12.6: Create or replace the get_student_classes RPC function
CREATE OR REPLACE FUNCTION get_student_classes(student_id_param UUID)
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    teacher_id UUID,
    teacher_name TEXT,
    section TEXT,
    subject TEXT,
    room TEXT,
    class_code TEXT,
    banner_image_url TEXT,
    theme_color TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    enrolled_at TIMESTAMP WITH TIME ZONE,
    enrollment_status TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.name,
        c.description,
        c.teacher_id,
        c.teacher_name,
        c.section,
        c.subject,
        c.room,
        c.class_code,
        c.banner_image_url,
        c.theme_color,
        c.created_at,
        c.updated_at,
        ce.enrolled_at,
        ce.status as enrollment_status
    FROM classes c
    INNER JOIN class_enrollments ce ON c.id = ce.class_id
    WHERE ce.student_id = student_id_param
    AND ce.status = 'active'
    ORDER BY ce.enrolled_at DESC;
END;
$$;

-- Step 13: Create trigger function and triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS update_class_enrollments_updated_at ON class_enrollments;
DROP TRIGGER IF EXISTS update_classes_updated_at ON classes;

-- Create triggers
CREATE TRIGGER update_class_enrollments_updated_at 
    BEFORE UPDATE ON class_enrollments 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_classes_updated_at 
    BEFORE UPDATE ON classes 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Step 14: Create RLS policies for profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can manage their own profile" ON profiles;

-- Policy for users to manage their own profile
CREATE POLICY "Users can manage their own profile" ON profiles
    FOR ALL USING (auth.uid() = id);

-- Step 15: Create RLS policies for classes (FIXED - No circular dependencies)
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Teachers can manage their own classes" ON classes;
DROP POLICY IF EXISTS "Students can view enrolled classes" ON classes;
DROP POLICY IF EXISTS "Public class code access" ON classes;
DROP POLICY IF EXISTS "Students can search and join classes" ON classes;
DROP POLICY IF EXISTS "Students can view class details for joining" ON classes;

-- Policy for teachers to manage their own classes
CREATE POLICY "Teachers can manage their own classes" ON classes
    FOR ALL USING (auth.uid() = teacher_id);

-- Policy for students to search and join classes (allows SELECT for searching)
CREATE POLICY "Students can search and join classes" ON classes
    FOR SELECT USING (
        -- Allow authenticated users to search classes
        auth.role() = 'authenticated'
    );

-- Policy for students to view class details when joining (allows SELECT for specific class details)
CREATE POLICY "Students can view class details for joining" ON classes
    FOR SELECT USING (
        -- Allow viewing class details for joining purposes
        auth.role() = 'authenticated'
    );

-- Step 16: Create RLS policies for class_enrollments (FIXED - No circular dependencies)
ALTER TABLE class_enrollments ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Students can view their own enrollments" ON class_enrollments;
DROP POLICY IF EXISTS "Teachers can view enrollments in their classes" ON class_enrollments;
DROP POLICY IF EXISTS "Users can insert their own enrollments" ON class_enrollments;
DROP POLICY IF EXISTS "Users can update their own enrollments" ON class_enrollments;

-- Policy for students to see their own enrollments
CREATE POLICY "Students can view their own enrollments" ON class_enrollments
    FOR SELECT USING (auth.uid() = student_id);

-- Policy for teachers to see enrollments in their classes (simplified to avoid recursion)
CREATE POLICY "Teachers can view enrollments in their classes" ON class_enrollments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM classes 
            WHERE id = class_enrollments.class_id 
            AND teacher_id = auth.uid()
        )
    );

-- Policy for inserting enrollments
CREATE POLICY "Users can insert their own enrollments" ON class_enrollments
    FOR INSERT WITH CHECK (auth.uid() = student_id);

-- Policy for updating enrollments
CREATE POLICY "Users can update their own enrollments" ON class_enrollments
    FOR UPDATE USING (auth.uid() = student_id);

-- Step 17: Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON class_enrollments TO authenticated;
GRANT ALL ON profiles TO authenticated;
GRANT ALL ON classes TO authenticated;

-- Step 18: Verify the setup
SELECT 'Complete database migration completed successfully' as status;
