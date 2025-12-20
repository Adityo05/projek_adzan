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
    
    // Pending result untuk menunggu respons permission
    private var pendingPermissionResult: MethodChannel.Result? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        createNotificationChannels()
        
        // Location Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> {
                    // Jika sudah punya izin, langsung return true
                    if (hasLocationPermission()) {
                        result.success(true)
                    } else {
                        // Simpan result untuk digunakan di callback
                        pendingPermissionResult = result
                        requestLocationPermission()
                    }
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
                "cancelAllReminders" -> {
                    cancelAllReminders()
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
                "refreshDailySchedule" -> {
                    val latitude = call.argument<Double>("latitude") ?: 0.0
                    val longitude = call.argument<Double>("longitude") ?: 0.0
                    refreshDailySchedule(latitude, longitude)
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
    
    // Callback ketika user memilih izin
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == LOCATION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && 
                          grantResults[0] == PackageManager.PERMISSION_GRANTED
            
            // Selesaikan pending result dengan hasil izin
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
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
    
    private fun cancelAllReminders() {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        // Reminder request codes are alarm codes + 100 (1101-1106)
        for (code in 1101..1106) {
            val intent = Intent(this, ReminderReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                code,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pendingIntent)
        }
    }
    
    /**
     * Refresh jadwal harian dari API dan schedule alarm
     * Dipanggil oleh WorkManager di background
     */
    private fun refreshDailySchedule(latitude: Double, longitude: Double) {
        Thread {
            try {
                // Fetch jadwal dari API Aladhan
                val today = java.text.SimpleDateFormat("dd-MM-yyyy", java.util.Locale.getDefault()).format(java.util.Date())
                val url = java.net.URL("https://api.aladhan.com/v1/timings/$today?latitude=$latitude&longitude=$longitude&method=20")
                val connection = url.openConnection() as java.net.HttpURLConnection
                connection.requestMethod = "GET"
                connection.connectTimeout = 30000
                connection.readTimeout = 30000
                
                if (connection.responseCode == 200) {
                    val response = connection.inputStream.bufferedReader().use { it.readText() }
                    val jsonObject = org.json.JSONObject(response)
                    val timings = jsonObject.getJSONObject("data").getJSONObject("timings")
                    
                    // Parse waktu sholat
                    val prayerTimes = mapOf(
                        "Fajr" to (timings.getString("Fajr").split(" ")[0]),
                        "Dhuhr" to (timings.getString("Dhuhr").split(" ")[0]),
                        "Asr" to (timings.getString("Asr").split(" ")[0]),
                        "Maghrib" to (timings.getString("Maghrib").split(" ")[0]),
                        "Isha" to (timings.getString("Isha").split(" ")[0])
                    )
                    
                    // Baca settings dari SharedPreferences
                    val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    val vibrate = prefs.getBoolean("flutter.vibration_enabled", true)
                    val defaultAzan = prefs.getString("flutter.selected_azan", "Adzan") ?: "Adzan"
                    val fajrAzan = prefs.getString("flutter.fajr_azan", "Adzan_subuh") ?: "Adzan_subuh"
                    
                    // Schedule alarm untuk setiap waktu sholat
                    val calendar = java.util.Calendar.getInstance()
                    val prayerCodes = mapOf(
                        "Fajr" to 1001,
                        "Dhuhr" to 1003,
                        "Asr" to 1004,
                        "Maghrib" to 1005,
                        "Isha" to 1006
                    )
                    
                    for ((prayerName, timeString) in prayerTimes) {
                        val parts = timeString.split(":")
                        if (parts.size == 2) {
                            calendar.set(java.util.Calendar.HOUR_OF_DAY, parts[0].toInt())
                            calendar.set(java.util.Calendar.MINUTE, parts[1].toInt())
                            calendar.set(java.util.Calendar.SECOND, 0)
                            
                            val prayerTime = calendar.timeInMillis
                            val now = System.currentTimeMillis()
                            
                            // Hanya schedule jika belum lewat
                            if (prayerTime > now) {
                                val azanFile = if (prayerName == "Fajr") fajrAzan else defaultAzan
                                val requestCode = prayerCodes[prayerName] ?: 1001
                                
                                scheduleAlarmBackground(
                                    requestCode,
                                    prayerTime,
                                    azanFile,
                                    vibrate,
                                    getPrayerNameId(prayerName)
                                )
                            }
                        }
                    }
                    
                    android.util.Log.i("BackgroundRefresh", "Successfully refreshed prayer schedule")
                }
                
                connection.disconnect()
            } catch (e: Exception) {
                android.util.Log.e("BackgroundRefresh", "Error refreshing schedule: ${e.message}")
            }
        }.start()
    }
    
    private fun getPrayerNameId(englishName: String): String {
        return when (englishName) {
            "Fajr" -> "Subuh"
            "Dhuhr" -> "Dzuhur"
            "Asr" -> "Ashar"
            "Maghrib" -> "Maghrib"
            "Isha" -> "Isya"
            else -> englishName
        }
    }
    
    private fun scheduleAlarmBackground(requestCode: Int, time: Long, azanFile: String, vibrate: Boolean, prayerName: String) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        val intent = Intent(this, AlarmReceiver::class.java).apply {
            action = "com.example.azan.AZAN_ALARM"
            putExtra("requestCode", requestCode)
            putExtra("azanFile", azanFile)
            putExtra("vibrate", vibrate)
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
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, time, pendingIntent)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, time, pendingIntent)
            }
        } catch (e: SecurityException) {
            alarmManager.set(AlarmManager.RTC_WAKEUP, time, pendingIntent)
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
