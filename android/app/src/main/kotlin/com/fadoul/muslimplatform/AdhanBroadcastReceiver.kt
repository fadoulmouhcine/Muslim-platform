package com.fadoul.muslimplatform

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.app.PendingIntent
import android.media.AudioManager
import android.os.PowerManager
import android.util.Log

/**
 * 📡 BroadcastReceiver باش يستقبل الإشعارات و يشغل Foreground Service
 * 
 * هادا كيتلاقى alarm من flutter_local_notifications
 * و كيبدا AdhanService باش يلعب الأذان
 */
class AdhanBroadcastReceiver : BroadcastReceiver() {
    
    companion object {
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_LAST_TIME = "adhanReceiver_lastBroadcastTime"
        private const val KEY_LAST_PRAYER = "adhanReceiver_lastBroadcastPrayer"
        // 60-second window — matches the stale-alarm check below
        private const val DEDUP_WINDOW_MS = 60_000L
        const val ACTION_MUTE_UPCOMING_ADHAN = "com.fadoul.muslimplatform.ACTION_MUTE_UPCOMING_ADHAN"
        private const val REMINDER_CHANNEL_SOUND = "reminder_channel_v2_sound"
        private const val REMINDER_CHANNEL_SILENT = "reminder_channel_v2_silent"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d("AdhanBroadcastReceiver", "📡 Received broadcast!")
        
        // 1. Instantly acquire a Partial WakeLock to keep CPU awake during execution
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "MuslimApp:ReceiverWakeLock")
        wakeLock.acquire(3000) // Keep CPU awake for 3 seconds to guarantee service starts

        
        // نجيبو البيانات من Intent
        val prayerName = intent.getStringExtra("PRAYER_NAME") ?: "الصلاة"
        val soundFile = intent.getStringExtra("SOUND_FILE") ?: "adhan_hamza"
        val scheduledTime = intent.getLongExtra("SCHEDULED_TIME", 0L)
        val isReminder = intent.getBooleanExtra("IS_REMINDER", false)
        val title = intent.getStringExtra("TITLE") ?: "تذكير"
        val body = intent.getStringExtra("BODY") ?: "اقتربت الصلاة"
        val payload = intent.getStringExtra("PAYLOAD") // ✅ Get Payload

        if (intent.action == ACTION_MUTE_UPCOMING_ADHAN) {
            val mutePrayerName = intent.getStringExtra("PRAYER_NAME") ?: return
            val notifId = intent.getIntExtra("NOTIFICATION_ID", -1)
            
            // 1. Mute it in SharedPreferences
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putBoolean("MUTE_UPCOMING_$mutePrayerName", true).apply()
            
            // 2. Clear the reminder notification
            if (notifId != -1) {
                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                notificationManager.cancel(notifId)
            }
            
            // 3. Show Toast
            android.widget.Toast.makeText(context, "تم كتم أذان $mutePrayerName لهذه الصلاة", android.widget.Toast.LENGTH_SHORT).show()
            
            Log.d("AdhanBroadcastReceiver", "🔕 Muted upcoming adhan for: $mutePrayerName")
            return
        }

        val now = System.currentTimeMillis()

