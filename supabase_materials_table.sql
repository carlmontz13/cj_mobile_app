-- Materials table for storing AI-generated instructional content in Supabase
CREATE TABLE IF NOT EXISTS materials (
    id BIGSERIAL PRIMARY KEY,
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    language_code TEXT NOT NULL DEFAULT 'en',
    simplified_content TEXT,
    standard_content TEXT,
    advanced_content TEXT,
    selected_content_type TEXT CHECK(selected_content_type IN ('simplified', 'standard', 'advanced')),
    selected_content TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT TRUE
);

-- Index for better query performance
CREATE INDEX IF NOT EXISTS idx_materials_class_id ON materials(class_id);
CREATE INDEX IF NOT EXISTS idx_materials_created_by ON materials(created_by);
CREATE INDEX IF NOT EXISTS idx_materials_language ON materials(language_code);
CREATE INDEX IF NOT EXISTS idx_materials_created_at ON materials(created_at);
CREATE INDEX IF NOT EXISTS idx_materials_is_active ON materials(is_active);

-- Trigger to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_materials_updated_at
    BEFORE UPDATE ON materials
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE materials ENABLE ROW LEVEL SECURITY;

-- Create policies for secure access
-- Users can only see materials from classes they are enrolled in or teach
CREATE POLICY "Users can view materials from their classes" ON materials
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM class_enrollments ce
            WHERE ce.class_id = materials.class_id
            AND ce.student_id = auth.uid()
            AND ce.status = 'active'
        )
        OR
        EXISTS (
            SELECT 1 FROM classes c
            WHERE c.id = materials.class_id
            AND c.teacher_id = auth.uid()
        )
    );

-- Only teachers can create materials for their classes
CREATE POLICY "Teachers can create materials for their classes" ON materials
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM classes c
            WHERE c.id = materials.class_id
            AND c.teacher_id = auth.uid()
        )
    );

-- Only teachers can update materials for their classes
CREATE POLICY "Teachers can update materials for their classes" ON materials
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM classes c
            WHERE c.id = materials.class_id
            AND c.teacher_id = auth.uid()
        )
    );

-- Only teachers can delete materials for their classes
CREATE POLICY "Teachers can delete materials for their classes" ON materials
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM classes c
            WHERE c.id = materials.class_id
            AND c.teacher_id = auth.uid()
        )
    );
