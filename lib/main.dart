import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/services.dart';
import 'services/sync_service.dart';

// Services
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'services/quran_service.dart';
import 'services/settings_provider.dart';
import 'services/tafsir_service.dart';
import 'services/notification_service.dart';

// Screens
import 'screens/main_screen.dart';
import 'screens/setup/setup_screen.dart'; // ✅ Import Setup Screen
import 'widgets/adhan_overlay_wrapper.dart'; // ✅ Import Banner Wrapper
import 'theme/theme.dart'; // ✅ Import Theme

// FCM Background Handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling background FCM message: ${message.messageId}");
}

// 1. دالة الخلفية
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding
        .ensureInitialized(); // ✅ FIX: Added to prevent background crash
    debugPrint("🔄 Background Sync Started: $task");
    if (task == "syncHijriTask") {
      await SyncService.syncHijriDate();
    } else if (task == "rescheduleTask") {
      // ✅ هذه هي المهمة الجديدة: إعادة جدولة الأذان دورياً
      // كتخدم كل 24 ساعة (أو 12) باش تضمن بلي الأذان عمرو يتقطع
      await NotificationService.rescheduleNotificationsFromBackground();
    }
    return Future.value(true);
  });
}

// ✅ Global Navigator Key for Notification Navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Firebase, Analytics & FCM Setup
  try {
    await Firebase.initializeApp();
    FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    await analytics.logAppOpen();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await FirebaseMessaging.instance.requestPermission();

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // ignore: avoid_print
      print('Received: ${message.notification?.title}');
      debugPrint(
          "Received FCM foreground message title: ${message.notification?.title}");
      debugPrint(
          "Received FCM foreground message body: ${message.notification?.body}");
    });

    String? fcmToken = await FirebaseMessaging.instance.getToken();
    // ignore: avoid_print
    print("FCM TOKEN: $fcmToken");
  } catch (e) {
    debugPrint("Firebase Messaging setup error: $e");
  }

  // ✅ Edge-to-Edge System Navigation & Transparent Status Bar Setup
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    await Workmanager().initialize(callbackDispatcher);

    // 1. مزامنة التاريخ الهجري (موجودة سابقاً)
    await Workmanager().registerPeriodicTask(
      "1",
      "syncHijriTask",
      frequency: const Duration(hours: 12),
      constraints: Constraints(networkType: NetworkType.connected),
    );

    // 2. ✅ المهمة الجديدة: إعادة جدولة الأذان (بدون إنترنت)
    // كتخدم كل 12 ساعة باش تجدد الجدولة (ديال 3 ايام)
    await Workmanager().registerPeriodicTask(
      "2", // ID مختلف
      "rescheduleTask",
      frequency: const Duration(hours: 12),
      // ماكنحتاجوش انترنت، كنحتاجو غير البطارية تكون مزيانة بلا ما نعيقو بيها
      constraints: Constraints(networkType: NetworkType.notRequired),
      // 🔥 FIX: Ensure policy is UPDATE to keep the task alive and fresh
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  } catch (e) {
    debugPrint("Workmanager error: $e");
  }

  try {
    await NotificationService.init();
    debugPrint("✅ Notification Service Initialized");
  } catch (e) {
    debugPrint("❌ Notification Init Error: $e");
  }

  await TafsirService.loadTafsir();

  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();
  await QuranService.loadQuran(settingsProvider.currentJsonPath);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settingsProvider),
      ],
      // ✅ نمرر الـ Provider باش نستخدموه فالـ child (Localization)
      child: const MuslimApp(),
    ),
  );
}

class GlobalCustomScrollBehavior extends ScrollBehavior {
  const GlobalCustomScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

class MuslimApp extends StatelessWidget {
  const MuslimApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ نستمعو للـ Settings باش إيلا بدل اللغة فالـ Setup تبدل فالتطبيق كامل
    final settings = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      navigatorKey: navigatorKey, // ✅ Navigation Global Key
      debugShowCheckedModeBanner: false,
      title: 'Muslim App',
      scrollBehavior:
          const GlobalCustomScrollBehavior(), // ✅ Unified App-Wide Bouncing Scroll Physics
      // ✅ Theme Configuration (Native System, Light, Dark)
      themeMode: settings.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'AE'),
        Locale('en', 'US'),
      ],
      // ✅ اللغة كتجي دابا من Settings
      locale: settings.appLocale,

      // ✅ اللوجيك: إيلا كان جديد -> Setup, إيلا قديم -> Main
      home: settings.isFirstTime ? const SetupScreen() : const MainScreen(),

      // ✅ Banner Overlay (فوق كل شيء)
      builder: (context, child) {
        return AdhanOverlayWrapper(child: child);
      },
    );
  }
}
