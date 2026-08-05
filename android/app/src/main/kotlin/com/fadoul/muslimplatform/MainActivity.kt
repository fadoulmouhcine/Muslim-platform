package com.fadoul.muslimplatform

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var methodChannel: MethodChannel? = null
    private var widgetChannel: MethodChannel? = null

    companion object {
        var initialPayload: String? = null

        // ✅ Task 3.5: Centralized channel name constant (matches
        // lib/services/method_channel_constants.dart -> MethodChannelNames.widget)
        const val WIDGET_CHANNEL_NAME = "com.example.muslim/widget"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 🔗 تسجيل MethodChannel للأذان
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            AdhanMethodChannel.CHANNEL_NAME
        )
        methodChannel?.setMethodCallHandler(AdhanMethodChannel(this))

        // 🔗 تسجيل MethodChannel للويدجت
        widgetChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WIDGET_CHANNEL_NAME
        )
        widgetChannel?.setMethodCallHandler { call, result ->
            if (call.method == "reloadWidget") {
                val updateIntent = Intent(this, PrayerWidgetProvider::class.java).apply {
                    action = "android.appwidget.action.APPWIDGET_UPDATE"
                }
                sendBroadcast(updateIntent)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }

        // 🔗 تسجيل MethodChannel للوضع الصامت
        val silentChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SilentModeChannel.CHANNEL_NAME
        )
        silentChannel.setMethodCallHandler(SilentModeChannel(this))

        // Check if launched from notification
        handleIntent(intent)
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: android.content.Intent) {
        val payload = intent.getStringExtra("payload")
        if (payload != null) {
            // Store for Cold Start & Background polling
            initialPayload = payload
        }
    }
}
