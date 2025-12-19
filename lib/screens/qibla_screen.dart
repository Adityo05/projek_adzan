import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../config/app_theme.dart';
import '../models/location_model.dart';
import '../services/storage_service.dart';

/// Halaman kompas arah kiblat dengan sensor
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  final StorageService _storage = StorageService();
  LocationModel? _location;
  double _qiblaDirection = 0; // Arah kiblat dari utara (derajat)
  double _deviceHeading = 0; // Arah perangkat menghadap (derajat)
  bool _hasCompass = false;
  StreamSubscription<CompassEvent>? _compassSubscription;

  @override
  void initState() {
    super.initState();
    _loadLocation();
    _initCompass();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initCompass() async {
    // Cek apakah perangkat memiliki sensor kompas
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (event.heading != null && mounted) {
        final newHeading = event.heading!;
        // Hanya update jika perubahan > 1 derajat untuk mengurangi rebuild
        if ((newHeading - _deviceHeading).abs() > 1.0) {
          setState(() {
            _hasCompass = true;
            _deviceHeading = newHeading;
          });
        } else if (!_hasCompass) {
          setState(() => _hasCompass = true);
        }
      }
    });
  }

  Future<void> _loadLocation() async {
    await _storage.init();
    _location = await _storage.getLocation() ?? LocationModel.defaultLocation;
    _calculateQibla();
  }

  void _calculateQibla() {
    if (_location == null) return;

    final direction = _calculateQiblaDirection(_location!);

    setState(() {
      _qiblaDirection = direction;
    });
  }

  double _calculateQiblaDirection(LocationModel location) {
    const double deg2rad = pi / 180.0;
    const double rad2deg = 180.0 / pi;

    final lat1 = location.latitude * deg2rad;
    final lng1 = location.longitude * deg2rad;
    const lat2 = 21.4225 * deg2rad; // Makkah latitude
    const lng2 = 39.8262 * deg2rad; // Makkah longitude

    final dLng = lng2 - lng1;
    final y = sin(dLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);

    var bearing = atan2(y, x) * rad2deg;
    return (bearing + 360) % 360;
  }

  /// Menghitung sudut rotasi jarum kiblat relatif terhadap arah perangkat
  double get _needleRotation {
    return (_qiblaDirection - _deviceHeading) * pi / 180;
  }

  /// Menghitung berapa derajat user harus memutar
  double get _rotationNeeded {
    return (_qiblaDirection - _deviceHeading + 360) % 360;
  }

  /// Mendapatkan teks instruksi rotasi
  String get _rotationText {
    final rotation = _rotationNeeded;
    if (rotation < 5 || rotation > 355) {
      return '';
    } else if (rotation < 180) {
      return 'Putar ${rotation.toStringAsFixed(0)}° ke kanan';
    } else {
      return 'Putar ${(360 - rotation).toStringAsFixed(0)}° ke kiri';
    }
  }

  /// Cek apakah sudah menghadap kiblat
  bool get _isFacingQibla {
    return _rotationNeeded < 5 || _rotationNeeded > 355;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Arah Kiblat'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Lokasi Info (Dipindah ke body)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _location?.displayName ?? 'Memuat...',
                      style: AppTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildCompass()),
            _buildInfo(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // _buildHeader removal

  Widget _buildCompass() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Kompas
          SizedBox(
            width: 300,
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring - rotates with device heading (wrapped with RepaintBoundary)
                RepaintBoundary(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: -_deviceHeading * pi / 180,
                      end: -_deviceHeading * pi / 180,
                    ),
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    builder: (context, angle, child) {
                      return Transform.rotate(angle: angle, child: child);
                    },
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.cardColor.withAlpha(204),
                            AppTheme.surfaceColor,
                          ],
                        ),
                        boxShadow: AppTheme.elevatedShadow,
                      ),
                      child: Stack(
                        children: [
                          // Compass markings
                          ...List.generate(36, (index) {
                            final angle = index * 10 * pi / 180;
                            return Transform.rotate(
                              angle: angle,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  width: index % 9 == 0
                                      ? 3
                                      : (index % 3 == 0 ? 2 : 1),
                                  height: index % 9 == 0
                                      ? 20
                                      : (index % 3 == 0 ? 12 : 8),
                                  color: index % 9 == 0
                                      ? AppTheme.accentColor
                                      : AppTheme.textSecondaryColor.withAlpha(
                                          128,
                                        ),
                                ),
                              ),
                            );
                          }),
                          // Cardinal directions
                          ..._buildCardinalDirections(),
                        ],
                      ),
                    ),
                  ),
                ),
                // Qibla needle - points to Qibla relative to device heading
                Transform.rotate(
                  angle: _needleRotation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Kaaba icon at the top
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _isFacingQibla
                              ? AppTheme.successColor
                              : AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (_isFacingQibla
                                          ? AppTheme.successColor
                                          : AppTheme.primaryColor)
                                      .withValues(alpha: 0.5),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.mosque,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      // Arrow pointing to Kaaba
                      Container(
                        width: 6,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _isFacingQibla
                                  ? AppTheme.successColor
                                  : AppTheme.primaryColor,
                              (_isFacingQibla
                                      ? AppTheme.successColor
                                      : AppTheme.primaryColor)
                                  .withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ),
                // Center dot
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentColor.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCardinalDirections() {
    const directions = ['U', 'T', 'S', 'B'];

    return List.generate(4, (index) {
      final angle = index * 90;
      return Transform.rotate(
        angle: angle * pi / 180,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Transform.rotate(
              angle: -angle * pi / 180,
              child: Text(
                directions[index],
                style: TextStyle(
                  color: index == 0
                      ? AppTheme.errorColor
                      : AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Arah Kiblat
          Text(
            'Arah Kiblat: ${_qiblaDirection.toStringAsFixed(1)}° dari Utara',
            style: AppTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Status / Instruksi
          if (!_hasCompass)
            Text(
              'Sensor kompas tidak tersedia',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
              textAlign: TextAlign.center,
            )
          else if (_isFacingQibla)
            Text(
              '✓ Anda menghadap kiblat!',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.successColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            )
          else
            Text(
              _rotationText,
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
