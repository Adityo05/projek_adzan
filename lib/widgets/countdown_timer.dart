import 'dart:async';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/prayer_time.dart';

/// Widget untuk menampilkan countdown menuju waktu sholat berikutnya
class CountdownTimer extends StatefulWidget {
  final PrayerTime? nextPrayer;
  final VoidCallback? onPrayerTime;

  const CountdownTimer({super.key, this.nextPrayer, this.onPrayerTime});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _startTimer();
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nextPrayer != widget.nextPrayer) {
      _updateRemaining();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    setState(() => _currentTime = now);

    if (widget.nextPrayer == null) {
      setState(() => _remaining = Duration.zero);
      return;
    }

    final target = widget.nextPrayer!.adjustedTime;

    if (target.isBefore(now)) {
      widget.onPrayerTime?.call();
      setState(() => _remaining = Duration.zero);
    } else {
      setState(() => _remaining = target.difference(now));
    }
  }

  String _formatCurrentTime() {
    final hour = _currentTime.hour.toString().padLeft(2, '0');
    final minute = _currentTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.nextPrayer == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Jam saat ini (besar, di tengah)
          Text(
            _formatCurrentTime(),
            style: AppTheme.countdownStyle.copyWith(
              fontSize: 56,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Label nama sholat
          Text(
            'Menuju ${widget.nextPrayer!.type.nameId}',
            style: AppTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          // Remaining time (lebih kecil)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              _formatDuration(_remaining),
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
