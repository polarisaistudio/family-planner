# Quick Start - Family Planner

## ⚡ 5-Minute Setup

### 1. Create Supabase Account (1 min)
🔗 Go to: **https://supabase.com** → Sign up

### 2. Create Project (1 min)
- Click "New Project"
- Name: `family-planner`
- Password: Choose strong password & save it
- Region: Choose closest
- Wait ~2 minutes

### 3. Run Database Schema (1 min)
1. Supabase Dashboard → **SQL Editor** → **New query**
2. Open `database/schema.sql` on your computer
3. Copy ALL content → Paste in SQL Editor
4. Click **Run**
5. ✅ Success!

### 4. Get Credentials (30 sec)
1. Supabase → **Settings** → **API**
2. Copy two values:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: `eyJ...` (the LONG one)

### 5. Configure App (30 sec)
1. Open: `lib/core/constants/supabase_config.dart`
2. Replace placeholders:
   ```dart
   defaultValue: 'https://your-project.supabase.co',  // ← Your URL
   defaultValue: 'eyJhbGc...',  // ← Your anon key
   ```
3. Save file

### 6. Enable Email Auth (30 sec)
1. Supabase → **Authentication** → **Providers**
2. Make sure **Email** is ON (enabled)
3. Save if needed

### 7. Run App (30 sec)
```bash
flutter run
```

## ✅ Quick Test

1. **Sign Up**: Create account with any email
2. **Add Task**: Click + button
3. **Done!** Your app is working!

## 🔍 Verify Setup

Run this before starting:
```bash
./verify_setup.sh
```

## 📚 Need More Help?

- Detailed guide: `SETUP_GUIDE.md`
- Database help: `database/README.md`
- Full docs: `README.md`

## 🆘 Common Issues

**Error: "Invalid credentials"**
→ Check `supabase_config.dart` has correct URL and key

**Error: "Permission denied"**
→ Re-run `database/schema.sql` in Supabase

**No devices found**
→ Start iOS Simulator or Android Emulator

## 🎯 What You'll Have

- ✅ User authentication
- ✅ Calendar view
- ✅ Create/edit/delete tasks
- ✅ 5 priority levels
- ✅ 5 task types
- ✅ Cloud sync with Supabase

Ready to build! 🚀
