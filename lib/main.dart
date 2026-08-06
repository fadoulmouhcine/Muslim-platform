// Copyright (c) 2026-present Mouhcine Fadoul. All rights reserved.
// Application: Muslim Platform — All Rights Reserved
// Author: Mouhcine Fadoul

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

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

/// Deferred initialisation: everything that doesn't need to complete before
/// the first frame is rendered. Called via addPostFrameCallback after runApp().
Future<void> _deferredInit(SettingsProvider settingsProvider) async {
  // ── TafsirService ──────────────────────────────────────────────────────────
  // Not needed for the first frame; load in the background.
  try {
    await TafsirService.loadTafsir();
  } catch (e) {
    debugPrint("❌ TafsirService.loadTafsir() error: $e");
  }

  // ✅ Firebase, Analytics & FCM Setup

  // 🛡️ Task 3.2: Each Firebase/FCM sub-step now has its OWN try/catch block
  // (instead of one giant try/catch wrapping everything). This prevents a
  // single failure — e.g. getToken() silently failing on devices/emulators
  // without Google Play Services — from swallowing/skipping the rest of the
  // Firebase setup (permissions, listeners, etc.) without any visibility.

  // 1. Core Firebase Initialization (must succeed for the rest to run)
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp();
    firebaseInitialized = true;
  } catch (e) {
    debugPrint("❌ Firebase.initializeApp() error: $e");
  }

  if (firebaseInitialized) {
    // 2. Analytics: log app open
    try {
      final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
      await analytics.logAppOpen();
    } catch (e) {
      debugPrint("❌ FirebaseAnalytics.logAppOpen() error: $e");
    }

    // 3. Background message handler registration
    try {
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint("❌ FCM onBackgroundMessage registration error: $e");
    }

    // 4. Notification permission request
    // Fix #4: Do NOT request permission on the very first cold start — the
    // user hasn't seen any rationale UI yet. Request it post-onboarding
    // from within the setup flow instead.

    if (!settingsProvider.isFirstTime) {
      try {
        await FirebaseMessaging.instance.requestPermission();
      } catch (e) {
        debugPrint("❌ FCM requestPermission() error: $e");
      }
    }

    // 5. Foreground notification presentation options
    try {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint(
          "❌ FCM setForegroundNotificationPresentationOptions() error: $e");
    }

    // 6. Foreground message listener
    // Fix #5: removed the duplicate kDebugMode-gated print() block; the two
    // debugPrint calls below already cover the same information.
    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
            "Received FCM foreground message title: ${message.notification?.title}");
        debugPrint(
            "Received FCM foreground message body: ${message.notification?.body}");
      });
    } catch (e) {
      debugPrint("❌ FCM onMessage listener setup error: $e");
    }

    // 7. FCM Token retrieval — isolated in its own try/catch since this is
    // the step most prone to silent failure (e.g. missing Google Play
    // Services on emulators/some devices) and must never block app startup.
    // Fix #6: changed print() → debugPrint() for consistent logging style.
    try {
      final String? fcmToken = await FirebaseMessaging.instance.getToken();
      debugPrint("FCM TOKEN: $fcmToken");
    } catch (e) {
      debugPrint("❌ FirebaseMessaging.getToken() error: $e");
    }
  }

  // ── Workmanager ────────────────────────────────────────────────────────────
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

  // ── NotificationService ────────────────────────────────────────────────────
  try {
    await NotificationService.init();
    debugPrint("✅ Notification Service Initialized");
  } catch (e) {
    debugPrint("❌ Notification Init Error: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fix #7: Global uncaught-exception handlers installed as early as possible.

  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint("🔥 FlutterError: ${details.exceptionAsString()}");
    debugPrint("🔥 Stack: ${details.stack}");
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint("🔥 PlatformDispatcher uncaught error: $error");
    debugPrint("🔥 Stack: $stack");
    return true; // Mark as handled so the framework doesn't also crash
  };

  // 🔒 Task 5.5: All fonts used by the app (Cairo, Amiri, Aref Ruqaa, Outfit,
  // IBM Plex Mono) are now bundled locally under assets/fonts/google_fonts/.
  // Disabling runtime HTTP fetching guarantees the app NEVER attempts a
  // network call for fonts (fully offline-safe) and will simply use the
  // matching bundled asset instead.
  GoogleFonts.config.allowRuntimeFetching = false;

  // 🔒 Task 5.5: Register OFL licenses for the Google Fonts bundled locally

  // as assets (assets/fonts/google_fonts/). This keeps Flutter's built-in
  // "Licenses" page (Settings > About > Licenses) accurate/compliant now
  // that these fonts ship inside the APK instead of being fetched over HTTP.
  LicenseRegistry.addLicense(() async* {
    const licenseFiles = <String>[
      'assets/fonts/google_fonts/OFL_cairo.txt',
      'assets/fonts/google_fonts/OFL_amiri.txt',
      'assets/fonts/google_fonts/OFL_arefruqaa.txt',
      'assets/fonts/google_fonts/OFL_outfit.txt',
      'assets/fonts/google_fonts/OFL_ibmplexmono.txt',
    ];
    for (final path in licenseFiles) {
      try {
        final license = await rootBundle.loadString(path);
        yield LicenseEntryWithLineBreaks(<String>['google_fonts'], license);
      } catch (e) {
        debugPrint("❌ Failed to load font license '$path': $e");
      }
    }
  });

  // ── Critical pre-runApp init ───────────────────────────────────────────────
  // Only settingsProvider.loadSettings() and QuranService.loadQuran() MUST
  // complete before runApp() — everything else is deferred post-first-frame.

  final settingsProvider = SettingsProvider();

  // Fix #1: wrap loadSettings() in its own try/catch so a failure here doesn't
  // crash main() before runApp() is ever called.
  bool settingsLoaded = false;
  try {
    await settingsProvider.loadSettings();
    settingsLoaded = true;
  } catch (e) {
    debugPrint("❌ settingsProvider.loadSettings() error: $e");
  }

  // Fix #1: wrap loadQuran() in its own try/catch — a JSON parse error must
  // not prevent the app from launching.
  if (settingsLoaded) {
    try {
      await QuranService.loadQuran(settingsProvider.currentJsonPath);
    } catch (e) {
      debugPrint("❌ QuranService.loadQuran() error: $e");
    }
  }

  // ✅ Edge-to-Edge System Navigation & Transparent Status Bar Setup
  // Fix #2: Keep this as a sane initial default for the very first frame only.
  // The widget tree now owns the reactive per-theme value via AnnotatedRegion
  // (see MuslimApp.build), so this call is only a fallback before first paint.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // light-mode default
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Fix #1: runApp() is called unconditionally — even if settings/quran failed,
  // the app must always launch (with whatever partial state is available).
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settingsProvider),
      ],
      // ✅ نمرر الـ Provider باش نستخدموه فالـ child (Localization)
      child: const MuslimApp(),
    ),
  );

  // Fix #3: Kick off all deferred (non-critical) init after the first frame
  // has been submitted to the engine, so startup latency is not blocked.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _deferredInit(settingsProvider);
  });
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

    // Fix #2: Compute the correct status-bar icon brightness reactively based
    // on the resolved theme brightness, so dark-mode users get light icons
    // instead of invisible dark icons.
    final resolvedBrightness = switch (settings.themeMode) {
      ThemeMode.dark => Brightness.dark,
      ThemeMode.light => Brightness.light,
      ThemeMode.system =>
        MediaQuery.platformBrightnessOf(context),
    };
    final isDark = resolvedBrightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        // Light icons on dark backgrounds, dark icons on light backgrounds.
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: MaterialApp(
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
        // ✅ التطبيق يدعم اللغة العربية فقط (Arabic-only application)
        supportedLocales: const [
          Locale('ar', 'AE'),
        ],
        locale: const Locale('ar', 'AE'),


        // ✅ اللوجيك: إيلا كان جديد -> Setup, إيلا قديم -> Main
        home: settings.isFirstTime ? const SetupScreen() : const MainScreen(),

        // ✅ Banner Overlay (فوق كل شيء)
        builder: (context, child) {
          return AdhanOverlayWrapper(child: child);
        },
      ),
    );
  }
}
