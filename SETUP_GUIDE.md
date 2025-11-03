# Step-by-Step Setup Guide

This guide will walk you through setting up Supabase and testing your Family Planner app.

## Step 1: Create Supabase Account (2 minutes)

1. **Open your browser** and go to: https://supabase.com
2. **Click "Start your project"** or "Sign up"
3. **Sign up with**:
   - GitHub (recommended - fastest)
   - OR Email/Password
4. **Verify your email** if using email signup

## Step 2: Create New Project (2 minutes)

1. After logging in, click **"New Project"**
2. If this is your first project, you'll need to create an organization:
   - Click **"New organization"**
   - Name it (e.g., "Personal" or "Family Projects")
   - Choose free plan
3. Fill in project details:
   - **Name**: `family-planner` (or any name you prefer)
   - **Database Password**: Choose a STRONG password and **SAVE IT SOMEWHERE SAFE**
     - Suggestion: Use a password manager
     - Must be at least 6 characters
   - **Region**: Choose closest to your location
     - US East (N. Virginia) for US East Coast
     - US West (Oregon) for US West Coast
     - Europe (Frankfurt) for Europe
     - Asia Pacific (Singapore) for Asia
4. Click **"Create new project"**
5. ⏱️ **Wait 1-2 minutes** for project to be created (you'll see a progress indicator)

## Step 3: Set Up Database (3 minutes)

1. Once project is ready, you should see the dashboard
2. On the left sidebar, click **"SQL Editor"** (icon looks like `</>`)
3. Click **"New query"** button (top right)
4. **Open the database schema file**:
   - On your computer, navigate to your project folder
   - Open `database/schema.sql` file
   - **Select ALL content** (Cmd+A on Mac, Ctrl+A on Windows)
   - **Copy** (Cmd+C / Ctrl+C)
5. **Back in Supabase SQL Editor**:
   - **Paste** the entire schema into the editor (Cmd+V / Ctrl+V)
   - Click **"Run"** button (bottom right)
6. ✅ You should see: **"Success. No rows returned"**
7. **Verify tables were created**:
   - Click **"Table Editor"** in left sidebar
   - You should see these tables:
     - ✅ users
     - ✅ todos
     - ✅ subtasks
     - ✅ shopping_items
     - ✅ appointment_notes
     - ✅ user_groups
     - ✅ group_members
     - ✅ shared_todos

## Step 4: Enable Email Authentication (1 minute)

1. In left sidebar, click **"Authentication"**
2. Click **"Providers"** tab
3. Find **"Email"** in the list
4. Make sure it's **ENABLED** (toggle should be ON/green)
5. **Scroll down** and check settings:
   - ✅ "Enable email confirmations" - can be OFF for testing (ON for production)
   - ✅ "Enable email signups" - should be ON
6. Click **"Save"** if you made any changes

## Step 5: Get API Credentials (1 minute)

1. Click **"Settings"** icon (⚙️) in left sidebar (bottom area)
2. Click **"API"** in the settings menu
3. **Find and copy these two values**:

   **A. Project URL**
   - Look for section "Project URL"
   - It looks like: `https://xxxxxxxxxxxxx.supabase.co`
   - Click the **copy icon** next to it
   - **SAVE THIS** - you'll need it in next step

   **B. Project API keys - anon/public**
   - Scroll down to "Project API keys"
   - Find the **"anon" "public"** key (NOT the service_role key!)
   - It's a LONG string starting with `eyJ...`
   - Click the **copy icon** next to it
   - **SAVE THIS** - you'll need it in next step

⚠️ **IMPORTANT**:
- Use the `anon` / `public` key, NOT the `service_role` key
- The service_role key should never be used in client apps

## Step 6: Configure Your Flutter App (2 minutes)

1. **Open your project** in VS Code or your preferred editor
2. **Navigate to**: `lib/core/constants/supabase_config.dart`
3. **Find these lines** (around line 10-20):
   ```dart
   static const String supabaseUrl = String.fromEnvironment(
     'SUPABASE_URL',
     defaultValue: 'YOUR_SUPABASE_URL_HERE',
   );

   static const String supabaseAnonKey = String.fromEnvironment(
     'SUPABASE_ANON_KEY',
     defaultValue: 'YOUR_SUPABASE_ANON_KEY_HERE',
   );
   ```

4. **Replace the placeholder values** with your actual credentials:
   ```dart
   static const String supabaseUrl = String.fromEnvironment(
     'SUPABASE_URL',
     defaultValue: 'https://xxxxxxxxxxxxx.supabase.co', // ← Paste your URL here
   );

   static const String supabaseAnonKey = String.fromEnvironment(
     'SUPABASE_ANON_KEY',
     defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...', // ← Paste your anon key here
   );
   ```

5. **Save the file** (Cmd+S / Ctrl+S)

## Step 7: Run the App (2 minutes)

1. **Open terminal** in your project folder
2. **Check connected devices**:
   ```bash
   flutter devices
   ```
   You should see at least one device listed

3. **Run the app**:
   ```bash
   flutter run
   ```

4. ⏱️ **Wait for build** (first build takes 2-5 minutes)
5. ✅ **App should launch!**

## Step 8: Test Registration (2 minutes)

1. **On the login screen**, click **"Sign Up"**
2. **Fill in the form**:
   - Full Name: Your name
   - Email: Use a real email (or test email like `test@test.com` if email confirmation is OFF)
   - Password: At least 6 characters
   - Confirm Password: Same password
3. **Click "Sign Up"**
4. ✅ **Success**: You should see "Account created successfully!" and be taken to the calendar

### If you get an error:
- Check the error message
- Common issues:
  - "Failed to connect" → Check your internet connection
  - "Invalid API key" → Double-check your credentials in `supabase_config.dart`
  - "Email already exists" → Try a different email

## Step 9: Test Creating Todos (2 minutes)

1. **On the calendar**, tap any date
2. **Tap the "+" button** (floating action button)
3. **Fill in the form**:
   - Title: "Test Task"
   - Description: "This is my first task"
   - Date: Today
   - Type: Personal
   - Priority: Medium (P3)
4. **Click "Create"**
5. ✅ **Success**: Task should appear in the list for that date

## Step 10: Verify Database (1 minute)

1. **Go back to Supabase dashboard**
2. **Click "Table Editor"** → **"todos"** table
3. ✅ You should see your test task in the database!
4. **Click "users"** table
5. ✅ You should see your user account

## Step 11: Test Other Features

### Test Task Completion
1. Tap the **checkbox** next to a task
2. Task should show as completed (strikethrough)

### Test Task Deletion
1. Tap the **trash icon** on a task
2. Confirm deletion
3. Task should disappear

### Test Logout
1. Tap the **menu icon** (three dots) in app bar
2. Select **"Logout"**
3. You should return to login screen

### Test Login
1. Enter your credentials
2. Click **"Log In"**
3. You should see your calendar and tasks

## Troubleshooting

### Error: "Supabase URL not found" or "Invalid credentials"
**Solution**:
1. Open `lib/core/constants/supabase_config.dart`
2. Make sure you replaced BOTH placeholders
3. Check there are no extra spaces or quotes
4. Save the file
5. Stop the app and run `flutter run` again

### Error: "Permission denied"
**Solution**:
1. Go to Supabase → SQL Editor
2. Re-run the entire `database/schema.sql` file
3. Check that RLS policies were created

### Error: "Email not confirmed"
**Solution**:
1. Supabase → Authentication → Settings
2. Turn OFF "Enable email confirmations" for testing
3. Try registering again

### App won't build
**Solution**:
```bash
flutter clean
flutter pub get
flutter run
```

### Cannot connect to device
**Solution**:
- iOS: Open Xcode, make sure simulator is running
- Android: Open Android Studio, start an emulator
- Then try `flutter run` again

## Success Checklist

✅ Supabase project created
✅ Database schema executed successfully
✅ All 8 tables visible in Table Editor
✅ Email authentication enabled
✅ API credentials copied
✅ `supabase_config.dart` updated with real credentials
✅ App builds and runs without errors
✅ Successfully registered a new account
✅ Successfully created a task
✅ Task visible in Supabase database
✅ Successfully completed/deleted tasks
✅ Successfully logged out and logged in

## Next Steps

Once everything is working:

1. **Explore the app**:
   - Create tasks with different types
   - Try different priority levels
   - Switch between calendar views (month/week)

2. **Check the database**:
   - See how data is stored in Supabase
   - Try the "Table Editor" to view raw data

3. **Plan next phase**:
   - Ready to implement Phase 2 (smart notifications)?
   - Want to add custom features?

## Need Help?

If you get stuck:
1. Check the error message carefully
2. Review this guide
3. Check `database/README.md`
4. Check main `README.md`
5. Ask for help with the specific error message

Congratulations! Your Family Planner app is now running! 🎉
