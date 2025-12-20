import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../models/prayer_time.dart';
import '../models/location_model.dart';

/// Service untuk mengambil waktu sholat dari API Aladhan
/// API Documentation: https://aladhan.com/prayer-times-api
class PrayerApiService {
  static const String _baseUrl = 'https://api.aladhan.com/v1';

  static const int kemenagMethod = 20;
  static const int mwlMethod = 3;
  static const int ummAlQuraMethod = 4;
  static const int isnaMethod = 2;

  int _currentMethod = kemenagMethod;

  void setMethod(int method) {
    _currentMethod = method;
  }

  /// Mendapatkan waktu sholat untuk hari ini berdasarkan koordinat
  Future<DailyPrayerSchedule?> getPrayerTimes({
    required double latitude,
    required double longitude,
    DateTime? date,
  }) async {
    try {
      final targetDate = date ?? DateTime.now();
      final timestamp = targetDate.millisecondsSinceEpoch ~/ 1000;

      final url =
          '$_baseUrl/timings/$timestamp'
          '?latitude=$latitude'
          '&longitude=$longitude'
          '&method=$_currentMethod';

      debugPrint('Fetching prayer times from: $url');

      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 10);

      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = json.decode(responseBody);

        if (data['code'] == 200 && data['data'] != null) {
          return _parsePrayerTimes(data['data'], targetDate);
        }
      }

      debugPrint('API Error: Status ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error fetching prayer times: $e');
      return null;
    }
  }

  /// Mendapatkan waktu sholat berdasarkan nama kota
  Future<DailyPrayerSchedule?> getPrayerTimesByCity({
    required String city,
    required String country,
    DateTime? date,
  }) async {
    try {
      final targetDate = date ?? DateTime.now();
      final dateStr =
          '${targetDate.day.toString().padLeft(2, '0')}-'
          '${targetDate.month.toString().padLeft(2, '0')}-'
          '${targetDate.year}';

      final url =
          '$_baseUrl/timingsByCity/$dateStr'
          '?city=${Uri.encodeComponent(city)}'
          '&country=${Uri.encodeComponent(country)}'
          '&method=$_currentMethod';

      debugPrint('Fetching prayer times from: $url');

      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = json.decode(responseBody);

        if (data['code'] == 200 && data['data'] != null) {
          return _parsePrayerTimes(data['data'], targetDate);
        }
      }

      debugPrint('API Error: Status ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error fetching prayer times: $e');
      return null;
    }
  }

  /// Parse response dari API menjadi DailyPrayerSchedule
  DailyPrayerSchedule _parsePrayerTimes(
    Map<String, dynamic> data,
    DateTime date,
  ) {
    final timings = data['timings'] as Map<String, dynamic>;
    final meta = data['meta'] as Map<String, dynamic>?;

    // Debug: print all timings
    debugPrint('Prayer Timings: $timings');

    final prayers = <PrayerTime>[
      _createPrayerTime(PrayerType.fajr, date, timings['Fajr'] as String),
      _createPrayerTime(PrayerType.sunrise, date, timings['Sunrise'] as String),
      _createPrayerTime(PrayerType.dhuhr, date, timings['Dhuhr'] as String),
      _createPrayerTime(PrayerType.asr, date, timings['Asr'] as String),
      _createPrayerTime(PrayerType.maghrib, date, timings['Maghrib'] as String),
      _createPrayerTime(PrayerType.isha, date, timings['Isha'] as String),
    ];

    return DailyPrayerSchedule(date: date, prayers: prayers);
  }

  /// Membuat PrayerTime dari string waktu (format "HH:mm" atau "HH:mm (timezone)")
  PrayerTime _createPrayerTime(
    PrayerType type,
    DateTime date,
    String timeString,
  ) {
    // Remove timezone info if present (e.g., "04:30 (WIB)" -> "04:30")
    final cleanTime = timeString.split(' ').first;
    final parts = cleanTime.split(':');

    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final time = DateTime(date.year, date.month, date.day, hour, minute);

    return PrayerTime(type: type, time: time, adjustmentMinutes: 0);
  }

  /// Menghitung arah kiblat dari lokasi tertentu
  double calculateQiblaDirection(LocationModel location) {
    const double deg2rad = 3.141592653589793 / 180.0;
    const double rad2deg = 180.0 / 3.141592653589793;

    final lat1 = location.latitude * deg2rad;
    final lng1 = location.longitude * deg2rad;
    final lat2 = 21.4225 * deg2rad; // Makkah latitude
    final lng2 = 39.8262 * deg2rad; // Makkah longitude

    final dLng = lng2 - lng1;
    final y = (dLng).abs() < 0.0001
        ? 0.0
        : (lat1.abs() < 0.0001
              ? (dLng > 0 ? 1.0 : -1.0) * 1e10
              : (lng1 < lng2 ? 1.0 : -1.0) *
                    (lat2 - lat1).abs() /
                    (dLng).abs());

    // Simplified calculation
    final sinDLng = (dLng).abs() < 1e-10
        ? 0.0
        : (dLng) / (dLng).abs() * (1 - (dLng * dLng / 6));

    final x = (lat2 - lat1) * (1 + (lat1 * lat1 / 2));

    var bearing =
        (90 -
        (lat2 > lat1 ? 1 : -1) *
            (90 * (dLng.abs() / (dLng.abs() + (lat2 - lat1).abs()))));

    if (dLng < 0) bearing = 360 - bearing;

    return bearing % 360;
  }

  /// Menghitung jarak ke Makkah dalam kilometer
  double calculateDistanceToMakkah(LocationModel location) {
    const double R = 6371.0; // Earth radius in km
    const double deg2rad = 3.141592653589793 / 180.0;

    final lat1 = location.latitude * deg2rad;
    final lng1 = location.longitude * deg2rad;
    final lat2 = 21.4225 * deg2rad;
    final lng2 = 39.8262 * deg2rad;

    final dLat = lat2 - lat1;
    final dLng = lng2 - lng1;

    final a =
        _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(lat1) * _cos(lat2) * _sin(dLng / 2) * _sin(dLng / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));

    return R * c;
  }

  // Simple math functions to avoid dart:math import issues
  double _sin(double x) => x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  double _cos(double x) => 1 - (x * x) / 2 + (x * x * x * x) / 24;
  double _sqrt(double x) => x > 0 ? _newtonSqrt(x, x / 2, 10) : 0;
  double _newtonSqrt(double n, double guess, int iterations) {
    if (iterations <= 0) return guess;
    return _newtonSqrt(n, (guess + n / guess) / 2, iterations - 1);
  }

  double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 3.141592653589793 / 2;
    if (x == 0 && y < 0) return -3.141592653589793 / 2;
    return 0;
  }

  double _atan(double x) => x - (x * x * x) / 3 + (x * x * x * x * x) / 5;
}
