import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:adhan/adhan.dart';
import '../main.dart'; // ✅ Import for navigatorKey
import '../screens/daily_harvest_screen.dart'; // ✅ Import DailyHarvestScreen
import '../screens/quran_reading_screen.dart';
import 'arabic_plural_helper.dart';
import 'method_channel_constants.dart'; // ✅ Task 3.5: Centralized channel names

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 🔗 MethodChannel للتواصل مع Native Android (Foreground Service)
  static const MethodChannel _adhanChannel =
      MethodChannel(MethodChannelNames.adhan);

  static Future<void> init() async {
    tz.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    final String timeZoneName = timezoneInfo.identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      // 🔥 Callback فقط للتذكيرات (الأذان كيخدم عبر AlarmManager)
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (Platform.isAndroid) {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }

    // ✅ Listen to Native Method Channel (For Notification Taps)
    _adhanChannel.setMethodCallHandler((call) async {
      if (call.method == "onNotificationTapped") {
        final String payload = call.arguments as String;
        debugPrint("🔔 Received Native Notification Tap: $payload");
        // Reuse same logic
        _onNotificationTapped(NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: payload));
      }
    });

    // ✅ Check for Initial Payload (Cold Start)
    try {
      final NotificationAppLaunchDetails? details =
          await _notificationsPlugin.getNotificationAppLaunchDetails();

      if (details != null && details.didNotificationLaunchApp) {
        debugPrint("🚀 App Launched via Notification (Plugin Detect)");
        if (details.notificationResponse?.payload == 'daily_harvest') {
          _isColdStartFromNotification = true;
        }
      }

      final String? initialPayload =
          await _adhanChannel.invokeMethod('getInitialPayload');
      if (initialPayload != null) {
        debugPrint("🚀 Found Initial Payload (Cold Start): $initialPayload");
        // Store until UI Request
        pendingPayload = initialPayload;
      }
    } catch (e) {
      debugPrint("❌ Error checking initial payload: $e");
    }
  }

  static String? pendingPayload;
  static bool _isColdStartFromNotification = false;

  // ✅ Task 3.4: Removed the unconditional `Future.delayed(300ms)` that used
  // to run on EVERY call (including warm/foreground taps where there's no
  // "UI frame not ready" concern at all). The delay is no longer needed
  // because:
  //   - Cold start: MainScreen already waits for
  //     `WidgetsBinding.instance.addPostFrameCallback` before calling this,
  //     which guarantees the first frame has already been rendered.
  //   - Warm/foreground taps: there is no pending native-side race condition
  //     to wait out — the payload (if any) is already available synchronously.
  // This makes navigation feel instant instead of waiting 300ms every time.
  static Future<String?> consumePendingPayload() async {
    String? targetPayload = pendingPayload;

    // 1. If local is empty, Double-Check Native Side
    if (targetPayload == null) {
      try {
        final String? nativePayload =
            await _adhanChannel.invokeMethod('getInitialPayload');
        if (nativePayload != null) {
          targetPayload = nativePayload;
        }
      } catch (e) {
        debugPrint("❌ Error fetching native payload: $e");
      }
    }

    // Clear static ref if found
    if (targetPayload != null) {
      pendingPayload = null;
    }

    return targetPayload;
  }

  // 🔥 Callback للتذكيرات (منين المستخدم ينقر)
  static Future<void> _onNotificationTapped(NotificationResponse response,
      {BuildContext? triggerContext}) async {
    debugPrint("📱 Notification tapped: ${response.payload}");

    // ✅ Handle Daily Harvest Navigation
    if (response.payload == 'daily_harvest') {
      // 🛑 PREVENT DOUBLE NAV (Cold Start):
      // If the app was launched by this notification, we ignore this specific callback.
      // Why? Because MainScreen will pick up the payload via consumePendingPayload()
      // and perform the navigation. This prevents the "Double Open" bug.
      if (_isColdStartFromNotification) {
        debugPrint(
            "🛑 Optimization: Ignoring Plugin Callback (Cold Start). MainScreen will handle it.");
        _isColdStartFromNotification = false; // Reset for next time
        return;
      }

      debugPrint("🚀 Preparing Navigation to Daily Harvest...");

      // Strategy 1: Use Provided Context (Most Reliable for Cold Start)
      if (triggerContext != null) {
        debugPrint("✅ Using MainScreen Context for Navigation");
        if (triggerContext.mounted) {
          Navigator.of(triggerContext).push(
            MaterialPageRoute(builder: (_) => const DailyHarvestScreen()),
          );
        }
        return;
      }

      // Strategy 2: Fallback to Global Key (For Background/Foreground taps)
      // 🔄 Retry Logic for Navigator (Fix Cold Start null Key)
      int retries = 0;
      while (navigatorKey.currentState == null && retries < 5) {
        debugPrint("⚠️ NavigatorState is NULL. Waiting... ($retries)");
        await Future.delayed(const Duration(milliseconds: 500));
        retries++;
      }

      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(builder: (_) => const DailyHarvestScreen()),
        );
        debugPrint("✅ Navigation Pushed via GlobalKey!");
      } else {
        debugPrint(
            "❌ CRITICAL: navigatorKey.currentState is NULL after 5 retries!");
      }
    }

    // ✅ Handle Surat Al-Mulk Notification Tap
    if (response.payload == 'quran_mulk') {
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => const QuranReadingScreen(
              initialSurahId: 67,
            ),
          ),
        );
      }
    }

    // ✅ Handle Surat Al-Kahf Notification Tap
    if (response.payload == 'quran_kahf') {
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => const QuranReadingScreen(
              initialSurahId: 18,
            ),
          ),
        );
      }
    }
  }

  static final StreamController<String> _adhanTriggerController =
      StreamController<String>.broadcast();

  static Stream<String> get onAdhanTriggered => _adhanTriggerController.stream;

  static void notifyAdhanTriggered(String prayerName) {
    debugPrint("📢 Broadcasting AdhanTriggerEvent for $prayerName");
    _adhanTriggerController.add(prayerName);
  }

  static Future<void> _cancelSpecificId(int id) async {
    if (Platform.isAndroid) {
      try {
        await _adhanChannel
            .invokeMethod('cancelAdhanAlarm', {'requestCode': id});
      } catch (e) {
        debugPrint("⚠️ Warning cancelling native alarm $id: $e");
      }
    }
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint("⚠️ Warning cancelling local notification $id: $e");
    }
  }

  // ✅ دالة ذكية لجدولة 3 أيام (اليوم، غداً، بعد غد) لضمان استمرار الأذان
  static Future<void> schedulePrayers(
      Coordinates coords, CalculationParameters params) async {
    // 1. طلب الصلاحية (Android)
    if (Platform.isAndroid) {
      final androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestExactAlarmsPermission();
    }

    debugPrint(
        "🔄 Re-scheduling prayer notifications with deduplicated deterministic IDs...");

    // 🛑 Cancel all existing Native Alarms across all ID ranges before rescheduling
    if (Platform.isAndroid) {
      try {
        debugPrint("🗑️ Cancelling all Native Alarms (100..450)...");
        for (int i = 100; i <= 450; i++) {
          await _adhanChannel
              .invokeMethod('cancelAdhanAlarm', {'requestCode': i});
        }
      } catch (e) {
        debugPrint("⚠️ Warning while cancelling native alarms: $e");
      }
    }
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint("⚠️ Warning cancelling local notifications: $e");
    }

    final prefs = await SharedPreferences.getInstance();

    // ✅ Save Params for Native TimeChangedReceiver
    await prefs.setString('native_latitude', coords.latitude.toString());
    await prefs.setString('native_longitude', coords.longitude.toString());

    int nativeMethodIndex = 21;
    switch (prefs.getString('calculationMethod') ?? 'morocco') {
      case 'mwl':
        nativeMethodIndex = 0;
        break;
      case 'egypt':
        nativeMethodIndex = 1;
        break;
      case 'karachi':
        nativeMethodIndex = 2;
        break;
      case 'umm_al_qura':
        nativeMethodIndex = 3;
        break;
      case 'dubai':
        nativeMethodIndex = 4;
        break;
      case 'qatar':
        nativeMethodIndex = 5;
        break;
      case 'morocco':
      default:
        nativeMethodIndex = 21;
        break;
    }
    await prefs.setInt('native_calculation_method_index', nativeMethodIndex);
    // ✅ Read the user's actual Madhab preference (Shafi'i=1 / Hanafi=2)
    // instead of a hardcoded value, so the native alarm scheduler (used for
    // background rescheduling) stays in sync with the in-app setting.
    final String madhabPref = prefs.getString('prayerMadhab') ?? 'shafi';
    await prefs.setInt(
        'native_madhab_index', madhabPref == 'hanafi' ? 2 : 1);
    await prefs.setInt(
        'native_notification_offset', prefs.getInt('notificationOffset') ?? 0);

    String rawSound = prefs.getString('adhanSound') ?? 'adhan_hamza';
    String adhanSound = rawSound.split('.').first;

    int? preFajrMinutes = prefs.getInt('preFajrAlarmMinutes');

    Map<String, int> prayerOffsets = {};
    String? offsetsJson = prefs.getString('prayerOffsets');
    if (offsetsJson != null) {
      Map<String, dynamic> decoded = json.decode(offsetsJson);
      prayerOffsets = decoded.map((key, value) => MapEntry(key, value as int));
    }

    Map<String, bool> prayerMuteStatus = {};
    String? muteJson = prefs.getString('prayerMuteStatus');
    if (muteJson != null) {
      Map<String, dynamic> decoded = json.decode(muteJson);
      prayerMuteStatus =
          decoded.map((key, value) => MapEntry(key, value as bool));
    }

    // 3. Schedule 3 days with strict deterministic IDs
    int scheduledCount = 0;
    final now = tz.TZDateTime.now(tz.local);

    for (int day = 0; day < 3; day++) {
      final tz.TZDateTime tzTarget = now.add(Duration(days: day));
      DateTime date = DateTime(tzTarget.year, tzTarget.month, tzTarget.day);
      DateComponents dateComponents =
          DateComponents(date.year, date.month, date.day);

      PrayerTimes prayerTimes = PrayerTimes(coords, dateComponents, params);

      final prayers = {
        'Fajr': prayerTimes.fajr,
        'Sunrise': prayerTimes.sunrise,
        'Dhuhr': prayerTimes.dhuhr,
        'Asr': prayerTimes.asr,
        'Maghrib': prayerTimes.maghrib,
        'Isha': prayerTimes.isha,
      };

      int prayerIndex = 0;

      for (var entry in prayers.entries) {
        String name = entry.key;
        DateTime time = entry.value;

        prayerIndex++;

        // Deterministic ID scheme per event & day
        final int mainAdhanId = 100 + (day * 10) + prayerIndex;
        final int reminderId = 200 + (day * 10) + prayerIndex;
        final int preFajrId = 300 + (day * 10) + prayerIndex;
        final int harvestId = 400 + (day * 10);

        bool isMuted = prayerMuteStatus[name] ?? false;
        int currentOffset = prayerOffsets[name.toLowerCase()] ?? 0;

        tz.TZDateTime scheduledTime = tz.TZDateTime.from(time, tz.local);

        bool isFuture = scheduledTime.isAfter(now);

        if (isFuture) {
          tz.TZDateTime finalTime = scheduledTime;

          String translatedPrayerName = PrayerMessaging.getTranslatedName(name);
          String prayerTitle = PrayerMessaging.getTitle(name);
          String prayerBody = PrayerMessaging.getBody(name);

          final String offsetMinutesFormatted =
              ArabicPluralHelper.formatMinutes(currentOffset);
          final String reminderBodyText =
              "﴿وَسَارِعُوا إِلَىٰ مَغْفِرَةٍ مِّن رَّبِّكُمْ﴾ • تبقى $offsetMinutesFormatted على الأذان";

          // 1. الأذان / الشروق (Strict ID 100+)
          if (!isMuted) {
            await _scheduleNotification(
              mainAdhanId,
              translatedPrayerName,
              finalTime,
              name == 'Sunrise' ? 'takbeer' : adhanSound,
              customTitle: prayerTitle,
              customBody: prayerBody,
            );
            scheduledCount++;
          }

          // 2. التذكير (المصلين) - Exact single offset reminder (Strict ID 200+)
          if (currentOffset > 0 && name != 'Sunrise') {
            tz.TZDateTime reminderTime =
                scheduledTime.subtract(Duration(minutes: currentOffset));

            if (reminderTime.isAfter(now)) {
              await _scheduleNotification(
                reminderId,
                "اقتربت صلاة $translatedPrayerName",
                reminderTime,
                'takbeer',
                isReminder: true,
                customTitle: "🕌 اقتربت صلاة $translatedPrayerName",
                customBody: reminderBodyText,
              );
            }
          }

          // 3. منبه الفجر (Pre-Fajr Alarm) (Strict ID 300+)
          if (name == 'Fajr' && preFajrMinutes != null && preFajrMinutes > 0) {
            tz.TZDateTime preFajrTime =
                scheduledTime.subtract(Duration(minutes: preFajrMinutes));

            if (preFajrTime.isAfter(now)) {
              final String preFajrFormatted =
                  ArabicPluralHelper.formatMinutes(preFajrMinutes);
              await _scheduleNotification(
                preFajrId,
                "منبه الفجر",
                preFajrTime,
                'takbeer',
                isReminder: true,
                customTitle: "🌙 منبه الفجر",
                customBody:
                    "﴿وَالْمُسْتَغْفِرِينَ بِالْأَسْحَارِ﴾ • تبقى $preFajrFormatted على أذان الفجر، استعد لصلاة الفجر",
              );
            }
          }
        }

        // 4. Daily Harvest Notification (30 mins after Isha) (Strict ID 400+)
        if (name == 'Isha') {
          tz.TZDateTime harvestTime =
              scheduledTime.add(const Duration(minutes: 30));
          if (harvestTime.isAfter(now)) {
            await _scheduleNotification(
              harvestId,
              "حاسبوا أنفسكم قبل أن تحاسبوا",
              harvestTime,
              'takbeer',
              isReminder: true,
              customTitle: "🌱 حاسبوا أنفسكم قبل أن تحاسبوا",
              customBody:
                  "لا تدع اليوم يمر دون وقفة مع النفس. اكتشف رصيد أعمالك الآن.",
              customPayload: 'daily_harvest',
            );
          }
        }
      }
    }

    debugPrint(
        "📊 تم تحديث الجدولة: $scheduledCount صلاة/شروق لـ 3 أيام القادمة.");
  }

  // نحتفظ بهذه الدالة للتوافق ولكن نمررها للجديد
  static Future<void> schedulePrayerNotifications(
      PrayerTimes prayerTimes, BuildContext context) async {
    await schedulePrayers(
        prayerTimes.coordinates, prayerTimes.calculationParameters);
  }

  static Future<void> _scheduleNotification(int id, String titleOrPrayer,
      tz.TZDateTime scheduledTime, String soundName,
      {bool isReminder = false,
      String? customTitle,
      String? customBody,
      String? customPayload}) async {
    // 🛑 Deduplicate: Cancel any previous notification/alarm with this exact ID
    await _cancelSpecificId(id);

    String safeSoundName = soundName.split('.').first;

    String bodyText = customBody ??
        (isReminder
            ? 'تبقت بضع دقائق على الأذان'
            : PrayerMessaging.getBody(titleOrPrayer));

    String finalTitle = customTitle ??
        (isReminder ? titleOrPrayer : PrayerMessaging.getTitle(titleOrPrayer));

    if (Platform.isAndroid) {
      try {
        final timeInMillis = scheduledTime.millisecondsSinceEpoch;

        Map<String, dynamic> args = {
          'requestCode': id,
          'timeInMillis': timeInMillis,
          'prayerName': titleOrPrayer,
          'soundFile': safeSoundName,
          'isReminder': isReminder,
          'title': finalTitle,
          'body': bodyText,
          'payload': customPayload,
        };

        await _adhanChannel.invokeMethod('scheduleAdhanAlarm', args);

        debugPrint(
            "⏰ Native Alarm (${isReminder ? 'Reminder' : 'Adhan'}) Scheduled: $finalTitle at $scheduledTime");
      } catch (e) {
        debugPrint("❌ Failed to schedule native alarm ($finalTitle): $e");
      }
      return;
    }

    String channelId = isReminder
        ? 'reminder_channel_v11_$safeSoundName'
        : 'adhan_channel_v11_$safeSoundName';

    String channelName =
        isReminder ? 'Reminders V11' : 'Adhan V11 ($safeSoundName)';
    String channelDesc = isReminder
        ? 'Notifications for prayer reminders'
        : 'High priority Adhan notifications';

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.max,
      icon: 'ic_stat_adhan',
      sound: RawResourceAndroidNotificationSound(safeSoundName),
      playSound: true,
      enableVibration: true,
      ongoing: false, // User can manually swipe it away
      autoCancel: false, // Never auto-clears on click or audio completion
      fullScreenIntent: false,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      ticker: finalTitle,
    );

    NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
          presentSound: true, presentAlert: true, presentBanner: true),
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        finalTitle,
        bodyText,
        scheduledTime,
        details,
        payload: customPayload, // ✅ Pass Payload
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    } catch (e) {
      debugPrint("❌ فشل الجدولة ($finalTitle): $e");
    }
  }

  /// Plays a test adhan sound via the native foreground service.
  static Future<void> showTestAdhan() async {
    if (!Platform.isAndroid) {
      debugPrint("Foreground Service is Android-only.");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    String soundName = prefs.getString('adhanSound') ?? 'adhan_hamza';

    try {
      await _adhanChannel.invokeMethod('playAdhanForeground', {
        'prayerName': 'تجربة الأذان',
        'soundFile': soundName,
      });

      debugPrint("Test adhan started via foreground service.");
    } catch (e) {
      debugPrint("Error starting test adhan: $e");
    }
  }

  /// Plays a test reminder sound via a high-priority notification.
  static Future<void> showTestTakbeer() async {
    String soundName = 'takbeer';
    String channelId = 'reminder_channel_v11_$soundName';

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId, 'Reminders V11',
        importance: Importance.max,
        priority: Priority.max,
        sound: RawResourceAndroidNotificationSound(soundName),
        playSound: true,
        fullScreenIntent: false,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm);

    await _notificationsPlugin.show(
        888,
        'تجربة التذكير',
        'واش الصوت خدام؟ (Banner Only - High Priority)',
        NotificationDetails(android: androidDetails));
  }

  /// Schedules a test alarm 1 minute from now.
  static Future<void> scheduleTestIn1Minute() async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = now.add(const Duration(minutes: 1));
    String soundName = 'takbeer';
    String channelId = 'test_schedule_v11_alarm';

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId, 'Test Alarm Schedule V11',
        importance: Importance.max,
        priority: Priority.max,
        sound: RawResourceAndroidNotificationSound(soundName),
        playSound: true,
        fullScreenIntent: false,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm);

    await _notificationsPlugin.zonedSchedule(
      777,
      'تجربة المنبه',
      'هذا الإشعار جاء بعد دقيقة!',
      scheduledTime,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.alarmClock, // Alarm Mode
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    debugPrint("Test alarm scheduled in 1 minute.");
  }

  /// Stops adhan playback via the native MethodChannel.
  static Future<void> stopAdhan() async {
    if (!Platform.isAndroid) return;

    try {
      await _adhanChannel.invokeMethod('stopAdhan');
      debugPrint("Adhan stopped.");
    } catch (e) {
      debugPrint("Error stopping adhan: $e");
    }
  }

  /// Returns whether adhan is currently playing.
  static Future<bool> isAdhanPlaying() async {
    if (!Platform.isAndroid) return false;

    try {
      final bool isPlaying = await _adhanChannel.invokeMethod('isAdhanPlaying');
      return isPlaying;
    } catch (e) {
      return false;
    }
  }

  /// Reschedules prayer notifications in the background based on saved location.
  static Future<void> rescheduleNotificationsFromBackground() async {
    debugPrint("Background: Rescheduling prayer notifications...");

    tz.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    final String timeZoneName = timezoneInfo.identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    final prefs = await SharedPreferences.getInstance();

    String? latStr = prefs.getString('native_latitude');
    String? longStr = prefs.getString('native_longitude');

    if (latStr == null || longStr == null) {
      debugPrint("Background: No coordinates saved. Aborting.");
      return;
    }

    double? lat = double.tryParse(latStr);
    double? long = double.tryParse(longStr);

    if (lat == null || long == null) {
      debugPrint("Background: Invalid coordinates. Aborting.");
      return;
    }

    Coordinates coordinates = Coordinates(lat, long);

    // 3. إعدادات الحساب
    String method = prefs.getString('calculationMethod') ?? 'umm_al_qura';
    CalculationParameters params;
    switch (method) {
      case 'egypt':
        params = CalculationMethod.egyptian.getParameters();
        break;
      case 'morocco':
        params = CalculationParameters(
          fajrAngle: 19.0,
          ishaAngle: 17.0,
          method: CalculationMethod.other,
        );
        break;
      case 'mwl':
        params = CalculationMethod.muslim_world_league.getParameters();
        break;
      case 'umm_al_qura':
      default:
        params = CalculationMethod.umm_al_qura.getParameters();
        break;
    }
    // ✅ Read the user's actual Madhab preference instead of hardcoding Shafi.
    final String madhabPref = prefs.getString('prayerMadhab') ?? 'shafi';
    params.madhab = madhabPref == 'hanafi' ? Madhab.hanafi : Madhab.shafi;

    // 4. الجدولة (تلقائياً كتمحي القديم وكدير 3 ايام جداد)
    // هنا يمكننا نزيدو العدد ل 7 أيام مثلاً إذا بغينا
    await schedulePrayers(coordinates, params);

    debugPrint("✅ Background Job: Prayers rescheduled successfully.");
  }

  static Future<void> showCatchUpNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'catch_up_channel_v1',
      'Post-Prayer Catch-Up',
      channelDescription:
          'Notifications for post-prayer audio restoration and messaging',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_adhan',
      color: Color(0xFFC5A059),
      autoCancel: true,
      ongoing: false,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );

    await _notificationsPlugin.show(
      9999,
      title,
      body,
      details,
    );
  }
}

