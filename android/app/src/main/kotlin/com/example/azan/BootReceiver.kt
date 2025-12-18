package com.example.azan

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences

/**
 * BroadcastReceiver untuk restore alarm setelah device restart
 * Diperlukan karena alarm yang terdaftar akan hilang saat device mati
 */
class BootReceiver : BroadcastReceiver() {
    
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON" ||
            intent.action == "com.htc.intent.action.QUICKBOOT_POWERON") {
            
            // Signal to Flutter app to reschedule alarms
            // This will be handled when the app is opened
            
            val prefs = context.getSharedPreferences("azan_prefs", Context.MODE_PRIVATE)
            prefs.edit().putBoolean("needs_reschedule", true).apply()
            
            // Optionally, start the main activity to reschedule
            // This is commented out to avoid bothering the user
            /*
            val mainIntent = Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                putExtra("reschedule_alarms", true)
            }
            context.startActivity(mainIntent)
            */
        }
    }
}
