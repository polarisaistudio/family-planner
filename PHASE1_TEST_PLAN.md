# Phase 1 Testing Plan

## Overview
This document outlines the comprehensive testing plan for Phase 1 features of the Family Planner app.

## Phase 1 Features to Test
- ✅ User authentication (email/password signup and login)
- ✅ Calendar view with monthly/weekly/daily formats
- ✅ Create, read, update, and delete (CRUD) todos
- ✅ Todo types: Appointment, Work, Shopping, Personal, Other
- ✅ Priority levels (P1-P5: Urgent to None)
- ✅ Task completion tracking
- ✅ Real-time database synchronization with Supabase
- ✅ Clean architecture with Riverpod state management

---

## Test Suite 1: Authentication

### Test 1.1: User Registration
**Objective**: Verify new users can create accounts

**Steps**:
1. Launch the app
2. Click "Sign Up" button
3. Fill in the registration form:
   - Full Name: "Test User"
   - Email: Use unique email (e.g., test_TIMESTAMP@test.com)
   - Password: "TestPass123!"
   - Confirm Password: "TestPass123!"
4. Click "Sign Up"

**Expected Results**:
- ✅ Success message appears: "Account created successfully!"
- ✅ User is automatically logged in
- ✅ User is redirected to calendar view
- ✅ User profile is created in Supabase `users` table

**Pass Criteria**: All expected results met

---

### Test 1.2: User Login
**Objective**: Verify registered users can log in

**Steps**:
1. If logged in, log out first
2. On login screen, enter credentials from Test 1.1
3. Click "Log In"

**Expected Results**:
- ✅ No error messages appear
- ✅ User is redirected to calendar view
- ✅ User session is established

**Pass Criteria**: All expected results met

---

### Test 1.3: User Logout
**Objective**: Verify users can log out

**Steps**:
1. While logged in, click menu icon (three dots)
2. Select "Logout"

**Expected Results**:
- ✅ User is redirected to login screen
- ✅ Session is cleared
- ✅ Attempting to go back doesn't show authenticated content

**Pass Criteria**: All expected results met

---

### Test 1.4: Invalid Login
**Objective**: Verify error handling for invalid credentials

**Steps**:
1. On login screen, enter:
   - Email: "invalid@test.com"
   - Password: "wrongpassword"
2. Click "Log In"

**Expected Results**:
- ✅ Error message appears
- ✅ User remains on login screen
- ✅ No crash occurs

**Pass Criteria**: All expected results met

---

## Test Suite 2: Todo Creation

### Test 2.1: Create Personal Todo (P3 - Medium Priority)
**Objective**: Create a basic personal task

**Steps**:
1. Log in to the app
2. Select today's date on calendar
3. Click the "+" (floating action button)
4. Fill in the form:
   - Title: "Buy groceries"
   - Description: "Milk, eggs, bread"
   - Date: Today
   - Time: 2 hours from now
   - Type: Personal
   - Priority: P3 (Medium)
5. Click "Create"

**Expected Results**:
- ✅ Success message appears
- ✅ Todo appears in today's list
- ✅ Todo shows correct title, type, and priority
- ✅ Todo appears in Supabase `todos` table

**Pass Criteria**: All expected results met

---

### Test 2.2: Create All Todo Types
**Objective**: Verify all 5 todo types work correctly

**Test Cases**:

#### 2.2a: Appointment
- Title: "Doctor Appointment"
- Type: Appointment
- Priority: P2

#### 2.2b: Work
- Title: "Team Meeting"
- Type: Work
- Priority: P1

#### 2.2c: Shopping
- Title: "Buy office supplies"
- Type: Shopping
- Priority: P3

#### 2.2d: Personal
- Title: "Gym workout"
- Type: Personal
- Priority: P4

#### 2.2e: Other
- Title: "Miscellaneous task"
- Type: Other
- Priority: P5

**Expected Results** (for each):
- ✅ Todo created successfully
- ✅ Correct type label displayed
- ✅ Correct icon/color shown (if applicable)

**Pass Criteria**: All 5 types create successfully

---

### Test 2.3: Create All Priority Levels
**Objective**: Verify all 5 priority levels

**Test Cases**:

#### 2.3a: P1 - Urgent
- Title: "Critical bug fix"
- Priority: P1 (Urgent)

#### 2.3b: P2 - High
- Title: "Important meeting"
- Priority: P2 (High)

#### 2.3c: P3 - Medium
- Title: "Regular task"
- Priority: P3 (Medium)

#### 2.3d: P4 - Low
- Title: "Nice to have"
- Priority: P4 (Low)

#### 2.3e: P5 - None
- Title: "Optional task"
- Priority: P5 (None)

**Expected Results** (for each):
- ✅ Todo created successfully
- ✅ Correct priority displayed
- ✅ Visual indicator matches priority (if applicable)

