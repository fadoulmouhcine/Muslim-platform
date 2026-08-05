// Copyright (c) 2026-present Mouhcine Fadoul. All rights reserved.
// Application: Muslim Platform — All Rights Reserved
// Author: Mouhcine Fadoul

/// 🗂️ Task 5.2 (Audit Fixes): Centralized Arabic UI strings.
///
/// This app is intentionally single-locale (Arabic-only, see Task 5.1 —
/// `Locale('en', 'US')` and any language toggle were removed from the UI).
/// Because there is currently only ONE supported locale, converting every
/// string in the codebase to the full `.arb` + `flutter gen-l10n` pipeline
/// would add build complexity and churn across 50+ files without providing
/// any real user-facing benefit (there is nothing to translate *to* yet).
///
/// Instead, this file centralizes the small set of **repeated, cross-cutting**
/// UI strings (common action button labels that are duplicated verbatim
/// across many screens: retry, cancel, close, copy, share, save, delete...).
/// This:
///   1. Removes duplicated string literals scattered across the codebase.
///   2. Gives a single source of truth for wording consistency.
///   3. Makes a *future* migration to `.arb` files trivial — each screen
///      already references `AppStrings.xxx` instead of an inline literal,
///      so swapping the implementation of this class for
///      `AppLocalizations.of(context)!.xxx` later is a one-file change.
///
/// Screen-specific / one-off strings (dua texts, hadith text, dynamic
/// content, etc.) are intentionally left inline in their respective screens,
/// since they are not reused and extracting them would add indirection
/// without benefit.
class AppStrings {
  AppStrings._(); // no instances

  // Common action buttons (repeated across many screens/dialogs)
  static const String retry = 'إعادة المحاولة';
  static const String cancel = 'إلغاء';
  static const String close = 'إغلاق';
  static const String copy = 'نسخ';
  static const String share = 'مشاركة';
  static const String save = 'حفظ';
  static const String delete = 'حذف';
  static const String ok = 'موافق';

  // Common empty/error states
  static const String genericErrorTitle = 'حدث خطأ غير متوقع';
  static const String noInternetTitle = 'لا يوجد اتصال بالإنترنت';
}
