package com.example.muslim

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

object AlarmScheduler {

    fun scheduleAlarm(
        context: Context,
        requestCode: Int,
        timeInMillis: Long,
        prayerName: String,
        soundFile: String,
        isReminder: Boolean,
        title: String,
        body: String,
        payload: String?
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        // Intent for BroadcastReceiver
        val intent = Intent(context, AdhanBroadcastReceiver::class.java).apply {
            putExtra("PRAYER_NAME", prayerName)
            putExtra("SOUND_FILE", soundFile)
            putExtra("SCHEDULED_TIME", timeInMillis)
            putExtra("IS_REMINDER", isReminder)
            putExtra("TITLE", title)
            putExtra("BODY", body)
            putExtra("PAYLOAD", payload)
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        
        // Android 12+ requires exact alarm permission check
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (!alarmManager.canScheduleExactAlarms()) {
                Log.e("AlarmScheduler", "❌ Cannot schedule exact alarm: Permission denied")
                return
            }
        }
        
        try {
            alarmManager.setAlarmClock(
                AlarmManager.AlarmClockInfo(timeInMillis, pendingIntent),
                pendingIntent
            )
            Log.d("AlarmScheduler", "✅ Alarm Scheduled: $prayerName (Reminder: $isReminder) at $timeInMillis")
        } catch (e: SecurityException) {
            Log.e("AlarmScheduler", "❌ SecurityException while scheduling alarm: ${e.message}")
        } catch (e: Exception) {
            Log.e("AlarmScheduler", "❌ Error scheduling alarm: ${e.message}")
        }
    }
    
    fun cancelAlarm(context: Context, requestCode: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AdhanBroadcastReceiver::class.java)
        
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        
        alarmManager.cancel(pendingIntent)
    }
}