        // 🛡️ PERSISTENT DEDUP: Use SharedPreferences so the guard survives process death
        if (!isReminder) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val lastTime = prefs.getLong(KEY_LAST_TIME, 0L)
            val lastPrayer = prefs.getString(KEY_LAST_PRAYER, "") ?: ""
            if (prayerName == lastPrayer && (now - lastTime) < DEDUP_WINDOW_MS) {
                Log.w("AdhanBroadcastReceiver", "⚠️ Duplicate broadcast for $prayerName received within ${DEDUP_WINDOW_MS / 1000}s (${now - lastTime}ms). Ignoring.")
                return
            }
            prefs.edit()
                .putLong(KEY_LAST_TIME, now)
                .putString(KEY_LAST_PRAYER, prayerName)
                .apply()
        }

        // 🔒 STALE CHECK: Strict 3-minute threshold (180,000 ms)
        if (scheduledTime > 0) {
            val currentTime = System.currentTimeMillis()
            val diff = currentTime - scheduledTime
            
            if (diff > 180000) {
                Log.w("AdhanBroadcastReceiver", "⚠️ LAG/STALE ALARM DETECTED for $prayerName (Reminder: $isReminder)!")
                Log.w("AdhanBroadcastReceiver", "   Scheduled: $scheduledTime, Current: $currentTime, Diff: ${diff}ms")
                Log.w("AdhanBroadcastReceiver", "   🚫 SKIPPING because it is more than 3 minutes late.")
                return
            }
        }
        
        // 🔕 MUTE & SILENT MODE LOGIC
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val isMutedViaReminder = prefs.getBoolean("MUTE_UPCOMING_$prayerName", false)
        val respectSilentMode = prefs.getBoolean("flutter.respect_silent_mode", false)
        
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val ringerMode = audioManager.ringerMode
        val isDeviceSilent = (ringerMode == AudioManager.RINGER_MODE_SILENT || ringerMode == AudioManager.RINGER_MODE_VIBRATE)
        
        val shouldMuteAudio = isMutedViaReminder || (respectSilentMode && isDeviceSilent)
        
        if (isMutedViaReminder) {
            prefs.edit().remove("MUTE_UPCOMING_$prayerName").apply()
        }
        
        Log.d("AdhanBroadcastReceiver", "Received Alarm: $prayerName, IsReminder: $isReminder, shouldMuteAudio: $shouldMuteAudio")
        
        if (isReminder) {
            // 📣 SHOW STANDARD NOTIFICATION (Manual)
            showReminderNotification(context, prayerName, title, body, soundFile, payload, shouldMuteAudio)
        } else {
            // 🕌 START ADHAN SERVICE
            try {
                AdhanService.startAdhan(context, prayerName, soundFile, title, body, shouldMuteAudio)
            } catch (e: Exception) {
                Log.e("AdhanBroadcastReceiver", "❌ Unexpected error starting AdhanService: ${e.message}")
            }
        }
    }

    private fun showReminderNotification(context: Context, prayerName: String, title: String, body: String, soundName: String, payload: String?, isMuted: Boolean) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
        
        // 1. Create Channel if needed
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            if (notificationManager.getNotificationChannel(REMINDER_CHANNEL_SOUND) == null) {
                notificationManager.createNotificationChannel(
                    android.app.NotificationChannel(REMINDER_CHANNEL_SOUND, "Reminders", android.app.NotificationManager.IMPORTANCE_HIGH).apply {
                        description = "Prayer reminders — default system sound"
                        setSound(
                            android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_NOTIFICATION),
                            android.media.AudioAttributes.Builder().setUsage(android.media.AudioAttributes.USAGE_NOTIFICATION).build()
                        )
                        enableVibration(true)
                        vibrationPattern = longArrayOf(0, 500, 200, 500)
                    }
                )
            }
            if (notificationManager.getNotificationChannel(REMINDER_CHANNEL_SILENT) == null) {
                notificationManager.createNotificationChannel(
                    android.app.NotificationChannel(REMINDER_CHANNEL_SILENT, "Reminders (Silent)", android.app.NotificationManager.IMPORTANCE_HIGH).apply {
                        description = "Prayer reminders — muted for this prayer"
                        setSound(null, null)
                        enableVibration(false)
                    }
                )
            }
        }

        val channelId = if (isMuted) REMINDER_CHANNEL_SILENT else REMINDER_CHANNEL_SOUND

        // 2. Build Notification
        val statIconRes = context.resources.getIdentifier("ic_stat_adhan", "drawable", context.packageName)
        val safeIcon = if (statIconRes != 0) statIconRes else android.R.drawable.ic_dialog_info

        val builder = androidx.core.app.NotificationCompat.Builder(context, channelId)
            .setSmallIcon(safeIcon) 
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(androidx.core.app.NotificationCompat.PRIORITY_HIGH)
            .setOngoing(false)
            .setAutoCancel(true)
            .setVisibility(androidx.core.app.NotificationCompat.VISIBILITY_PUBLIC)

         // Intent to open App
        // 🔥 FIX: Use Explicit Intent to ensure extras are delivered reliably
        val contentIntent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            if (payload != null) {
                putExtra("payload", payload)
                Log.d("AdhanBroadcastReceiver", "📩 Attaching Payload: $payload")
                
                // 🛡️ BACKUP: Save to SharedPreferences (Persistent delivery)
                // This ensures that even if Intent Extras are stripped by the Launcher, 
                // Flutter can still retrieve the data from disk.
                try {
                    val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    prefs.edit().putString("flutter.notification_payload", payload).apply()
                    Log.d("AdhanBroadcastReceiver", "💾 Payload Saved to Prefs: $payload")
                } catch (e: Exception) {
                    Log.e("AdhanBroadcastReceiver", "❌ Failed to save payload to prefs: $e")
                }
            }
        }
        
        val pendingContentIntent = PendingIntent.getActivity(
            context, 
            (System.currentTimeMillis() % 10000).toInt(), 
            contentIntent, 
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        builder.setContentIntent(pendingContentIntent)

        val notificationId = (System.currentTimeMillis() % 10000).toInt()
        
        // Mute Action Intent
        val muteIntent = Intent(context, AdhanBroadcastReceiver::class.java).apply {
            action = ACTION_MUTE_UPCOMING_ADHAN
            putExtra("PRAYER_NAME", prayerName)
            putExtra("NOTIFICATION_ID", notificationId)
        }
        val pendingMuteIntent = PendingIntent.getBroadcast(
            context,
            notificationId + 100, // Unique request code
            muteIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        
        if (payload != "daily_harvest") {
            builder.addAction(
                0, // Optional icon, using 0 skips it
                "🔕 عدم تشغيل الأذان لهذه الصلاة",
                pendingMuteIntent
            )
        }

        notificationManager.notify(notificationId, builder.build())
        Log.d("AdhanBroadcastReceiver", "🔔 Native Notification POSTED: $title (Icon: $safeIcon)")
    }
}
