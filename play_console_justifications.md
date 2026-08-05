# 📋 Google Play Console — Permission Declaration Justifications

> **Task 6.4 (Audit Fixes):** Ready-to-paste justification texts for the Play
> Console "App content" → "Permissions declaration" forms for the two
> sensitive permissions used by **Muslim Platform**. Copy the relevant block
> verbatim (or lightly adapted) into the corresponding declaration form field
> before submitting a release that requests these permissions.

---

## 1. `FOREGROUND_SERVICE_SPECIAL_USE`

**Where it's used:** `AdhanService` (a foreground service with
`android:foregroundServiceType="mediaPlayback|specialUse"`) that plays the
Adhan (Islamic call to prayer) audio at the precise, pre-scheduled prayer
time — even while the app is closed or the device is idle/Doze-restricted.

**Play Console justification text (paste into the "Core functionality"
description field for the special use foreground service type):**

> Muslim Platform is an Islamic prayer companion app. Its core function is to
> play the Adhan (the Islamic call to prayer) audibly at the exact,
> astronomically-calculated time of each of the five daily prayers, even when
> the app is not in the foreground or the screen is off. A foreground service
> is required because:
> 1. Prayer times are time-critical — the Adhan must play at the exact
>    minute, which regular (non-foreground) background execution and Doze
>    mode restrictions would delay or silently drop.
> 2. The existing `mediaPlayback` foreground service type alone does not
>    fully cover this use case, since the service is not started in
>    response to direct, continuous user media-control interaction (like a
>    music player) — it is triggered by an exact-alarm at prayer time while
>    the app may be completely closed.
> 3. No existing specific foreground service type (camera, location,
>    connected device, etc.) accurately describes "play a scheduled audio
>    notification of religious significance at a precise time," which is
>    exactly the case `specialUse` exists for.
>
> This service performs no other function: it does not collect data, run in
> the background indefinitely, or perform any work unrelated to playing the
> Adhan audio and stopping itself immediately afterward.

---

## 2. `USE_EXACT_ALARM`

**Where it's used:** `AlarmScheduler` schedules exact alarms (via
`AlarmManager.setExactAndAllowWhileIdle` / `setAlarmClock`) so that prayer
time notifications and the Adhan playback trigger at the precise
astronomically-calculated minute, and so that pre-Fajr (Sahur/Tahajjud)
reminders fire at the exact configured offset.

**Play Console justification text (paste into the "Use exact alarm
permission" declaration field):**

> Muslim Platform calculates the five daily Islamic prayer times using
> precise astronomical calculations based on the user's location. The core
> purpose of the app is to notify the user and play the Adhan (call to
> prayer) at the *exact* minute each prayer time begins — even a delay of a
> few minutes defeats the religious purpose of the alert, since prayer times
> are tied to specific solar/astronomical events (sunrise, solar noon,
> sunset, etc.).
>
> Using inexact alarms (`AlarmManager.setInexactRepeating` /
> `WorkManager` periodic tasks) would allow the OS to batch or delay the
> alarm by several minutes, causing the Adhan or prayer reminder to fire
> late or at the wrong time relative to the actual prayer time — an
> unacceptable and confusing experience for a religious observance app.
>
> `USE_EXACT_ALARM` is used exclusively for this time-critical,
> user-facing alarm-clock-like functionality (prayer time alerts and the
> optional pre-Fajr Sahur/Tahajjud reminder), which is explicitly one of the
> permitted "alarm clock" style use cases for this permission. No other
> scheduling need in the app uses this permission.

---

## Notes for future maintainers

- Both permissions are already declared in
  `android/app/src/main/AndroidManifest.xml`.
- If Google Play requests additional clarification, emphasize: (1) the app
  is 100% offline for prayer-time computation (no server dependency that
  could otherwise "wake up" the app in time), and (2) both permissions are
  used for a single, narrow, clearly-scoped purpose (playing/scheduling the
  Adhan and prayer notifications) — never for unrelated background work,
  analytics, or data collection.
