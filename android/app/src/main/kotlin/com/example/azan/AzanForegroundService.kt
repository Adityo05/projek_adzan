package com.example.azan

import android.app.*
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * Foreground Service untuk pemutaran audio azan
 * 
 * Foreground Service diperlukan untuk:
 * 1. Memastikan audio tetap diputar meski aplikasi di background
 * 2. Menampilkan notifikasi permanen saat azan
 * 3. Menghindari pembatasan background oleh sistem
 */
class AzanForegroundService : Service() {
    
    companion object {
        private const val TAG = "AzanForegroundService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "azan_channel"
    }
    
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service created")
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "PLAY_AZAN" -> {
                val prayerName = intent.getStringExtra("prayerName") ?: "Sholat"
                val azanFile = intent.getStringExtra("azanFile") ?: intent.getStringExtra("azanId") ?: "Azan"
                val vibrate = intent.getBooleanExtra("vibrate", true)
                val volume = intent.getFloatExtra("volume", 0.8f)
                
                startForeground(NOTIFICATION_ID, createNotification(prayerName))
                acquireWakeLock()
                playAzan(azanFile, volume)
                
                if (vibrate) {
                    startVibration()
                }
            }
            "START_FOREGROUND" -> {
                val title = intent.getStringExtra("title") ?: "Projek Adzan"
                val content = intent.getStringExtra("content") ?: ""
                startForeground(NOTIFICATION_ID, createNotification(title, content))
            }
            "STOP" -> {
                stopAzan()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        
        return START_NOT_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onDestroy() {
        stopAzan()
        releaseWakeLock()
        super.onDestroy()
        Log.d(TAG, "Service destroyed")
    }
    
    private fun createNotification(prayerName: String, content: String? = null): Notification {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val stopIntent = Intent(this, AzanForegroundService::class.java).apply {
            action = "STOP"
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 1, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Waktu $prayerName")
            .setContentText(content ?: "Ketuk untuk menghentikan azan")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentIntent(stopPendingIntent) // Ketuk notifikasi untuk stop
            .addAction(android.R.drawable.ic_delete, "Hentikan", stopPendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .build()
    }
    
    private fun playAzan(azanFile: String, volume: Float) {
        try {
            // Stop any existing playback
            mediaPlayer?.release()
            
            // Get audio file from assets
            // azanFile bisa berupa "Azan" atau "Azan_Subuh" - tambahkan .mp3 jika belum ada
            val fileName = if (azanFile.endsWith(".mp3")) azanFile else "$azanFile.mp3"
            val assetManager = assets
            
            Log.d(TAG, "Trying to play: flutter_assets/assets/audio/$fileName")
            
            val descriptor = assetManager.openFd("flutter_assets/assets/audio/$fileName")
            
            mediaPlayer = MediaPlayer().apply {
                setDataSource(descriptor.fileDescriptor, descriptor.startOffset, descriptor.length)
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                setVolume(volume, volume)
                setOnCompletionListener {
                    stopVibration()
                    stopForeground(STOP_FOREGROUND_REMOVE)
                    stopSelf()
                }
                prepare()
                start()
            }
            
            descriptor.close()
            Log.d(TAG, "Playing azan: $fileName")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error playing azan: ${e.message}")
            e.printStackTrace()
            // Stop service if audio fails
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
        }
    }
    
    private fun stopAzan() {
        try {
            mediaPlayer?.stop()
            mediaPlayer?.release()
            mediaPlayer = null
            stopVibration()
            Log.d(TAG, "Azan stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping azan: ${e.message}")
        }
    }
    
    private fun startVibration() {
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vibratorManager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        
        // Vibration pattern: wait 0ms, vibrate 500ms, wait 500ms, repeat
        val pattern = longArrayOf(0, 500, 500, 500, 500, 500)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator?.vibrate(
                VibrationEffect.createWaveform(pattern, 0),
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .build()
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(pattern, 0)
        }
    }
    
    private fun stopVibration() {
        vibrator?.cancel()
        vibrator = null
    }
    
    private fun acquireWakeLock() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "azan:AzanWakeLock"
        )
        wakeLock?.acquire(5 * 60 * 1000L) // 5 minutes max
    }
    
    private fun releaseWakeLock() {
        if (wakeLock?.isHeld == true) {
            wakeLock?.release()
        }
        wakeLock = null
    }
}