**Pass Criteria**: All 5 priorities create successfully

---

### Test 2.4: Create Todo with All Fields
**Objective**: Test creating todo with all optional fields

**Steps**:
1. Click "+" to create todo
2. Fill in ALL fields:
   - Title: "Complete Project"
   - Description: "Finish all remaining tasks for Q4 project"
   - Date: Tomorrow
   - Time: 10:00 AM
   - Type: Work
   - Priority: P1
   - Location: "Office Building A" (if available)
   - Notifications: Enabled
   - Notification time: 30 minutes before
3. Click "Create"

**Expected Results**:
- ✅ Todo created with all fields saved
- ✅ All data appears correctly when viewing
- ✅ Notification settings saved (if implemented)

**Pass Criteria**: All fields persist correctly

---

## Test Suite 3: Todo Reading/Viewing

### Test 3.1: View Today's Todos
**Objective**: View all todos for current day

**Steps**:
1. Navigate to calendar
2. Ensure today's date is selected
3. View the todo list

**Expected Results**:
- ✅ All todos for today are displayed
- ✅ Todos are sorted appropriately
- ✅ Each todo shows: title, type, priority, time

**Pass Criteria**: Today's todos display correctly

---

### Test 3.2: View Todos by Date
**Objective**: View todos for different dates

**Steps**:
1. Create todos for 3 different dates:
   - Today
   - Tomorrow
   - Next week
2. Click on each date in calendar
3. Observe todo list changes

**Expected Results**:
- ✅ Todo list updates when date changes
- ✅ Only todos for selected date show
- ✅ Empty dates show no todos

**Pass Criteria**: Date filtering works correctly

---

### Test 3.3: Calendar Monthly View
**Objective**: Verify monthly calendar view

**Steps**:
1. Ensure calendar is in month view
2. Observe dates with todos

**Expected Results**:
- ✅ Month view displays correctly
- ✅ Dates with todos are highlighted/marked
- ✅ Can navigate between months

**Pass Criteria**: Monthly view works correctly

---

### Test 3.4: Calendar Weekly View (if implemented)
**Objective**: Verify weekly calendar view

**Steps**:
1. Switch to week view (if available)
2. Observe current week

**Expected Results**:
- ✅ Week view displays correctly
- ✅ Todos appear in correct days
- ✅ Can navigate between weeks

**Pass Criteria**: Weekly view works correctly (or skip if not implemented)

---

## Test Suite 4: Todo Updates

### Test 4.1: Edit Todo Title
**Objective**: Update an existing todo's title

**Steps**:
1. Select any existing todo
2. Click edit/tap on todo
3. Change title to "Updated Title"
4. Save changes

**Expected Results**:
- ✅ Title updates successfully
- ✅ Updated title displays in list
- ✅ Change persists in database
- ✅ Other fields remain unchanged

**Pass Criteria**: Title updates correctly

---

### Test 4.2: Change Todo Priority
**Objective**: Update todo priority level

**Steps**:
1. Select a P3 (Medium) todo
2. Edit and change to P1 (Urgent)
3. Save changes

**Expected Results**:
- ✅ Priority updates successfully
- ✅ Visual indicator updates
- ✅ Change persists after refresh

**Pass Criteria**: Priority updates correctly

---

### Test 4.3: Change Todo Type
**Objective**: Update todo type

**Steps**:
1. Select a "Personal" todo
2. Edit and change to "Work"
3. Save changes

**Expected Results**:
- ✅ Type updates successfully
- ✅ Icon/color updates (if applicable)
- ✅ Change persists in database

**Pass Criteria**: Type updates correctly

---

### Test 4.4: Change Todo Date
**Objective**: Reschedule a todo

**Steps**:
1. Select a todo scheduled for today
2. Edit and change date to tomorrow
3. Save changes

**Expected Results**:
- ✅ Todo disappears from today's list
- ✅ Todo appears in tomorrow's list
- ✅ All other data remains intact

**Pass Criteria**: Date change works correctly

---

## Test Suite 5: Todo Completion

### Test 5.1: Mark Todo as Complete
**Objective**: Complete a pending todo

**Steps**:
1. Find a pending todo
2. Click/tap the checkbox
3. Observe changes

**Expected Results**:
- ✅ Todo marked as completed
- ✅ Visual indicator shows completion (strikethrough, checkmark, etc.)
- ✅ Status updates in database

**Pass Criteria**: Completion toggle works

---

### Test 5.2: Unmark Completed Todo
**Objective**: Revert a completed todo to pending

**Steps**:
1. Find a completed todo
2. Click/tap the checkbox again
3. Observe changes

**Expected Results**:
- ✅ Todo marked as pending/incomplete
- ✅ Visual indicators revert
- ✅ Status updates in database

