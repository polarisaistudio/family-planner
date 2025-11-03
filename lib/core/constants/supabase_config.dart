/// Supabase configuration constants
///
/// IMPORTANT: Before running the app, you need to:
/// 1. Create a Supabase project at https://supabase.com
/// 2. Copy .env.example to .env
/// 3. Fill in your Supabase URL and anon key in the .env file
/// 4. For production, use environment variables or a secure method
class SupabaseConfig {
  // TODO: Replace these with your actual Supabase credentials
  // For now, these are placeholders that should be replaced before running
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://pvfrozgxhlbypmsaftet.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB2ZnJvemd4aGxieXBtc2FmdGV0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIwMTU1MTksImV4cCI6MjA3NzU5MTUxOX0.D47czfWQbbykJ87UrCywV1M_9XiumNt6eoPYIIHjgrw',
  );

  // Table names
  static const String usersTable = 'users';
  static const String todosTable = 'todos';
  static const String subtasksTable = 'subtasks';
  static const String shoppingItemsTable = 'shopping_items';
  static const String appointmentNotesTable = 'appointment_notes';
  static const String userGroupsTable = 'user_groups';
  static const String groupMembersTable = 'group_members';
  static const String sharedTodosTable = 'shared_todos';
}
