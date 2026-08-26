<p align="center">
  <img src="assets/branding/Muslim-Platform.png" alt="Muslim Platform Logo" width="130" style="border-radius: 28px; box-shadow: 0 10px 30px rgba(197, 160, 89, 0.25);">
</p>

<h1 align="center">منصة مسلم — Muslim Platform</h1>

<p align="center">
  <strong>منصة مسلم لكل مسلم — Islamic Platform for Every Muslim</strong><br>
  <em>The Ultimate Offline-First, Privacy-Focused Islamic Ecosystem for Android.<br>
  Quran with 6 Riwayat • Hadith Encyclopedias • Precise Adhan • Qibla Compass • Daily Athkar<br>
  <strong>100% Free • Zero Ads • Zero Tracking • 100% On-Device</strong></em>
</p>

<p align="center">
  <a href="./README.md"><b>🇬🇧 English Documentation</b></a> &nbsp;•&nbsp; 
  <a href="./README.ar.md"><b>🇸🇦 النسخة العربية (Arabic)</b></a>
</p>

<p align="center">
  <a href="https://play.google.com/store/apps/details?id=com.fadoul.muslimplatform">
    <img src="https://img.shields.io/badge/Google_Play-Get_App-004D38?style=for-the-badge&logo=google-play&logoColor=10B981" alt="Google Play Download">
  </a>
  <a href="https://fadoulmouhcine.github.io/Muslim-platform/">
    <img src="https://img.shields.io/badge/Privacy_Policy-Verified_2026-C5A059?style=for-the-badge&logo=shield&logoColor=white" alt="Privacy Policy Website">
  </a>
  <a href="https://github.com/fadoulmouhcine/Muslim-platform">
    <img src="https://img.shields.io/badge/Source-GitHub_Repo-0E2B21?style=for-the-badge&logo=github&logoColor=10B981" alt="GitHub Repository">
  </a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android_8.0%2B_%7C_14%2B_Ready-0E2B21?style=flat-square&logo=android&logoColor=10B981" alt="Android">
  <img src="https://img.shields.io/badge/Engine-Flutter_%26_Dart-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Database-100%25_Offline--First-059669?style=flat-square&logo=sqlite&logoColor=white" alt="Offline First">
  <img src="https://img.shields.io/badge/Privacy-100%25_On--Device-C5A059?style=flat-square&logo=protectwise&logoColor=white" alt="Privacy">
  <img src="https://img.shields.io/badge/Ads-0%25_Zero_Ads-red?style=flat-square" alt="Zero Ads">
  <img src="https://img.shields.io/badge/Status-Production_Ready-brightgreen?style=flat-square" alt="Status">
</p>

<p align="center">
  <a href="#key-features">Key Features</a> •
  <a href="#privacy--security-pillars">Privacy by Design</a> •
  <a href="#hadith--quran-library">Quran & Hadith Library</a> •
  <a href="#technical-architecture">Architecture</a> •
  <a href="#permissions-transparency">Permissions</a> •
  <a href="#download">Download</a> •
  <a href="#author--support">Author</a>
</p>

---

## 🌟 Overview

**Muslim Platform (منصة مسلم)** is an all-in-one Islamic application crafted with one uncompromising principle: **Privacy by Design**. 

Unlike conventional apps that require user registrations, harvest telemetry, or inject intrusive advertisements into sacred worship experiences, Muslim Platform operates **100% on your device**. All mathematical calculations, astronomical prayer timings, full Quran databases, tafsir collections, and hadith compendiums are embedded locally. The app functions flawlessly in **Airplane Mode** without an active internet connection.

---

## 🚀 Key Features

### 📖 1. The Holy Quran (المصحف الشريف)
- **6 Authentic Riwayat (القراءات والروايات المعتمدة)**:
  - Hafs ‘an ‘Asim (*حفص عن عاصم*)
  - Warsh ‘an Nafi’ (*ورش عن نافع*)
  - Qaloun ‘an Nafi’ (*قالون عن نافع*)
  - Ad-Douri ‘an Abi ‘Amr (*الدوري عن أبي عمرو*)
  - As-Sousi ‘an Abi ‘Amr (*السوسي عن أبي عمرو*)
  - Shu’bah ‘an ‘Asim (*شعبة عن عاصم*)
- **Multilingual Translations**: Instant translations in **English**, **French (Français)**, **Spanish (Español)**, and **Arabic**.
- **Tafsir & Meanings**: Integrated classical and simplified Tafsir for every Surah and Ayah.
- **Dua Khatm Al-Quran (دعاء ختم القرآن)**: Authentic supplications for concluding Quran recitation.
- **Reading Experience**: Custom Uthmanic typography, Surah/Juz/Hizb navigation, custom bookmarks, dark/light visual modes, and reading progress memorization.

### 🎧 2. Audio Recitations (التلاوات القرآنية العطرة)
- High-fidelity audio recitations by renowned international reciters (e.g., Sheikh Abdul Basit Abdul Samad).
- **Smart Offline Cache Engine**: Audio tracks are saved locally after playback, enabling smooth offline listening anytime.

