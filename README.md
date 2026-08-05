# Muslim Platform
### An authentic, privacy-first Islamic companion app for Android

**Author:** Mouhcine Fadoul  
**Contact:** fadoulmouhcine@gmail.com

---

## About

Muslim Platform is a comprehensive Islamic lifestyle application featuring:

- 🕌 **Adhan & Prayer Times** — Precise prayer time calculations for 16+ world methods with native Adhan audio playback
- 🧭 **Qibla Compass** — Real-time GPS-powered Qibla direction
- 📖 **Quran** — Full Quran with multiple Riwayat (Hafs, Warsh, Qaloun, Sousi), Tafsir, and audio recitation
- 📅 **Hijri Calendar** — Synchronized Hijri calendar with API correction offset
- 📿 **Tasbih Counter** — Digital dhikr counter with haptic feedback
- 📚 **Sunnah Books** — Hadith collections (Bukhari, Muslim, and more)
- 🔇 **Smart Auto-Silent Mode** — Automatically silences the phone during prayer windows
- 🌙 **Full Dark Mode** — System-aware adaptive theming

## Firebase Integration

This application uses Firebase for:
- Cloud Messaging (FCM) for remote notifications
- Analytics for usage insights
- Crashlytics for stability monitoring

> **Note:** `google-services.json` and `firebase_options.dart` are excluded from version control.

## Tech Stack

- **Framework:** Flutter (Dart)
- **Min SDK:** Android 21+
- **Calculation Engine:** Adhan library + custom Morocco Ministry of Habous method
- **Background Tasks:** WorkManager + AlarmManager (Exact Alarms)
- **Persistence:** SharedPreferences (on-device, encrypted)

## Privacy

All user data (location, preferences, prayer logs) is processed and stored **locally on device only**.  
No personal data is transmitted to external servers.  
See [Privacy Policy](./index.html) for full disclosure.

---

## License

Copyright (c) 2026-present Mouhcine Fadoul. All rights reserved.  
This software is proprietary. Unauthorized copying, distribution, or modification is strictly prohibited.  
See [LICENSE](./LICENSE) for full terms.
