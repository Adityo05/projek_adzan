# Projek Adzan

Aplikasi pengingat waktu sholat untuk Android dengan fitur:
- ⏰ Waktu sholat akurat berdasarkan lokasi GPS
- 🔔 Alarm azan tepat waktu
- 🧭 Kompas arah kiblat
- 📍 Deteksi lokasi otomatis dengan GPS
- 🌙 Notifikasi reminder 5 menit sebelum waktu sholat

## Persyaratan

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android SDK (API 21+)
- Android NDK (untuk native code)

## Instalasi

1. **Clone repository**
   ```bash
   git clone https://github.com/username/azan.git
   cd azan
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Jalankan aplikasi**
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
├── services/       # Layanan (Alarm, Location, Storage, API)
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

### Alarm Azan
- Alarm tepat waktu menggunakan Android AlarmManager
- Audio azan dengan Foreground Service
- Getaran opsional
- Notifikasi reminder 5 menit sebelumnya

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

## Lisensi

MIT License

## Kontribusi

Pull request dipersilakan. Untuk perubahan besar, silakan buka issue terlebih dahulu.
