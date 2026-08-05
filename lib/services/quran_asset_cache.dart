// Copyright (c) 2026-present Mouhcine Fadoul. All rights reserved.
// Application: Muslim Platform — All Rights Reserved
// Author: Mouhcine Fadoul

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


/// ✅ Performance Fix: Pre-caches the static image/vector assets used by the
/// Quran reading screen — the Surah header ornament banner (SVG) and the
/// Bismillah graphic (PNG) — so that the very first time a Surah header is
/// painted on screen (page open / page swipe / initial route push) there is
/// **zero** decode/parse latency and therefore no visible flash, stutter or
/// jank.
///
/// Without this, the first frame that ever needs to paint `Sura_border.svg`
/// or `basmala.png` has to:
///   1. Read the asset bytes from the asset bundle (I/O).
///   2. For the SVG: parse the XML + compile it into a vector_graphics binary
///      representation (CPU work, done in an isolate by `flutter_svg`, but
///      the *result* still isn't available on the very first paint request).
///   3. For the PNG: decode the raster image via `instantiateImageCodec`.
///
/// By kicking these off ahead of time (as soon as the app boots) and letting
/// their respective caches (`svg.cache` for vector_graphics /
/// `PaintingBinding.instance.imageCache` for raster images) hold onto the
/// already-resolved data, the actual `SvgPicture.asset` / `Image.asset`
/// widgets simply synchronously reuse the cached bytes → **instant** paint.
///
/// This class purposefully avoids any blocking of the UI thread: the
/// underlying `loadBytes`/`precacheImage` calls are asynchronous and are
/// simply "fired and left to complete in the background" — we never `await`
/// them anywhere that could delay a frame or a screen transition.
class QuranAssetCache {
  QuranAssetCache._();

  static bool _isPrecached = false;
  static Future<void>? _precacheFuture;

  /// The Surah header ornament SVG border.
  static const String suraBorderAsset = 'assets/svg/Sura_border.svg';

  /// The Bismillah ("بسم الله الرحمن الرحيم") graphic.
  static const String basmalaAsset = 'assets/images/basmala.png';

  /// Kicks off pre-caching of the Quran reading screen's static ornament
  /// assets (Surah header border SVG + Bismillah PNG) exactly once for the
  /// lifetime of the app. Safe to call from multiple widgets/screens — every
  /// call after the first one is a cheap no-op (returns the same in-flight
  /// or already-completed future).
  ///
  /// This is intentionally **not** awaited by callers in build methods; it
  /// runs opportunistically in the background the moment a valid
  /// [BuildContext] becomes available (e.g. app startup), well before the
  /// user actually opens the Quran reader.
  static Future<void> precache(BuildContext context) {
    if (_isPrecached) {
      return _precacheFuture ?? Future.value();
    }
    _isPrecached = true;

    _precacheFuture = Future.wait<void>([
      // 1) Bismillah PNG → Flutter's raster ImageCache.
      precacheImage(const AssetImage(basmalaAsset), context).catchError((e) {
        debugPrint("⚠️ Failed to precache Bismillah asset: $e");
      }),
      // 2) Surah header ornament SVG → flutter_svg / vector_graphics cache.
      //    Using the exact same loader configuration (no theme/colorMapper
      //    overrides) as `SvgPicture.asset('assets/svg/Sura_border.svg', ...)`
      //    in the reading screen ensures the cache key matches, so the
      //    widget re-uses this pre-decoded result instead of re-parsing.
      const SvgAssetLoader(suraBorderAsset).loadBytes(context).then((_) {
        // Successfully warmed the vector_graphics cache.
      }).catchError((e) {
        debugPrint("⚠️ Failed to precache Surah header ornament SVG: $e");
      }),
    ]).catchError((e) {
      debugPrint("⚠️ QuranAssetCache.precache() error: $e");
      return <void>[];
    });


    return _precacheFuture!;
  }
}
