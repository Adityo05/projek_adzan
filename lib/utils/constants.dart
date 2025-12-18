/// Konstanta aplikasi
class AppConstants {
  // Nama aplikasi
  static const String appName = 'Projek Adzan';
  static const String appVersion = '1.0.0';

  // Channel names
  static const String locationChannel = 'com.example.azan/location';
  static const String alarmChannel = 'com.example.azan/alarm';
  static const String audioChannel = 'com.example.azan/audio';
  static const String foregroundChannel = 'com.example.azan/foreground';

  // Notification channels
  static const String azanNotificationChannel = 'azan_channel';
  static const String foregroundNotificationChannel = 'foreground_channel';

  // Notification IDs
  static const int azanNotificationId = 1;
  static const int foregroundNotificationId = 2;

  // SharedPreferences keys
  static const String prefLocation = 'user_location';
  static const String prefMethod = 'calculation_method';
  static const String prefMadhab = 'madhab';
  static const String prefAlarmSettings = 'alarm_settings';
  static const String prefAudioVolume = 'audio_volume';
  static const String prefSelectedAzan = 'selected_azan';
  static const String prefFajrAzan = 'fajr_azan';

  // Default values
  static const double defaultLatitude = -6.2088;
  static const double defaultLongitude = 106.8456;
  static const double defaultVolume = 0.8;
  static const String defaultAzan = 'azan_makkah';
  static const String defaultFajrAzan = 'azan_fajr';

  // Makkah coordinates
  static const double makkahLatitude = 21.4225;
  static const double makkahLongitude = 39.8262;

  // Time constants
  static const int alarmAdvanceMinutes = 0;
  static const int reminderAdvanceMinutes = 15;

  // UI constants
  static const double borderRadius = 16.0;
  static const double cardElevation = 8.0;
  static const double iconSize = 32.0;
}
