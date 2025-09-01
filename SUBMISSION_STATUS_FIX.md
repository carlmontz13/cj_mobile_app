# Submission Status Fix

## Issue
The unsubmit functionality is failing with a database constraint error because the `submissions` table doesn't allow the `'draft'` status.

## Solution
Run the database migration script to update the constraint.

## Steps to Fix

1. **Apply the Database Migration**
   
   Run the SQL script `database_fix_submission_status.sql` in your Supabase SQL editor:
   
   ```sql
   -- Drop the existing check constraint
   ALTER TABLE submissions DROP CONSTRAINT IF EXISTS submissions_status_check;
   
   -- Add the new check constraint that includes 'draft'
   ALTER TABLE submissions ADD CONSTRAINT submissions_status_check 
       CHECK (status IN ('draft', 'submitted', 'graded', 'late'));
   
   -- Update the default value to 'draft' for new submissions
   ALTER TABLE submissions ALTER COLUMN status SET DEFAULT 'draft';
   
   -- Update existing submissions that don't have a status to 'submitted'
   UPDATE submissions 
   SET status = 'submitted' 
   WHERE status IS NULL OR status = '';
   ```

2. **Verify the Fix**
   
   After running the migration, the unsubmit functionality should work properly.

## What Changed

- **Database**: Added `'draft'` status to the allowed submission statuses
- **App**: Updated submission screen to handle draft vs submitted states
- **Features**: 
  - Students can now save drafts
  - Students can unsubmit assignments (before grading)
  - Clear visual indicators for submission status

## Status Meanings

- **Draft**: Work in progress, not yet submitted
- **Submitted**: Final submission handed in
- **Graded**: Teacher has graded the submission
- **Late**: Submission was submitted after due date
