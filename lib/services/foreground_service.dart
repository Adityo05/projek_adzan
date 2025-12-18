import 'package:flutter/services.dart';

/// Service untuk mengelola Foreground Service Android
/// Diperlukan agar alarm tetap berjalan di background
class ForegroundService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.azan/foreground',
  );

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  Future<bool> start({
    String title = 'Aplikasi Azan',
    String content = 'Menunggu waktu sholat berikutnya',
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('startService', {
        'title': title,
        'content': content,
      });
      _isRunning = result ?? false;
      return _isRunning;
    } catch (e) {
      return false;
    }
  }

  Future<bool> stop() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopService');
      _isRunning = false;
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateNotification({
    required String title,
    required String content,
  }) async {
    try {
      return await _channel.invokeMethod<bool>('updateNotification', {
            'title': title,
            'content': content,
          }) ??
          false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkStatus() async {
    try {
      final result = await _channel.invokeMethod<bool>('isServiceRunning');
      _isRunning = result ?? false;
      return _isRunning;
    } catch (e) {
      return false;
    }
  }
}
