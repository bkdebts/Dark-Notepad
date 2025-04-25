class AppConstants {
  AppConstants._();
  
  // Shared Preferences Keys
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keyUserEmail = 'user_email';
  static const String keyUserId = 'user_id';
  static const String keyAppLockEnabled = 'app_lock_enabled';
  static const String keyAutoSyncEnabled = 'auto_sync_enabled';
  static const String keyRemindersEnabled = 'reminders_enabled';
  static const String keyCloudSyncEnabled = 'cloud_sync_enabled';
  static const String keyFontSize = 'font_size';
  static const String keyLastSyncTime = 'last_sync_time';
  
  // Collection names for Firestore
  static const String usersCollection = 'users';
  static const String notesCollection = 'notes';
  
  // Secure storage keys
  static const String keyAppLockPin = 'app_lock_pin';
  
  // Fonts
  static const List<String> availableFonts = [
    'Roboto',
    'Poppins',
    'Lato',
    'Montserrat',
    'Open Sans',
    'Playfair Display',
    'Merriweather',
  ];
  
  // Routes
  static const String splashRoute = '/';
  static const String homeRoute = '/home';
  static const String editorRoute = '/editor';
  static const String settingsRoute = '/settings';
  static const String authRoute = '/auth';
  static const String lockRoute = '/lock';
  
  // Error messages
  static const String errorAuth = 'Authentication failed. Please try again.';
  static const String errorNetworkConnection = 'Network connection issue. Please check your internet connection.';
  static const String errorCloudSync = 'Failed to sync with cloud. Will retry automatically.';
  static const String errorSaveNote = 'Failed to save note. Please try again.';
  static const String errorLoadNote = 'Failed to load note. Please try again.';
  static const String errorPdfExport = 'Failed to export as PDF. Please try again.';
  static const String errorFileAccess = 'Cannot access file system. Please check app permissions.';
  
  // Success messages
  static const String successSaveNote = 'Note saved successfully.';
  static const String successCloudSync = 'Synced with cloud successfully.';
  static const String successPdfExport = 'PDF exported successfully.';
  static const String successSignIn = 'Signed in successfully.';
  static const String successSignUp = 'Account created successfully.';
  static const String successSignOut = 'Signed out successfully.';
  
  // Animation durations
  static const int splashDuration = 2000;
  static const int cardAnimationDuration = 300;
  static const int pageTransitionDuration = 300;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double noteBorderRadius = 16.0;
  static const double buttonBorderRadius = 12.0;
}
