class AppConstants {
  // App Info
  static const String appName = 'Advanced Diary App';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String diaryEntriesCollection = 'diary_entries';
  static const String usersCollection = 'users';

  // Shared Preferences Keys
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String themeKey = 'theme_mode';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double iconSize = 24.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Validation
  static const int maxTitleLength = 100;
  static const int maxContentLength = 5000;
  static const int previewContentLength = 50;

  // Date Formats
  static const String dateFormat = 'yyyy/MM/dd';
  static const String timeFormat = 'HH:mm';
  static const String fullDateTimeFormat = 'yyyy年MM月dd日 HH:mm';
}
