# Projek Adzan

Aplikasi pengingat waktu sholat untuk Android dengan fitur:
- ⏰ Waktu sholat akurat berdasarkan lokasi GPS
- 🔔 Alarm azan tepat waktu
- 🧭 Kompas arah kiblat
- 📍 Deteksi lokasi otomatis dengan GPS
- 🌙 Notifikasi reminder 5 menit sebelum waktu sholat
- 🔄 Auto-refresh jadwal harian dengan WorkManager

## Persyaratan Sistem

| Komponen | Versi Minimum |
|----------|---------------|
| Flutter SDK | 3.38.0+ |
| Dart SDK | 3.10.0+ |
| Android SDK (compileSdk) | 36 |
| Android SDK Build-Tools | 36.1.0 |
| Android NDK | 29.0.14206865 |
| Android Gradle Plugin | 8.9.2 |
| Gradle | 8.11.1 |
| Kotlin | 2.1.0 |

## Instalasi

### 1. Clone repository
```bash
git clone https://github.com/Adityo05/projek_adzan.git
cd azan
```

### 2. Pastikan Flutter versi terbaru
```bash
flutter upgrade
flutter --version  # Harus 3.38.0+
```

### 3. Install Android SDK & NDK

Buka **Android Studio** → **Settings** → **Languages & Frameworks** → **Android SDK**:

**SDK Platforms:**
- ✅ Android 15.0 (API 36)

**SDK Tools:**
- ✅ Android SDK Build-Tools 36.1.0
- ✅ NDK (Side by side) 29.0.14206865

> **Catatan:** Jika NDK 29 gagal download via SDK Manager, download manual dari [developer.android.com/ndk/downloads](https://developer.android.com/ndk/downloads) dan extract ke `[SDK Path]/ndk/29.0.14206865/`

### 4. Install dependencies
```bash
flutter pub get
```

### 5. Jalankan aplikasi
```bash
flutter run
```

## Build APK

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```

APK akan tersedia di `build/app/outputs/flutter-apk/`

## Struktur Proyek

```
lib/
├── config/         # Konfigurasi tema dan konstanta
├── models/         # Model data (PrayerTime, Location)
├── screens/        # Halaman UI (Home, Qibla, Settings, Onboarding)
├── services/       # Layanan (Alarm, Location, Storage, API, Background)
├── widgets/        # Widget reusable (PrayerCard, CountdownTimer)
└── main.dart       # Entry point aplikasi

android/
└── app/src/main/kotlin/com/example/azan/
    ├── MainActivity.kt           # Platform channel handler
    ├── AlarmReceiver.kt          # Broadcast receiver untuk alarm
    ├── ReminderReceiver.kt       # Broadcast receiver untuk reminder
    ├── AzanForegroundService.kt  # Foreground service untuk audio
    └── BootReceiver.kt           # Restore alarm setelah reboot

assets/
└── audio/
    ├── Adzan.mp3       # Audio azan biasa
    └── Adzan_subuh.mp3 # Audio azan subuh
```

## Fitur

### Waktu Sholat
- Perhitungan menggunakan API Aladhan
- Mendukung berbagai metode perhitungan (MWL, ISNA, dll)
- Penyesuaian waktu sholat (iqomah)
- Auto-refresh jadwal setiap tengah malam dengan WorkManager

### Alarm Azan
- Alarm tepat waktu menggunakan Android AlarmManager
- Audio azan dengan Foreground Service
- Getaran opsional (dapat diaktifkan/nonaktifkan)
- Notifikasi reminder 5 menit sebelumnya (dapat diaktifkan/nonaktifkan)

### Arah Kiblat
- Kompas digital dengan sensor magnetometer
- Perhitungan akurat berdasarkan koordinat GPS

## Izin yang Diperlukan

- `ACCESS_FINE_LOCATION` - Untuk GPS
- `POST_NOTIFICATIONS` - Untuk notifikasi
- `SCHEDULE_EXACT_ALARM` - Untuk alarm tepat waktu
- `VIBRATE` - Untuk getaran
- `FOREGROUND_SERVICE` - Untuk memutar audio di background
- `WAKE_LOCK` - Untuk membangunkan perangkat
- `RECEIVE_BOOT_COMPLETED` - Untuk restore alarm setelah reboot
- `INTERNET` - Untuk fetch jadwal dari API

## Troubleshooting

### Build Error: "Could not read workspace metadata"
```bash
# Stop Gradle daemon dan hapus cache
cd android
.\gradlew.bat --stop
cd ..
flutter clean
flutter pub get
flutter run
```

### Warning Kotlin version
Jika muncul warning tentang Kotlin version, project ini sudah menggunakan Kotlin 2.1.0 yang terbaru.