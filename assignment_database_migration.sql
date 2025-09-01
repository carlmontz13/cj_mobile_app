    -- Assignment System Database Migration
    -- This file contains the SQL commands to create the necessary tables for the assignment system

    -- Create assignments table
    CREATE TABLE IF NOT EXISTS assignments (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        description TEXT NOT NULL,
        due_date TIMESTAMP WITH TIME ZONE NOT NULL,
        total_points INTEGER NOT NULL DEFAULT 100,
        status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'archived')),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        attachments TEXT[], -- Array of file URLs
        instructions TEXT -- Additional instructions for students
    );

    -- Create submissions table
    CREATE TABLE IF NOT EXISTS submissions (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        assignment_id UUID NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
        student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
        student_name VARCHAR(255) NOT NULL,
        content TEXT NOT NULL,
        attachments TEXT[], -- Array of file URLs
        submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        graded_at TIMESTAMP WITH TIME ZONE,
        grade INTEGER CHECK (grade >= 0),
        feedback TEXT,
        status VARCHAR(20) NOT NULL DEFAULT 'submitted' CHECK (status IN ('submitted', 'graded', 'late')),
        is_late BOOLEAN DEFAULT FALSE,
        
        -- Ensure one submission per student per assignment
        UNIQUE(assignment_id, student_id)
    );

    -- Create indexes for better performance
    CREATE INDEX IF NOT EXISTS idx_assignments_class_id ON assignments(class_id);
    CREATE INDEX IF NOT EXISTS idx_assignments_status ON assignments(status);
    CREATE INDEX IF NOT EXISTS idx_assignments_due_date ON assignments(due_date);
    CREATE INDEX IF NOT EXISTS idx_submissions_assignment_id ON submissions(assignment_id);
    CREATE INDEX IF NOT EXISTS idx_submissions_student_id ON submissions(student_id);
    CREATE INDEX IF NOT EXISTS idx_submissions_status ON submissions(status);

    -- Create a function to automatically update the updated_at timestamp
    CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS $$
    BEGIN
        NEW.updated_at = NOW();
        RETURN NEW;
    END;
    $$ language 'plpgsql';

    -- Create trigger to automatically update updated_at on assignments table
    CREATE TRIGGER update_assignments_updated_at 
        BEFORE UPDATE ON assignments 
        FOR EACH ROW 
        EXECUTE FUNCTION update_updated_at_column();

    -- Create a function to automatically set is_late flag
    CREATE OR REPLACE FUNCTION set_late_flag()
    RETURNS TRIGGER AS $$
    BEGIN
        -- Check if submission is late
        IF NEW.submitted_at > (SELECT due_date FROM assignments WHERE id = NEW.assignment_id) THEN
            NEW.is_late = TRUE;
            NEW.status = 'late';
        END IF;
        RETURN NEW;
    END;
    $$ language 'plpgsql';

    -- Create trigger to automatically set late flag on submissions
    CREATE TRIGGER set_submission_late_flag 
        BEFORE INSERT OR UPDATE ON submissions 
        FOR EACH ROW 
        EXECUTE FUNCTION set_late_flag();

    -- Create a function to automatically update submission status when graded
    CREATE OR REPLACE FUNCTION update_submission_status_on_grade()
    RETURNS TRIGGER AS $$
    BEGIN
        IF NEW.grade IS NOT NULL AND OLD.grade IS NULL THEN
            NEW.status = 'graded';
            NEW.graded_at = NOW();
        END IF;
        RETURN NEW;
    END;
    $$ language 'plpgsql';

    -- Create trigger to automatically update status when graded
    CREATE TRIGGER update_submission_status_on_grade 
        BEFORE UPDATE ON submissions 
        FOR EACH ROW 
        EXECUTE FUNCTION update_submission_status_on_grade();

    -- Insert sample data for testing (optional)
    -- You can uncomment these lines to add sample data

    /*
    -- Sample assignments
    INSERT INTO assignments (class_id, title, description, due_date, total_points, status, instructions) VALUES
    (
        (SELECT id FROM classes LIMIT 1),
        'Introduction to Flutter',
        'Create a simple Flutter app that displays "Hello World" and includes a button that changes the text when pressed.',
        NOW() + INTERVAL '7 days',
        100,
        'active',
        'Make sure to follow Flutter best practices and include proper documentation in your code.'
    ),
    (
        (SELECT id FROM classes LIMIT 1),
        'State Management with Provider',
        'Implement a simple counter app using the Provider package for state management.',
        NOW() + INTERVAL '14 days',
        150,
        'active',
        'Demonstrate understanding of Provider pattern and show how to manage state effectively.'
    );

    -- Sample submissions (only if there are students enrolled)
    INSERT INTO submissions (assignment_id, student_id, student_name, content, status) VALUES
    (
        (SELECT id FROM assignments LIMIT 1),
        (SELECT id FROM profiles WHERE role = 'student' LIMIT 1),
        (SELECT full_name FROM profiles WHERE role = 'student' LIMIT 1),
        'I created a Flutter app with a "Hello World" text and a button that changes the text to "Hello Flutter!" when pressed. The app uses a StatefulWidget to manage the state of the text.',
        'submitted'
    );
    */

    -- Grant necessary permissions (adjust based on your Supabase setup)
    -- These permissions should be configured in your Supabase dashboard

    -- Enable Row Level Security (RLS)
    ALTER TABLE assignments ENABLE ROW LEVEL SECURITY;
    ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;

    -- Create policies for assignments table
    -- Teachers can see all assignments in their classes
    CREATE POLICY "Teachers can view assignments in their classes" ON assignments
        FOR SELECT USING (
            EXISTS (
                SELECT 1 FROM classes 
                WHERE classes.id = assignments.class_id 
                AND classes.teacher_id = auth.uid()
            )
        );

    -- Students can see assignments in classes they're enrolled in
    CREATE POLICY "Students can view assignments in enrolled classes" ON assignments
        FOR SELECT USING (
            EXISTS (
                SELECT 1 FROM class_enrollments 
                WHERE class_enrollments.class_id = assignments.class_id 
                AND class_enrollments.student_id = auth.uid()
                AND class_enrollments.status = 'active'
            )
        );

    -- Teachers can create assignments in their classes
    CREATE POLICY "Teachers can create assignments in their classes" ON assignments
        FOR INSERT WITH CHECK (
            EXISTS (
                SELECT 1 FROM classes 
                WHERE classes.id = assignments.class_id 
                AND classes.teacher_id = auth.uid()
            )
        );

    -- Teachers can update assignments in their classes
    CREATE POLICY "Teachers can update assignments in their classes" ON assignments
        FOR UPDATE USING (
            EXISTS (
                SELECT 1 FROM classes 
                WHERE classes.id = assignments.class_id 
                AND classes.teacher_id = auth.uid()
            )
        );

    -- Teachers can delete assignments in their classes
    CREATE POLICY "Teachers can delete assignments in their classes" ON assignments
        FOR DELETE USING (
            EXISTS (
                SELECT 1 FROM classes 
                WHERE classes.id = assignments.class_id 
                AND classes.teacher_id = auth.uid()
            )
        );

    -- Create policies for submissions table
    -- Teachers can see all submissions for assignments in their classes
    CREATE POLICY "Teachers can view submissions in their classes" ON submissions
        FOR SELECT USING (
            EXISTS (
                SELECT 1 FROM assignments 
                JOIN classes ON classes.id = assignments.class_id
                WHERE assignments.id = submissions.assignment_id 
                AND classes.teacher_id = auth.uid()
            )
        );

    -- Students can see their own submissions
    CREATE POLICY "Students can view their own submissions" ON submissions
        FOR SELECT USING (
            student_id = auth.uid()
        );

    -- Students can create submissions for assignments in classes they're enrolled in
    CREATE POLICY "Students can create submissions in enrolled classes" ON submissions
        FOR INSERT WITH CHECK (
            student_id = auth.uid() AND
            EXISTS (
                SELECT 1 FROM assignments 
                JOIN class_enrollments ON class_enrollments.class_id = assignments.class_id
                WHERE assignments.id = submissions.assignment_id 
                AND class_enrollments.student_id = auth.uid()
                AND class_enrollments.status = 'active'
            )
        );

    -- Students can update their own submissions
    CREATE POLICY "Students can update their own submissions" ON submissions
        FOR UPDATE USING (
            student_id = auth.uid()
        );

    -- Teachers can grade submissions for assignments in their classes
    CREATE POLICY "Teachers can grade submissions in their classes" ON submissions
        FOR UPDATE USING (
            EXISTS (
                SELECT 1 FROM assignments 
                JOIN classes ON classes.id = assignments.class_id
                WHERE assignments.id = submissions.assignment_id 
                AND classes.teacher_id = auth.uid()
            )
        );

    -- Comments for documentation
    COMMENT ON TABLE assignments IS 'Stores assignment information for each class';
    COMMENT ON TABLE submissions IS 'Stores student submissions for assignments';
    COMMENT ON COLUMN assignments.attachments IS 'Array of file URLs attached to the assignment';
    COMMENT ON COLUMN assignments.instructions IS 'Additional instructions for students';
    COMMENT ON COLUMN submissions.attachments IS 'Array of file URLs attached to the submission';
    COMMENT ON COLUMN submissions.feedback IS 'Teacher feedback on the submission';
    COMMENT ON COLUMN submissions.is_late IS 'Indicates if the submission was submitted after the due date';
