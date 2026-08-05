// Copyright (c) 2026-present Mouhcine Fadoul. All rights reserved.
// Application: Muslim Platform — All Rights Reserved
// Author: Mouhcine Fadoul

/// 🔗 Centralized MethodChannel name constants (Task 3.5).
///
/// Previously, each service/widget declared its own raw MethodChannel name
/// string (e.g. `MethodChannel('com.example.muslim/adhan')`), duplicated
/// across multiple Dart files. Any typo or rename would silently break the
/// native <-> Flutter bridge with no compile-time safety.
///
/// These constants MUST always match the corresponding Kotlin
/// `CHANNEL_NAME` constants declared natively in:
///   - android/app/src/main/kotlin/com/fadoul/muslimplatform/AdhanMethodChannel.kt
///   - android/app/src/main/kotlin/com/fadoul/muslimplatform/SilentModeChannel.kt
///   - android/app/src/main/kotlin/com/fadoul/muslimplatform/MainActivity.kt (widget channel)
class MethodChannelNames {
  MethodChannelNames._();

  /// Channel used for Adhan playback, scheduling & notification-tap events.
  static const String adhan = 'com.example.muslim/adhan';

  /// Channel used to trigger native home/lock-screen widget updates.
  static const String widget = 'com.example.muslim/widget';

  /// Channel used for Do-Not-Disturb / Silent-mode control during prayer.
  static const String silentMode = 'com.example.muslim/silent_mode';
}
