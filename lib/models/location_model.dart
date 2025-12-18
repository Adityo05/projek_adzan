/// Model untuk menyimpan informasi lokasi pengguna
class LocationModel {
  final double latitude;
  final double longitude;
  final double altitude; // dalam meter
  final String? cityName;
  final String? provinceName;
  final String? countryName;
  final String? timezone;
  final DateTime? lastUpdated;

  const LocationModel({
    required this.latitude,
    required this.longitude,
    this.altitude = 0,
    this.cityName,
    this.provinceName,
    this.countryName,
    this.timezone,
    this.lastUpdated,
  });

  /// Lokasi default (Jakarta, Indonesia)
  static const LocationModel defaultLocation = LocationModel(
    latitude: -6.2088,
    longitude: 106.8456,
    altitude: 8,
    cityName: 'Jakarta',
    provinceName: 'DKI Jakarta',
    countryName: 'Indonesia',
    timezone: 'Asia/Jakarta',
  );

  /// Lokasi Makkah (untuk perhitungan arah kiblat)
  static const LocationModel makkah = LocationModel(
    latitude: 21.4225,
    longitude: 39.8262,
    altitude: 277,
    cityName: 'Makkah',
    countryName: 'Saudi Arabia',
    timezone: 'Asia/Riyadh',
  );

  /// Nama tampilan lokasi
  String get displayName {
    if (cityName != null && provinceName != null && countryName != null) {
      return '$cityName, $provinceName, $countryName';
    } else if (cityName != null && provinceName != null) {
      return '$cityName, $provinceName';
    } else if (cityName != null && countryName != null) {
      return '$cityName, $countryName';
    } else if (cityName != null) {
      return cityName!;
    } else {
      return 'Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)}';
    }
  }

  /// Koordinat dalam format string
  String get coordinatesString {
    final latDir = latitude >= 0 ? 'N' : 'S';
    final lngDir = longitude >= 0 ? 'E' : 'W';
    return '${latitude.abs().toStringAsFixed(4)}° $latDir, ${longitude.abs().toStringAsFixed(4)}° $lngDir';
  }

  /// Apakah lokasi ini valid
  bool get isValid {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  /// Apakah ini daerah dengan latitude tinggi (>45°)
  bool get isHighLatitude {
    return latitude.abs() > 45;
  }

  /// Membuat salinan dengan perubahan
  LocationModel copyWith({
    double? latitude,
    double? longitude,
    double? altitude,
    String? cityName,
    String? provinceName,
    String? countryName,
    String? timezone,
    DateTime? lastUpdated,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      cityName: cityName ?? this.cityName,
      provinceName: provinceName ?? this.provinceName,
      countryName: countryName ?? this.countryName,
      timezone: timezone ?? this.timezone,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Konversi ke Map untuk penyimpanan
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'cityName': cityName,
      'provinceName': provinceName,
      'countryName': countryName,
      'timezone': timezone,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  /// Membuat dari Map
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble() ?? 0,
      cityName: json['cityName'] as String?,
      provinceName: json['provinceName'] as String?,
      countryName: json['countryName'] as String?,
      timezone: json['timezone'] as String?,
      lastUpdated:
          json['lastUpdated'] != null
              ? DateTime.parse(json['lastUpdated'] as String)
              : null,
    );
  }

  @override
  String toString() {
    return 'LocationModel($displayName: $coordinatesString)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationModel &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}
