import 'package:adhan/adhan.dart';

enum PrayerPhase {
  adhanCountdown,
  iqamahCountdown,
  prayerInProgress,
}

class PrayerDisplayState {
  final PrayerPhase phase;
  final Prayer prayer;
  final String prayerNameArabic;
  final DateTime targetTime;
  final Duration remaining;
  final String titleText;
  final String? wuduMessage;
  final String? inPrayerMessage;
  final String? silentModeMessage;
  final double progress;

  const PrayerDisplayState({
    required this.phase,
    required this.prayer,
    required this.prayerNameArabic,
    required this.targetTime,
    required this.remaining,
    required this.titleText,
    this.wuduMessage,
    this.inPrayerMessage,
    this.silentModeMessage,
    required this.progress,
  });

  static int getIqamahMinutes(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 20;
      case Prayer.dhuhr:
      case Prayer.asr:
      case Prayer.isha:
        return 15;
      case Prayer.maghrib:
        return 10;
      default:
        return 15;
    }
  }

  static String getArabicPrayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return "الفجر";
      case Prayer.sunrise:
        return "الشروق";
      case Prayer.dhuhr:
        return "الظهر";
      case Prayer.asr:
        return "العصر";
      case Prayer.maghrib:
        return "المغرب";
      case Prayer.isha:
        return "العشاء";
      default:
        return "الصلاة";
    }
  }

  static PrayerDisplayState calculateState({
    required PrayerTimes prayerTimes,
    required DateTime currentTime,
    Coordinates? coordinates,
    CalculationParameters? params,
    int inPrayerBufferMinutes = 15,
  }) {
    // 1. Evaluate active prayers today for Iqamah & In-Prayer states
    final prayersToCheck = [
      Prayer.fajr,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
    ];

    for (final p in prayersToCheck) {
      final adhanTime = prayerTimes.timeForPrayer(p);
      if (adhanTime == null) continue;

      final iqamahMins = getIqamahMinutes(p);
      final iqamahTime = adhanTime.add(Duration(minutes: iqamahMins));
      final prayerEndTime =
          iqamahTime.add(Duration(minutes: inPrayerBufferMinutes));

      // 2a. Check Iqamah Countdown Phase (Adhan time <= currentTime < Iqamah time)
      if ((currentTime.isAtSameMomentAs(adhanTime) ||
              currentTime.isAfter(adhanTime)) &&
          currentTime.isBefore(iqamahTime)) {
        final remaining = iqamahTime.difference(currentTime);
        final totalSecs = iqamahMins * 60;
        final elapsedSecs = currentTime.difference(adhanTime).inSeconds;
        final progress = (elapsedSecs / totalSecs).clamp(0.0, 1.0);

        return PrayerDisplayState(
          phase: PrayerPhase.iqamahCountdown,
          prayer: p,
          prayerNameArabic: getArabicPrayerName(p),
          targetTime: iqamahTime,
          remaining: remaining,
          titleText: "المتبقي لإقامة صلاة ${getArabicPrayerName(p)}",
          wuduMessage: "🕌 حان وقت الوضوء والاستعداد لصلاة الجماعة",
          progress: progress,
        );
      }

      // 2b. Check Prayer In Progress Phase (Iqamah time <= currentTime < Prayer end time)
      if ((currentTime.isAtSameMomentAs(iqamahTime) ||
              currentTime.isAfter(iqamahTime)) &&
          currentTime.isBefore(prayerEndTime)) {
        final totalSecs = inPrayerBufferMinutes * 60;
        final elapsedSecs = currentTime.difference(iqamahTime).inSeconds;
        final progress = (elapsedSecs / totalSecs).clamp(0.0, 1.0);

        return PrayerDisplayState(
          phase: PrayerPhase.prayerInProgress,
          prayer: p,
          prayerNameArabic: getArabicPrayerName(p),
          targetTime: prayerEndTime,
          remaining: prayerEndTime.difference(currentTime),
          titleText: "صلاة ${getArabicPrayerName(p)} قائمة الآن",
          inPrayerMessage: "الصلاة تقام الآن في المساجد - تقبل الله طاعتكم 🕌",
          silentModeMessage: "يرجى التأكد من تفعيل وضع الصامت 🔇",
          progress: progress,
        );
      }
    }

    // 2c. Check if yesterday's Isha is in Iqamah or In-Prayer phase
    if (coordinates != null && params != null) {
      final yesterday = currentTime.subtract(const Duration(days: 1));
      final dateComp =
          DateComponents(yesterday.year, yesterday.month, yesterday.day);
      final yesterdayPrayers = PrayerTimes(coordinates, dateComp, params);
      final ishaAdhan = yesterdayPrayers.isha;
      final iqamahMins = getIqamahMinutes(Prayer.isha);
      final iqamahTime = ishaAdhan.add(Duration(minutes: iqamahMins));
      final prayerEndTime =
          iqamahTime.add(Duration(minutes: inPrayerBufferMinutes));

      if (currentTime.isAfter(ishaAdhan) && currentTime.isBefore(iqamahTime)) {
        final remaining = iqamahTime.difference(currentTime);
        return PrayerDisplayState(
          phase: PrayerPhase.iqamahCountdown,
          prayer: Prayer.isha,
          prayerNameArabic: "العشاء",
          targetTime: iqamahTime,
          remaining: remaining,
          titleText: "المتبقي لإقامة صلاة العشاء",
          wuduMessage: "🕌 حان وقت الوضوء والاستعداد لصلاة الجماعة",
          progress:
              (currentTime.difference(ishaAdhan).inSeconds / (iqamahMins * 60))
                  .clamp(0.0, 1.0),
        );
      }

      if ((currentTime.isAtSameMomentAs(iqamahTime) ||
              currentTime.isAfter(iqamahTime)) &&
          currentTime.isBefore(prayerEndTime)) {
        return PrayerDisplayState(
          phase: PrayerPhase.prayerInProgress,
          prayer: Prayer.isha,
          prayerNameArabic: "العشاء",
          targetTime: prayerEndTime,
          remaining: prayerEndTime.difference(currentTime),
          titleText: "صلاة العشاء قائمة الآن",
          inPrayerMessage: "الصلاة تقام الآن في المساجد - تقبل الله طاعتكم 🕌",
          silentModeMessage: "يرجى التأكد من تفعيل وضع الصامت 🔇",
          progress: (currentTime.difference(iqamahTime).inSeconds /
                  (inPrayerBufferMinutes * 60))
              .clamp(0.0, 1.0),
        );
      }
    }

    // 3. Adhan Countdown Phase (Upcoming Prayer)
    Prayer next = prayerTimes.nextPrayer();
    DateTime nextTime = prayerTimes.timeForPrayer(next) ?? currentTime;

    // Handle post-Isha transition to tomorrow's Fajr
    if (next == Prayer.none || currentTime.isAfter(prayerTimes.isha)) {
      next = Prayer.fajr;
      if (coordinates != null && params != null) {
        final tomorrow = currentTime.add(const Duration(days: 1));
        final dateComp =
            DateComponents(tomorrow.year, tomorrow.month, tomorrow.day);
        final tomorrowPrayers = PrayerTimes(coordinates, dateComp, params);
        nextTime = tomorrowPrayers.fajr;
      } else {
        nextTime = prayerTimes.fajr.add(const Duration(days: 1));
      }
    }

    Duration diff = nextTime.difference(currentTime);
    if (diff.isNegative) diff = Duration.zero;

    DateTime prevTime = currentTime;
    if (next == Prayer.fajr) {
      prevTime = prayerTimes.isha;
    } else if (next == Prayer.dhuhr) {
      prevTime = prayerTimes.sunrise;
    } else if (next == Prayer.asr) {
      prevTime = prayerTimes.dhuhr;
    } else if (next == Prayer.maghrib) {
      prevTime = prayerTimes.asr;
    } else if (next == Prayer.isha) {
      prevTime = prayerTimes.maghrib;
    }

    double progress = 0.5;
    final totalWindow = nextTime.difference(prevTime).inSeconds;
    if (totalWindow > 0) {
      final elapsed = currentTime.difference(prevTime).inSeconds;
      progress = (elapsed / totalWindow).clamp(0.0, 1.0);
    }

    return PrayerDisplayState(
      phase: PrayerPhase.adhanCountdown,
      prayer: next,
      prayerNameArabic: getArabicPrayerName(next),
      targetTime: nextTime,
      remaining: diff,
      titleText: "الوقت المتبقي لصلاة ${getArabicPrayerName(next)}",
      progress: progress,
    );
  }
}