### 🕋 3. Prayer Times & Exact Adhan Engine (مواقيت الصلاة ومحرك الأذان)
- **100% Local Astronomical Calculations**: Computed on-device using trusted mathematical algorithms without sending coordinates to remote APIs.
- **Major Regional Calculation Methods**:
  - Ministry of Endowments and Islamic Affairs (Morocco)
  - Umm Al-Qura University (Makkah & Saudi Arabia / Gulf)
  - Presidency of Religious Affairs (*Diyanet*, Turkey & Europe)
  - Muslim World League (MWL)
  - Egyptian General Authority of Survey
  - Islamic Society of North America (ISNA)
  - University of Islamic Sciences, Karachi
  - Shia Ithna-Ashari / Leva Institute (Qum)
- **Multi-Muazzin Adhan Voices**: Authentic Adhan recordings from Makkah Al-Mukarramah, Al-Madinah Al-Munawwarah, Al-Masjid Al-Aqsa, Cairo (Egypt), and Sheikh Abdul Basit.
- **Android 14/15 Exact Alarm Engine**: Scheduled with `SCHEDULE_EXACT_ALARM` to guarantee millisecond accuracy even during deep battery sleep (Doze Mode).
- **Smart DND Mode (الوضع الصامت الذكي في المساجد)**: Automatically mutes the phone during prayer congregational times and restores original sound profile afterward — without requiring microphone access.

### 🧭 4. Sensor-Based Qibla Compass (بوصلة القبلة الدقيقة)
- High-precision direction computation directly to the Holy Kaaba in Makkah.
- Uses fused device hardware magnetometer and accelerometer sensors with real-time calibration hints and smooth haptic feedback.
- Works 100% offline without cellular or Wi-Fi data.

### 📚 5. Comprehensive Sunnah & Hadith Encyclopedia (موسوعة السنة النبوية)
Full offline indexed library of authentic classical Hadith collections:
| Classical Collection | Arabic Name | Category |
|---|---|---|
| **Sahih al-Bukhari** | صحيح البخاري | Sahih Collections |
| **Sahih Muslim** | صحيح مسلم | Sahih Collections |
| **Sunan an-Nasa'i** | سنن النسائي | The 6 Canonical Sunan |
| **Sunan Abi Dawud** | سنن أبي داود | The 6 Canonical Sunan |
| **Jami' at-Tirmidhi** | جامع الترمذي | The 6 Canonical Sunan |
| **Sunan Ibn Majah** | سنن ابن ماجه | The 6 Canonical Sunan |
| **Muwatta Malik** | موطأ الإمام مالك | Classical Jurisprudence |
| **Musnad Ahmad** | مسند الإمام أحمد بن حنبل | Comprehensive Musnad |
| **Sunan ad-Darimi** | سنن الدارمي | Classical Sunan |
| **Riyad as-Salihin** | رياض الصالحين | Adab & Purification |
| **Bulugh al-Maram** | بلوغ المرام من أدلة الأحكام | Hadith of Rulings |
| **Ash-Shamail al-Muhammadiyyah** | الشمائل المحمدية للإمام الترمذي | Prophetic Traits |
| **Mishkat al-Masabih** | مشكاة المصابيح | Comprehensive Reference |
| **Al-Adab al-Mufrad** | الأدب المفرد للبخاري | Islamic Etiquette |
| **The 40 Hadith Qudsi** | الأحاديث القدسية | Divine Hadiths |
| **Hisn al-Muslim** | حصن المسلم من أذكار الكتاب والسنة | Fortress of the Muslim |

### 📿 6. Athkar, Duas & Digital Tasbih (الأذكار والأدعية والسبحة)
- **Fortress of the Muslim (Hisn al-Muslim)**: Morning, evening, sleep, wake-up, prayer, and travel adhkar.
- **Quranic & Prophetic Supplications**: Duas from the Holy Quran and authentic prayers of the Prophets (أدعية الأنبياء).
- **99 Beautiful Names of Allah (أسماء الله الحسنى)**: Full names with meanings and reflections.
- **Daily Wisdom & Athar (حكمة اليوم وأثر اليوم)**: Daily inspirational spiritual gems.
- **Advanced Digital Tasbih (السبحة الإلكترونية المتطورة)**: Multi-dhikr selector, customizable daily goals, vibrational haptics, and streak counters.

### 🌾 7. Hassad Al-Muslim — Daily Spiritual Harvest (الحصاد اليومي)
- Personal offline habit tracker to log daily prayers, Nawafil, rawatib, Quran daily roses, morning/evening athkar, fasting, and charity.
- Visual charts and streaks to maintain consistency and spiritual growth over days, weeks, and months.

### 🕌 8. Friday Hub (ملتقى يوم الجمعة المباركة)
- **Surah Al-Kahf**: Quick reading and listening shortcut for Friday.
- **Sunan of Friday Checklist**: Ghusl, Siwak, Clean garments, Perfume, Early arrival.
- **Salawat Counter**: Interactive counter for sending blessings upon Prophet Muhammad ﷺ.
- **Hour of Response Reminder (ساعة الاستجابة)**: Countdown and notifications before Maghrib.

