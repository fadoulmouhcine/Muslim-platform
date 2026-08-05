// Copyright (c) 2026-present Mouhcine Fadoul. All rights reserved.
// Application: Muslim Platform — All Rights Reserved

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Handles **on-demand** download & local caching of the Quran Tajweed
/// reference guide (PDF).
///
/// This file used to be bundled directly inside `assets/pdf/` (~75 MB),
/// which drastically inflated the app's install size for every single user
/// — even the ones who never open the Tajweed guide. It has been removed
/// from the bundled assets entirely.
///
/// Instead, [TajweedPdfService] fetches the file from a remote URL
/// (e.g. Firebase Storage) **only when the user explicitly requests it**
/// (e.g. taps "View Tajweed Guide"), and caches it in the app's local
/// documents directory so it only needs to be downloaded once — all
/// subsequent opens are served instantly from local disk, fully offline.
class TajweedPdfService {
  /// Remote URL hosting the PDF (Firebase Storage direct-download link).
  /// Replace with the real hosted URL before wiring this up to a UI screen.
  static const String _remoteUrl =
      "https://firebasestorage.googleapis.com/v0/b/muslimplatform.firebasestorage.app/o/quran_tajweed.pdf?alt=media";

  static const String _localFileName = "quran_tajweed.pdf";

  /// Returns the locally cached PDF file if it has already been downloaded,
  /// or `null` if it hasn't been fetched yet.
  static Future<File?> getCachedFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/$_localFileName");
      if (await file.exists()) return file;
    } catch (e) {
      debugPrint("⚠️ TajweedPdfService.getCachedFile error: $e");
    }
    return null;
  }

  /// Downloads the PDF from the remote server only if it isn't already
  /// cached locally. Returns the local [File] on success, or `null` on
  /// failure (network error, bad response, etc.).
  ///
  /// [onProgress] optionally reports a 0.0–1.0 download ratio (when the
  /// server provides a `Content-Length` header) so callers can show a
  /// progress bar to the user during the download.
  static Future<File?> downloadIfNeeded({
    void Function(double progress)? onProgress,
  }) async {
    final cached = await getCachedFile();
    if (cached != null) return cached;

    http.Client? client;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/$_localFileName");
      final tempFile = File("${file.path}.part");

      client = http.Client();
      final request = http.Request('GET', Uri.parse(_remoteUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        debugPrint(
            "❌ TajweedPdfService: Download failed with status ${response.statusCode}");
        return null;
      }

      final contentLength = response.contentLength ?? 0;
      int received = 0;
      final sink = tempFile.openWrite();

      await response.stream.listen((chunk) {
        received += chunk.length;
        sink.add(chunk);
        if (contentLength > 0 && onProgress != null) {
          onProgress(received / contentLength);
        }
      }).asFuture<void>();

      await sink.close();

      // Only replace the final file once the download has fully succeeded,
      // avoiding a corrupted/partial cached file if the download is
      // interrupted mid-way.
      if (await tempFile.exists()) {
        await tempFile.rename(file.path);
      }

      debugPrint(
          "✅ TajweedPdfService: Downloaded Tajweed PDF ($received bytes)");
      return file;
    } catch (e) {
      debugPrint("❌ TajweedPdfService: Error downloading PDF: $e");
      return null;
    } finally {
      client?.close();
    }
  }

  /// Deletes the cached file to free up device storage (e.g. exposed via a
  /// "Clear Tajweed Guide Cache" option in Settings).
  static Future<void> clearCache() async {
    try {
      final file = await getCachedFile();
      if (file != null && await file.exists()) {
        await file.delete();
        debugPrint("🧹 TajweedPdfService: Cleared cached Tajweed PDF.");
      }
    } catch (e) {
      debugPrint("⚠️ TajweedPdfService.clearCache error: $e");
    }
  }
}
