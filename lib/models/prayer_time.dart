import 'package:flutter/material.dart';

/// Enum untuk jenis waktu sholat
enum PrayerType {
  fajr, // Subuh
  sunrise,
  dhuhr, // Dzuhur
  asr, // Ashar
  maghrib, // Maghrib
  isha, // Isya
}

/// Ekstensi untuk PrayerType
extension PrayerTypeExtension on PrayerType {
  /// Nama dalam Bahasa Indonesia
  String get nameId {
    switch (this) {
      case PrayerType.fajr:
        return 'Subuh';
      case PrayerType.sunrise:
        return 'Syuruq';
      case PrayerType.dhuhr:
        return 'Dzuhur';
      case PrayerType.asr:
        return 'Ashar';
      case PrayerType.maghrib:
        return 'Maghrib';
      case PrayerType.isha:
        return 'Isya';
    }
  }

  /// Nama dalam Bahasa Arab
  String get nameArabic {
    switch (this) {
      case PrayerType.fajr:
        return 'الفجر';
      case PrayerType.sunrise:
        return 'الشروق';
      case PrayerType.dhuhr:
        return 'الظهر';
      case PrayerType.asr:
        return 'العصر';
      case PrayerType.maghrib:
        return 'المغرب';
      case PrayerType.isha:
        return 'العشاء';
    }
  }

  /// Icon untuk setiap waktu sholat
  IconData get icon {
    switch (this) {
      case PrayerType.fajr:
        return Icons.nights_stay_rounded;
      case PrayerType.sunrise:
        return Icons.wb_twilight_rounded;
      case PrayerType.dhuhr:
        return Icons.wb_sunny_rounded;
      case PrayerType.asr:
        return Icons.sunny_snowing;
      case PrayerType.maghrib:
        return Icons.wb_twilight_rounded;
      case PrayerType.isha:
        return Icons.dark_mode_rounded;
    }
  }

  /// Warna representatif untuk setiap waktu
  Color get color {
    switch (this) {
      case PrayerType.fajr:
        return const Color(0xFF4CAF50); // Hijau (Subuh)
      case PrayerType.sunrise:
        return const Color(0xFF81C784); // Hijau muda (Syuruq)
      case PrayerType.dhuhr:
        return const Color(0xFF2E7D32); // Hijau solid (Dzuhur)
      case PrayerType.asr:
        return const Color(0xFF1B5E20); // Hijau tua (Ashar)
      case PrayerType.maghrib:
        return const Color(0xFF388E3C); // Hijau (Maghrib)
      case PrayerType.isha:
        return const Color(0xFF1B5E20); // Hijau gelap (Isya)
    }
  }

  /// Apakah ini waktu sholat wajib
  bool get isObligatoryPrayer {
    return this != PrayerType.sunrise;
  }

  /// Deskripsi waktu sholat
  String get description {
    switch (this) {
      case PrayerType.fajr:
        return 'Sholat Subuh, dilaksanakan saat fajar menyingsing hingga terbit matahari';
      case PrayerType.sunrise:
        return 'Waktu terbit matahari, menandai berakhirnya waktu Subuh';
      case PrayerType.dhuhr:
        return 'Sholat Dzuhur, dilaksanakan setelah matahari condong dari zenith';
      case PrayerType.asr:
        return 'Sholat Ashar, dilaksanakan saat bayangan sama atau lebih panjang dari bendanya';
      case PrayerType.maghrib:
        return 'Sholat Maghrib, dilaksanakan setelah matahari terbenam';
      case PrayerType.isha:
        return 'Sholat Isya, dilaksanakan saat mega merah telah hilang';
    }
  }
}

/// Model untuk satu waktu sholat
class PrayerTime {
  final PrayerType type;
  final DateTime time;
  final bool isEnabled; // Apakah alarm aktif untuk waktu ini
  final int adjustmentMinutes; // Penyesuaian waktu dalam menit

  const PrayerTime({
    required this.type,
    required this.time,
    this.isEnabled = true,
    this.adjustmentMinutes = 0,
  });

  /// Waktu yang sudah disesuaikan
  DateTime get adjustedTime {
    return time.add(Duration(minutes: adjustmentMinutes));
  }

