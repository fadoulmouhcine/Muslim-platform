// Copyright (c) 2026-present Mouhcine Fadoul. All rights reserved.
// Application: Muslim Platform — All Rights Reserved

import 'dart:async';
import 'package:flutter/material.dart';

/// A single, app-wide ticking clock shared by every screen that needs to
/// display a live-updating time (prayer countdowns, "next prayer" progress
/// bars, etc.).
///
/// PROBLEM THIS SOLVES:
/// Previously, several screens (`DashboardScreen`, `PrayerTimesScreen`,
/// `ActivePrayerMessageTicker`, ...) each created and managed their own
/// independent `Timer.periodic(Duration(seconds: 1))`. When multiple of
/// these screens stayed mounted at the same time (e.g. behind the bottom
/// navigation bar), the app would end up with several concurrent 1-second
/// timers all firing `setState()` independently — causing redundant CPU
/// wakeups, unnecessary rebuilds, and avoidable battery drain.
///
/// SOLUTION:
/// `AppClockService` is a single app-wide singleton exposing one shared
/// [ValueNotifier<DateTime>]. Screens subscribe to it via
/// [ValueListenableBuilder], which automatically registers/unregisters its
/// listener as widgets are built/disposed — so a screen that is popped or
/// removed from the tree stops receiving ticks with zero extra bookkeeping.
///
/// The service also observes app lifecycle changes and automatically
/// **pauses** its internal timer while the app is backgrounded
/// (`paused`/`inactive`/`detached`), and **resumes** it when the app returns
/// to the foreground (`resumed`) — eliminating background battery usage
/// entirely, on top of removing the duplicate-timer problem.
class AppClockService with WidgetsBindingObserver {
  AppClockService._internal() {
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  /// Global singleton instance.
  static final AppClockService instance = AppClockService._internal();

  /// The shared ticking value. Listen via `ValueListenableBuilder` or
  /// `AppClockService.instance.now.addListener(...)`.
  final ValueNotifier<DateTime> now = ValueNotifier<DateTime>(DateTime.now());

  Timer? _timer;

  void _startTimer() {
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      now.value = DateTime.now();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Immediately refresh + resume ticking when the app comes back.
      now.value = DateTime.now();
      _startTimer();
    } else {
      // paused / inactive / detached / hidden -> stop ticking to save battery.
      _stopTimer();
    }
  }
}
