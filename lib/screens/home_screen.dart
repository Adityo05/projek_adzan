import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/location_model.dart';
import '../models/prayer_time.dart';
import '../services/prayer_api_service.dart';
import '../services/storage_service.dart';
import '../services/alarm_service.dart';
import '../services/location_service.dart';
import '../widgets/prayer_card.dart';
import '../widgets/countdown_timer.dart';
import '../utils/date_utils.dart';
import 'settings_screen.dart';
import 'qibla_screen.dart';
import 'oem_helper_screen.dart';

/// Halaman utama aplikasi Azan
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final StorageService _storage = StorageService();
  final AlarmService _alarm = AlarmService();
  final PrayerApiService _prayerApi = PrayerApiService();
  final LocationService _locationService = LocationService();

  LocationModel? _location;
  DailyPrayerSchedule? _schedule;
  Map<PrayerType, bool> _alarmSettings = {};
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isAlarmPlaying = false;
  String? _currentPrayerName;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshSchedule();
    }
  }

  Future<void> _initializeApp() async {
    await _storage.init();
    await _loadSettings();
    await _fetchPrayerTimes();
    await _scheduleAlarms();
    setState(() => _isLoading = false);

    // Refresh lokasi GPS di background setelah UI sudah tampil
    _refreshLocationInBackground();
  }

  Future<void> _loadSettings() async {
    // Gunakan lokasi tersimpan dulu agar UI cepat tampil
    final storedLocation = await _storage.getLocation();
    _location = storedLocation ?? LocationModel.defaultLocation;
    _alarmSettings = await _storage.getAlarmSettings();
  }

  /// Refresh lokasi dari GPS di background (tidak blocking UI)
  Future<void> _refreshLocationInBackground() async {
    try {
      final hasPermission = await _locationService.checkPermission();
      if (hasPermission) {
        final freshLocation = await _locationService
            .getLocationWithFallback()
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => _location ?? LocationModel.defaultLocation,
            );

        // Jika lokasi berubah, update dan refresh jadwal
        if (_location?.latitude != freshLocation.latitude ||
            _location?.longitude != freshLocation.longitude) {
          _location = freshLocation;
          await _storage.saveLocation(_location!);
          await _fetchPrayerTimes();
          await _scheduleAlarms();
          if (mounted) setState(() {});
          print('Location refreshed from GPS: ${_location!.displayName}');
        }
      }
    } catch (e) {
      print('Failed to refresh location in background: $e');
    }
  }

  Future<void> _fetchPrayerTimes() async {
    if (_location == null) return;

    setState(() {
      _errorMessage = null;
    });

    try {
      final schedule = await _prayerApi.getPrayerTimes(
        latitude: _location!.latitude,
        longitude: _location!.longitude,
        date: DateTime.now(),
      );

      if (schedule != null) {
        setState(() => _schedule = schedule);
      } else {
        setState(
          () => _errorMessage =
              'Gagal memuat jadwal sholat. Periksa koneksi internet.',
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    }
  }

  Future<void> _scheduleAlarms() async {
    if (_schedule == null) return;

    final defaultAzan = await _storage.getSelectedAzan();
    final fajrAzan = await _storage.getFajrAzan();
    final vibrate = await _storage.getVibrationEnabled();
    final showReminder = await _storage.getNotificationEnabled();

    await _alarm.scheduleAllAlarms(
      schedule: _schedule!,
      settings: _alarmSettings,
      defaultAzan: defaultAzan,
      fajrAzan: fajrAzan,
      vibrate: vibrate,
      showReminder: showReminder,
    );
  }

  Future<void> _refreshSchedule() async {
    await _loadSettings();
    await _fetchPrayerTimes();
    await _scheduleAlarms();
  }

  Future<void> _updateLocation() async {
    setState(() => _isLoading = true);

    try {
      final hasPermission = await _locationService.requestPermission();
      if (hasPermission) {
        final location = await _locationService.getLocationWithFallback();
        await _storage.saveLocation(location);
        _location = location;
        await _fetchPrayerTimes();
        await _scheduleAlarms();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memperbarui lokasi: $e')));
    }

    setState(() => _isLoading = false);
  }

  void _toggleAlarm(PrayerType type) async {
    final currentValue = _alarmSettings[type] ?? true;

    // Jika akan mematikan alarm, tampilkan konfirmasi
    if (currentValue) {
      final confirmed = await _showDisableAlarmDialog(type);
      if (!confirmed) return;
    }

    final newValue = !currentValue;
    setState(() {
      _alarmSettings[type] = newValue;
    });
    await _storage.saveAlarmSettings(_alarmSettings);

    // Jika dimatikan, batalkan alarm yang sudah terjadwal
    if (!newValue) {
      await _alarm.cancelAlarm(type);
    }

    // Re-schedule semua alarm
    await _scheduleAlarms();
  }

  Future<bool> _showDisableAlarmDialog(PrayerType type) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.notifications_off, color: AppTheme.accentColor),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Matikan Alarm ${type.nameId}?',
                    style: AppTheme.titleLarge,
                  ),
                ),
              ],
            ),
            content: Text(
              'Alarm adzan ${type.nameId} akan dimatikan secara permanen sampai Anda mengaktifkannya kembali.',
              style: AppTheme.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                ),
                child: const Text('Matikan'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _stopAlarm() async {
    await _alarm.stopAzan();
    setState(() {
      _isAlarmPlaying = false;
      _currentPrayerName = null;
    });
  }

  void showAlarmPlaying(String prayerName) {
    setState(() {
      _isAlarmPlaying = true;
      _currentPrayerName = prayerName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.accentColor),
              ),
            )
          : IndexedStack(
              index: _currentIndex,
              children: [
                _buildHomeTab(),
                const QiblaScreen(),
                SettingsScreen(onSettingsChanged: _refreshSchedule),
              ],
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  String _formatGregorianDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  Widget _buildHomeTab() {
    final now = DateTime.now();
    final hijriDate = HijriDateUtils.formatHijri(now);
    final gregorianDate = _formatGregorianDate(now);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Banner Alarm
            if (_isAlarmPlaying) ...[
              _buildAlarmBanner(),
              const SizedBox(height: 20),
            ],

            // HEADER INFO (Tanpa Container Background/AppBar)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KOLOM KIRI (Salam & Lokasi)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Assalamu'alaikum",
                        style: AppTheme.headingSmall.copyWith(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _updateLocation,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: AppTheme.accentColor, // Gold Accent
                              size: 14, // Ikon agak kecil
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _location?.displayName ?? 'Lokasi...',
                                // Lebih kecil agar tombol reload (tap area) jelas
                                style: const TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // KOLOM KANAN (Tanggal)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      gregorianDate,
                      // Warna Hitam
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Tanggal Islam warna Gold (seperti sebelumnya)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor, // Gold Solid
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        hijriDate,
                        style: const TextStyle(
                          color: Colors.white, // Teks Putih di atas Gold
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // COUNTDOWN TIMER (Card)
            if (_schedule != null)
              CountdownTimer(
                nextPrayer: _schedule!.nextPrayer,
                onPrayerTime: _refreshSchedule,
              )
            else
              const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              ),

            const SizedBox(height: 24),

            // PRAYER LIST
            if (_errorMessage != null)
              _buildErrorWidget()
            else if (_schedule != null)
              _buildPrayerList(),

            const SizedBox(height: 20),

            // HELP BANNER
            _buildHelpBanner(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpBanner() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OemHelperScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.warningColor.withAlpha(25),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          border: Border.all(color: AppTheme.warningColor.withAlpha(77)),
        ),
        child: Row(
          children: [
            Icon(Icons.help_outline, color: AppTheme.warningColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Notifikasi adzan tidak muncul? Klik di sini',
                style: TextStyle(
                  color: AppTheme.warningColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.warningColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentColor.withValues(alpha: 0.9),
            AppTheme.primaryColor.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.volume_up, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Adzan Berkumandang',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _currentPrayerName ?? 'Waktu Sholat',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _stopAlarm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Hentikan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off,
            size: 64,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshSchedule,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerList() {
    if (_schedule == null) {
      return const Center(child: Text('Tidak ada jadwal sholat'));
    }

    final nextPrayer = _schedule!.nextPrayer;

    // Filter hanya 5 waktu sholat wajib (tanpa Sunrise)
    final obligatoryPrayers = _schedule!.prayers
        .where((p) => p.type != PrayerType.sunrise)
        .toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: obligatoryPrayers.length,
      itemBuilder: (context, index) {
        final prayer = obligatoryPrayers[index];
        return PrayerCard(
          prayer: prayer,
          isNext: nextPrayer?.type == prayer.type,
          alarmEnabled: _alarmSettings[prayer.type] ?? true,
          onAlarmToggle: () => _toggleAlarm(prayer.type),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Jadwal',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Kiblat'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
