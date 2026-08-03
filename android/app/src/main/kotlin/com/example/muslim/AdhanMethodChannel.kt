package com.example.muslim

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * 🔗 MethodChannel باش Flutter يتصل بـ Native Android
 */
class AdhanMethodChannel(private val context: Context) : MethodChannel.MethodCallHandler {
    
    companion object {
        const val CHANNEL_NAME = "com.example.muslim/adhan"
        private var previewPlayer: MediaPlayer? = null
    }

    private fun stopPreview() {
        try {
            if (previewPlayer?.isPlaying == true) {
                previewPlayer?.stop()
            }
            previewPlayer?.release()
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            previewPlayer = null
        }
    }
    
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "playAdhanForeground" -> {
                val prayerName = call.argument<String>("prayerName") ?: "صلاة الأذان"
                val soundFile = call.argument<String>("soundFile") ?: "adhan_hamza"
                
                // بدء Foreground Service
                AdhanService.startAdhan(context, prayerName, soundFile)
                
                result.success("Adhan started")
            }

            "playAdhanPreview" -> {
                val soundFile = call.argument<String>("soundFile") ?: "adhan_hamza"
                val volume = call.argument<Double>("volume")?.toFloat() ?: 1.0f

                stopPreview()

                try {
                    val resId = context.resources.getIdentifier(soundFile, "raw", context.packageName)
                    if (resId == 0) {
                        android.util.Log.e("AdhanPreview", "❌ Sound not found: $soundFile")
                        result.success("Sound not found")
                        return
                    }

                    val uri = Uri.parse("android.resource://${context.packageName}/$resId")

                    // Mirror the exact same pattern as AdhanService.playAdhan()
                    // Do NOT use MediaPlayer.create() — it calls prepare() before
                    // AudioAttributes are applied, which silently fails on Samsung.
                    previewPlayer = MediaPlayer().apply {
                        setAudioAttributes(
                            AudioAttributes.Builder()
                                .setUsage(AudioAttributes.USAGE_ALARM)
                                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                                .build()
                        )
                        setDataSource(context, uri)
                        setVolume(volume, volume)
                        
                        setOnCompletionListener {
                            android.util.Log.d("AdhanPreview", "✅ Preview completed")
                            stopPreview()
                        }
                        setOnErrorListener { _, what, extra ->
                            android.util.Log.e("AdhanPreview", "❌ Error: what=$what, extra=$extra")
                            stopPreview()
                            true
                        }
                        
                        prepare()
                        start()
                        android.util.Log.d("AdhanPreview", "▶️ Playing preview: $soundFile vol=$volume")
                    }
                } catch (e: Exception) {
                    android.util.Log.e("AdhanPreview", "❌ Exception: ${e.message}")
                    e.printStackTrace()
                }
                result.success("Preview started")
            }

            "stopAdhanPreview" -> {
                stopPreview()
                result.success("Preview stopped")
            }

            "isPreviewPlaying" -> {
                val isPlaying = try {
                    previewPlayer?.isPlaying == true
                } catch (e: Exception) {
                    false
                }
                result.success(isPlaying)
            }

            // ✅ NEW: Real-time volume control while preview is playing
            "setPreviewVolume" -> {
                val volume = call.argument<Double>("volume")?.toFloat() ?: 1.0f
                try {
                    previewPlayer?.setVolume(volume, volume)
                    result.success("Volume set to $volume")
                } catch (e: Exception) {
                    android.util.Log.e("AdhanPreview", "❌ setPreviewVolume error: ${e.message}")
                    result.success("Error setting volume")
                }
            }
            
            "scheduleAdhanAlarm" -> {
                val requestCode = call.argument<Int>("requestCode") ?: 0
                val timeInMillis = call.argument<Long>("timeInMillis") ?: 0L
                val prayerName = call.argument<String>("prayerName") ?: "الصلاة"
                val soundFile = call.argument<String>("soundFile") ?: "adhan_hamza"
                
                // NEW: Reminder arguments
                val isReminder = call.argument<Boolean>("isReminder") ?: false
                val title = call.argument<String>("title") ?: "تذكير"
                val body = call.argument<String>("body") ?: "اقتربت الصلاة"
                val payload = call.argument<String>("payload")
                
                AlarmScheduler.scheduleAlarm(context, requestCode, timeInMillis, prayerName, soundFile, isReminder, title, body, payload)
                
                result.success("Alarm scheduled")
            }

            "stopAdhan" -> {
                AdhanService.stopAdhan(context)
                result.success("Stopped")
            }

            "isAdhanPlaying" -> {
                result.success(AdhanService.isServiceRunning)
            }
            
            "cancelAdhanAlarm" -> {
                val requestCode = call.argument<Int>("requestCode") ?: 0
                AlarmScheduler.cancelAlarm(context, requestCode)
                result.success("Alarm cancelled")
            }
            
            "getInitialPayload" -> {
                // 1. Try Memory (Intent)
                var payload = MainActivity.initialPayload
                
                // 2. ALWAYS Clean up Persistence (SharedPrefs Backup) 
                // This prevents "Zombie" payloads on next launch
                try {
                    val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    val storedPayload = prefs.getString("flutter.notification_payload", null)
                    
                    if (payload == null && storedPayload != null) {
                        // Only use stored payload if Memory is empty
                        payload = storedPayload
                    }
                    
                    // 🔥 NUCLEAR CLEANUP: Remove it immediately so it never triggers twice
                    prefs.edit().remove("flutter.notification_payload").apply()
                    
                } catch (e: Exception) {
                    // Ignore errors
                }

                // Clear Memory reference
                MainActivity.initialPayload = null
                result.success(payload)
            }

            else -> {
                result.notImplemented()
            }
        }
    }
    
}
