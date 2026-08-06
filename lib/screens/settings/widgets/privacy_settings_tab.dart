import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../services/app_colors.dart';
import '../../../services/settings_provider.dart';

class PrivacySettingsTab extends StatefulWidget {
  const PrivacySettingsTab({super.key});

  @override
  State<PrivacySettingsTab> createState() => _PrivacySettingsTabState();
}

class _PrivacySettingsTabState extends State<PrivacySettingsTab> with WidgetsBindingObserver {
  int _locationMode = 0; // 0: Precise, 1: Approximate
  bool _isNotificationGranted = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNotificationStatus();
    }
  }

  Future<void> _checkNotificationStatus() async {
    final status = await Permission.notification.status;
    if (mounted) {
      setState(() {
        _isNotificationGranted = status.isGranted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSettingsCard(
          title: "صلاحيات الموقع",
          icon: Icons.location_on_outlined,
          child: Column(
            children: [
              _buildRadioRow(
                title: "موقع دقيق للقبلة",
                subtitle: "يستخدم GPS لتحديد اتجاه القبلة بدقة عالية",
                value: 0,
                groupValue: _locationMode,
                onChanged: (val) => setState(() => _locationMode = val as int),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: Color(0xFFE1E3E2), height: 1),
              ),
              _buildRadioRow(
                title: "موقع تقريبي للأذان",
                subtitle: "يستخدم الشبكة لتحديد المدينة وحساب المواقيت",
                value: 1,
                groupValue: _locationMode,
                onChanged: (val) => setState(() => _locationMode = val as int),
              ),
            ],
          ),
        ),
        _buildSettingsCard(
          title: "صلاحيات الإشعارات",
          icon: Icons.notifications_active_outlined,
          child: Column(
            children: [
              _buildNotificationTile(),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: Color(0xFFE1E3E2), height: 1),
              ),
              _buildSilentModeToggle(),
            ],
          ),
        ),
        _buildAboutSection(),
      ],
    );
  }

  Widget _buildAboutSection() {
    final c = AppColors.of(context);
    final currentYear = DateTime.now().year;
    final legalese =
        'Copyright \u00a9 2026\u2013$currentYear Mouhcine Fadoul.\nAll rights reserved.';

    return GestureDetector(
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      '\u262a',
                      style:
                          TextStyle(fontSize: 28, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Muslim Platform',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'الإصدار 1.0.0',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  legalese,
                  style: GoogleFonts.cairo(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'تم تطوير هذا التطبيق بواسطة Mouhcine Fadoul. '
                  'جميع البيانات تُعالج محلياً على جهازك دون مشاركة مع أي طرف خارجي.',
                  style: GoogleFonts.cairo(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'حسناً',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: c.mutedBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF1B5E20),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'حول التطبيق',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: c.textSecondary,
                    ),
                  ),
                  Text(
                    'Muslim Platform \u00a9 2026\u2013$currentYear Mouhcine Fadoul',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: c.textSubtle,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.textSubtle),
          ],
        ),
      ),
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

  Widget _buildRadioRow({
    required String title,
    required String subtitle,
    required int value,
    required int groupValue,
    required ValueChanged onChanged,
  }) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: c.textSecondary)),
                  Text(subtitle,
                      style:
                          GoogleFonts.cairo(fontSize: 12, color: c.textSubtle)),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: value == groupValue ? c.goldAccent : c.borderColor,
                  width: value == groupValue ? 6 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile() {
    final c = AppColors.of(context);
    return InkWell(
      onTap: () async {
        if (!_isNotificationGranted) {
          final status = await Permission.notification.request();
          if (status.isPermanentlyDenied || status.isDenied) {
            openAppSettings();
          } else {
            _checkNotificationStatus();
          }
        } else {
          openAppSettings(); // Open settings to disable if they want
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("إشعارات الأذان والتنبيهات",
                      style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: c.textSecondary)),
                  Text(
                      _isNotificationGranted
                          ? "الإشعارات مفعلة بنجاح"
                          : "اضغط لمنح الصلاحية لتلقي الإشعارات",
                      style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: _isNotificationGranted ? Colors.green[700] : Colors.red[700])),
                ],
              ),
            ),
            Icon(
              _isNotificationGranted ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              color: _isNotificationGranted ? Colors.green[700] : Colors.red[700],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSilentModeToggle() {
    final c = AppColors.of(context);
    final settings = Provider.of<SettingsProvider>(context);

    return InkWell(
      onTap: () => settings.setRespectSilentMode(!settings.respectSilentMode),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("احترام الوضع الصامت",
                      style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: c.textSecondary)),
                  Text("تشغيل الأذان بصمت إذا كان الهاتف في وضع الاهتزاز أو الصامت",
                      style: GoogleFonts.cairo(fontSize: 12, color: c.textSubtle)),
                ],
              ),
            ),
            Switch(
              value: settings.respectSilentMode,
              activeThumbColor: const Color(0xFFC9A96E),
              onChanged: (val) => settings.setRespectSilentMode(val),
            ),
          ],
        ),
      ),
    );
  }
}
