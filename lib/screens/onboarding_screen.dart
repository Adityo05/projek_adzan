import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../services/alarm_service.dart';

/// Layar onboarding untuk meminta izin lokasi dan baterai saat pertama kali
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final LocationService _locationService = LocationService();
  final StorageService _storage = StorageService();
  final AlarmService _alarmService = AlarmService();

  int _currentStep = 0; // 0 = welcome, 1 = location, 2 = battery, 3 = autostart
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildCurrentStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep();
      case 1:
        return _buildLocationStep();
      case 2:
        return _buildBatteryStep();
      case 3:
        return _buildAutostartStep();
      default:
        return _buildWelcomeStep();
    }
  }

  Widget _buildWelcomeStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // Icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mosque,
            size: 60,
            color: AppTheme.accentColor,
          ),
        ),
        const SizedBox(height: 32),
        // Title
        Text(
          'Selamat Datang',
          style: AppTheme.headingLarge.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Projek Adzan',
          style: AppTheme.headingMedium.copyWith(color: AppTheme.accentColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // Description
        Text(
          'Aplikasi pengingat waktu sholat dengan fitur:\n'
          '• Waktu sholat otomatis sesuai lokasi\n'
          '• Alarm adzan tepat waktu\n'
          '• Arah kiblat dengan kompas\n'
          '• Dukungan internasional',
          style: AppTheme.bodyMedium.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        // Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => _currentStep = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: AppTheme.backgroundColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Mulai',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // Icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.location_on,
            size: 50,
            color: AppTheme.accentColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Izin Lokasi',
          style: AppTheme.headingMedium.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Untuk menampilkan waktu sholat dan arah kiblat yang akurat, '
          'kami memerlukan izin untuk mengakses lokasi perangkat Anda.',
          style: AppTheme.bodyMedium.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // Features
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryDarkColor.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildFeatureItem(
                Icons.access_time,
                'Waktu sholat sesuai lokasi',
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(Icons.explore, 'Arah kiblat akurat'),
              const SizedBox(height: 12),
              _buildFeatureItem(Icons.public, 'Bekerja di seluruh dunia'),
            ],
          ),
        ),
        const Spacer(),
        // Status message
        if (_statusMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _statusMessage,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.accentColor),
              textAlign: TextAlign.center,
            ),
          ),
        // Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _requestLocationPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: AppTheme.backgroundColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.backgroundColor,
                      ),
                    )
                    : const Text(
                      'Izinkan Akses Lokasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isLoading ? null : _skipLocation,
          child: Text(
            'Lewati',
            style: AppTheme.bodySmall.copyWith(color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _buildBatteryStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // Icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.battery_saver,
            size: 50,
            color: AppTheme.accentColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Izin Baterai',
          style: AppTheme.headingMedium.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Agar alarm adzan tetap berbunyi meskipun aplikasi ditutup, '
          'izinkan aplikasi berjalan di latar belakang.',
          style: AppTheme.bodyMedium.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // Features
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryDarkColor.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildFeatureItem(Icons.alarm, 'Alarm berbunyi tepat waktu'),
              const SizedBox(height: 12),
              _buildFeatureItem(
                Icons.notifications_active,
                'Notifikasi adzan aktif',
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                Icons.power_settings_new,
                'Aplikasi tetap berjalan',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Catatan: Pada beberapa HP (Xiaomi, OPPO, Vivo, Samsung, Huawei), Anda mungkin perlu mengaktifkan Aplikasi Latar Belakang secara manual.',
          style: AppTheme.bodySmall.copyWith(
            fontStyle: FontStyle.italic,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        // Status message
        if (_statusMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _statusMessage,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.accentColor),
              textAlign: TextAlign.center,
            ),
          ),
        // Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _requestBatteryPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: AppTheme.backgroundColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.backgroundColor,
                      ),
                    )
                    : const Text(
                      'Izinkan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed:
              _isLoading
                  ? null
                  : () => setState(() {
                    _currentStep = 3;
                    _statusMessage = '';
                  }),
          child: Text(
            'Lewati',
            style: AppTheme.bodySmall.copyWith(color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _buildAutostartStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // Icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_circle_outline,
            size: 50,
            color: AppTheme.accentColor,
          ),
        ),
        const SizedBox(height: 32),
        // Title
        Text(
          'Latar Belakang Aplikasi',
          style: AppTheme.headingMedium.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // Description
        Text(
          'Agar alarm adzan tidak terlewat, aktifkan izin latar belakang aplikasi.',
          style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        // Features list
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryDarkColor.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildFeatureItem(
                Icons.check_circle,
                'Alarm tetap berbunyi walau aplikasi ditutup',
              ),
              const SizedBox(height: 8),
              _buildFeatureItem(
                Icons.check_circle,
                'Tidak terpengaruh oleh pembersih memori',
              ),
              const SizedBox(height: 8),
              _buildFeatureItem(
                Icons.check_circle,
                'Notifikasi reminder berjalan lancar',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Penting untuk HP Xiaomi, OPPO, Vivo, Samsung, dan Huawei',
          style: AppTheme.bodySmall.copyWith(
            fontStyle: FontStyle.italic,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        // Status message
        if (_statusMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _statusMessage,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.accentColor),
              textAlign: TextAlign.center,
            ),
          ),
        // Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _requestAutostartPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: AppTheme.backgroundColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.backgroundColor,
                      ),
                    )
                    : const Text(
                      'Buka Pengaturan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isLoading ? null : _completeOnboarding,
          child: Text(
            'Lewati & Selesai',
            style: AppTheme.bodySmall.copyWith(color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accentColor, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: AppTheme.bodySmall)),
      ],
    );
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Meminta izin lokasi...';
    });

    try {
      final hasPermission = await _locationService.requestPermission();

      if (hasPermission) {
        setState(() => _statusMessage = 'Mendapatkan lokasi...');

        final location = await _locationService.getLocationWithFallback();

        await _storage.init();
        await _storage.saveLocation(location);

        setState(() => _statusMessage = 'Lokasi: ${location.displayName}');
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        setState(
          () => _statusMessage = 'Izin ditolak. Menggunakan lokasi default.',
        );
        await Future.delayed(const Duration(seconds: 1));
      }

      // Move to next step
      setState(() {
        _currentStep = 2;
        _statusMessage = '';
      });
    } catch (e) {
      setState(() => _statusMessage = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _skipLocation() async {
    await _storage.init();
    setState(() => _currentStep = 2);
  }

  Future<void> _requestBatteryPermission() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Membuka pengaturan baterai...';
    });

    try {
      await _alarmService.requestIgnoreBatteryOptimizations();
      await Future.delayed(const Duration(seconds: 1));

      // Also try to request exact alarm permission
      await _alarmService.requestExactAlarmPermission();

      setState(
        () => _statusMessage = 'Silakan izinkan di pengaturan yang muncul',
      );
      await Future.delayed(const Duration(seconds: 2));

      // Move to autostart step
      setState(() {
        _currentStep = 3;
        _statusMessage = '';
      });
    } catch (e) {
      setState(() => _statusMessage = 'Tidak dapat membuka pengaturan baterai');
      await Future.delayed(const Duration(seconds: 1));
      _completeOnboarding();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestAutostartPermission() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Membuka pengaturan latar belakang...';
    });

    try {
      await _alarmService.showAutoStartSettings();

      setState(
        () =>
            _statusMessage =
                'Silakan aktifkan "Autostart" atau "Latar Belakang" untuk aplikasi ini',
      );
      await Future.delayed(const Duration(seconds: 3));

      _completeOnboarding();
    } catch (e) {
      setState(() => _statusMessage = 'Pengaturan tidak tersedia di HP ini');
      await Future.delayed(const Duration(seconds: 1));
      _completeOnboarding();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeOnboarding() async {
    await _storage.init();
    await _storage.setFirstRunComplete();
    widget.onComplete();
  }
}
