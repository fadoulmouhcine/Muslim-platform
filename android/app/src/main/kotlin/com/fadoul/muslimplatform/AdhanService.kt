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
        fun startAdhan(context: Context, prayerName: String, soundFileName: String, title: String? = null, body: String? = null) {
            val intent = Intent(context, AdhanService::class.java).apply {
                putExtra("PRAYER_NAME", prayerName)
                putExtra("SOUND_FILE", soundFileName)
                if (title != null) putExtra("TITLE", title)
                if (body != null) putExtra("BODY", body)
            }
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
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
        val prayerName = intent?.getStringExtra("PRAYER_NAME") ?: "الصلاة"
        
        // 🔒 PERSISTENT DISK DEDUPING & RE-ENTRANCY GUARD: Abort if played within 3 mins
        val now = System.currentTimeMillis()
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val lastTimestamp = prefs.getLong("lastAdhanPlayedTimestamp", 0L)
        val lastPrayer = prefs.getString("lastAdhanPlayedPrayer", "") ?: ""

        if (mediaPlayer?.isPlaying == true) {
            android.util.Log.w("AdhanService", "⚠️ Adhan is already actively playing for $currentPrayerName. Ignoring duplicate start for $prayerName.")
            return START_NOT_STICKY
        }

        if (prayerName == lastPrayer && (now - lastTimestamp) < 180000L) {
            android.util.Log.w("AdhanService", "⚠️ Persistent Dedupe: Adhan for $prayerName was already triggered within 3 min (${now - lastTimestamp}ms). Aborting.")
            stopSelf()
            return START_NOT_STICKY
        }

        prefs.edit()
            .putLong("lastAdhanPlayedTimestamp", now)
            .putString("lastAdhanPlayedPrayer", prayerName)
            .apply()

        lastTriggerTime = now
        lastTriggerPrayer = prayerName

        currentPrayerName = prayerName
        
        currentTitle = intent?.getStringExtra("TITLE") ?: getPrayerTitleFallback(prayerName)
        currentBody = intent?.getStringExtra("BODY") ?: getPrayerBodyFallback(prayerName)

        val soundFileName = intent?.getStringExtra("SOUND_FILE") ?: "adhan_hamza"
        
        // 1️⃣ نبداو Foreground Service بـ Notification
        if (intent?.action == "STOP_ADHAN") {
            cleanup()
            return START_NOT_STICKY
        }

        if (intent?.action == "MUTE_SILENT_MODE") {
            SilentModeChannel.muteDevice(this)
            android.widget.Toast.makeText(this, "🔕 تم تفعيل الوضع الصامت للصلاة", android.widget.Toast.LENGTH_SHORT).show()
            return START_NOT_STICKY
        }

        createNotificationChannel()
        val notification = createForegroundNotification()
        startForeground(NOTIFICATION_ID, notification)
        
        // 2️⃣ Acquire Wake Lock (باش يبقى الجهاز صاحي)
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK, // No ACQUIRE_CAUSES_WAKEUP — keeps CPU alive without forcing screen on
            "MuslimApp::AdhanWakeLock"
        )
        wakeLock?.acquire(5 * 60 * 1000L) // 5 دقائق max
        
        // 3️⃣ Request Audio Focus (باش ما يتقطعش الأذان)
        requestAudioFocus()
        
        // 4️⃣ نلعبو الأذان
        playAdhan(soundFileName)
        
        return START_NOT_STICKY // باش يرجع يبدا ila ت9فل Service
    }

    private fun getPrayerTitleFallback(name: String): String {
        return when (name.trim()) {
            "Fajr", "الفجر" -> "🕌 حان الآن وقت أذان الفجر"
            "Sunrise", "الشروق" -> "🌅 حان الآن وقت الشروق"
            "Dhuhr", "الظهر" -> "🕌 حان الآن وقت أذان الظهر"
            "Asr", "العصر" -> "🕌 حان الآن وقت أذان العصر"
            "Maghrib", "المغرب" -> "🕌 حان الآن وقت أذان المغرب"
            "Isha", "العشاء" -> "🕌 حان الآن وقت أذان العشاء"
            else -> "🕌 حان الآن وقت أذان $name"
        }
    }

    private fun getPrayerBodyFallback(name: String): String {
        return when (name.trim()) {
            "Fajr", "الفجر" -> "﴿إِنَّ قُرْآنَ الْفَجْرِ كَانَ مَشْهُوداً﴾ • الصلاة خير من النوم، حان وقت الفلاح."
            "Sunrise", "الشروق" -> "﴿وَسَبِّحْ بِحَمْدِ رَبِّكَ قَبْلَ طُلُوعِ الشَّمْسِ﴾ • أشرقت الأرض بنور ربها، أذكار الصباح حصنك."
            "Dhuhr", "الظهر" -> "﴿وَأَقِمِ الصَّلَاةَ لِذِكْرِي﴾ • حان وقت اللقاء، استعد لصلاة الجماعة."
            "Asr", "العصر" -> "﴿حَافِظُوا عَلَى الصَّلَوَاتِ وَالصَّلَاةِ الْوُسْطَىٰ﴾ • طُوبَى لمن حافظ عليها في وقتها."
            "Maghrib", "المغرب" -> "﴿وَسَبِّحْ بِحَمْدِ رَبِّكَ قَبْلَ غُرُوبِ الشَّمْسِ﴾ • تقبل الله طاعتكم وصالح أعمالكم."
            "Isha", "العشاء" -> "﴿وَمِنَ اللَّيْلِ فَسَبِّحْهُ وَأَدْبَارَ السُّجُودِ﴾ • اختم يومك بالقيام والسكينة."
            else -> "﴿وَأَقِمِ الصَّلَاةَ لِذِكْرِي﴾ • حان وقت اللقاء، استعد لصلاة الجماعة."
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
    
    private fun requestAudioFocus() {
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM) // 🔥 المفتاح!
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build()
            
            audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(audioAttributes)
                .setWillPauseWhenDucked(false) // ما ت-pause-يش
                .setOnAudioFocusChangeListener { focusChange ->
                    when (focusChange) {
                        AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                            // مكلمة phone - ن9صو الصوت
                            mediaPlayer?.setVolume(0.3f, 0.3f)
                        }
                        AudioManager.AUDIOFOCUS_GAIN -> {
                            // رجع Volume كامل
                            mediaPlayer?.setVolume(1.0f, 1.0f)
                        }
                        AudioManager.AUDIOFOCUS_LOSS -> {
                            // ضاع Focus - نوقفو
                            cleanup()
                        }
                    }
                }
                .build()
            
            audioManager.requestAudioFocus(audioFocusRequest!!)
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                null,
                AudioManager.STREAM_ALARM,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT
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
                        .setUsage(AudioAttributes.USAGE_ALARM) // 🔥 المفتاح!
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
            audioManager.abandonAudioFocus(null)
        }
        
        // 3. نحللو Wake Lock
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        
        // 4. Detach foreground service while keeping notification persistent in status bar
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_DETACH)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(false)
        }

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