  /// Format waktu dalam string HH:mm
  String get formattedTime {
    final adjustedTime = this.adjustedTime;
    final hour = adjustedTime.hour.toString().padLeft(2, '0');
    final minute = adjustedTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Apakah waktu ini sudah lewat untuk hari ini
  bool get hasPassed {
    return DateTime.now().isAfter(adjustedTime);
  }

  /// Durasi menuju waktu ini
  Duration get timeUntil {
    return adjustedTime.difference(DateTime.now());
  }

  /// Membuat salinan dengan perubahan
  PrayerTime copyWith({
    PrayerType? type,
    DateTime? time,
    bool? isEnabled,
    int? adjustmentMinutes,
  }) {
    return PrayerTime(
      type: type ?? this.type,
      time: time ?? this.time,
      isEnabled: isEnabled ?? this.isEnabled,
      adjustmentMinutes: adjustmentMinutes ?? this.adjustmentMinutes,
    );
  }

  /// Konversi ke Map untuk penyimpanan
  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'time': time.toIso8601String(),
      'isEnabled': isEnabled,
      'adjustmentMinutes': adjustmentMinutes,
    };
  }

  /// Membuat dari Map
  factory PrayerTime.fromJson(Map<String, dynamic> json) {
    return PrayerTime(
      type: PrayerType.values[json['type'] as int],
      time: DateTime.parse(json['time'] as String),
      isEnabled: json['isEnabled'] as bool? ?? true,
      adjustmentMinutes: json['adjustmentMinutes'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'PrayerTime(${type.nameId}: $formattedTime, enabled: $isEnabled)';
  }
}

/// Model untuk jadwal sholat harian
class DailyPrayerSchedule {
  final DateTime date;
  final List<PrayerTime> prayers;

  const DailyPrayerSchedule({required this.date, required this.prayers});

  /// Mendapatkan waktu sholat berdasarkan tipe
  PrayerTime? getPrayer(PrayerType type) {
    try {
      return prayers.firstWhere((p) => p.type == type);
    } catch (_) {
      return null;
    }
  }

  /// Waktu Subuh
  PrayerTime? get fajr => getPrayer(PrayerType.fajr);

  /// Waktu Syuruq (sunrise)
  PrayerTime? get sunrise => getPrayer(PrayerType.sunrise);

  /// Waktu Dzuhur
  PrayerTime? get dhuhr => getPrayer(PrayerType.dhuhr);

  /// Waktu Ashar
  PrayerTime? get asr => getPrayer(PrayerType.asr);

  /// Waktu Maghrib
  PrayerTime? get maghrib => getPrayer(PrayerType.maghrib);

  /// Waktu Isya
  PrayerTime? get isha => getPrayer(PrayerType.isha);

  /// Mendapatkan waktu sholat berikutnya
  /// Jika semua sholat hari ini sudah lewat, return Subuh dengan waktu besok
  PrayerTime? get nextPrayer {
    final now = DateTime.now();

    // Cari waktu sholat berikutnya hari ini
    for (final prayer in prayers) {
      if (prayer.type != PrayerType.sunrise &&
          prayer.adjustedTime.isAfter(now)) {
        return prayer;
      }
    }

    // Jika semua sudah lewat, return Subuh untuk countdown ke besok
    // Buat PrayerTime Subuh dengan waktu digeser ke besok
    final fajrToday = getPrayer(PrayerType.fajr);
    if (fajrToday != null) {
      final tomorrowFajrTime = DateTime(
        now.year,
        now.month,
        now.day + 1,
        fajrToday.time.hour,
        fajrToday.time.minute,
      );
      return PrayerTime(
        type: PrayerType.fajr,
        time: tomorrowFajrTime,
        isEnabled: fajrToday.isEnabled,
        adjustmentMinutes: fajrToday.adjustmentMinutes,
      );
    }

    return null;
  }

  /// Mendapatkan waktu sholat saat ini (yang sedang berlangsung)
  PrayerTime? get currentPrayer {
    final now = DateTime.now();
    PrayerTime? current;

    for (int i = 0; i < prayers.length; i++) {
      final prayer = prayers[i];
      if (prayer.type == PrayerType.sunrise) continue;

      if (prayer.adjustedTime.isBefore(now) ||
          prayer.adjustedTime.isAtSameMomentAs(now)) {
        current = prayer;
      }
    }

    return current;
  }

  /// Apakah sekarang dalam waktu terlarang untuk sholat
  /// (saat terbit/terbenam matahari dan zenith)
  bool get isForbiddenTime {
    final now = DateTime.now();
    final sunriseTime = sunrise?.adjustedTime;
    final dhuhrTime = dhuhr?.adjustedTime;

    if (sunriseTime != null) {
      // 15 menit sebelum dan sesudah terbit
      final sunriseStart = sunriseTime.subtract(const Duration(minutes: 15));
      final sunriseEnd = sunriseTime.add(const Duration(minutes: 15));
      if (now.isAfter(sunriseStart) && now.isBefore(sunriseEnd)) {
        return true;
      }
    }

    if (dhuhrTime != null) {
      // Beberapa menit sebelum dzuhur (zenith)
      final zenithStart = dhuhrTime.subtract(const Duration(minutes: 5));
      if (now.isAfter(zenithStart) && now.isBefore(dhuhrTime)) {
        return true;
      }
    }

    return false;
  }

  /// Membuat salinan dengan perubahan
  DailyPrayerSchedule copyWith({DateTime? date, List<PrayerTime>? prayers}) {
    return DailyPrayerSchedule(
      date: date ?? this.date,
      prayers: prayers ?? this.prayers,
    );
  }

  /// Konversi ke Map untuk penyimpanan
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'prayers': prayers.map((p) => p.toJson()).toList(),
    };
  }

  /// Membuat dari Map
  factory DailyPrayerSchedule.fromJson(Map<String, dynamic> json) {
    return DailyPrayerSchedule(
      date: DateTime.parse(json['date'] as String),
      prayers:
          (json['prayers'] as List)
              .map((p) => PrayerTime.fromJson(p as Map<String, dynamic>))
              .toList(),
    );
  }

  @override
  String toString() {
    return 'DailyPrayerSchedule($date: ${prayers.length} prayers)';
  }
}
