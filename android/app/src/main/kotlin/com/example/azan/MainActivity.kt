package com.example.azan

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Geocoder
import android.location.Location
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity: FlutterActivity() {
    private val LOCATION_CHANNEL = "com.example.azan/location"
    private val ALARM_CHANNEL = "com.example.azan/alarm"
    private val AUDIO_CHANNEL = "com.example.azan/audio"
    private val FOREGROUND_CHANNEL = "com.example.azan/foreground"
    
    private val LOCATION_REQUEST_CODE = 1001
    private val NOTIFICATION_REQUEST_CODE = 1002
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        createNotificationChannels()
        
        // Location Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> {
                    requestLocationPermission()
                    result.success(hasLocationPermission())
                }
                "checkPermission" -> result.success(hasLocationPermission())
                "getCurrentLocation" -> getCurrentLocation(result)
                "reverseGeocode" -> {
                    val lat = call.argument<Double>("latitude") ?: 0.0
                    val lng = call.argument<Double>("longitude") ?: 0.0
                    reverseGeocode(lat, lng, result)
                }
                "openAppSettings" -> {
                    openAppSettings()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        
        // Alarm Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestExactAlarmPermission" -> {
                    requestExactAlarmPermission()
                    result.success(true)
                }
                "canScheduleExactAlarms" -> result.success(canScheduleExactAlarms())
                "scheduleAlarm" -> {
                    val requestCode = call.argument<Int>("requestCode") ?: 0
                    val time = call.argument<Long>("time") ?: 0L
                    val prayerName = call.argument<String>("prayerName") ?: ""
                    val azanFile = call.argument<String>("azanFile") ?: ""
                    val vibrate = call.argument<Boolean>("vibrate") ?: true
                    scheduleAlarm(requestCode, time, prayerName, azanFile, vibrate)
                    result.success(true)
                }
                "scheduleReminder" -> {
                    val requestCode = call.argument<Int>("requestCode") ?: 0
                    val time = call.argument<Long>("time") ?: 0L
                    val prayerName = call.argument<String>("prayerName") ?: ""
                    scheduleReminder(requestCode, time, prayerName)
                    result.success(true)
                }
                "cancelAlarm" -> {
                    val requestCode = call.argument<Int>("requestCode") ?: 0
                    cancelAlarm(requestCode)
                    result.success(true)
                }
                "cancelAllAlarms" -> {
                    cancelAllAlarms()
                    result.success(true)
                }
                "stopAzan" -> {
                    stopAzanService()
                    result.success(true)
                }
                "testAzan" -> {
                    val azanFile = call.argument<String>("azanFile") ?: "Adzan"
                    testAzan(azanFile)
                    result.success(true)
                }
                "isIgnoringBatteryOptimizations" -> result.success(isIgnoringBatteryOptimizations())
                "requestIgnoreBatteryOptimizations" -> {
                    requestIgnoreBatteryOptimizations()
                    result.success(true)
                }
                "showAutoStartSettings" -> {
                    showAutoStartSettings()
                    result.success(true)
                }
                "requestDeviceSpecificPermissions" -> {
                    requestDeviceSpecificPermissions()
                    result.success(true)
                }
                "vibrate" -> {
                    val duration = call.argument<Int>("duration") ?: 50
                    vibrateDevice(duration.toLong())
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        
        // Audio Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "playAzan" -> {
                    val azanId = call.argument<String>("azanId") ?: "Azan"
                    val volume = call.argument<Double>("volume") ?: 0.8
                    playAzan(azanId, volume.toFloat())
                    result.success(true)
                }
                "stopAzan" -> {
                    stopAzanService()
                    result.success(true)
                }
                "setVolume" -> {
                    // Volume akan di-handle oleh service
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        
        // Foreground Service Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FOREGROUND_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val title = call.argument<String>("title") ?: "Projek Adzan"
                    val content = call.argument<String>("content") ?: ""
                    startForegroundService(title, content)
                    result.success(true)
                }
                "stopService" -> {
                    stopAzanService()
                    result.success(true)
                }
                "isServiceRunning" -> result.success(isServiceRunning())
                else -> result.notImplemented()
            }
        }
    }
    
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)
            
            // Azan notification channel
            val azanChannel = NotificationChannel(
                "azan_channel",
                "Alarm Azan",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifikasi untuk alarm azan"
                enableVibration(true)
                setBypassDnd(true)
            }
            notificationManager.createNotificationChannel(azanChannel)
            
            // Foreground service channel
            val foregroundChannel = NotificationChannel(
                "foreground_channel",
                "Layanan Azan",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notifikasi layanan background"
            }
            notificationManager.createNotificationChannel(foregroundChannel)
        }
    }
    
    // Location methods
    private fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
    }
    
    private fun requestLocationPermission() {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION),
            LOCATION_REQUEST_CODE
        )
    }
    
    private fun openAppSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:$packageName")
        }
        startActivity(intent)
    }
    
    private fun getCurrentLocation(result: MethodChannel.Result) {
        if (!hasLocationPermission()) {
            result.success(null)
            return
        }
        
        try {
            val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
            val location = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
                ?: locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
            
            if (location != null) {
                result.success(mapOf(
                    "latitude" to location.latitude,
                    "longitude" to location.longitude,
                    "altitude" to location.altitude
                ))
            } else {
                result.success(null)
            }
        } catch (e: SecurityException) {
            result.success(null)
        }
    }
    
    private fun reverseGeocode(lat: Double, lng: Double, result: MethodChannel.Result) {
        try {
            val geocoder = Geocoder(this, Locale.getDefault())
            val addresses = geocoder.getFromLocation(lat, lng, 1)
            if (!addresses.isNullOrEmpty()) {
                val address = addresses[0]
                result.success(mapOf(
                    "city" to (address.locality ?: address.subAdminArea ?: ""),
                    "province" to (address.adminArea ?: ""),
                    "country" to (address.countryName ?: "")
                ))
            } else {
                result.success(null)
            }
        } catch (e: Exception) {
            result.success(null)
        }
    }
    
    // Alarm methods
    private fun canScheduleExactAlarms(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.canScheduleExactAlarms()
        } else {
            true
        }
    }
    
    private fun requestExactAlarmPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
            startActivity(intent)
        }
    }
    
    private fun scheduleAlarm(requestCode: Int, time: Long, prayerName: String, azanFile: String, vibrate: Boolean) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        val intent = Intent(this, AlarmReceiver::class.java).apply {
            action = "com.example.azan.AZAN_ALARM"
            putExtra("prayerName", prayerName)
            putExtra("azanFile", azanFile)
            putExtra("vibrate", vibrate)
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && alarmManager.canScheduleExactAlarms()) {
                alarmManager.setAlarmClock(
                    AlarmManager.AlarmClockInfo(time, pendingIntent),
                    pendingIntent
                )
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    time,
                    pendingIntent
                )
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    time,
                    pendingIntent
                )
            }
        } catch (e: SecurityException) {
            // Fallback ke alarm biasa
            alarmManager.set(AlarmManager.RTC_WAKEUP, time, pendingIntent)
        }
    }
    
    private fun scheduleReminder(requestCode: Int, time: Long, prayerName: String) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        val intent = Intent(this, ReminderReceiver::class.java).apply {
            action = "com.example.azan.PRAYER_REMINDER"
            putExtra("prayerName", prayerName)
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    time,
                    pendingIntent
                )
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    time,
                    pendingIntent
                )
            }
        } catch (e: SecurityException) {
            alarmManager.set(AlarmManager.RTC_WAKEUP, time, pendingIntent)
        }
    }
    
    private fun cancelAlarm(requestCode: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, AlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
    }
    
    private fun cancelAllAlarms() {
        for (code in 1001..1006) {
            cancelAlarm(code)
        }
    }
    
    // Battery optimization
    private fun isIgnoringBatteryOptimizations(): Boolean {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        return powerManager.isIgnoringBatteryOptimizations(packageName)
    }
    
    private fun requestIgnoreBatteryOptimizations() {
        openAppSettings()
    }
    
    private fun showAutoStartSettings() {
        val intents = listOf(
            // Xiaomi
            Intent().setClassName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity"),
            // Oppo
            Intent().setClassName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity"),
            Intent().setClassName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity"),
            // Vivo
            Intent().setClassName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"),
            Intent().setClassName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity"),
            // Huawei
            Intent().setClassName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"),
            Intent().setClassName("com.huawei.systemmanager", "com.huawei.systemmanager.optimize.process.ProtectActivity"),
            // Samsung
            Intent().setClassName("com.samsung.android.lool", "com.samsung.android.sm.battery.ui.BatteryActivity"),
            Intent().setClassName("com.samsung.android.lool", "com.samsung.android.sm.ui.battery.BatteryActivity"),
            // OnePlus
            Intent().setClassName("com.oneplus.security", "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity"),
            // Realme
            Intent().setClassName("com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity")
        )
        
        for (intent in intents) {
            try {
                startActivity(intent)
                return
            } catch (e: Exception) {
                // Try next intent
            }
        }
        
        // Fallback: open app info settings
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
            }
            startActivity(intent)
        } catch (e: Exception) {
            // Ignore
        }
    }
    
    private fun requestDeviceSpecificPermissions() {
        requestIgnoreBatteryOptimizations()
        showAutoStartSettings()
    }
    
    private fun vibrateDevice(durationMs: Long) {
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as android.os.VibratorManager
            vibratorManager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as android.os.Vibrator
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(android.os.VibrationEffect.createOneShot(durationMs, android.os.VibrationEffect.DEFAULT_AMPLITUDE))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(durationMs)
        }
    }
    
    // Service methods
    private fun playAzan(azanId: String, volume: Float) {
        val intent = Intent(this, AzanForegroundService::class.java).apply {
            action = "PLAY_AZAN"
            putExtra("azanId", azanId)
            putExtra("volume", volume)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
    
    private fun testAzan(azanFile: String) {
        playAzan(azanFile, 0.8f)
    }
    
    private fun startForegroundService(title: String, content: String) {
        val intent = Intent(this, AzanForegroundService::class.java).apply {
            action = "START_FOREGROUND"
            putExtra("title", title)
            putExtra("content", content)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
    
    private fun stopAzanService() {
        val intent = Intent(this, AzanForegroundService::class.java)
        stopService(intent)
    }
    
    private fun isServiceRunning(): Boolean {
        // Simplified check
        return false
    }
}
