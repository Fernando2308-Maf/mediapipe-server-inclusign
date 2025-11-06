class AppConstants {
  // API Configuration
  // Production (Railway): 'https://inclusing-production.up.railway.app/api'
  // Windows/Web: 'http://localhost:5246/api'
  // Android Emulator: 'http://10.0.2.2:5246/api'
  static const String baseUrl = 'http://localhost:5246/api';

  // Storage Keys
  static const String keyUserToken = 'user_token';
  static const String keyUserEmail = 'user_email';
  static const String keyIsGuest = 'is_guest';
  static const String keyIsNewUser = 'is_new_user';
  static const String keyRememberMe = 'remember_me';

  // App Info
  static const String appName = 'Inclusign';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Aprende lenguaje de señas de forma divertida e interactiva';

  // Default Values
  static const int defaultDailyGoal = 5;
  static const int defaultExperiencePerLesson = 10;
  static const int minPasswordLength = 6;

  // Timeout
  static const Duration requestTimeout = Duration(seconds: 120);

  // Guest User
  static const String guestEmail = 'guest@inclusign.com';
  static const String guestToken = 'guest_token';
}
