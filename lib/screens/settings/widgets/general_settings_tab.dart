import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';

import '../../../services/app_colors.dart';
import '../../../services/settings_provider.dart';
import '../../../services/silent_mode_service.dart';
import '../../../services/vibration_service.dart';
import '../../../constants/app_strings.dart';


// ✅ Task 4.7: Top-level helpers so they can run on a background isolate via
// `compute()`. Both are strictly scoped to the single directory path passed
// in (the app's own temp/cache directory from `getTemporaryDirectory()`) —
// never anything outside of it.

/// Recursively sums the size (bytes) of all files under [dirPath].
int _computeDirectorySizeIsolate(String dirPath) {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) return 0;
  int total = 0;
  try {
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          total += entity.lengthSync();
        } catch (_) {
          // Ignore files that vanish/are inaccessible mid-scan.
        }
      }
    }
  } catch (_) {}
  return total;
}

/// Deletes only the *contents* of [dirPath] (never the directory itself),
/// returning the number of bytes freed. Runs off the UI thread via
/// `compute()` so large caches never jank the UI.
int _clearDirectoryContentsIsolate(String dirPath) {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) return 0;
  int freed = 0;
  try {
    for (final entity in dir.listSync(followLinks: false)) {
      try {
        if (entity is File) {
          freed += entity.lengthSync();
          entity.deleteSync();
        } else if (entity is Directory) {
          freed += _computeDirectorySizeIsolate(entity.path);
          entity.deleteSync(recursive: true);
        }
      } catch (_) {
        // Skip locked/in-use files instead of aborting the whole operation.
      }
    }
  } catch (_) {}
  return freed;
}

class GeneralSettingsTab extends StatefulWidget {
  const GeneralSettingsTab({super.key});

  @override
  State<GeneralSettingsTab> createState() => _GeneralSettingsTabState();
}

class _GeneralSettingsTabState extends State<GeneralSettingsTab> {
  // ✅ Task 4.7: Real, computed cache size instead of a hardcoded "250 MB".
  String _cacheSizeLabel = "جارٍ الحساب...";
  bool _isClearingCache = false;

  @override
  void initState() {
    super.initState();
    _refreshCacheSize();
  }

