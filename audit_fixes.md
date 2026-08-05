# 📋 MASTER AUDIT FIXES (Muslim Platform)

> **AI INSTRUCTIONS:** 
> When completing a task, update its checkbox to `[x] ✅` to mark it as done. Do not modify tasks you haven't fully completed.

## 🚀 EPIC 1: Play Store Readiness & Build Config (CRITICAL)
- [x] ✅ Task 1.1: In `build.gradle.kts`, change both `applicationId` and `namespace` to `com.fadoul.muslimplatform`, and regenerate the `google-services.json` setup. (Codebase side complete: `namespace`/`applicationId` updated, Kotlin sources moved to `com.fadoul.muslimplatform`, `AndroidManifest.xml` package updated, `proguard-rules.pro` updated. `google-services.json` regeneration to be done manually via Firebase console as requested.)
- [x] ✅ Task 1.2: Remove `ACCESS_BACKGROUND_LOCATION` and `android:usesCleartextTraffic="true"` from `AndroidManifest.xml`.
- [x] ✅ Task 1.3: Enable release minification (`isMinifyEnabled = true`, `isShrinkResources = true`) and verify `proguard-rules.pro` has proper `-keep` rules for Firebase, Gson, and reflection plugins.
- [x] ✅ Task 1.4: Fix `versionCode` in `build.gradle.kts` to read from `pubspec.yaml` instead of `local.properties`.
- [x] ✅ Task 1.5: Add a Gradle safeguard in `build.gradle.kts` to fail the release build if `key.properties` is missing.
- [ ] Task 1.6: Confirm the app icon is a custom icon (not `@mipmap/ic_launcher`).


## 🗑️ EPIC 2: Asset Bloat & Cleanup (PERFORMANCE)
- [ ] Task 2.1: Delete the duplicate `assets/json/hadith/` folder (keep `sunnah/`).
- [ ] Task 2.2: Delete the duplicate `assets/json/quran/0/` folder.
- [ ] Task 2.3: Remove the unused `quran: ^1.3.3` dependency and clean up redundant individual asset file declarations in `pubspec.yaml`.
- [x] ✅ Task 2.4: Remove `assets/pdf/quran_tajweed.pdf` (75MB) from local assets and implement an on-demand download mechanism instead.

## 🐛 EPIC 3: Core Bugs & App Stability (HIGH)
- [x] ✅ Task 3.1: In `main.dart`, wrap `unawaited(OfficialPrayerTimesService.pruneOldCache())` in a proper `try/catch` block.
- [ ] Task 3.2: In `main.dart`, split the single large Firebase/FCM setup into individual `try/catch` blocks (especially for `getToken()`) to prevent silent failures.
- [ ] Task 3.3: Fix `QiblaScreen` compass logic (`heading == 0` is valid) and add a retry/error UI state for location resolution failures.
- [ ] Task 3.4: Remove the unconditional `Future.delayed(300ms)` in `NotificationService.consumePendingPayload()`.
- [ ] Task 3.5: Centralize `MethodChannel` string names into shared constants.
- [x] ✅ Task 3.6: Perform a project-wide check to ensure all `setState()` calls after `await` are protected by `if (mounted)`.

## 🏗️ EPIC 4: Architecture & Memory Optimization (MEDIUM)
- [x] ✅ Task 4.1: Consolidate multiple `Timer.periodic(1s)` across screens into a single shared app-wide `ValueNotifier<DateTime>` clock service.
- [ ] Task 4.2: Consolidate the duplicated `getOfficialPrayerTimes()` fetch/fallback logic (spread across 4 screens) into a single shared Controller/Provider.
- [ ] Task 4.3: Implement a cache-pruning routine in `OfficialPrayerTimesService` and remove any dual/redundant calls to `clearCache()` in `settings_provider.dart`.
- [ ] Task 4.4: Refactor `QuranService` to lazy-load the Hafs reference JSON instead of keeping it permanently in memory.
- [x] ✅ Task 4.5: Profile JSON parsing in `main.dart`; if >50ms, move it to a background isolate using `compute()`.
- [ ] Task 4.6: Fix memory leak in `main_screen.dart` by explicitly storing the `settings.addListener` reference and calling `removeListener` in `dispose()`.
- [ ] Task 4.7: Fix the "Clear Temp Files" button in `general_settings_tab.dart`: Scope deletion to an app-specific subdirectory via `compute()`, compute actual cache size, and add a UI confirmation dialog.

## 🎨 EPIC 5: UI/UX & Localization (MEDIUM)
- [x] ✅ Task 5.1: Completely remove `Locale('en', 'US')` from `main.dart` and remove language toggles from Settings UI (App must be 100% Arabic).
- [ ] Task 5.2: Audit all hardcoded Arabic UI strings and extract them into `.arb` files to prepare for scalable localization.
- [x] ✅ Task 5.3: Add a visual loading indicator (shimmer/progress) in `prayer_screen.dart` during network fetches.
- [x] ✅ Task 5.4: Ensure explicit loading and error states are displayed across all prayer screens if the API fetch fails, instead of silently keeping stale data.
- [ ] Task 5.5: Ensure `google_fonts` are bundled locally for offline use.

## 🔒 EPIC 6: Security Check & Housekeeping (MANUAL)
- [ ] Task 6.1: Manually verify that `android/key.properties` has NEVER been committed to git history (`git log --all -- android/key.properties`).
- [x] ✅ Task 6.2: Write widget and unit tests for `OfficialPrayerTimesService` and `SettingsProvider`.
- [ ] Task 6.3: Run `flutter pub outdated` to check for major dependency updates.
- [ ] Task 6.4: Prepare Play Console justification texts for `FOREGROUND_SERVICE_SPECIAL_USE` and `USE_EXACT_ALARM`.


