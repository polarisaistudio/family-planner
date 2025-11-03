# Family Planner

A smart family planner app with AI-powered scheduling and multi-language support. Plan together, achieve together!

## Features

### Phase 1 (Current Implementation)
✅ User authentication (email/password signup and login)
✅ Calendar view with monthly/weekly/daily formats
✅ Create, read, update, and delete (CRUD) todos
✅ Todo types: Appointment, Work, Shopping, Personal, Other
✅ Priority levels (P1-P5: Urgent to None)
✅ Task completion tracking
✅ Real-time database synchronization with Supabase
✅ Clean architecture with Riverpod state management

### Upcoming Features (Phases 2-7)
🔜 Smart notifications based on location, traffic, and weather
🔜 Sub-tasks and nested organization (shopping lists, appointment notes)
🔜 Multi-language support (English & Chinese)
🔜 Real-time family sharing and collaboration
🔜 Cross-language translation for shared events
🔜 AI agent for natural language task creation (text & audio)
🔜 Web interface

## Tech Stack

- **Frontend**: Flutter 3.10.6
- **State Management**: Riverpod 2.5.0
- **Backend**: Supabase (Database, Auth, Real-time)
- **Calendar**: TableCalendar
- **Architecture**: Clean Architecture (Domain, Data, Presentation layers)

## Project Structure

```
lib/
├── core/
│   ├── constants/          # App constants and config
│   ├── themes/             # App theming
│   └── utils/              # Utility functions
├── features/
│   ├── auth/               # Authentication feature
│   │   ├── data/           # Models & repositories implementation
│   │   ├── domain/         # Entities & repository interfaces
│   │   └── presentation/   # UI, providers, pages, widgets
│   ├── calendar/           # Calendar feature
│   │   └── presentation/
│   └── todos/              # Todo management feature
│       ├── data/
│       ├── domain/
│       └── presentation/
└── shared/
    ├── services/           # Shared services (Supabase, etc.)
    └── widgets/            # Reusable widgets
```

## Getting Started

### Prerequisites

- Flutter SDK 3.10.6 or higher
- Dart 3.0.6 or higher
- A Supabase account (free tier works great!)

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd family_planner
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Set Up Supabase

#### Create a Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up or log in
3. Click "New Project"
4. Fill in:
   - **Name**: family-planner
   - **Database Password**: Choose a strong password
   - **Region**: Select closest to your location
5. Wait 1-2 minutes for project creation

#### Get API Credentials

1. Go to Project Settings → API
2. Copy:
   - **Project URL** (under "Project URL")
   - **anon/public key** (under "Project API keys")

#### Configure the App

1. Open `lib/core/constants/supabase_config.dart`
2. Replace the placeholder values:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
```

#### Set Up Database

1. Open Supabase dashboard → SQL Editor
2. Open `database/schema.sql` in this project
3. Copy the entire content and paste into SQL Editor
4. Click "Run"
5. Verify tables are created in Table Editor:
   - users
   - todos
   - subtasks
   - shopping_items
   - appointment_notes
   - user_groups
   - group_members
   - shared_todos

See `database/README.md` for detailed database setup instructions.

### 4. Run the App

```bash
# Run on connected device/emulator
flutter run

# Run on specific device
flutter devices  # List available devices
flutter run -d <device-id>

# Run on iOS simulator
flutter run -d ios

# Run on Android emulator
flutter run -d android
```

## Usage

### First Time Setup

1. **Register**: Click "Sign Up" on the login screen
2. **Fill in details**: Name, email, password
3. **Create account**: You'll be automatically logged in

### Creating a Task

1. **Select a date**: Tap on any date in the calendar
2. **Add task**: Tap the floating "+" button
3. **Fill in details**:
   - Title (required)
   - Description (optional)
   - Date and time
   - Type (Appointment/Work/Shopping/Personal/Other)
   - Priority (P1-P5)
4. **Save**: Click "Create"

### Managing Tasks

- **Complete**: Tap the checkbox next to a task
- **Delete**: Tap the delete icon
- **View**: Tasks are organized by date in the calendar

### Priority Levels

- **P1 (Urgent)**: Critical tasks requiring immediate attention
- **P2 (High)**: Important tasks
- **P3 (Medium)**: Regular tasks (default)
- **P4 (Low)**: Less urgent tasks
- **P5 (None)**: Optional/low-priority tasks

### Task Types

- **Appointment**: Doctor visits, meetings, etc.
- **Work**: Work-related tasks
- **Shopping**: Shopping trips and errands
- **Personal**: Personal activities
- **Other**: Miscellaneous tasks

## Development

### Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/features/auth/auth_test.dart
```

### Code Generation (if needed in future)

```bash
# Generate code for json_serializable, etc.
flutter pub run build_runner build
```

### Linting

```bash
# Analyze code
flutter analyze

# Format code
flutter format lib/
```

## Troubleshooting

### Issue: "Supabase URL not found" or connection errors

**Solution**:
1. Check `lib/core/constants/supabase_config.dart` has correct credentials
2. Ensure URL doesn't have a trailing slash
3. Verify you're using the `anon` key, not the `service_role` key

### Issue: "Permission denied" when accessing database

**Solution**:
1. Verify database schema was run completely
2. Check Row Level Security (RLS) policies in Supabase dashboard
3. Re-run `database/schema.sql`

### Issue: App won't build

**Solution**:
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Issue: "User not authenticated" errors

**Solution**:
1. Log out and log back in
2. Check authentication is properly set up in Supabase (Authentication → Providers → Email)
3. Verify user exists in the `users` table

## Roadmap

### Phase 2: Smart Planning (Weeks 13-15)
- Location-based notifications
- Traffic and weather integration
- Dynamic reminder times

### Phase 3: Sub-tasks (Weeks 16-17)
- Shopping list items
- Appointment notes and questions
- Nested task organization

### Phase 4: Multi-language (Weeks 18-19)
- English & Chinese support
- Language preference settings
- Dynamic content translation

### Phase 5: Family Sharing (Weeks 20-22)
- Create/join family groups
- Share individual events
- Real-time collaboration
- Cross-language viewing

### Phase 6: AI Agent (Weeks 23-25)
- Natural language task creation
- Voice input support
- Smart scheduling suggestions
- Auto-categorization

### Phase 7: Polish & Deploy (Weeks 26-27)
- Performance optimization
- UI/UX enhancements
- App Store & Play Store deployment
- Web version (Vercel)

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Check the `database/README.md` for database-specific help
- Review Supabase documentation at [https://supabase.com/docs](https://supabase.com/docs)

## Acknowledgments

- Flutter team for the amazing framework
- Supabase for the backend infrastructure
- TableCalendar package for calendar functionality
- Riverpod for state management

---

**Built with ❤️ for families who plan together**
