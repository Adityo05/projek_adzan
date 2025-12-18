import 'package:flutter/services.dart';
import '../models/prayer_time.dart';

/// Service untuk mengelola alarm waktu sholat
class AlarmService {
  static const MethodChannel _channel = MethodChannel('com.example.azan/alarm');

  static const int _fajrCode = 1001;
  static const int _sunriseCode = 1002;
  static const int _dhuhrCode = 1003;
  static const int _asrCode = 1004;
  static const int _maghribCode = 1005;
  static const int _ishaCode = 1006;

  int _getCode(PrayerType type) {
    switch (type) {
      case PrayerType.fajr:
        return _fajrCode;
      case PrayerType.sunrise:
        return _sunriseCode;
      case PrayerType.dhuhr:
        return _dhuhrCode;
      case PrayerType.asr:
        return _asrCode;
      case PrayerType.maghrib:
        return _maghribCode;
      case PrayerType.isha:
        return _ishaCode;
    }
  }

  Future<bool> requestExactAlarmPermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestExactAlarmPermission') ??
          false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> canScheduleExactAlarms() async {
    try {
      return await _channel.invokeMethod<bool>('canScheduleExactAlarms') ??
          false;
    } catch (e) {
      return false;
    }
  }

  /// Trigger a short vibration for haptic feedback
  Future<void> vibrate({int durationMs = 50}) async {
    try {
      await _channel.invokeMethod('vibrate', {'duration': durationMs});
    } catch (e) {
      // Ignore errors
    }
  }

  Future<bool> scheduleAlarm({
    required PrayerTime prayer,
    required String azanFile,
    bool vibrate = true,
  }) async {
    if (prayer.hasPassed) return false;
    try {
      return await _channel.invokeMethod<bool>('scheduleAlarm', {
            'requestCode': _getCode(prayer.type),
            'time': prayer.adjustedTime.millisecondsSinceEpoch,
            'prayerName': prayer.type.nameId,
            'azanFile': azanFile,
            'vibrate': vibrate,
          }) ??
          false;
    } catch (e) {
      return false;
    }
  }

  /// Schedule reminder notification 5 minutes before prayer time
  Future<bool> scheduleReminder({required PrayerTime prayer}) async {
    final reminderTime = prayer.adjustedTime.subtract(
      const Duration(minutes: 5),
    );
    if (reminderTime.isBefore(DateTime.now())) return false;

    try {
      return await _channel.invokeMethod<bool>('scheduleReminder', {
            'requestCode':
                _getCode(prayer.type) + 100, // Different request code
            'time': reminderTime.millisecondsSinceEpoch,
            'prayerName': prayer.type.nameId,
          }) ??
          false;
    } catch (e) {
      return false;
    }
  }

  Future<int> scheduleAllAlarms({
    required DailyPrayerSchedule schedule,
    required Map<PrayerType, bool> settings,
    required String defaultAzan,
    required String fajrAzan,
    bool vibrate = true,
    bool showReminder = true,
  }) async {
    // Cancel all reminders first if reminder is disabled
    if (!showReminder) {
      await cancelAllReminders();
    }

    int count = 0;
    for (final prayer in schedule.prayers) {
      if (!(settings[prayer.type] ?? true) || prayer.hasPassed) continue;
      final azan = prayer.type == PrayerType.fajr ? fajrAzan : defaultAzan;
      if (await scheduleAlarm(
        prayer: prayer,
        azanFile: azan,
        vibrate: vibrate,
      )) {
        count++;
      }
      // Schedule reminder if enabled
      if (showReminder && prayer.type != PrayerType.sunrise) {
        await scheduleReminder(prayer: prayer);
      }
    }
    return count;
  }

  Future<bool> cancelAlarm(PrayerType type) async {
    try {
      return await _channel.invokeMethod<bool>('cancelAlarm', {
            'requestCode': _getCode(type),
          }) ??
          false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelAllAlarms() async {
    try {
      return await _channel.invokeMethod<bool>('cancelAllAlarms') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Cancel all scheduled reminders
  Future<bool> cancelAllReminders() async {
    try {
      return await _channel.invokeMethod<bool>('cancelAllReminders') ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> stopAzan() async {
    try {
      return await _channel.invokeMethod<bool>('stopAzan') ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> testAzan(String azanFile) async {
    try {
      return await _channel.invokeMethod<bool>('testAzan', {
            'azanFile': azanFile,
          }) ??
          false;
    } catch (e) {
      return false;
    }
  }

  Future<void> requestDeviceSpecificPermissions() async {
    try {
      await _channel.invokeMethod('requestDeviceSpecificPermissions');
    } catch (_) {}
  }

  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      return await _channel.invokeMethod<bool>(
            'isIgnoringBatteryOptimizations',
          ) ??
          false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      return await _channel.invokeMethod<bool>(
            'requestIgnoreBatteryOptimizations',
          ) ??
          false;
    } catch (e) {
      return false;
    }
  }

  Future<void> showAutoStartSettings() async {
    try {
      await _channel.invokeMethod('showAutoStartSettings');
    } catch (_) {}
  }
}
