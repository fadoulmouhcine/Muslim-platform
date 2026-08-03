/// 🌿 Helper for proper Arabic Pluralization & Grammar Rules (قواعد التمييز والأعداد)
class ArabicPluralHelper {
  /// Formats minutes into grammatically correct Arabic
  /// - 1: دقيقة واحدة
  /// - 2: دقيقتان
  /// - 3-10: X دقائق (مثلاً: 5 دقائق)
  /// - 11+: X دقيقة (مثلاً: 15 دقيقة)
  static String formatMinutes(int count) {
    if (count <= 0) return "0 دقيقة";
    if (count == 1) return "دقيقة واحدة";
    if (count == 2) return "دقيقتان";
    if (count >= 3 && count <= 10) return "$count دقائق";
    return "$count دقيقة";
  }

  /// Formats hours into grammatically correct Arabic
  /// - 1: ساعة واحدة
  /// - 2: ساعتان
  /// - 3-10: X ساعات (مثلاً: 5 ساعات)
  /// - 11+: X ساعة (مثلاً: 12 ساعة)
  static String formatHours(int count) {
    if (count <= 0) return "0 ساعة";
    if (count == 1) return "ساعة واحدة";
    if (count == 2) return "ساعتان";
    if (count >= 3 && count <= 10) return "$count ساعات";
    return "$count ساعة";
  }

  /// Formats days into grammatically correct Arabic
  /// - 1: يوم واحد
  /// - 2: يومان
  /// - 3-10: X أيام (مثلاً: 5 أيام)
  /// - 11+: X يوماً (مثلاً: 30 يوماً)
  static String formatDays(int count) {
    if (count <= 0) return "0 يوم";
    if (count == 1) return "يوم واحد";
    if (count == 2) return "يومان";
    if (count >= 3 && count <= 10) return "$count أيام";
    return "$count يوماً";
  }

  /// Formats seconds into grammatically correct Arabic
  /// - 1: ثانية واحدة
  /// - 2: ثانيتان
  /// - 3-10: X ثوانٍ
  /// - 11+: X ثانية
  static String formatSeconds(int count) {
    if (count <= 0) return "0 ثانية";
    if (count == 1) return "ثانية واحدة";
    if (count == 2) return "ثانيتان";
    if (count >= 3 && count <= 10) return "$count ثوانٍ";
    return "$count ثانية";
  }

  /// Formats Hizb goals into grammatically correct Arabic
  /// - 1: حزب واحد
  /// - 2: حزبان
  /// - 3-10: X أحزاب
  /// - 11+: X حزباً
  static String formatHizb(int count) {
    if (count <= 0) return "0 حزب";
    if (count == 1) return "حزب واحد";
    if (count == 2) return "حزبان";
    if (count >= 3 && count <= 10) return "$count أحزاب";
    return "$count حزباً";
  }
}
