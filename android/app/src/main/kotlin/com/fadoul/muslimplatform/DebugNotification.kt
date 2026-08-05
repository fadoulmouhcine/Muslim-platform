package com.fadoul.muslimplatform

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat

object DebugNotification {
    fun show(context: Context, title: String, body: String) {
        // Only for Debugging - Comment out in Production
        val channelId = "debug_channel"
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Debug Notifications",
                NotificationManager.IMPORTANCE_HIGH
            )
            manager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_menu_info_details)
            .setContentTitle("🐞 DEBUG: $title")
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()
            
        // Use a random ID to stack notifications
        manager.notify((System.currentTimeMillis() % 10000).toInt(), notification)
    }
}
