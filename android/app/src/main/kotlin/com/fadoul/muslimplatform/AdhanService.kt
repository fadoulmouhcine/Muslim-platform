package com.fadoul.muslimplatform

import android.annotation.SuppressLint
import android.app.*
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.content.pm.ServiceInfo
import androidx.core.app.NotificationCompat

/**
 * 🕌 Foreground Service للأذان
 * 
 * هذا الـ Service يشتغل بـ Foreground Priority العالية
 * ما يمكن لأي notification يوقفو لأنه كيستعمل:
 * - Audio Focus بـ USAGE_ALARM
 * - Wake Lock باش يبقى الجهاز نشيط
 * - Foreground Service باش ما يتقتلش
 */
class AdhanService : Service() {
    
    private var mediaPlayer: MediaPlayer? = null
    private lateinit var audioManager: AudioManager
    private var wakeLock: PowerManager.WakeLock? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    
    private var currentPrayerName: String = "الصلاة"
    private var currentTitle: String = "🕌 حان الآن وقت الصلاة"
    private var currentBody: String = "﴿وَأَقِمِ الصَّلَاةَ لِذِكْرِي﴾ • حان وقت اللقاء، استعد لصلاة الجماعة."
    
    companion object {
        private const val NOTIFICATION_ID = 7777
        private const val CHANNEL_ID = "adhan_foreground_service"
        
        private var lastTriggerTime: Long = 0L
        private var lastTriggerPrayer: String = ""

        // 🎯 دالة ساهلة باش نبداو Service من Dart
        fun startAdhan(context: Context, prayerName: String, soundFileName: String, title: String? = null, body: String? = null, isMuted: Boolean = false) {
            val intent = Intent(context, AdhanService::class.java).apply {
                putExtra("PRAYER_NAME", prayerName)
                putExtra("SOUND_FILE", soundFileName)
                putExtra("IS_MUTED", isMuted)
                if (title != null) putExtra("TITLE", title)
                if (body != null) putExtra("BODY", body)
            }
            
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (e: Exception) {
                // ForegroundServiceStartNotAllowedException (API 31+) is an IllegalStateException.
                android.util.Log.e("AdhanService", "⚠️ FGS start blocked (${e.javaClass.simpleName}): ${e.message}. Falling back.")
                postFallbackAlarmNotification(context, prayerName, soundFileName, title, body, isMuted)
            }
        }

        private const val FALLBACK_CHANNEL_ID = "adhan_fallback_alarm_v1"

        private fun postFallbackAlarmNotification(context: Context, prayerName: String, soundFileName: String, title: String?, body: String?, isMuted: Boolean) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val soundUri = if (isMuted) null else Uri.parse(
                "android.resource://${context.packageName}/raw/$soundFileName"
            )

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val existing = nm.getNotificationChannel(FALLBACK_CHANNEL_ID)
                if (existing == null) {
                    val channel = NotificationChannel(FALLBACK_CHANNEL_ID, "Adhan (Fallback)", NotificationManager.IMPORTANCE_HIGH).apply {
                        setSound(
                            soundUri ?: android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_ALARM),
                            AudioAttributes.Builder()
                                .setUsage(AudioAttributes.USAGE_ALARM)
                                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                                .build()
                        )
                        enableVibration(true)
                        lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                    }
                    nm.createNotificationChannel(channel)
                }
            }

            val builder = NotificationCompat.Builder(context, FALLBACK_CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
                .setContentTitle(title ?: "🕌 حان وقت الصلاة")
                .setContentText(body ?: prayerName)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setAutoCancel(true)

            nm.notify(NOTIFICATION_ID, builder.build())
        }

        // 🛑 دالة لإيقاف الأذان
        fun stopAdhan(context: Context) {
            val intent = Intent(context, AdhanService::class.java)
            context.stopService(intent)
        }

        // 🎵 هل الأذان يشتغل؟
        var isServiceRunning = false
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    @SuppressLint("WakelockTimeout")
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // 🚨 CRITICAL FIX: Handle notification actions FIRST before any deduplication or isPlaying checks!
        if (intent?.action == "STOP_ADHAN") {
            cleanup()
            return START_NOT_STICKY
        }

        if (intent?.action == "MUTE_SILENT_MODE") {
            SilentModeChannel.muteDevice(this)
            android.widget.Toast.makeText(this, "🔕 تم تفعيل الوضع الصامت للصلاة", android.widget.Toast.LENGTH_SHORT).show()
            cleanup() // Stop Adhan audio since device is now muted for prayer
            return START_NOT_STICKY
        }

        val prayerName = intent?.getStringExtra("PRAYER_NAME") ?: "الصلاة"
        val soundFileName = intent?.getStringExtra("SOUND_FILE") ?: "adhan_hamza"
        val isMuted = intent?.getBooleanExtra("IS_MUTED", false) ?: false

        currentPrayerName = prayerName
        
        val prefsFlutter = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val userNameRaw = prefsFlutter.getString("flutter.userName", "")?.trim()
        
        currentTitle = intent?.getStringExtra("TITLE") ?: getPrayerTitleFallback(prayerName, userNameRaw)
        currentBody = intent?.getStringExtra("BODY") ?: getPrayerBodyFallback(prayerName, userNameRaw)

        // 1️⃣ MUST start Foreground Service FIRST to prevent ForegroundServiceDidNotStartInTimeException on API 26+
        createNotificationChannel()
        val notification = createForegroundNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        // 2️⃣ Check active playing state & persistent deduplication AFTER service is foregrounded
        val now = System.currentTimeMillis()
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val lastTimestamp = prefs.getLong("lastAdhanPlayedTimestamp", 0L)
        val lastPrayer = prefs.getString("lastAdhanPlayedPrayer", "") ?: ""

        if (mediaPlayer?.isPlaying == true) {
            android.util.Log.w("AdhanService", "⚠️ Adhan is already actively playing for $currentPrayerName. Ignoring duplicate start for $prayerName.")
            return START_NOT_STICKY
        }

        if (prayerName == lastPrayer && (now - lastTimestamp) < 180000L) {
            android.util.Log.w("AdhanService", "⚠️ Persistent Dedupe: Adhan for $prayerName was already triggered within 3 min (${now - lastTimestamp}ms). Keeping notification.")
            return START_NOT_STICKY
        }

        prefs.edit()
            .putLong("lastAdhanPlayedTimestamp", now)
            .putString("lastAdhanPlayedPrayer", prayerName)
            .apply()

        lastTriggerTime = now
        lastTriggerPrayer = prayerName
        
        // 3️⃣ Acquire Wake Lock (keep CPU awake during playback)
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "MuslimApp::AdhanWakeLock"
        )
        wakeLock?.acquire(5 * 60 * 1000L) // 5 minutes max
        
        if (!isMuted) {
            // 4️⃣ Request Audio Focus & Play Adhan Sound
            requestAudioFocus()
            playAdhan(soundFileName)
        } else {
            android.util.Log.d("AdhanService", "🔕 Adhan is MUTED for $prayerName. Showing notification only, no audio.")
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                cleanup()
            }, 3 * 60 * 1000L)
        }
        
        return START_NOT_STICKY // باش يرجع يبدا ila ت9فل Service
    }

    private fun getPrayerTitleFallback(name: String, userNameRaw: String?): String {
        val suffix = if (!userNameRaw.isNullOrBlank()) " يا $userNameRaw" else ""

        return when (name.trim()) {
            "Fajr", "الفجر" -> "🤍 الصلاة خير من النوم"
            "Sunrise", "الشروق" -> "🌅 حان الآن وقت الشروق$suffix"
            "Dhuhr", "الظهر" -> "🕌 أرحنا بها$suffix"
            "Asr", "العصر" -> "🕌 حان وقت أذان العصر"
            "Maghrib", "المغرب" -> "🕌 حان أذان المغرب$suffix"
            "Isha", "العشاء" -> "🕌 حان وقت أذان العشاء"
            else -> "🕌 حان الآن وقت أذان $name$suffix"
        }
    }

    private fun getPrayerBodyFallback(name: String, userNameRaw: String?): String {
        val suffix = if (!userNameRaw.isNullOrBlank()) " يا $userNameRaw" else ""
        
        return when (name.trim()) {
            "Fajr", "الفجر" -> "حان وقت أذان الفجر$suffix.. انهض لربك وانعم بالسكينة."
            "Sunrise", "الشروق" -> "﴿وَسَبِّحْ بِحَمْدِ رَبِّكَ قَبْلَ طُلُوعِ الشَّمْسِ﴾ • أشرقت الأرض بنور ربها، أذكار الصباح حصنك."
            "Dhuhr", "الظهر" -> "حان أذان الظهر.. جدد وضوءك، وصافح السكينة في صلاتك."
            "Asr", "العصر" -> "اقتطع من وقتك دقائق لربك$suffix.. طوبى لمن حافظ عليها."
            "Maghrib", "المغرب" -> "طوى النهار صحائفه، فاجعل طاعتك مسك الختام."
            "Isha", "العشاء" -> "في هدوء الليل، لقاء ربك هو أجمل ختام.. لا تنس الوتر$suffix."
            else -> "حان وقت اللقاء، استعد لصلاة الجماعة."
        }
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Adhan Playback",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Foreground service for Adhan playback"
                setSound(null, null) // ❗ بلا sound f notification!
                enableVibration(false)
                setShowBadge(false)
            }
            
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
    
    private fun getNotificationIcon(): Int {
        val resId = resources.getIdentifier("ic_stat_adhan", "drawable", packageName)
        return if (resId != 0) resId else android.R.drawable.ic_lock_idle_alarm
    }

    private fun createForegroundNotification(): Notification {
        // Intent باش نفتحو التطبيق منين ينقر على Notification
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        
        // Intent لإيقاف الأذان
        val stopIntent = Intent(this, AdhanService::class.java).apply {
            action = "STOP_ADHAN"
        }
        val stopPendingIntent = PendingIntent.getService(
            this,
            0,
            stopIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        // Intent لتفعيل الوضع الصامت للصلاة
        val muteIntent = Intent(this, AdhanService::class.java).apply {
            action = "MUTE_SILENT_MODE"
        }
        val mutePendingIntent = PendingIntent.getService(
            this,
            1,
            muteIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isAutoSilentGlobal = prefs.getBoolean("flutter.autoSilentEnabled", false)

        val displayBody = if (isAutoSilentGlobal) {
            "$currentBody • 🔕 الوضع الصامت مفعّل تلقائياً"
        } else {
            currentBody
        }

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(currentTitle)
            .setContentText(displayBody)
            .setSmallIcon(getNotificationIcon())
            .setOngoing(false)
            .setAutoCancel(false)
            .setContentIntent(pendingIntent) // User can still TAP to open app
            // setFullScreenIntent removed — was auto-launching app without user tap
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            // ✅ زر إيقاف الأذان في Notification
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel, // أيقونة Stop
                "إيقاف الأذان",
                stopPendingIntent
            )

        if (!isAutoSilentGlobal) {
            // ✅ زر كتم الصوت السريع (يظهر فقط إذا كان الوضع الصامت التلقائي غير مفعّل)
            builder.addAction(
                android.R.drawable.ic_lock_silent_mode,
                "🔕 كتم الصوت للصلاة",
                mutePendingIntent
            )
        }

        return builder.build()
    }
    
    private val focusChangeListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
        when (focusChange) {
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                // 🛑 CRITICAL: Override default ducking! Don't let notifications lower Adhan volume.
                mediaPlayer?.setVolume(1.0f, 1.0f)
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                // Phone call ringing - lower volume slightly so they can hear the ringtone
                mediaPlayer?.setVolume(0.3f, 0.3f)
            }
            AudioManager.AUDIOFOCUS_GAIN -> {
                // Regained focus
                mediaPlayer?.setVolume(1.0f, 1.0f)
            }
            AudioManager.AUDIOFOCUS_LOSS -> {
                // Lost focus completely (e.g. user answered call or played video)
                cleanup()
            }
        }
    }

    private fun requestAudioFocus() {
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build()
            
            // EXCLUSIVE — other apps are told not to duck at all, instead of us
            // fighting the OS's default ducking behavior in the focus listener.
            audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE)
                .setAudioAttributes(audioAttributes)
                .setOnAudioFocusChangeListener(focusChangeListener)
                .build()
            
            audioManager.requestAudioFocus(audioFocusRequest!!)
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                focusChangeListener,
                AudioManager.STREAM_ALARM,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE
            )
        }
    }
    
    private fun playAdhan(soundFileName: String) {
        try {
            // Stop and release previous player if any exists
            mediaPlayer?.apply {
                try {
                    if (isPlaying) stop()
                    release()
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
            mediaPlayer = null

            // 🎵 نحصلو على الملف من res/raw
            val resourceId = resources.getIdentifier(
                soundFileName,
                "raw",
                packageName
            )
            
            if (resourceId == 0) {
                android.util.Log.e("AdhanService", "❌ Sound file not found: $soundFileName")
                cleanup()
                return
            }
            
            val uri = Uri.parse("android.resource://$packageName/$resourceId")
            
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                
                setDataSource(this@AdhanService, uri)
                
                setOnCompletionListener {
                    android.util.Log.d("AdhanService", "✅ Adhan completed")
                    cleanup()
                }
                
                setOnErrorListener { _, what, extra ->
                    android.util.Log.e("AdhanService", "❌ Error playing: what=$what, extra=$extra")
                    cleanup()
                    true
                }
                
                prepare()
                start()
                
                android.util.Log.d("AdhanService", "▶️ Playing adhan: $soundFileName")
            }
            
        } catch (e: Exception) {
            android.util.Log.e("AdhanService", "❌ Exception: ${e.message}")
            e.printStackTrace()
            cleanup()
        }
    }

    private fun cleanup() {
        // 1. نوقفو MediaPlayer
        mediaPlayer?.apply {
            try {
                if (isPlaying) stop()
                release()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        mediaPlayer = null
        
        // 2. نرجعو Audio Focus
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let {
                audioManager.abandonAudioFocusRequest(it)
            }
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(focusChangeListener)
        }
        
        // 3. نحللو Wake Lock
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        
        // 4. Detach foreground service and REMOVE the notification banner
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(NOTIFICATION_ID)

        stopSelf()
    }
    
    override fun onCreate() {
        super.onCreate()
        isServiceRunning = true
    }

    override fun onDestroy() {
        isServiceRunning = false
        cleanup()
        super.onDestroy()
    }
}