/// 🕌 Premium Islamic Copywriting Engine for Notifications
class PrayerMessaging {
  static String getTranslatedName(String name) {
    switch (name) {
      case 'Fajr':
        return 'الفجر';
      case 'Sunrise':
        return 'الشروق';
      case 'Dhuhr':
        return 'الظهر';
      case 'Asr':
        return 'العصر';
      case 'Maghrib':
        return 'المغرب';
      case 'Isha':
        return 'العشاء';
      default:
        return name;
    }
  }

  static String getTitle(String nameOrKey) {
    switch (nameOrKey) {
      case 'Fajr':
      case 'الفجر':
        return '🕌 حان الآن وقت أذان الفجر';
      case 'Sunrise':
      case 'الشروق':
        return '🌅 حان الآن وقت الشروق';
      case 'Dhuhr':
      case 'الظهر':
        return '🕌 حان الآن وقت أذان الظهر';
      case 'Asr':
      case 'العصر':
        return '🕌 حان الآن وقت أذان العصر';
      case 'Maghrib':
      case 'المغرب':
        return '🕌 حان الآن وقت أذان المغرب';
      case 'Isha':
      case 'العشاء':
        return '🕌 حان الآن وقت أذان العشاء';
      default:
        return '🕌 حان الآن وقت أذان $nameOrKey';
    }
  }

