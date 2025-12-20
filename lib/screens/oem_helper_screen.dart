import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/alarm_service.dart';

/// Halaman bantuan optimasi untuk berbagai merek HP
/// Membantu user mengaktifkan autostart, menonaktifkan battery optimization, dll
class OemHelperScreen extends StatefulWidget {
  const OemHelperScreen({super.key});

  @override
  State<OemHelperScreen> createState() => _OemHelperScreenState();
}

class _OemHelperScreenState extends State<OemHelperScreen> {
  final AlarmService _alarm = AlarmService();
  String? _selectedBrand;

  // Daftar merek HP dan instruksi spesifik
  final Map<String, OemBrandInfo> _brands = {
    'xiaomi': OemBrandInfo(
      name: 'Xiaomi / Redmi / POCO',
      icon: '📱',
      steps: [
        OemStep(
          title: 'Autostart',
          description:
              'Settings → Apps → Permissions → Autostart → Aktifkan Projek Adzan',
          hasButton: true,
          buttonType: 'autostart',
        ),
        OemStep(
          title: 'Battery Saver',
          description:
              'Settings → Apps → Manage Apps → Projek Adzan → Battery Saver → No restrictions',
          hasButton: true,
          buttonType: 'battery',
        ),
        OemStep(
          title: 'Lock App',
          description:
              'Buka Projek Adzan → Tekan tombol Recent Apps → Tarik aplikasi ke bawah atau tekan ikon gembok 🔒',
          hasButton: false,
        ),
        OemStep(
          title: 'MIUI Optimization',
          description:
              'Settings → Additional Settings → Developer Options → Matikan "MIUI Optimization"',
          hasButton: false,
        ),
      ],
    ),
    'samsung': OemBrandInfo(
      name: 'Samsung',
      icon: '📱',
      steps: [
        OemStep(
          title: 'Sleeping Apps',
          description:
              'Settings → Battery → Background usage limits → Hapus Projek Adzan dari Sleeping apps',
          hasButton: true,
          buttonType: 'battery',
        ),
        OemStep(
          title: 'App Power Management',
          description:
              'Settings → Apps → Projek Adzan → Battery → Unrestricted',
          hasButton: true,
          buttonType: 'battery',
        ),
        OemStep(
          title: 'Lock App',
          description: 'Buka Recent Apps → Tekan ikon aplikasi → Lock this app',
          hasButton: false,
        ),
      ],
    ),
    'oppo': OemBrandInfo(
      name: 'OPPO / Realme',
      icon: '📱',
      steps: [
        OemStep(
          title: 'Auto-launch',
          description:
              'Settings → App Management → App List → Projek Adzan → Auto-launch → Allow',
          hasButton: true,
          buttonType: 'autostart',
        ),
        OemStep(
          title: 'Battery Optimization',
          description:
              'Settings → Battery → More Settings → Optimize battery use → Projek Adzan → Don\'t optimize',
          hasButton: true,
          buttonType: 'battery',
        ),
        OemStep(
          title: 'Background Running',
          description:
              'Settings → App Management → Projek Adzan → Power Saver → Allow background running',
          hasButton: false,
        ),
        OemStep(
          title: 'Lock App',
          description:
              'Buka Recent Apps → Tarik ke bawah pada aplikasi untuk mengunci',
          hasButton: false,
        ),
      ],
    ),
    'vivo': OemBrandInfo(
      name: 'Vivo / iQOO',
      icon: '📱',
      steps: [
        OemStep(
          title: 'Autostart',
          description:
              'Settings → Apps → Autostart Manager → Aktifkan Projek Adzan',
          hasButton: true,
          buttonType: 'autostart',
        ),
        OemStep(
          title: 'Battery Optimization',
          description:
              'Settings → Battery → High background power consumption → Aktifkan Projek Adzan',
          hasButton: true,
          buttonType: 'battery',
        ),
        OemStep(
          title: 'Lock App',
          description: 'Buka Recent Apps → Tarik ke bawah untuk mengunci',
          hasButton: false,
        ),
      ],
    ),
    'huawei': OemBrandInfo(
      name: 'Huawei / Honor',
      icon: '📱',
      steps: [
        OemStep(
          title: 'App Launch',
          description:
              'Settings → Battery → App Launch → Projek Adzan → Manage manually → Aktifkan semua toggle',
          hasButton: true,
          buttonType: 'battery',
        ),
        OemStep(
          title: 'Ignore Optimizations',
          description:
              'Settings → Apps → Projek Adzan → Battery → Launch → Uncheck all restrictions',
          hasButton: true,
          buttonType: 'battery',
        ),
        OemStep(
          title: 'Protected Apps',
          description:
              'Settings → Battery → Protected apps → Aktifkan Projek Adzan',
          hasButton: false,
        ),
        OemStep(
          title: 'Lock App',
          description: 'Buka Recent Apps → Tarik ke bawah untuk mengunci',
          hasButton: false,
        ),
      ],
    ),
    'itel': OemBrandInfo(
      name: 'Itel / Infinix / Tecno',
      icon: '📱',
      steps: [
        OemStep(
          title: 'Autostart',
          description:
              'Settings → Apps → Permissions → Autostart → Aktifkan Projek Adzan',
          hasButton: true,
          buttonType: 'autostart',
        ),
        OemStep(
          title: 'Battery Optimization',
          description:
              'Settings → Battery → App Battery Saver → Projek Adzan → No restrictions',
          hasButton: true,
          buttonType: 'battery',
        ),
        OemStep(
          title: 'Phone Master',
          description:
              'Buka Phone Master → Auto-start Management → Aktifkan Projek Adzan',
          hasButton: false,
        ),
        OemStep(
          title: 'Lock App',
          description: 'Buka Recent Apps → Tekan ikon gembok 🔒 pada aplikasi',
          hasButton: false,
        ),
        OemStep(
          title: 'Power Saving Mode',
          description: 'Matikan Power Saving Mode dari Settings → Battery',
          hasButton: false,
        ),
      ],
    ),
    'other': OemBrandInfo(
      name: 'Merek Lainnya',
      icon: '📱',
      steps: [
        OemStep(
          title: 'Battery Optimization',
          description:
              'Settings → Battery → Cari pengaturan untuk menonaktifkan optimasi baterai untuk Projek Adzan',
          hasButton: true,
          buttonType: 'battery',
        ),
        OemStep(
          title: 'Autostart',
          description:
              'Settings → Apps → Permissions → Cari Autostart dan aktifkan untuk Projek Adzan',
          hasButton: true,
          buttonType: 'autostart',
        ),
        OemStep(
          title: 'Lock App',
          description:
              'Buka Recent Apps → Cari cara mengunci aplikasi (biasanya tarik ke bawah atau tekan ikon gembok)',
          hasButton: false,
        ),
      ],
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Bantuan Notifikasi'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _selectedBrand == null
            ? _buildBrandSelector()
            : _buildStepsView(),
      ),
    );
  }

  Widget _buildBrandSelector() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          ),
          child: Column(
            children: [
              const Icon(Icons.help_outline, color: Colors.white, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Notifikasi Azan Tidak Muncul?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Beberapa HP memiliki pengaturan hemat baterai yang agresif. Pilih merek HP Anda untuk panduan pengaturan.',
                style: TextStyle(
                  color: Colors.white.withAlpha(230),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Brand List
        const Text('Pilih Merek HP Anda:', style: AppTheme.titleMedium),
        const SizedBox(height: 12),

        ..._brands.entries.map(
          (entry) => _buildBrandCard(entry.key, entry.value),
        ),
      ],
    );
  }

  Widget _buildBrandCard(String key, OemBrandInfo brand) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: ListTile(
        leading: Text(brand.icon, style: const TextStyle(fontSize: 28)),
        title: Text(
          brand.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          '${brand.steps.length} langkah',
          style: const TextStyle(color: AppTheme.textSecondaryColor),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.primaryColor),
        onTap: () {
          setState(() => _selectedBrand = key);
        },
      ),
    );
  }

  Widget _buildStepsView() {
    final brand = _brands[_selectedBrand]!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _selectedBrand = null),
            ),
            Text(brand.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(child: Text(brand.name, style: AppTheme.titleLarge)),
          ],
        ),
        const SizedBox(height: 16),

        // Progress indicator
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha(25),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            border: Border.all(color: AppTheme.primaryColor.withAlpha(77)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Ikuti semua langkah di bawah ini untuk memastikan notifikasi adzan berfungsi dengan baik.',
                  style: TextStyle(color: AppTheme.primaryColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Steps
        ...brand.steps.asMap().entries.map(
          (entry) => _buildStepCard(entry.key + 1, entry.value),
        ),

        const SizedBox(height: 24),

        // Done button
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.check),
          label: const Text('Selesai'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard(int stepNumber, OemStep step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step number
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '$stepNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.description,
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (step.hasButton) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openSettings(step.buttonType),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Buka Pengaturan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openSettings(String? type) {
    switch (type) {
      case 'battery':
        _alarm.requestIgnoreBatteryOptimizations();
        break;
      case 'autostart':
        _alarm.showAutoStartSettings();
        break;
      default:
        break;
    }
  }
}

/// Model untuk informasi merek HP
class OemBrandInfo {
  final String name;
  final String icon;
  final List<OemStep> steps;

  const OemBrandInfo({
    required this.name,
    required this.icon,
    required this.steps,
  });
}

/// Model untuk langkah-langkah instruksi
class OemStep {
  final String title;
  final String description;
  final bool hasButton;
  final String? buttonType;

  const OemStep({
    required this.title,
    required this.description,
    this.hasButton = false,
    this.buttonType,
  });
}