  Future<void> _refreshCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final bytes =
          await compute(_computeDirectorySizeIsolate, cacheDir.path);
      if (mounted) {
        setState(() {
          _cacheSizeLabel = _formatBytes(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cacheSizeLabel = "غير معروف";
        });
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 MB";
    const int kb = 1024;
    const int mb = kb * 1024;
    if (bytes < mb) {
      return "${(bytes / kb).toStringAsFixed(1)} KB";
    }
    return "${(bytes / mb).toStringAsFixed(1)} MB";
  }

  // ✅ Task 4.7: UI confirmation dialog before any destructive deletion.
  Future<void> _confirmAndClearCache(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("مسح الملفات المؤقتة؟",
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text(
          "سيتم حذف الملفات المؤقتة ($_cacheSizeLabel) الخاصة بالتطبيق فقط. هذا الإجراء لا يمكن التراجع عنه.",
          style: GoogleFonts.cairo(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.cancel, style: GoogleFonts.cairo(color: Colors.grey)),

          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("مسح",
                style: GoogleFonts.cairo(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    setState(() => _isClearingCache = true);

    try {
      final cacheDir = await getTemporaryDirectory();
      // ✅ Task 4.7: Runs off the UI thread via compute(), and is strictly
      // scoped to this app's own temp/cache subdirectory contents (the
      // directory itself is preserved — only its contents are purged).
      await compute(_clearDirectoryContentsIsolate, cacheDir.path);
      await _refreshCacheSize();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("تم مسح الملفات المؤقتة بنجاح",
                style: GoogleFonts.cairo(color: Colors.white)),
            backgroundColor: const Color(0xFF003527),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("حدث خطأ أثناء مسح الملفات المؤقتة",
                style: GoogleFonts.cairo(color: Colors.white)),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isClearingCache = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Column(
      children: [
        _buildSettingsCard(
          title: "مظهر التطبيق",
          icon: Icons.palette_outlined,
          child: _buildCompactThemeSegmentedControl(context, settings),
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: "الوضع الصامت الذكي",
          icon: Icons.do_not_disturb_on_rounded,
          child: _buildAutoSilentToggle(context, settings),
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: "التقويم والأرقام",
          icon: Icons.date_range_outlined,
          child: Column(
            children: [
              _buildTimeFormatOption(context, settings),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: Color(0xFFE1E3E2), height: 1),
              ),
              _buildGregorianMonthNamingDropdown(context, settings),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: Color(0xFFE1E3E2), height: 1),
              ),
              _buildNumberSystemDropdown(context, settings),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: "إدارة التخزين",
          icon: Icons.storage_outlined,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("الملفات المؤقتة",
                      style: GoogleFonts.cairo(
                          fontSize: 14, color: Colors.grey[700])),
                  // ✅ Task 4.7: Real, computed cache size instead of a
                  // hardcoded "250 MB" placeholder.
                  Text(_cacheSizeLabel,
                      style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF003527))),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    side: const BorderSide(color: Color(0xFF003527)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  // ✅ Task 4.7: Deletion is now scoped to the app's own
                  // temp/cache subdirectory only (never anything outside of
                  // it), runs off the UI thread via compute(), recomputes
                  // the actual cache size afterwards, and requires explicit
                  // user confirmation before deleting anything.
                  onPressed:
                      _isClearingCache ? null : () => _confirmAndClearCache(context),
                  child: _isClearingCache
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Color(0xFF003527),
                          ),
                        )
                      : Text("مسح الملفات المؤقتة",
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: "التفاعل والاهتزاز",
          icon: Icons.vibration,
          child: _buildSwitchRow(
            context: context,
            title: "الاهتزاز عند التفاعل",
            value: settings.isHapticEnabled,
            onChanged: (val) async {
              await settings.setHapticEnabled(val);
              if (val) VibrationService.triggerHaptic(settings);
            },
            activeTrackColor: const Color(0xFFC5A059),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(
      {required String title, required IconData icon, required Widget child}) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFFC9A96E), size: 24),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFC9A96E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
        const SizedBox(height: 24),
        Divider(color: colors.borderColor),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCompactThemeSegmentedControl(
      BuildContext context, SettingsProvider settings) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF071710) : const Color(0xFFEFF2F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: c.borderColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactThemePill(
              context: context,
              settings: settings,
              mode: ThemeMode.dark,
              label: "داكن",
              icon: Icons.dark_mode_rounded,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildCompactThemePill(
              context: context,
              settings: settings,
              mode: ThemeMode.light,
              label: "فاتح",
              icon: Icons.light_mode_rounded,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildCompactThemePill(
              context: context,
              settings: settings,
              mode: ThemeMode.system,
              label: "تلقائي",
              icon: Icons.brightness_auto_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactThemePill({
    required BuildContext context,
    required SettingsProvider settings,
    required ThemeMode mode,
    required String label,
    required IconData icon,
  }) {
    final isSelected = settings.themeMode == mode;
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        VibrationService.triggerHaptic(settings);
        settings.setThemeMode(mode);
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0F2C20) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFC5A059) : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFC5A059).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFFC5A059) : c.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? const Color(0xFFC5A059) : c.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoSilentToggle(
      BuildContext context, SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryDarkGreen =
        isDark ? const Color(0xFFC5A059) : const Color(0xFF003527);
    final mutedGreen =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F0EC);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: mutedGreen,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFC9A96E).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: SwitchListTile(
          tileColor: Colors.transparent,
          hoverColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          activeThumbColor: Colors.white,
          activeTrackColor: const Color(0xFFC5A059),
          title: Row(
            children: [
              const Icon(Icons.do_not_disturb_on_rounded,
                  color: Color(0xFFC9A96E), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "الوضع الصامت الذكي للصلاة",
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: primaryDarkGreen,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text(
              "كتم تلقائي لصوت الجهاز أثناء الصلاة واستعادته فور انتهائها.",
              style: GoogleFonts.cairo(
                fontSize: 11.5,
                color: Colors.grey[700],
              ),
            ),
          ),
          value: settings.autoSilentEnabled,
          onChanged: (bool val) async {
            VibrationService.triggerHaptic(settings);
            if (val) {
              final bool hasPerm = await SilentModeService.hasDndPermission();
              if (!hasPerm) {
                if (context.mounted) {
                  await SilentModeService.showDndPermissionDialog(context);
                }
                final bool nowGranted =
                    await SilentModeService.hasDndPermission();
                if (!nowGranted) return;
              }
            }
            await settings.setAutoSilentEnabled(val);
          },
        ),
      ),
    );
  }

  Widget _buildGregorianMonthNamingDropdown(
      BuildContext context, SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedGreen =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F0EC);
    final cardWhite = isDark ? const Color(0xFF1E293B) : Colors.white;

    final options = {
      'standard': 'الخليج والدولي (يناير، فبراير...)',
      'maghrebi': 'المغرب العربي (ماي، غشت، شتنبر...)',
      'levantine': 'المشرق العربي (شباط، آذار، آب...)',
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "نظام الأشهر الميلادية",
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                "تسمية الأشهر في التقويم الهجري/الميلادي",
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: mutedGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: settings.gregorianMonthNaming,
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: Theme.of(context).colorScheme.onSurface),
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12.5),
                dropdownColor: cardWhite,
                borderRadius: BorderRadius.circular(12),
                items: options.entries.map((e) {
                  return DropdownMenuItem<String>(
                    value: e.key,
                    child: Text(e.value, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    settings.setGregorianMonthNaming(val);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            "تم تحديث نظام تسمية الأشهر الميلادية بنجاح",
                            style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        backgroundColor: const Color(0xFF003527),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.all(20),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberSystemDropdown(
      BuildContext context, SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedGreen =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F0EC);
    final cardWhite = isDark ? const Color(0xFF1E293B) : Colors.white;

    final options = {
      'arabic': 'الأرقام العربية (١، ٢، ٣...)',
      'latin': 'الأرقام اللاتينية (1, 2, 3...)',
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "نظام الأرقام",
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                "عرض الأرقام عبر جميع شاشات التطبيق",
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: mutedGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: settings.numberType,
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: Theme.of(context).colorScheme.onSurface),
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12.5),
                dropdownColor: cardWhite,
                borderRadius: BorderRadius.circular(12),
                items: options.entries.map((e) {
                  return DropdownMenuItem<String>(
                    value: e.key,
                    child: Text(e.value, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    settings.setNumberType(val);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("تم تغيير نظام الأرقام بنجاح",
                            style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        backgroundColor: const Color(0xFF003527),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.all(20),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeFormatOption(
      BuildContext context, SettingsProvider settings) {
    final c = AppColors.of(context);

    String subtitleText;
    switch (settings.timeFormatMode) {
      case 'h12':
        subtitleText = "نظام 12 ساعة (10:03 م)";
        break;
      case 'h24':
        subtitleText = "نظام 24 ساعة (22:03)";
        break;
      case 'system':
      default:
        bool sys24 = MediaQuery.of(context).alwaysUse24HourFormat;
        subtitleText = "تلقائي (حسب النظام: ${sys24 ? '24 ساعة' : '12 ساعة'})";
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "نظام عرض الوقت",
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitleText,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment<String>(
              value: 'system',
              label: Text("تلقائي",
                  style: GoogleFonts.cairo(
                      fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            ButtonSegment<String>(
              value: 'h12',
              label: Text("12h",
                  style: GoogleFonts.cairo(
                      fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            ButtonSegment<String>(
              value: 'h24',
              label: Text("24h",
                  style: GoogleFonts.cairo(
                      fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
          selected: {settings.timeFormatMode},
          onSelectionChanged: (Set<String> newSelection) {
            settings.setTimeFormatMode(newSelection.first);
            if (settings.isHapticEnabled) {
              VibrationService.triggerHaptic(settings);
            }
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required BuildContext context,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? activeTrackColor,
  }) {
    final c = AppColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
            child: Text(title,
                style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface))),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: activeTrackColor ?? const Color(0xFFC5A059),
          inactiveThumbColor: c.switchInactiveThumb,
          inactiveTrackColor: c.switchInactiveTrack,
          hoverColor: Colors.transparent,
        ),
      ],
    );
  }
}
