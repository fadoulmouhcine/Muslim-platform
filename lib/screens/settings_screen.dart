import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/app_colors.dart';
import 'settings/widgets/adhan_settings_tab.dart';
import 'settings/widgets/general_settings_tab.dart';
import 'settings/widgets/privacy_settings_tab.dart';
import 'settings/widgets/quran_settings_tab.dart';

class SettingsScreen extends StatefulWidget {
  final int initialTabIndex;
  const SettingsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _activeTabIndex;

  final List<String> _tabs = [
    "إعدادات القرآن",
    "الأذان والمواقيت",
    "إعدادات عامة",
    "الخصوصية",
  ];

  @override
  void initState() {
    super.initState();
    _activeTabIndex = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final primaryDarkGreen = colors.primaryDarkGreen;
    final bgLight = colors.scaffoldBg;
    final mutedGreen = colors.mutedBg;

    return Scaffold(
      backgroundColor: bgLight,
      extendBodyBehindAppBar: true,
      appBar: _buildGlassAppBar(bgLight, primaryDarkGreen),
      body: SafeArea(
        child: Column(
          children: [
            _buildStickyTabs(primaryDarkGreen, mutedGreen),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                physics: const BouncingScrollPhysics(),
                children: [
                  if (_activeTabIndex == 0) const QuranSettingsTab(),
                  if (_activeTabIndex == 1) const AdhanSettingsTab(),
                  if (_activeTabIndex == 2) const GeneralSettingsTab(),
                  if (_activeTabIndex == 3) const PrivacySettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildGlassAppBar(Color bgLight, Color primaryDarkGreen) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AppBar(
            backgroundColor: bgLight.withValues(alpha: 0.7),
            elevation: 0,
            centerTitle: true,
            title: Text(
              "الإعدادات",
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                color: primaryDarkGreen,
                fontSize: 20,
              ),
            ),
            leading: const SizedBox.shrink(),
            actions: [
              if (Navigator.canPop(context))
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios_rounded,
                      color: primaryDarkGreen, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStickyTabs(Color primaryDarkGreen, Color mutedGreen) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isActive = _activeTabIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _activeTabIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? primaryDarkGreen : mutedGreen,
                borderRadius: BorderRadius.circular(9999),
              ),
              alignment: Alignment.center,
              child: Text(
                _tabs[index],
                style: GoogleFonts.cairo(
                  color: isActive ? Colors.white : const Color(0xFF4A4A4A),
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