**Pass Criteria**: Un-completion works correctly

---

### Test 5.3: Filter by Status (if implemented)
**Objective**: View only completed or pending todos

**Steps**:
1. Create mix of completed and pending todos
2. Apply status filter (if available)
3. Observe filtered results

**Expected Results**:
- ✅ Filtering shows only selected status
- ✅ Filter can be cleared
- ✅ Correct count displayed

**Pass Criteria**: Status filtering works (or skip if not implemented)

---

## Test Suite 6: Todo Deletion

### Test 6.1: Delete Single Todo
**Objective**: Remove a todo

**Steps**:
1. Select any todo
2. Click delete/trash icon
3. Confirm deletion (if prompted)

**Expected Results**:
- ✅ Todo removed from list
- ✅ Todo removed from database
- ✅ Cannot retrieve deleted todo

**Pass Criteria**: Deletion works correctly

---

### Test 6.2: Confirm Deletion Dialog (if implemented)
**Objective**: Verify deletion confirmation

**Steps**:
1. Click delete on a todo
2. If confirmation dialog appears, click "Cancel"
3. Try again and click "Confirm"

**Expected Results**:
- ✅ Cancel keeps the todo
- ✅ Confirm deletes the todo
- ✅ No accidental deletions

**Pass Criteria**: Confirmation works correctly (or skip if no dialog)

---

## Test Suite 7: Database Synchronization

### Test 7.1: Real-time Sync - Create
**Objective**: Verify new todos sync to database

**Steps**:
1. Open Supabase dashboard in browser
2. Navigate to Table Editor → todos
3. Note current count
4. In app, create a new todo
5. Refresh Supabase table

**Expected Results**:
- ✅ New todo appears in database within 1-2 seconds
- ✅ All fields match app data
- ✅ Timestamps are correct

**Pass Criteria**: Create syncs in real-time

---

### Test 7.2: Real-time Sync - Update
**Objective**: Verify updates sync to database

**Steps**:
1. Edit an existing todo in app
2. Check Supabase table for same todo
3. Verify updated_at timestamp changed

**Expected Results**:
- ✅ Changes appear in database
- ✅ updated_at field updates
- ✅ All modified fields sync

**Pass Criteria**: Updates sync correctly

---

### Test 7.3: Real-time Sync - Delete
**Objective**: Verify deletions sync to database

**Steps**:
1. Note a todo ID from Supabase
2. Delete that todo in app
3. Refresh Supabase table

**Expected Results**:
- ✅ Todo removed from database
- ✅ No orphaned records

**Pass Criteria**: Deletions sync correctly

---

### Test 7.4: Offline Behavior (optional)
**Objective**: Test app behavior without internet

**Steps**:
1. Disable internet connection
2. Try to create/edit todos
3. Re-enable internet

**Expected Results**:
- ✅ Appropriate error message shown
- ✅ App doesn't crash
- ✅ (Optional) Offline changes sync when reconnected

**Pass Criteria**: Graceful offline handling

---

## Test Suite 8: Data Validation

### Test 8.1: Required Fields
**Objective**: Verify required field validation

**Steps**:
1. Try to create todo without title
2. Try to create todo without date

**Expected Results**:
- ✅ Validation error shown
- ✅ Todo not created
- ✅ Clear error message

**Pass Criteria**: Required fields enforced

---

### Test 8.2: Invalid Data
**Objective**: Test handling of invalid input

**Test Cases**:
- Very long title (>1000 characters)
- Special characters in title
- Past dates (if not allowed)
- Invalid time format

**Expected Results**:
- ✅ Validation catches issues
- ✅ User-friendly error messages
- ✅ No crashes

**Pass Criteria**: Invalid data handled gracefully

---

## Test Suite 9: Edge Cases

### Test 9.1: Overdue Todos
**Objective**: Verify overdue detection

**Steps**:
1. Create a todo for yesterday
2. Don't complete it
3. View today

**Expected Results**:
- ✅ Todo marked as overdue (if feature exists)
- ✅ Visual indicator for overdue status
- ✅ isOverdue property returns true

**Pass Criteria**: Overdue detection works

---

### Test 9.2: Many Todos Performance
**Objective**: Test performance with many todos

**Steps**:
1. Create 50+ todos for today
2. Navigate calendar
3. Observe performance

**Expected Results**:
- ✅ App remains responsive
- ✅ No lag when switching dates
- ✅ Smooth scrolling

**Pass Criteria**: Handles many todos smoothly

---

### Test 9.3: Same Date/Time Todos
**Objective**: Multiple todos at same time

**Steps**:
1. Create 3 todos for same date/time
2. View list

**Expected Results**:
- ✅ All todos displayed
- ✅ No conflicts or overwrites
- ✅ Each maintains unique ID

