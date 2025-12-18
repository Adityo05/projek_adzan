import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_model.dart';
import '../models/prayer_time.dart';

/// Service untuk mengelola penyimpanan data lokal menggunakan SharedPreferences
///
/// Menyimpan:
/// - Lokasi pengguna
/// - Pengaturan alarm
/// - Pengaturan audio
/// - Jadwal sholat ter-cache
class StorageService {
  static const String _keyLocation = 'user_location';
  static const String _keyAlarmSettings = 'alarm_settings';
  static const String _keyAudioVolume = 'audio_volume';
  static const String _keySelectedAzan = 'selected_azan';
  static const String _keyFajrAzan = 'fajr_azan';
  static const String _keyCachedSchedule = 'cached_schedule';
  static const String _keyFirstRun = 'first_run';
  static const String _keyNotificationEnabled = 'notification_enabled';
  static const String _keyVibrationEnabled = 'vibration_enabled';

  SharedPreferences? _prefs;

  /// Inisialisasi SharedPreferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Memastikan prefs sudah diinisialisasi
  Future<SharedPreferences> _getPrefs() async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  // ==================== LOKASI ====================

  /// Menyimpan lokasi pengguna
  Future<bool> saveLocation(LocationModel location) async {
    final prefs = await _getPrefs();
    return prefs.setString(_keyLocation, jsonEncode(location.toJson()));
  }

  /// Mengambil lokasi pengguna
  Future<LocationModel?> getLocation() async {
    final prefs = await _getPrefs();
    final json = prefs.getString(_keyLocation);
    if (json == null) return null;

    try {
      return LocationModel.fromJson(jsonDecode(json));
    } catch (e) {
      return null;
    }
  }

  // ==================== PENGATURAN ALARM ====================

  /// Menyimpan pengaturan alarm untuk setiap waktu sholat
  Future<bool> saveAlarmSettings(Map<PrayerType, bool> settings) async {
    final prefs = await _getPrefs();
    final map = settings.map(
      (key, value) => MapEntry(key.index.toString(), value),
    );
    return prefs.setString(_keyAlarmSettings, jsonEncode(map));
  }

  /// Mengambil pengaturan alarm
  Future<Map<PrayerType, bool>> getAlarmSettings() async {
    final prefs = await _getPrefs();
    final json = prefs.getString(_keyAlarmSettings);

    if (json == null) {
      // Default: semua alarm aktif kecuali sunrise
      return {
        PrayerType.fajr: true,
        PrayerType.sunrise: false,
        PrayerType.dhuhr: true,
        PrayerType.asr: true,
        PrayerType.maghrib: true,
        PrayerType.isha: true,
      };
    }

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return map.map(
        (key, value) =>
            MapEntry(PrayerType.values[int.parse(key)], value as bool),
      );
    } catch (e) {
      return {
        PrayerType.fajr: true,
        PrayerType.sunrise: false,
        PrayerType.dhuhr: true,
        PrayerType.asr: true,
        PrayerType.maghrib: true,
        PrayerType.isha: true,
      };
    }
  }

  // ==================== PENGATURAN AUDIO ====================

  /// Menyimpan volume audio
  Future<bool> saveAudioVolume(double volume) async {
    final prefs = await _getPrefs();
    return prefs.setDouble(_keyAudioVolume, volume);
  }

  /// Mengambil volume audio
  Future<double> getAudioVolume() async {
    final prefs = await _getPrefs();
    return prefs.getDouble(_keyAudioVolume) ?? 0.8;
  }

  /// Menyimpan file azan yang dipilih
  Future<bool> saveSelectedAzan(String azanName) async {
    final prefs = await _getPrefs();
    return prefs.setString(_keySelectedAzan, azanName);
  }

  /// Mengambil file azan yang dipilih
  Future<String> getSelectedAzan() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keySelectedAzan) ?? 'Adzan';
  }

  /// Menyimpan file azan untuk Subuh (berbeda dengan waktu lain)
  Future<bool> saveFajrAzan(String azanName) async {
    final prefs = await _getPrefs();
    return prefs.setString(_keyFajrAzan, azanName);
  }

  /// Mengambil file azan untuk Subuh
  Future<String> getFajrAzan() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyFajrAzan) ?? 'Adzan_subuh';
  }

  // ==================== CACHE JADWAL ====================

  /// Menyimpan jadwal sholat ter-cache
  Future<bool> saveCachedSchedule(List<DailyPrayerSchedule> schedules) async {
    final prefs = await _getPrefs();
    final list = schedules.map((s) => s.toJson()).toList();
    return prefs.setString(_keyCachedSchedule, jsonEncode(list));
  }

  /// Mengambil jadwal sholat ter-cache
  Future<List<DailyPrayerSchedule>> getCachedSchedule() async {
    final prefs = await _getPrefs();
    final json = prefs.getString(_keyCachedSchedule);
    if (json == null) return [];

    try {
      final list = jsonDecode(json) as List;
      return list
          .map(
            (item) =>
                DailyPrayerSchedule.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== PENGATURAN UMUM ====================

  /// Mengecek apakah ini pertama kali aplikasi dijalankan
  Future<bool> isFirstRun() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyFirstRun) ?? true;
  }

  /// Menandai bahwa aplikasi sudah pernah dijalankan
  Future<bool> setFirstRunComplete() async {
    final prefs = await _getPrefs();
    return prefs.setBool(_keyFirstRun, false);
  }

  /// Menyimpan pengaturan notifikasi
  Future<bool> saveNotificationEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    return prefs.setBool(_keyNotificationEnabled, enabled);
  }

  /// Mengambil pengaturan notifikasi
  Future<bool> getNotificationEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyNotificationEnabled) ?? true;
  }

  /// Menyimpan pengaturan getar
  Future<bool> saveVibrationEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    return prefs.setBool(_keyVibrationEnabled, enabled);
  }

  /// Mengambil pengaturan getar
  Future<bool> getVibrationEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyVibrationEnabled) ?? true;
  }

  /// Menghapus semua data
  Future<bool> clearAll() async {
    final prefs = await _getPrefs();
    return prefs.clear();
  }
}
