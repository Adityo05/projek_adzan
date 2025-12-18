import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_theme.dart';
import '../models/location_model.dart';
import '../services/storage_service.dart';
import '../services/alarm_service.dart';
import '../services/location_service.dart';

/// Halaman pengaturan aplikasi
class SettingsScreen extends StatefulWidget {
  final VoidCallback? onSettingsChanged;

  const SettingsScreen({super.key, this.onSettingsChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  final AlarmService _alarm = AlarmService();
  final LocationService _locationService = LocationService();

  LocationModel? _location;
  bool _notificationEnabled = true;
  bool _vibrationEnabled = true;
  bool _isLoading = true;
  bool _isUpdatingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _storage.init();
    _location = await _storage.getLocation() ?? LocationModel.defaultLocation;
    _notificationEnabled = await _storage.getNotificationEnabled();
    _vibrationEnabled = await _storage.getVibrationEnabled();
    setState(() => _isLoading = false);
  }

  Future<void> _saveAndNotify() async {
    widget.onSettingsChanged?.call();
  }

  Future<void> _updateLocation() async {
    setState(() => _isUpdatingLocation = true);

    try {
      final hasPermission = await _locationService.requestPermission();
      if (hasPermission) {
        final location = await _locationService.getLocationWithFallback();
        await _storage.saveLocation(location);
        setState(() => _location = location);
        _saveAndNotify();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lokasi diperbarui: ${location.displayName}'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui lokasi: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }

    setState(() => _isUpdatingLocation = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Pengaturan'), centerTitle: true),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                )
                : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 8),
                    _buildLocationSection(),
                    const SizedBox(height: 16),
                    _buildNotificationSection(),
                    const SizedBox(height: 16),
                    _buildBatterySection(),
                    const SizedBox(height: 32),
                  ],
                ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.accentColor),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    title,
                    style: AppTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return _buildSectionCard(
      title: 'Lokasi',
      icon: Icons.location_on,
      children: [
        ListTile(
          title: const Text(
            'Lokasi Saat Ini',
            style: TextStyle(color: AppTheme.textPrimaryColor),
          ),
          subtitle: Text(
            _location?.displayName ?? 'Tidak diketahui',
            style: const TextStyle(color: AppTheme.accentColor),
          ),
          trailing:
              _isUpdatingLocation
                  ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.accentColor,
                    ),
                  )
                  : IconButton(
                    icon: const Icon(
                      Icons.my_location,
                      color: AppTheme.accentColor,
                    ),
                    onPressed: _updateLocation,
                  ),
        ),
        if (_location != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Koordinat: ${_location!.latitude.toStringAsFixed(4)}, ${_location!.longitude.toStringAsFixed(4)}',
              style: AppTheme.bodySmall,
            ),
          ),
        ListTile(
          title: const Text(
            'Izin Lokasi',
            style: TextStyle(color: AppTheme.textPrimaryColor),
          ),
          subtitle: const Text(
            'Buka pengaturan izin lokasi aplikasi',
            style: TextStyle(color: AppTheme.textSecondaryColor),
          ),
          trailing: ElevatedButton(
            onPressed: _openLocationSettings,
            child: const Text('Buka'),
          ),
        ),
      ],
    );
  }

  Future<void> _openLocationSettings() async {
    // Membuka halaman pengaturan aplikasi di sistem
    await _locationService.openAppSettings();
  }

  Widget _buildNotificationSection() {
    return _buildSectionCard(
      title: 'Notifikasi',
      icon: Icons.notifications,
      children: [
        SwitchListTile(
          title: const Text(
            'Pengingat Sebelum Sholat',
            style: TextStyle(color: AppTheme.textPrimaryColor),
          ),
          subtitle: const Text(
            'Tampilkan notifikasi 5 menit sebelum waktu sholat',
            style: TextStyle(color: AppTheme.textSecondaryColor),
          ),
          value: _notificationEnabled,
          onChanged: (value) async {
            setState(() => _notificationEnabled = value);
            await _storage.saveNotificationEnabled(value);
            _saveAndNotify(); // Re-schedule alarms with new reminder setting
          },
        ),
        SwitchListTile(
          title: const Text(
            'Getar',
            style: TextStyle(color: AppTheme.textPrimaryColor),
          ),
          subtitle: const Text(
            'Getarkan ponsel saat azan',
            style: TextStyle(color: AppTheme.textSecondaryColor),
          ),
          value: _vibrationEnabled,
          onChanged: (value) async {
            setState(() => _vibrationEnabled = value);
            await _storage.saveVibrationEnabled(value);
            _saveAndNotify(); // Re-schedule alarms with new vibration setting

            // Feedback getar sesaat saat diaktifkan
            if (value) {
              _alarm.vibrate(durationMs: 100);
            }
          },
        ),
      ],
    );
  }

  Widget _buildBatterySection() {
    return _buildSectionCard(
      title: 'Pengaturan Baterai',
      icon: Icons.battery_saver,
      children: [
        ListTile(
          title: const Text(
            'Pengaturan Baterai',
            style: TextStyle(color: AppTheme.textPrimaryColor),
          ),
          subtitle: const Text(
            'Ubah pengaturan baterai ke tanpa batas',
            style: TextStyle(color: AppTheme.textSecondaryColor),
          ),
          trailing: ElevatedButton(
            onPressed: () => _alarm.requestIgnoreBatteryOptimizations(),
            child: const Text('Buka'),
          ),
        ),
        ListTile(
          title: const Text(
            'Latar Belakang Aplikasi',
            style: TextStyle(color: AppTheme.textPrimaryColor),
          ),
          subtitle: const Text(
            'Aktifkan latar belakang aplikasi jika alarm tidak berbunyi',
            style: TextStyle(color: AppTheme.textSecondaryColor),
          ),
          trailing: ElevatedButton(
            onPressed: () => _alarm.showAutoStartSettings(),
            child: const Text('Buka'),
          ),
        ),
      ],
    );
  }
}
