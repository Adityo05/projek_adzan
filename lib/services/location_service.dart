import 'package:flutter/services.dart';
import '../models/location_model.dart';

/// Service untuk mendapatkan lokasi pengguna menggunakan GPS
///
/// Service ini menggunakan platform channel untuk mengakses GPS
/// karena plugin geolocator memerlukan setup tambahan
class LocationService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.azan/location',
  );

  /// Status permission
  bool _hasPermission = false;

  /// Lokasi terakhir yang didapat
  LocationModel? _lastLocation;

  /// Mendapatkan status permission
  bool get hasPermission => _hasPermission;

  /// Mendapatkan lokasi terakhir
  LocationModel? get lastLocation => _lastLocation;

  /// Meminta izin lokasi
  Future<bool> requestPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPermission');
      _hasPermission = result ?? false;
      return _hasPermission;
    } on PlatformException catch (e) {
      print('Error requesting location permission: ${e.message}');
      return false;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  /// Mengecek status permission
  Future<bool> checkPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkPermission');
      _hasPermission = result ?? false;
      return _hasPermission;
    } on PlatformException catch (e) {
      print('Error checking location permission: ${e.message}');
      return false;
    } catch (e) {
      print('Error checking location permission: $e');
      return false;
    }
  }

  /// Membuka halaman pengaturan aplikasi di sistem
  Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } catch (e) {
      print('Error opening app settings: $e');
    }
  }

  /// Mendapatkan lokasi saat ini
  Future<LocationModel?> getCurrentLocation() async {
    try {
      // Coba dapatkan dari GPS terlebih dahulu
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getCurrentLocation',
      );

      if (result != null) {
        final latitude = (result['latitude'] as num?)?.toDouble();
        final longitude = (result['longitude'] as num?)?.toDouble();
        final altitude = (result['altitude'] as num?)?.toDouble() ?? 0;

        if (latitude != null && longitude != null) {
          _lastLocation = LocationModel(
            latitude: latitude,
            longitude: longitude,
            altitude: altitude,
            lastUpdated: DateTime.now(),
          );

          // Coba dapatkan nama kota (reverse geocoding)
          final cityInfo = await _getCityFromCoordinates(latitude, longitude);
          if (cityInfo != null) {
            _lastLocation = _lastLocation!.copyWith(
              cityName: cityInfo['city'],
              provinceName: cityInfo['province'],
              countryName: cityInfo['country'],
            );
          }

          return _lastLocation;
        }
      }

      return null;
    } on PlatformException catch (e) {
      print('Error getting current location: ${e.message}');
      return null;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Mendapatkan lokasi menggunakan mock data untuk development
  /// atau saat GPS tidak tersedia
  Future<LocationModel> getLocationWithFallback() async {
    // Coba GPS terlebih dahulu
    final gpsLocation = await getCurrentLocation();
    if (gpsLocation != null) {
      return gpsLocation;
    }

    // Gunakan lokasi default jika GPS gagal
    return LocationModel.defaultLocation.copyWith(lastUpdated: DateTime.now());
  }

  /// Mendapatkan nama kota dari koordinat (reverse geocoding)
  /// Menggunakan method channel ke native
  Future<Map<String, String>?> _getCityFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'reverseGeocode',
        {'latitude': latitude, 'longitude': longitude},
      );

      if (result != null) {
        return {
          'city': result['city']?.toString() ?? '',
          'province': result['province']?.toString() ?? '',
          'country': result['country']?.toString() ?? '',
        };
      }

      return null;
    } catch (e) {
      print('Error reverse geocoding: $e');
      return null;
    }
  }

  /// Menghitung jarak antara dua koordinat dalam km
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) *
            _cos(_toRadians(lat2)) *
            _sin(dLon / 2) *
            _sin(dLon / 2);

    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));

    return earthRadius * c;
  }

  // Helper math functions
  double _toRadians(double degree) => degree * 3.141592653589793 / 180.0;
  double _sin(double x) => _mathSin(x);
  double _cos(double x) => _mathCos(x);
  double _sqrt(double x) => _mathSqrt(x);
  double _atan2(double y, double x) => _mathAtan2(y, x);

  // Dart math implementations
  double _mathSin(double x) {
    // Taylor series approximation
    x = x % (2 * 3.141592653589793);
    double result = x;
    double term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  double _mathCos(double x) {
    return _mathSin(x + 3.141592653589793 / 2);
  }

  double _mathSqrt(double x) {
    if (x < 0) return double.nan;
    if (x == 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _mathAtan2(double y, double x) {
    if (x > 0) return _mathAtan(y / x);
    if (x < 0 && y >= 0) return _mathAtan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _mathAtan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 3.141592653589793 / 2;
    if (x == 0 && y < 0) return -3.141592653589793 / 2;
    return 0; // x == 0 && y == 0
  }

  double _mathAtan(double x) {
    // Taylor series approximation for small x
    if (x.abs() <= 1) {
      double result = x;
      double term = x;
      for (int i = 1; i <= 15; i++) {
        term *= -x * x;
        result += term / (2 * i + 1);
      }
      return result;
    } else {
      // For |x| > 1, use identity: atan(x) = pi/2 - atan(1/x)
      double sign = x > 0 ? 1 : -1;
      return sign * 3.141592653589793 / 2 - _mathAtan(1 / x);
    }
  }
}
