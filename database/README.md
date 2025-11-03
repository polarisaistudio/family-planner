# Database Setup Guide

## Step 1: Create a Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up or log in
3. Click "New Project"
4. Fill in project details:
   - **Name**: family-planner
   - **Database Password**: Choose a strong password
   - **Region**: Select closest to your location
5. Wait for project to be created (takes 1-2 minutes)

## Step 2: Get API Credentials

1. Go to Project Settings → API
2. Copy the following:
   - **Project URL** (under "Project URL")
   - **anon/public key** (under "Project API keys")

## Step 3: Configure the App

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and add your credentials:
   ```
   SUPABASE_URL=your_project_url_here
   SUPABASE_ANON_KEY=your_anon_key_here
   ```

## Step 4: Run Database Schema

1. Open your Supabase project dashboard
2. Go to **SQL Editor** (left sidebar)
3. Click "New query"
4. Copy the entire content of `database/schema.sql`
5. Paste it into the SQL Editor
6. Click "Run" button

This will create:
- All necessary tables
- Row Level Security policies
- Indexes for performance
- Triggers for automatic timestamps
- Auto user profile creation on signup

## Step 5: Verify Setup

1. Go to **Table Editor** in Supabase dashboard
2. You should see these tables:
   - users
   - user_groups
   - group_members
   - todos
   - subtasks
   - shopping_items
   - appointment_notes
   - shared_todos

## Database Schema Overview

### Core Tables

- **users**: User profiles (extends auth.users)
- **todos**: Main task/event items
- **subtasks**: Nested tasks under a todo
- **shopping_items**: Items for shopping-type todos
- **appointment_notes**: Notes for appointment-type todos

### Sharing Tables

- **user_groups**: Family groups
- **group_members**: Users in a group
- **shared_todos**: Individual todo sharing

### Security

All tables have Row Level Security (RLS) enabled:
- Users can only see their own data
- Users can see todos shared with them
- Group owners can manage their groups

## Troubleshooting

### Error: "relation does not exist"
- Make sure you ran the entire schema.sql file
- Check SQL Editor for error messages

### Error: "permission denied"
- RLS policies might not be set correctly
- Re-run the schema.sql file

### Can't connect from app
- Verify `.env` file has correct credentials
- Check that URL doesn't have trailing slash
- Ensure anon key is correct (not the service_role key)

## Next Steps

After database setup:
1. Enable email authentication in Supabase (Authentication → Providers → Email)
2. (Optional) Enable Google sign-in for easier authentication
3. Run the Flutter app and test signup/login
