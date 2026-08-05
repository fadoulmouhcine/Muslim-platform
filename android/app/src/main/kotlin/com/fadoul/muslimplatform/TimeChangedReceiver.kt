package com.fadoul.muslimplatform

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import androidx.work.OneTimeWorkRequest
import androidx.work.WorkManager
import androidx.work.Data
import com.batoulapps.adhan.CalculationMethod
import com.batoulapps.adhan.Coordinates
import com.batoulapps.adhan.Madhab
import com.batoulapps.adhan.PrayerTimes
import com.batoulapps.adhan.data.DateComponents
import java.util.Date

class TimeChangedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        
        if (action == Intent.ACTION_TIME_CHANGED || 
            action == Intent.ACTION_TIMEZONE_CHANGED) {
             
             Log.d("TimeChangedReceiver", "⏰ Time Changed Detected: $action")
             
             // 1. Native Fallback: Try to schedule NEXT prayer immediately
             try {
                 scheduleNextPrayerNatively(context)
             } catch (e: Exception) {
                 Log.e("TimeChangedReceiver", "❌ Native Adhan Logic Failed: ${e.message}")
                 e.printStackTrace()
             }

             // 2. Trigger Full Resync via WorkManager (for full 3-day schedule)
             triggerFlutterSync(context)
        }
    }
    
     private fun scheduleNextPrayerNatively(context: Context) {
        val prefs: SharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        // ---------------------------------------------------------
        // 1. Always Schedule Harvest (Independent of Location/Prayer)
        // ---------------------------------------------------------
        try {
             val calendar = java.util.Calendar.getInstance()
             calendar.set(java.util.Calendar.HOUR_OF_DAY, 21)
             calendar.set(java.util.Calendar.MINUTE, 30)
             calendar.set(java.util.Calendar.SECOND, 0)
             calendar.set(java.util.Calendar.MILLISECOND, 0)
             
             var harvestTime = calendar.timeInMillis
             val now = System.currentTimeMillis()
             
             // If 21:30 has already passed today, schedule for tomorrow
             if (harvestTime <= now) {
                 harvestTime += 24 * 60 * 60 * 1000 // Add 1 Day
             }
             
             Log.d("TimeChangedReceiver", "🌾 Scheduling Harvest Fixed: 21:30 at $harvestTime")
             AlarmScheduler.scheduleAlarm(
                 context,
                 400, // Harvest ID
                 harvestTime,
                 "Harvest",
                 "takbeer",
                 true, // shows a Notification
                 "حصاد اليوم 🌿",
                 "اضغط لتدوين حصاد اليوم",
                 "daily_harvest"
             )
        } catch (e: Exception) {
            Log.e("TimeChangedReceiver", "❌ Failed to schedule Harvest: ${e.message}")
        }
        
        // 🔒 Anti-Drift Guardrail: Enforce immutable cached coordinates, disabling dynamic GPS queries
        val latStr = prefs.getString("flutter.native_latitude", "0.0")
        val longStr = prefs.getString("flutter.native_longitude", "0.0")
        
        val lat = latStr?.toDoubleOrNull() ?: 0.0
        val long = longStr?.toDoubleOrNull() ?: 0.0
        
        val methodIndex = try {
            prefs.getLong("flutter.native_calculation_method_index", 3).toInt()
        } catch (e: Exception) {
            prefs.getInt("flutter.native_calculation_method_index", 3)
        }
        
        val madhabIndex = try {
            prefs.getLong("flutter.native_madhab_index", 1).toInt()
        } catch (e: Exception) {
            prefs.getInt("flutter.native_madhab_index", 1)
        }
        
        val offset = try {
            prefs.getLong("flutter.native_notification_offset", 0).toInt()
        } catch (e: Exception) {
            prefs.getInt("flutter.native_notification_offset", 0)
        }
        
        val soundName = prefs.getString("flutter.adhanSound", "adhan_hamza") ?: "adhan_hamza"
        val safeSoundName = soundName.split(".").first()

        if (lat == 0.0 && long == 0.0) {
            Log.w("TimeChangedReceiver", "⚠️ No coordinates found in SharedPrefs (native_latitude/longitude). Skipping native logic.")
            return
        }
        
        val params = when(methodIndex) {
            0 -> CalculationMethod.MUSLIM_WORLD_LEAGUE.parameters
            1 -> CalculationMethod.EGYPTIAN.parameters
            2 -> CalculationMethod.KARACHI.parameters
            3 -> CalculationMethod.UMM_AL_QURA.parameters
            4 -> CalculationMethod.DUBAI.parameters
            5 -> CalculationMethod.QATAR.parameters
            21 -> com.batoulapps.adhan.CalculationParameters(19.0, 17.0).apply {
                method = CalculationMethod.OTHER
            }
            else -> com.batoulapps.adhan.CalculationParameters(19.0, 17.0).apply {
                method = CalculationMethod.OTHER
            }
        }
        
        params.madhab = if (madhabIndex == 2) Madhab.HANAFI else Madhab.SHAFI
        
        val date = DateComponents.from(Date())
        val coordinates = Coordinates(lat, long)
        val prayerTimes = PrayerTimes(coordinates, date, params)
        
        val nextPrayer = prayerTimes.nextPrayer()
        val nextTime = prayerTimes.timeForPrayer(nextPrayer)
        
        if (nextTime != null) {
             val prayerName = getPrayerName(nextPrayer)
             if (prayerName != "Unknown") {
                 val timeInMillis = nextTime.time
                 val now = System.currentTimeMillis()
                 
                 // 1. Schedule Adhan
                 if (timeInMillis > now) {
                     Log.d("TimeChangedReceiver", "🕌 Scheduling Next Prayer Natively: $prayerName at $timeInMillis")
                     
                     val pIndex = when(nextPrayer) {
                         com.batoulapps.adhan.Prayer.FAJR -> 1
                         com.batoulapps.adhan.Prayer.SUNRISE -> 2
                         com.batoulapps.adhan.Prayer.DHUHR -> 3
                         com.batoulapps.adhan.Prayer.ASR -> 4
                         com.batoulapps.adhan.Prayer.MAGHRIB -> 5
                         com.batoulapps.adhan.Prayer.ISHA -> 6
                         else -> 99
                     }
                     
                     val alarmId = 100 + pIndex
                     val reminderId = 200 + pIndex

                     AlarmScheduler.scheduleAlarm(
                         context,
                         alarmId,
                         timeInMillis,
                         prayerName,
                         safeSoundName,
                         false, 
                         "حان الآن موعد أذان $prayerName",
                         "حي على الصلاة - حي على الفلاح",
                         null
                     )
                     
                     // 2. Schedule Reminder (if offset > 0)
                     if (offset > 0 && prayerName != "Sunrise") {
                         val reminderTime = timeInMillis - (offset * 60 * 1000)
                         if (reminderTime > now) {
                             val reminderBodyText = when (offset) {
                                 1 -> "تبقت دقيقة واحدة على الأذان"
                                 2 -> "تبقت دقيقتان على الأذان"
                                 in 3..10 -> "تبقت $offset دقائق على الأذان"
                                 else -> "تبقت $offset دقيقة على الأذان"
                             }
                             Log.d("TimeChangedReceiver", "🔔 Scheduling Reminder Natively: $prayerName at $reminderTime")
                             AlarmScheduler.scheduleAlarm(
                                 context,
                                 reminderId,
                                 reminderTime,
                                 prayerName,
                                 "takbeer",
                                 true,
                                 "اقتربت صلاة $prayerName",
                                 reminderBodyText,
                                 null
                             )
                         }
                     }
                 }
             }
        }
    }
    
    private fun getPrayerName(prayer: com.batoulapps.adhan.Prayer): String {
        return when(prayer) {
            com.batoulapps.adhan.Prayer.FAJR -> "Fajr"
            com.batoulapps.adhan.Prayer.DHUHR -> "Dhuhr"
            com.batoulapps.adhan.Prayer.ASR -> "Asr"
            com.batoulapps.adhan.Prayer.MAGHRIB -> "Maghrib"
            com.batoulapps.adhan.Prayer.ISHA -> "Isha"
            else -> "Unknown"
        }
    }

    private fun triggerFlutterSync(context: Context) {
             // Prepare Data for Flutter WorkManager
             val data = Data.Builder()
                 .putString("be.tramckrijte.workmanager.DART_TASK", "rescheduleTask")
                 .build()

             try {
                val workerClass = Class.forName("be.tramckrijte.workmanager.BackgroundWorker") as Class<out androidx.work.ListenableWorker>
                
                val workRequest = OneTimeWorkRequest.Builder(workerClass)
                    .setInputData(data)
                    .addTag("rescheduleTask")
                    .setExpedited(androidx.work.OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
                    .build()

                WorkManager.getInstance(context).enqueueUniqueWork(
                    "rescheduleTask_time_change",
                    androidx.work.ExistingWorkPolicy.REPLACE,
                    workRequest
                )
                Log.d("MuslimAppTracker", "✅ Expedited Work (REPLACE) Enqueued!")
                
             } catch (e: Exception) {
                 Log.e("TimeChangedReceiver", "❌ Failed to schedule work: ${e.message}")
                 e.printStackTrace()
             }
    }
}
