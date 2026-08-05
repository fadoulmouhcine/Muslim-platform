package com.fadoul.muslimplatform

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class PrayerWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        // Refresh all instances of our widget
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val thisWidget = ComponentName(context, PrayerWidgetProvider::class.java)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
        onUpdate(context, appWidgetManager, appWidgetIds)
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.prayer_widget_layout)

        try {
            val sharedPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val rawJson = sharedPrefs.getString("flutter.widget_prayer_data", null)

            if (rawJson != null) {
                val data = JSONObject(rawJson)
                val city = data.optString("city", "موقعي")
                views.setTextViewText(R.id.widget_city, city)

                // Determine next prayer time
                val now = Date()
                val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US)

                val prayers = listOf(
                    Pair("الفجر", format.parse(data.getString("fajr"))),
                    Pair("الشروق", format.parse(data.getString("sunrise"))),
                    Pair("الظهر", format.parse(data.getString("dhuhr"))),
                    Pair("العصر", format.parse(data.getString("asr"))),
                    Pair("المغرب", format.parse(data.getString("maghrib"))),
                    Pair("العشاء", format.parse(data.getString("isha")))
                )

                var nextPrayerName = "الفجر"
                var nextPrayerTime: Date = prayers.first().second

                for (prayer in prayers) {
                    if (prayer.second.after(now)) {
                        nextPrayerName = prayer.first
                        nextPrayerTime = prayer.second
                        break
                    }
                }

                // Format display time
                val displayFormat = SimpleDateFormat("hh:mm a", Locale("ar"))
                views.setTextViewText(R.id.widget_title, "الصلاة القادمة: $nextPrayerName")
                views.setTextViewText(R.id.widget_time, displayFormat.format(nextPrayerTime))
            } else {
                views.setTextViewText(R.id.widget_title, "يرجى فتح التطبيق")
                views.setTextViewText(R.id.widget_time, "--:--")
            }
        } catch (e: Exception) {
            views.setTextViewText(R.id.widget_title, "خطأ في البيانات")
            views.setTextViewText(R.id.widget_time, "--:--")
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
