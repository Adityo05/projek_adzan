import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

/// Service untuk mengelola background task menggunakan WorkManager
/// Task ini akan berjalan setiap tengah malam untuk fetch jadwal dan schedule alarm
class BackgroundService {
  static const String taskName = 'refreshPrayerSchedule';
  static const String uniqueTaskName = 'com.example.azan.refreshSchedule';

  /// Initialize WorkManager
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  /// Register periodic task untuk refresh setiap hari
  static Future<void> registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      uniqueTaskName,
      taskName,
      frequency: const Duration(hours: 24),
      initialDelay: _calculateInitialDelay(),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  /// Hitung delay sampai tengah malam berikutnya
  static Duration _calculateInitialDelay() {
    final now = DateTime.now();
    final midnight = DateTime(
      now.year,
      now.month,
      now.day + 1,
      0,
      5,
    ); // 00:05 untuk margin
    return midnight.difference(now);
  }

  /// Cancel task
  static Future<void> cancelTask() async {
    await Workmanager().cancelByUniqueName(uniqueTaskName);
  }
}

/// Callback yang dipanggil oleh WorkManager di background
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == BackgroundService.taskName) {
      try {
        // Get stored location from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final locationJson = prefs.getString('saved_location');

        if (locationJson != null) {
          final locationData = jsonDecode(locationJson);
          final latitude = locationData['latitude'] as double;
          final longitude = locationData['longitude'] as double;

          // Call native method to fetch and schedule
          const channel = MethodChannel('com.example.azan/alarm');
          await channel.invokeMethod('refreshDailySchedule', {
            'latitude': latitude,
            'longitude': longitude,
          });
        }

        return true;
      } catch (e) {
        print('Background task error: $e');
        return false;
      }
    }
    return false;
  });
}
