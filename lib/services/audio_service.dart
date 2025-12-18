import 'package:flutter/services.dart';

/// Service untuk pemutaran audio azan dari file lokal
class AudioService {
  static const MethodChannel _channel = MethodChannel('com.example.azan/audio');

  /// Daftar file azan yang tersedia
  static const List<Map<String, String>> availableAzans = [
    {'id': 'Adzan', 'name': 'Adzan Utama', 'file': 'Adzan.mp3'},
    {'id': 'Adzan_subuh', 'name': 'Adzan Subuh', 'file': 'Adzan_subuh.mp3'},
  ];

  double _volume = 0.8;
  bool _isPlaying = false;

  double get volume => _volume;
  bool get isPlaying => _isPlaying;

  Future<bool> play(String azanId) async {
    try {
      final result = await _channel.invokeMethod<bool>('playAzan', {
        'azanId': azanId,
        'volume': _volume,
      });
      _isPlaying = result ?? false;
      return _isPlaying;
    } catch (e) {
      return false;
    }
  }

  Future<bool> stop() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopAzan');
      _isPlaying = false;
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    try {
      return await _channel.invokeMethod<bool>('setVolume', {
            'volume': _volume,
          }) ??
          false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> pause() async {
    try {
      final result = await _channel.invokeMethod<bool>('pauseAzan');
      if (result == true) _isPlaying = false;
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resume() async {
    try {
      final result = await _channel.invokeMethod<bool>('resumeAzan');
      if (result == true) _isPlaying = true;
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  String getAzanName(String azanId) {
    final azan = availableAzans.firstWhere(
      (a) => a['id'] == azanId,
      orElse: () => {'name': 'Unknown'},
    );
    return azan['name'] ?? 'Unknown';
  }
}
