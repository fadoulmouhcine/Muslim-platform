package com.example.muslim

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.app.PendingIntent // ✅ FIX: Added missing import
import android.util.Log

/**
 * 📡 BroadcastReceiver باش يستقبل الإشعارات و يشغل Foreground Service
 * 
 * هادا كيتلاقى alarm من flutter_local_notifications
 * و كيبدا AdhanService باش يلعب الأذان
 */
class AdhanBroadcastReceiver : BroadcastReceiver() {
    
    companion object {
        private var lastBroadcastTime: Long = 0L
        private var lastBroadcastPrayer: String = ""
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d("AdhanBroadcastReceiver", "📡 Received broadcast!")
        
        // نجيبو البيانات من Intent
        val prayerName = intent.getStringExtra("PRAYER_NAME") ?: "الصلاة"
        val soundFile = intent.getStringExtra("SOUND_FILE") ?: "adhan_hamza"
        val scheduledTime = intent.getLongExtra("SCHEDULED_TIME", 0L)
        val isReminder = intent.getBooleanExtra("IS_REMINDER", false)
        val title = intent.getStringExtra("TITLE") ?: "تذكير"
        val body = intent.getStringExtra("BODY") ?: "اقتربت الصلاة"
        val payload = intent.getStringExtra("PAYLOAD") // ✅ Get Payload

        val now = System.currentTimeMillis()
        if (!isReminder && prayerName == lastBroadcastPrayer && (now - lastBroadcastTime) < 30000L) {
            Log.w("AdhanBroadcastReceiver", "⚠️ Duplicate broadcast for $prayerName received within 30s (${now - lastBroadcastTime}ms). Ignoring.")
            return
        }
        lastBroadcastTime = now
        lastBroadcastPrayer = prayerName

        // 🔒 STALE CHECK: Time Jump Fix (Unified for Adhan & Reminder)
        if (scheduledTime > 0) {
            val currentTime = System.currentTimeMillis()
            val diff = currentTime - scheduledTime
            
            if (diff > 60000) {
                Log.w("AdhanBroadcastReceiver", "⚠️ LAG/STALE ALARM DETECTED for $prayerName (Reminder: $isReminder)!")
                Log.w("AdhanBroadcastReceiver", "   Scheduled: $scheduledTime, Current: $currentTime, Diff: ${diff}ms")
                Log.w("AdhanBroadcastReceiver", "   🚫 SKIPPING to prevent spam.")
                return
            }
        }
        
        Log.d("AdhanBroadcastReceiver", "Received Alarm: $prayerName, IsReminder: $isReminder")
        
        if (isReminder) {
            // 📣 SHOW STANDARD NOTIFICATION (Manual)
            showReminderNotification(context, title, body, soundFile, payload)
        } else {
            // 🕌 START ADHAN SERVICE
            AdhanService.startAdhan(context, prayerName, soundFile, title, body)
        }
    }

    private fun showReminderNotification(context: Context, title: String, body: String, soundName: String, payload: String?) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
        val channelId = "reminder_channel_v11_native" // Native Channel
        
        // 1. Create Channel if needed
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            val channel = android.app.NotificationChannel(
                channelId,
                "Reminders (Native)",
                android.app.NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for prayer reminders"
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(channel)
        }

        // 2. Play Sound manually? Or use Notification Sound?
        // Finding Resource ID dynamically
        val soundResId = context.resources.getIdentifier(soundName, "raw", context.packageName)
        val soundUri = if (soundResId != 0) {
            android.net.Uri.parse("android.resource://" + context.packageName + "/" + soundResId)
        } else {
            android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_NOTIFICATION)
        }

        // 3. Build Notification
        val statIconRes = context.resources.getIdentifier("ic_stat_adhan", "drawable", context.packageName)
        val safeIcon = if (statIconRes != 0) statIconRes else android.R.drawable.ic_dialog_info

        val builder = androidx.core.app.NotificationCompat.Builder(context, channelId)
            .setSmallIcon(safeIcon) 
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(androidx.core.app.NotificationCompat.PRIORITY_HIGH)
            .setOngoing(false)
            .setAutoCancel(false)
            .setVisibility(androidx.core.app.NotificationCompat.VISIBILITY_PUBLIC)
            .setSound(soundUri)
            .setVibrate(longArrayOf(0, 500, 200, 500))

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

        notificationManager.notify((System.currentTimeMillis() % 10000).toInt(), builder.build())
        Log.d("AdhanBroadcastReceiver", "🔔 Native Notification POSTED: $title (Icon: $safeIcon)")
    }
}