### 📅 9. Hijri Calendar & Astronomical Synchronization (التقويم الهجري)
- Complete Hijri-Gregorian calendar with today's Islamic date and major Islamic occasions (Ramadan, Eid al-Fitr, Eid al-Adha, Mawlid, Isra and Miraj, Day of Arafah, Ashura).
- Regional alignment options with manual date adjustment (+/- 2 days).

### 📍 10. Privacy-Quantized Nearby Mosques (المساجد القريبة)
- Locates nearby mosques around your current location using open geographic data (OpenStreetMap/Overpass).
- **Coordinate Quantization (~110m Privacy Fuzzing)**: Truncates user coordinates before sending requests, ensuring your exact home address or GPS point is never transmitted.

---

## 🛡️ Privacy & Security Matrix

Muslim Platform sets a gold standard for digital privacy compliance (**Google Play 2026 Privacy & Transparency Standard**).

```
┌─────────────────────────────────────────────────────────────┐
│                 MUSLIM PLATFORM PRIVACY MODEL               │
├──────────────────────────────┬──────────────────────────────┤
│ 🚫 User Registration         │ ZERO Accounts & Logins       │
│ 🚫 Advertisements            │ 0% Ads, 100% Free Forever    │
│ 🚫 Commercial Data Tracking  │ ZERO Profiling & Analytics   │
│ 🔒 Coordinates & Location    │ Encrypted Locally on Device  │
│ 🔒 Religious Data & Habits   │ Never Leaves Your Phone      │
│ 🛡️ 1-Click Complete Wipe     │ Instantly Clears All Data    │
└──────────────────────────────┴──────────────────────────────┘
```

### System Permissions Breakdown
| Android Permission | Classification | Purpose |
|---|---|---|
| `SCHEDULE_EXACT_ALARM`<br>`USE_EXACT_ALARM` | **Essential** | Schedules the Adhan at the exact second, overcoming background battery sleep optimizations (Doze Mode). |
| `POST_NOTIFICATIONS` | **Standard (Android 13+)** | Displays notifications for Adhan, prayer reminders, and daily Athkar. |
| `ACCESS_COARSE_LOCATION`<br>`ACCESS_FINE_LOCATION` | **Foreground GPS** | Determines city coordinates locally for prayer angle and Qibla calculations. |
| `ACCESS_NOTIFICATION_POLICY` | **Optional (Smart DND)** | Enables automatic phone silencing during mosque congregational prayer. **Zero microphone or audio recording access.** |

---

## 🏗️ Technical Architecture

- **Core Framework**: [Flutter](https://flutter.dev) (v3.x+) & [Dart](https://dart.dev) (v3.x+).
- **Architecture Pattern**: Clean Architecture with modular service mixins, decoupled providers, and reactive UI state management.
- **Storage Layer**: Local SQLite & Encrypted KeyStore (`FlutterSecureStorage` / `EncryptedSharedPreferences`).
- **Calculation Engines**: Local trigonometric and astronomical spherical vector models for celestial solar angles and Kaaba geodesic bearings.
- **Localization**: Native RTL/LTR support with comprehensive Arabic, English, French, and Spanish localization dictionaries.

---

## 📱 Download

<p align="center">
  <a href="https://play.google.com/store/apps/details?id=com.fadoul.muslimplatform">
    <img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" alt="Get it on Google Play" width="220">
  </a>
</p>

| Metric | Details |
|---|---|
| **Package Name** | `com.fadoul.muslimplatform` |
| **Supported OS** | Android 7.0 (API 24) to Android 15+ |
| **Network Requirement** | 100% Offline (Optional internet only for map view & audio streaming) |
| **License / Pricing** | 100% Free & Sadaqah Jariyah (صدقة جارية) |

---

## 🌐 Live Privacy Site

The complete interactive privacy policy and compliance portal is hosted on GitHub Pages:  
👉 **[https://fadoulmouhcine.github.io/Muslim-platform/](https://fadoulmouhcine.github.io/Muslim-platform/)**

---

## 👨‍💻 Author & Contact

**Muslim Platform (منصة مسلم)** is designed and developed with devotion by:

**Mouhcine Fadoul (محسن فضول)**  
*Flutter & Mobile Software Engineer — Specialist in Offline-First, Privacy-Preserving Applications*

- 🌐 GitHub: [@fadoulmouhcine](https://github.com/fadoulmouhcine)
- 📧 Email: [fadoulmouhcine@gmail.com](mailto:fadoulmouhcine@gmail.com)
- 📍 Website: [fadoulmouhcine.github.io](https://fadoulmouhcine.github.io)

---

<p align="center">
  <sub>© 2026 <strong>Mouhcine Fadoul</strong>. All rights reserved. Made with ❤️ for the Muslim Ummah.</sub>
</p>