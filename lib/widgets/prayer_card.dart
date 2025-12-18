import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/prayer_time.dart';

/// Widget kartu untuk menampilkan waktu sholat
class PrayerCard extends StatelessWidget {
  final PrayerTime prayer;
  final bool isActive;
  final bool isNext;
  final bool alarmEnabled;
  final VoidCallback? onAlarmToggle;

  const PrayerCard({
    super.key,
    required this.prayer,
    this.isActive = false,
    this.isNext = false,
    this.alarmEnabled = true,
    this.onAlarmToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        gradient:
            isNext ? AppTheme.activePrayerGradient : AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        boxShadow: isNext ? AppTheme.elevatedShadow : AppTheme.cardShadow,
        border:
            isNext
                ? Border.all(
                  color: AppTheme.accentColor.withValues(alpha: 0.5),
                  width: 1,
                )
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          onTap: onAlarmToggle,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon waktu sholat
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: prayer.type.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    prayer.type.icon,
                    color: isNext ? AppTheme.accentColor : prayer.type.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Nama dan status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              prayer.type.nameId,
                              style: AppTheme.titleLarge.copyWith(
                                color: isNext ? AppTheme.accentColor : null,
                                fontWeight:
                                    isNext ? FontWeight.bold : FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isNext) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'BERIKUTNYA',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prayer.type.nameArabic,
                        style: AppTheme.bodyMedium.copyWith(
                          fontFamily: 'serif',
                        ),
                      ),
                    ],
                  ),
                ),
                // Waktu
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      prayer.formattedTime,
                      style: TextStyle(
                        fontSize: isNext ? 28 : 24,
                        fontWeight: FontWeight.bold,
                        color:
                            isNext
                                ? AppTheme.accentColor
                                : AppTheme.textPrimaryColor,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Toggle alarm
                    Icon(
                      alarmEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      color:
                          alarmEnabled
                              ? (isNext
                                  ? AppTheme.accentColor
                                  : AppTheme.successColor)
                              : AppTheme.textSecondaryColor,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
