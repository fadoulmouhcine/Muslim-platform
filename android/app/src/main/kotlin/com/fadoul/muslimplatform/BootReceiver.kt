package com.fadoul.muslimplatform

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import com.batoulapps.adhan.CalculationMethod
import com.batoulapps.adhan.Coordinates
import com.batoulapps.adhan.Madhab
import com.batoulapps.adhan.PrayerTimes
import com.batoulapps.adhan.data.DateComponents
import java.util.Calendar
import java.util.Date

class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action == Intent.ACTION_BOOT_COMPLETED || 
            action == "android.intent.action.QUICKBOOT_POWERON" || 
            action == "com.htc.intent.action.QUICKBOOT_POWERON") {
            
            Log.d("BootReceiver", "🚀 Device Boot Detected: $action. Initializing persistent offline re-registration...")
            
            try {
                schedulePrayersFor30Days(context)
                scheduleHarvest(context)
            } catch (e: Exception) {
                Log.e("BootReceiver", "❌ Persistent scheduling failed on boot: ${e.message}")
                e.printStackTrace()
            }
        }
    }

    private fun schedulePrayersFor30Days(context: Context) {
        val prefs: SharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        // Read cached coordinates
        val latStr = prefs.getString("flutter.native_latitude", "0.0")
        val longStr = prefs.getString("flutter.native_longitude", "0.0")
        
        val lat = latStr?.toDoubleOrNull() ?: 0.0
        val long = longStr?.toDoubleOrNull() ?: 0.0

        if (lat == 0.0 && long == 0.0) {
            Log.w("BootReceiver", "⚠️ No coordinates found in SharedPrefs. Skipping Boot rescheduling.")
            return
        }

        // Read calculation params
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

        val coordinates = Coordinates(lat, long)
        val now = System.currentTimeMillis()
        var scheduledCount = 0

        // Schedule alarms for the next 30 days
        for (d in 0 until 30) {
            val calendar = Calendar.getInstance().apply {
                timeInMillis = now + d * 24L * 60 * 60 * 1000
            }
            val dateComponents = DateComponents(
                calendar.get(Calendar.YEAR),
                calendar.get(Calendar.MONTH) + 1, // 0-indexed month
                calendar.get(Calendar.DAY_OF_MONTH)
            )

            val prayerTimes = PrayerTimes(coordinates, dateComponents, params)
            
            val prayers = listOf(
                Triple("Fajr", prayerTimes.fajr, 1),
                Triple("Sunrise", prayerTimes.sunrise, 2),
                Triple("Dhuhr", prayerTimes.dhuhr, 3),
                Triple("Asr", prayerTimes.asr, 4),
                Triple("Maghrib", prayerTimes.maghrib, 5),
                Triple("Isha", prayerTimes.isha, 6)
            )

            for (prayer in prayers) {
                val prayerName = prayer.first
                val time = prayer.second
                val pIndex = prayer.third

                if (time != null) {
                    val timeInMillis = time.time
                    
                    if (timeInMillis > now) {
                        val alarmId = 100 + (d * 10) + pIndex
                        val reminderId = 200 + (d * 10) + pIndex
                        
                        val prefsFlutter = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                        val userNameRaw = prefsFlutter.getString("flutter.userName", "")
                        val suffix = if (!userNameRaw.isNullOrBlank()) " يا $userNameRaw" else ""

                        // 1. Schedule Adhan Alert
                        AlarmScheduler.scheduleAlarm(
                            context,
                            alarmId,
                            timeInMillis,
                            prayerName,
                            safeSoundName,
                            false,
                            "حان الآن موعد أذان $prayerName$suffix",
                            "حي على الصلاة - حي على الفلاح",
                            null
                        )
                        scheduledCount++

                        // 2. Schedule Pre-Adhan Reminder (if offset > 0)
                        if (offset > 0 && prayerName != "Sunrise") {
                            val reminderTime = timeInMillis - (offset * 60 * 1000)
                            if (reminderTime > now) {
                                val reminderBodyText = when (offset) {
                                    1 -> "تبقت دقيقة واحدة على الأذان"
                                    2 -> "تبقت دقيقتان على الأذان"
                                    in 3..10 -> "تبقت $offset دقائق على الأذان"
                                    else -> "تبقت $offset دقيقة على الأذان"
                                }
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
                                scheduledCount++
                            }
                        }
                    }
                }
            }
        }
        Log.d("BootReceiver", "✅ Successfully rescheduled $scheduledCount tasks for the next 30 days!")
    }

    private fun scheduleHarvest(context: Context) {
        try {
            val calendar = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, 21)
                set(Calendar.MINUTE, 30)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            
            var harvestTime = calendar.timeInMillis
            val now = System.currentTimeMillis()
            
            if (harvestTime <= now) {
                harvestTime += 24L * 60 * 60 * 1000
            }
            
            Log.d("BootReceiver", "🌾 Scheduling boot persistence Harvest: 21:30 at $harvestTime")
            AlarmScheduler.scheduleAlarm(
                context,
                400,
                harvestTime,
                "Harvest",
                "takbeer",
                true,
                "حصاد اليوم 🌿",
                "اضغط لتدوين حصاد اليوم",
                "daily_harvest"
            )
        } catch (e: Exception) {
            Log.e("BootReceiver", "❌ Failed to reschedule Harvest on boot: ${e.message}")
        }
    }
}
