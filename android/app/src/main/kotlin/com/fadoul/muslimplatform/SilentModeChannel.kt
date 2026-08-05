package com.fadoul.muslimplatform

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class SilentModeChannel(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "com.example.muslim/silent_mode"
        private var savedRingerMode: Int? = null

        // Android NotificationManager Interruption Filters (API 23+)
        private const val INTERRUPT_FILTER_ALL = 1
        private const val INTERRUPT_FILTER_PRIORITY = 2

        fun muteDevice(context: Context): Boolean {
            return try {
                val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

                // ✅ Always capture ringer mode BEFORE switching, regardless of DND path.
                if (savedRingerMode == null) {
                    savedRingerMode = audioManager.ringerMode
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && notificationManager.isNotificationPolicyAccessGranted) {
                    // Full DND: suppress all interruptions via NotificationManager
                    notificationManager.setInterruptionFilter(INTERRUPT_FILTER_PRIORITY)
                    // Also set ringer to silent for maximum compatibility
                    @Suppress("DEPRECATION")
                    audioManager.ringerMode = AudioManager.RINGER_MODE_SILENT
                } else {
                    // ✅ FIX: Use RINGER_MODE_SILENT (not VIBRATE) — actual silence during prayer.
                    @Suppress("DEPRECATION")
                    audioManager.ringerMode = AudioManager.RINGER_MODE_SILENT
                }
                true
            } catch (e: Exception) {
                android.util.Log.e("SilentModeChannel", "muteDevice error: ${e.message}")
                false
            }
        }

        fun restoreDevice(context: Context): Boolean {
            return try {
                val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && notificationManager.isNotificationPolicyAccessGranted) {
                    notificationManager.setInterruptionFilter(INTERRUPT_FILTER_ALL)
                }

                val targetMode = savedRingerMode ?: AudioManager.RINGER_MODE_NORMAL
                @Suppress("DEPRECATION")
                audioManager.ringerMode = targetMode
                savedRingerMode = null
                true
            } catch (e: Exception) {
                false
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        when (call.method) {
            "hasDndPermission" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    result.success(notificationManager.isNotificationPolicyAccessGranted)
                } else {
                    result.success(true)
                }
            }

            "openDndSettings" -> {
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        try {
                            val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            context.startActivity(intent)
                        } catch (e1: Exception) {
                            val fallbackIntent = Intent(Settings.ACTION_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            context.startActivity(fallbackIntent)
                        }
                    }
                    result.success(true)
                } catch (e: Exception) {
                    android.util.Log.e("SilentModeChannel", "Error launching DND settings: ${e.message}")
                    result.error("ERR_SETTINGS", e.message, null)
                }
            }

            "enableSilentMode" -> {
                val success = muteDevice(context)
                if (success) result.success(true) else result.error("ERR_MUTE", "Could not mute device", null)
            }

            "restoreNormalMode" -> {
                val success = restoreDevice(context)
                if (success) result.success(true) else result.error("ERR_RESTORE", "Could not restore mode", null)
            }

            "isSilentOrDnd" -> {
                val isDnd = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    notificationManager.currentInterruptionFilter != INTERRUPT_FILTER_ALL
                } else false

                val isSilent = audioManager.ringerMode == AudioManager.RINGER_MODE_SILENT ||
                        audioManager.ringerMode == AudioManager.RINGER_MODE_VIBRATE

                result.success(isDnd || isSilent)
            }

            else -> result.notImplemented()
        }
    }
}
