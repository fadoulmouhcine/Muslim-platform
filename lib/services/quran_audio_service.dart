import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'quran_service.dart';

class Reciter {
  final String id; // الرابط فالسيرفر
  final String name; // سمية القارئ
  final String riwaya; // الرواية

  Reciter({required this.id, required this.name, required this.riwaya});
}

class QuranAudioService {
  final AudioPlayer _player = AudioPlayer();

  // ✅ القائمة مبنية على الروابط اللي عطيتيني بالحرف
  static final List<Reciter> reciters = [
    // 1. عبد الباسط (حفص)
    // Link: https://everyayah.com/data/AbdulSamad_64kbps_QuranExplorer.Com/
    Reciter(
        id: "AbdulSamad_64kbps_QuranExplorer.Com",
        name: "عبد الباسط عبد الصمد",
        riwaya: "حفص"),

    // 2. ماهر المعيقلي (حفص)
    // Link: https://everyayah.com/data/MaherAlMuaiqly128kbps
    Reciter(id: "MaherAlMuaiqly128kbps", name: "ماهر المعيقلي", riwaya: "حفص"),

    // 3. ياسين الجزائري (ورش)
    // Link: https://everyayah.com/data/warsh/warsh_yassin_al_jazaery_64kbps
    Reciter(
        id: "warsh/warsh_yassin_al_jazaery_64kbps",
        name: "ياسين الجزائري",
        riwaya: "ورش"),

    // 4. علي الحذيفي (حفص - وغنخدموه لقالون حيت مكاينش فرق كبير فالصوت)
    // Link: https://everyayah.com/data/Hudhaify_128kbps
    Reciter(id: "Hudhaify_128kbps", name: "علي الحذيفي", riwaya: "حفص/قالون"),
  ];

  Reciter currentReciter = reciters[0];

  void setReciter(String reciterId) {
    currentReciter = reciters.firstWhere((r) => r.id == reciterId,
        orElse: () => reciters[0]);
  }

  // دالة التشغيل
  Future<void> playAyah(
      int surahNumber, int ayahNumber, String verseText) async {
    try {
      // ✅ 1. تحويل رقم الآية إلى حفص (باش السيرفر يفهمنا)
      // هاد الدالة كاين ف quran_service.dart وغتصلح المشكل د 404
      // ✅ Task 4.4: This now awaits the lazy-loaded Hafs reference JSON.
      int fileAyahNumber = await QuranService.getHafsAyahNumberForTafsir(
          surahNumber, ayahNumber, verseText);

      debugPrint(
          "🔍 Audio: Requested Ayah $ayahNumber -> Playing File $fileAyahNumber (Reciter: ${currentReciter.id})");

      // ✅ 2. صياغة الرابط (001001.mp3)
      String s = surahNumber.toString().padLeft(3, '0');
      String a = fileAyahNumber.toString().padLeft(3, '0');

      String url = "https://everyayah.com/data/${currentReciter.id}/$s$a.mp3";

      debugPrint("🔗 Link: $url"); // تأكد أن الرابط كيبان هو هذاك فالكونسول

      await _player.stop();
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      debugPrint("❌ Error playing audio: $e");
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}
