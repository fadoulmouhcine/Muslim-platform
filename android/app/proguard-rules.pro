# ==========================================================
# ProGuard / R8 keep rules for Muslim Platform (release build)
# Ensures minification/shrinking does not break Firebase,
# Flutter plugins, or other reflection-based libraries.
# ==========================================================

# --- Flutter ---
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# --- Firebase (Core / Analytics / Messaging) ---
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# --- Flutter Local Notifications ---
-keep class com.dexterous.** { *; }

# --- WorkManager ---
-keep class androidx.work.** { *; }

# --- Adhan (native prayer time calculation) ---
-keep class com.batoulapps.adhan.** { *; }

# --- App-specific native classes (MethodChannels, Receivers, Services) ---
# Note: Kotlin source package/namespace remains com.example.muslim
# (applicationId was changed to com.fadoul.muslimplatform, but the
# Kotlin package declarations were intentionally left untouched).
-keep class com.example.muslim.** { *; }

# --- Gson / JSON reflection safety (used transitively by some plugins) ---
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# --- General Android component safety ---
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.appwidget.AppWidgetProvider
-keep public class * extends android.app.Activity

# --- Suppress noisy warnings from missing optional classes ---
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