**Pass Criteria**: Handles duplicates correctly

---

## Test Suite 10: UI/UX

### Test 10.1: Calendar Navigation
**Objective**: Test calendar controls

**Steps**:
1. Navigate forward 3 months
2. Navigate back 3 months
3. Jump to specific date (if available)

**Expected Results**:
- ✅ Smooth navigation
- ✅ Current selection clear
- ✅ No UI glitches

**Pass Criteria**: Navigation works smoothly

---

### Test 10.2: Responsive Layout
**Objective**: Test on different screen sizes

**Steps**:
1. Run app on phone
2. Run app on tablet (if available)
3. Resize window (on desktop)

**Expected Results**:
- ✅ Layout adapts appropriately
- ✅ All elements accessible
- ✅ No text cutoff

**Pass Criteria**: Responsive design works

---

### Test 10.3: Dark Mode (if implemented)
**Objective**: Test theme switching

**Steps**:
1. Switch to dark mode
2. Navigate through app

**Expected Results**:
- ✅ All screens support dark mode
- ✅ Text readable
- ✅ Consistent color scheme

**Pass Criteria**: Dark mode works (or skip if not implemented)

---

## Test Results Summary

### Test Execution Tracking

| Test ID | Test Name | Status | Notes |
|---------|-----------|--------|-------|
| 1.1 | User Registration | ⬜ Not Run | |
| 1.2 | User Login | ⬜ Not Run | |
| 1.3 | User Logout | ⬜ Not Run | |
| 1.4 | Invalid Login | ⬜ Not Run | |
| 2.1 | Create Personal Todo | ⬜ Not Run | |
| 2.2a-e | Create All Types | ⬜ Not Run | |
| 2.3a-e | Create All Priorities | ⬜ Not Run | |
| 2.4 | Create with All Fields | ⬜ Not Run | |
| 3.1 | View Today's Todos | ⬜ Not Run | |
| 3.2 | View by Date | ⬜ Not Run | |
| 3.3 | Monthly View | ⬜ Not Run | |
| 3.4 | Weekly View | ⬜ Not Run | |
| 4.1 | Edit Title | ⬜ Not Run | |
| 4.2 | Change Priority | ⬜ Not Run | |
| 4.3 | Change Type | ⬜ Not Run | |
| 4.4 | Change Date | ⬜ Not Run | |
| 5.1 | Mark Complete | ⬜ Not Run | |
| 5.2 | Unmark Complete | ⬜ Not Run | |
| 5.3 | Filter by Status | ⬜ Not Run | |
| 6.1 | Delete Todo | ⬜ Not Run | |
| 6.2 | Confirm Deletion | ⬜ Not Run | |
| 7.1 | Sync - Create | ⬜ Not Run | |
| 7.2 | Sync - Update | ⬜ Not Run | |
| 7.3 | Sync - Delete | ⬜ Not Run | |
| 7.4 | Offline Behavior | ⬜ Not Run | |
| 8.1 | Required Fields | ⬜ Not Run | |
| 8.2 | Invalid Data | ⬜ Not Run | |
| 9.1 | Overdue Todos | ⬜ Not Run | |
| 9.2 | Many Todos | ⬜ Not Run | |
| 9.3 | Same Time Todos | ⬜ Not Run | |
| 10.1 | Calendar Navigation | ⬜ Not Run | |
| 10.2 | Responsive Layout | ⬜ Not Run | |
| 10.3 | Dark Mode | ⬜ Not Run | |

### Status Legend
- ⬜ Not Run
- ✅ Passed
- ❌ Failed
- ⚠️ Partial Pass
- ⏭️ Skipped (feature not implemented)

---

## How to Use This Test Plan

### For Manual Testing:
1. Run the app: `flutter run`
2. Go through each test case sequentially
3. Mark status in the table above
4. Document any issues found
5. Take screenshots of failures

### For Automated Testing:
- Integration tests are in `test/integration/phase1_integration_test.dart`
- Run with: `flutter test test/integration/` (requires device/emulator)

### Reporting Issues:
When a test fails, document:
- Test ID
- Steps to reproduce
- Expected vs actual behavior
- Screenshots/error messages
- Device/platform info

---

## Success Criteria

Phase 1 is considered complete when:
- ✅ All authentication tests pass
- ✅ All CRUD operations work correctly
- ✅ All 5 todo types function properly
- ✅ All 5 priority levels function properly
- ✅ Calendar views display correctly
- ✅ Database sync is reliable
- ✅ No critical bugs remain
- ✅ At least 90% of tests pass

---

## Next Steps After Phase 1 Testing

Once Phase 1 tests pass:
1. Document all known issues
2. Prioritize bug fixes
3. Plan Phase 2 implementation
4. Set up continuous testing workflow
