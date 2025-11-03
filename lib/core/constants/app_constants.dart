/// Application-wide constants
class AppConstants {
  // App Info
  static const String appName = 'Family Planner';
  static const String appVersion = '1.0.0';

  // Priority Levels
  static const int priorityUrgent = 1;
  static const int priorityHigh = 2;
  static const int priorityMedium = 3;
  static const int priorityLow = 4;
  static const int priorityNone = 5;

  // Todo Types
  static const String todoTypeAppointment = 'appointment';
  static const String todoTypeWork = 'work';
  static const String todoTypeShopping = 'shopping';
  static const String todoTypePersonal = 'personal';
  static const String todoTypeOther = 'other';

  // Todo Status
  static const String statusPending = 'pending';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // Notification Settings
  static const int appointmentReminderMinutes = 120; // 2 hours
  static const int workReminderMinutes = 30;
  static const int shoppingReminderMinutes = 60;

  // Shared Preferences Keys
  static const String keyLanguage = 'language_preference';
  static const String keyThemeMode = 'theme_mode';
  static const String keyUserId = 'user_id';
}
