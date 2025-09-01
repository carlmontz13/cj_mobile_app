-- Database Migration to Fix Submission Status Constraint
-- This script updates the submissions table to allow 'draft' status

-- Step 1: Drop the existing check constraint
ALTER TABLE submissions DROP CONSTRAINT IF EXISTS submissions_status_check;

-- Step 2: Add the new check constraint that includes 'draft'
ALTER TABLE submissions ADD CONSTRAINT submissions_status_check 
    CHECK (status IN ('draft', 'submitted', 'graded', 'late'));

-- Step 3: Update the default value to 'draft' for new submissions
ALTER TABLE submissions ALTER COLUMN status SET DEFAULT 'draft';

-- Step 4: Update existing submissions that don't have a status to 'submitted'
-- (This ensures existing data remains valid)
UPDATE submissions 
SET status = 'submitted' 
WHERE status IS NULL OR status = '';

-- Step 5: Verify the constraint is working
-- You can test this by running:
-- INSERT INTO submissions (assignment_id, student_id, student_name, content, status) 
-- VALUES ('some-uuid', 'some-uuid', 'Test Student', 'Test content', 'draft');

-- Comments for documentation
COMMENT ON COLUMN submissions.status IS 'Submission status: draft, submitted, graded, or late';
