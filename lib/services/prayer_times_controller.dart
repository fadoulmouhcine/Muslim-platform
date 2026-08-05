// Copyright (c) 2026-present Mouhcine Fadoul. All rights reserved.
// Application: Muslim Platform — All Rights Reserved

import 'package:adhan/adhan.dart';
import 'settings_provider.dart';

/// ✅ Task 4.2: Centralized prayer-times computation & fallback logic.
///
/// Prayer times are computed 100% offline via the `adhan` astronomical
/// calculation engine (no network round-trip, no API, no cache). Before
/// this refactor, the logic to (a) fall back to a default location (Masjid
/// al-Haram, Mecca) whenever real GPS coordinates weren't yet available,
/// and (b) resolve `CalculationParameters` from [SettingsProvider], was
/// hand-duplicated across four different call sites:
///   - `main_screen.dart`
///   - `prayer_screen.dart`
///   - `dashboard/widgets/hero_prayer_card.dart`
///   - `settings/widgets/adhan_settings_tab.dart`
///
/// This meant any future change to that fallback behavior (e.g. changing
/// the default location, or how parameters are derived) would require
/// hunting down and updating 4+ separate places — an easy source of subtle
/// inconsistency bugs. [PrayerTimesController] is now the single shared
/// source of truth all four (and any future) call sites route through.
class PrayerTimesController {
  PrayerTimesController._();

  /// Default fallback coordinates (Masjid al-Haram, Mecca) used only until
  /// the device's real GPS location becomes available.
  static final Coordinates defaultCoordinates = Coordinates(21.4225, 39.8262);

  /// Computes today's prayer times for an explicit, already-known
  /// [coordinates]/[params] pair (no fallback resolution needed — use this
  /// when both values are guaranteed non-null by the caller).
  static PrayerTimes computeTimes(
    Coordinates coordinates,
    CalculationParameters params,
  ) {
    return PrayerTimes.today(coordinates, params);
  }

  /// Computes today's prayer times, resolving fallbacks as needed:
  /// - [coordinates] falls back to [defaultCoordinates] if null.
  /// - [params] falls back to `settings.getCalculationParameters()` if null.
  static PrayerTimes computeTodayTimes({
    Coordinates? coordinates,
    CalculationParameters? params,
    required SettingsProvider settings,
  }) {
    final coords = coordinates ?? defaultCoordinates;
    final calcParams = params ?? settings.getCalculationParameters();
    return computeTimes(coords, calcParams);
  }
}
