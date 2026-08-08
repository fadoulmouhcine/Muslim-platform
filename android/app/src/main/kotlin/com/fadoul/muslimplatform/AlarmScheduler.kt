package com.fadoul.muslimplatform

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
        payload: String?,
        forceAlarmClock: Boolean = false
    ): Boolean {
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
        
        if (forceAlarmClock) {
            return scheduleViaAlarmClock(context, alarmManager, requestCode, timeInMillis, pendingIntent, prayerName, isReminder)
        }
        
        var scheduled = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && alarmManager.canScheduleExactAlarms()) {
            try {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    timeInMillis,
                    pendingIntent
                )
                scheduled = true
            } catch (e: SecurityException) {
                Log.w("AlarmScheduler", "⚠️ SecurityException on setExactAndAllowWhileIdle, falling back to setAlarmClock: ${e.message}")
            }
        } else if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        timeInMillis,
                        pendingIntent
                    )
                } else {
                    alarmManager.setExact(
                        AlarmManager.RTC_WAKEUP,
                        timeInMillis,
                        pendingIntent
                    )
                }
                scheduled = true
            } catch (e: Exception) {
                Log.w("AlarmScheduler", "⚠️ Exception on setExact, falling back to setAlarmClock: ${e.message}")
            }
        }

        if (!scheduled) {
            scheduled = scheduleViaAlarmClock(context, alarmManager, requestCode, timeInMillis, pendingIntent, prayerName, isReminder)
        }

        if (scheduled) {
            Log.d("AlarmScheduler", "✅ Alarm Scheduled successfully: $prayerName (Reminder: $isReminder) at $timeInMillis")
        }
        return scheduled
    }
    
    private fun scheduleViaAlarmClock(
        context: Context, alarmManager: AlarmManager, requestCode: Int,
        timeInMillis: Long, pendingIntent: PendingIntent, prayerName: String, isReminder: Boolean
    ): Boolean {
        return try {
            val showIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_MAIN
                addCategory(Intent.CATEGORY_LAUNCHER)
            }
            val showPendingIntent = PendingIntent.getActivity(
                context,
                requestCode + 50000,
                showIntent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            val alarmClockInfo = AlarmManager.AlarmClockInfo(timeInMillis, showPendingIntent)
            alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
            Log.d("AlarmScheduler", "✅ Alarm Scheduled via setAlarmClock fallback: $prayerName (Reminder: $isReminder) at $timeInMillis")
            true
        } catch (e: Exception) {
            Log.e("AlarmScheduler", "❌ Error scheduling alarm via setAlarmClock fallback: ${e.message}")
            false
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