  static String getBody(String nameOrKey) {
    switch (nameOrKey) {
      case 'Fajr':
      case 'الفجر':
        return '﴿إِنَّ قُرْآنَ الْفَجْرِ كَانَ مَشْهُوداً﴾ • الصلاة خير من النوم، حان وقت الفلاح.';
      case 'Sunrise':
      case 'الشروق':
        return '﴿وَسَبِّحْ بِحَمْدِ رَبِّكَ قَبْلَ طُلُوعِ الشَّمْسِ﴾ • أشرقت الأرض بنور ربها، أذكار الصباح حصنك.';
      case 'Dhuhr':
      case 'الظهر':
        return '﴿وَأَقِمِ الصَّلَاةَ لِذِكْرِي﴾ • حان وقت اللقاء، استعد لصلاة الجماعة.';
      case 'Asr':
      case 'العصر':
        return '﴿حَافِظُوا عَلَى الصَّلَوَاتِ وَالصَّلَاةِ الْوُسْطَىٰ﴾ • طُوبَى لمن حافظ عليها في وقتها.';
      case 'Maghrib':
      case 'المغرب':
        return '﴿وَسَبِّحْ بِحَمْدِ رَبِّكَ قَبْلَ غُرُوبِ الشَّمْسِ﴾ • تقبل الله طاعتكم وصالح أعمالكم.';
      case 'Isha':
      case 'العشاء':
        return '﴿وَمِنَ اللَّيْلِ فَسَبِّحْهُ وَأَدْبَارَ السُّجُودِ﴾ • اختم يومك بالقيام والسكينة.';
      default:
        return '﴿وَأَقِمِ الصَّلَاةَ لِذِكْرِي﴾ • حان وقت اللقاء، استعد لصلاة الجماعة.';
    }
  }
}
