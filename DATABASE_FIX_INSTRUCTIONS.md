# Database Fix Instructions

## Issue Summary
The application was experiencing database schema issues:
1. Missing `class_ids` column in the `profiles` table
2. Missing normalized `class_enrollments` table
3. RPC functions not working properly with the new structure

## Solution
I've created a comprehensive database migration script that fixes all these issues and implements a proper normalized database structure.

## Files Created

### 1. `database_migration_fix.sql`
This is the main migration script that:
- Creates the normalized `class_enrollments` table
- Adds the missing `class_ids` column to the `profiles` table
- Creates all necessary RPC functions
- Sets up proper Row Level Security (RLS) policies
- Creates indexes for better performance

### 2. `verify_database_fix.sql`
This verification script tests if the migration was successful by:
- Checking if all tables and columns exist
- Verifying RPC functions are created
- Testing the `create_user_profile` function
- Checking RLS policies

## How to Apply the Fix

### Step 1: Run the Migration
1. Go to your Supabase dashboard
2. Navigate to the SQL Editor
3. Copy and paste the contents of `database_migration_fix.sql`
4. Execute the script

### Step 2: Verify the Migration
1. In the same SQL Editor
2. Copy and paste the contents of `verify_database_fix.sql`
3. Execute the script
4. All checks should show "EXISTS" or "PASSED"

### Step 3: Test the Application
1. Run your Flutter application
2. Try to sign in with an existing user
3. The profile creation should now work without errors
4. Test joining and leaving classes

## What the Migration Does

### Database Structure
- **`classes` table**: Main table for class information
  - `id`: Unique class ID
  - `name`: Class name
  - `description`: Class description
  - `teacher_id`: Reference to the teacher profile
  - `teacher_name`: Cached teacher name for performance
  - `section`: Class section
  - `subject`: Subject area
  - `room`: Room number/location
  - `class_code`: Unique 6-character code for joining
  - `banner_image_url`: Optional banner image
  - `theme_color`: Theme color for the class
  - `created_at`/`updated_at`: Timestamps

- **`class_enrollments` table**: Normalized table for student-class relationships
  - `id`: Unique enrollment ID
  - `class_id`: Reference to the class
  - `student_id`: Reference to the student profile
  - `student_name`: Cached student name for performance
  - `student_email`: Cached student email for performance
  - `enrolled_at`: When the student joined
  - `status`: Enrollment status (active/inactive/dropped)
  - `created_at`/`updated_at`: Timestamps

- **`profiles` table**: Updated with `class_ids` array column
  - Maintains backward compatibility
  - Stores array of class IDs for quick access

### RPC Functions
- **`create_user_profile`**: Creates user profiles with proper error handling
- **`create_class`**: Creates new classes with auto-generated class codes
- **`update_class`**: Updates class information
- **`delete_class`**: Deletes classes (cascades to enrollments)
- **`get_teacher_classes`**: Retrieves all classes for a teacher with student counts
- **`join_class`**: Handles class enrollment with validation
- **`leave_class`**: Handles class withdrawal
- **`get_class_students`**: Retrieves all students in a class

### Security
- Row Level Security (RLS) policies ensure users can only access their own data
- Teachers can manage their own classes and see enrollments in their classes
- Students can only see classes they are enrolled in and their own enrollments

## Code Changes Made

### AuthService Updates
- Improved error handling in profile creation
- Better fallback mechanisms when RPC fails
- Temporary profile creation for immediate app functionality

### EnrollmentService Updates
- Added fallback queries when RPC functions fail
- Better error handling and recovery

## Troubleshooting

### If Migration Fails
1. Check if you have the necessary permissions in Supabase
2. Ensure the `classes` and `profiles` tables exist
3. Run the verification script to identify specific issues

### If App Still Shows Errors
1. Check the browser console for specific error messages
2. Verify that the RPC functions are working in the SQL Editor
3. Test the functions manually with sample data

### Common Issues
- **"column class_ids does not exist"**: Run the migration script again
- **"function does not exist"**: Ensure all RPC functions were created
- **"permission denied"**: Check RLS policies and user permissions

## Benefits of This Fix

1. **Normalized Database**: Proper relational structure
2. **Better Performance**: Indexes and optimized queries
3. **Data Integrity**: Foreign key constraints and validation
4. **Security**: Row Level Security policies
5. **Scalability**: Proper structure for future features
6. **Error Handling**: Robust fallback mechanisms

## Next Steps

After applying this fix:
1. Test all enrollment functionality
2. Verify that existing users can sign in
3. Test class creation and joining
4. Monitor for any remaining issues

The application should now work properly with the normalized database structure and proper error handling.
