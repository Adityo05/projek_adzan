package com.example.azan

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager

/**
 * BroadcastReceiver untuk menerima alarm azan
 * Dipicu oleh AlarmManager saat waktu sholat tiba
 */
class AlarmReceiver : BroadcastReceiver() {
    
    override fun onReceive(context: Context, intent: Intent) {
        val prayerName = intent.getStringExtra("prayerName") ?: "Sholat"
        val azanFile = intent.getStringExtra("azanFile") ?: "azan_makkah"
        val vibrate = intent.getBooleanExtra("vibrate", true)
        
        // Acquire wake lock to ensure device stays awake
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
            "azan:AlarmWakeLock"
        )
        wakeLock.acquire(60000) // 1 minute timeout
        
        try {
            // Start foreground service to play azan
            val serviceIntent = Intent(context, AzanForegroundService::class.java).apply {
                action = "PLAY_AZAN"
                putExtra("prayerName", prayerName)
                putExtra("azanFile", azanFile)
                putExtra("vibrate", vibrate)
            }
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } finally {
            if (wakeLock.isHeld) {
                wakeLock.release()
            }
        }
    }
}
