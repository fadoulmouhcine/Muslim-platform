import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_colors.dart';
import '../services/settings_provider.dart';
import '../services/vibration_service.dart';
import 'package:provider/provider.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen>
    with TickerProviderStateMixin {
  // ── STRICT SINGLE-EXPANSION STATE ───────────────────────────────────────────
  // null means all cards are strictly COLLAPSED by default on page render.
  int? _expandedIndex;

  void _toggleCard(int index) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    VibrationService.triggerHaptic(settings, type: HapticType.selection);

    setState(() {
      if (_expandedIndex == index) {
        _expandedIndex = null; // Collapse if tapped again
      } else {
        _expandedIndex =
            index; // Expand new card & automatically collapse previous
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = c.isDark;

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "سياسة الخصوصية",
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: c.textPrimary,
            fontSize: 19,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: c.textPrimary, size: 19),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── TOP NEO-ISLAMIC REASSURING BANNER ─────────────────────────────
            _buildWarmIntroBanner(isDark),

            const SizedBox(height: 24),

            // ── SINGLE-EXPANSION ACCORDION CARDS ──────────────────────────────

            // Card 0: Location Access
            _buildExpandableCard(
              index: 0,
              icon: Icons.location_on_outlined,
              iconColor: const Color(0xFFE11D48),
              title: "تحديد الموقع الجغرافي",
              badgeText: "لحساب أوقات الصلاة والقبلة",
              explanation:
                  "نحتاج للوصول إلى موقعك فقط لمعرفة مواقيت الصلاة لمدينتك وتحديد اتجاه القبلة بدقة. لا نقوم بتتبع تحركاتك أو حفظ موقعك في أي سيرفر خارجي، وكل الحسابات تتم داخل جهازك فقط.",
              technicalTag: "المعرف التقني: ACCESS_FINE_LOCATION",
              isDark: isDark,
            ),

            const SizedBox(height: 14),

            // Card 1: DND Mode / Auto-Silent
            _buildExpandableCard(
              index: 1,
              icon: Icons.do_not_disturb_on_outlined,
              iconColor: const Color(0xFFC5A059),
              title: "الوضع الصامت التلقائي في المسجد",
              badgeText: "لعدم إزعاج المصلين",
              explanation:
                  "يستخدم التطبيق خاصية 'عدم الإزعاج' لتحويل هاتفك تلقائياً إلى الوضع الصامت أثناء وقت الإقامة في المسجد، وإعادته لحالته الطبيعية بعد الصلاة. التطبيق لا يقرأ إشعاراتك ولا رسائلك الشخصية نهائياً.",
              technicalTag: "المعرف التقني: ACCESS_NOTIFICATION_POLICY",
              isDark: isDark,
            ),

            const SizedBox(height: 14),

            // Card 2: Exact Alarms & Foreground Services
            _buildExpandableCard(
              index: 2,
              icon: Icons.alarm_on_outlined,
              iconColor: const Color(0xFF10B981),
              title: "تنبيهات الأذان والخدمات في الخلفية",
              badgeText: "لضمان انطلاق الأذان في وقته",
              explanation:
                  "لكي يشتغل الأذان في وقته المضبوط حتى لو كان الهاتف مغلقاً أو التطبيق متوقفاً، نحتاج لإذن تشغيل التنبيهات والخدمات الدقيقة.",
              technicalTag: "المعرف التقني: FOREGROUND_SERVICE & EXACT_ALARM",
              isDark: isDark,
            ),

            const SizedBox(height: 14),

            // Card 3: Local Storage & Rights
            _buildExpandableCard(
              index: 3,
              icon: Icons.security_outlined,
              iconColor: const Color(0xFF6366F1),
              title: "حفظ البيانات وحقوقك",
              badgeText: "بياناتك في أمان 100%",
              explanation:
                  "جميع إعداداتك وتفضيلاتك (مثل الأذكار والأذان المفضل) تُحفظ محلياً على ذاكرة هاتفك فقط. يمكنك إلغاء أي إذن في أي وقت من إعدادات الهاتف.",
              technicalTag: "التخزين المحلي: LOCAL_SECURE_STORAGE",
              isDark: isDark,
            ),

            const SizedBox(height: 36),

            // ── FOOTER BRANDING ───────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC5A059).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: const Color(0xFFC5A059).withValues(alpha: 0.8),
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "تطبيق مسلم — لوجه الله تعالى",
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: c.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── NEO-ISLAMIC WARM INTRO BANNER ─────────────────────────────────────────
  Widget _buildWarmIntroBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2A1E0A), const Color(0xFF161007)]
              : [const Color(0xFFFDF3DC), const Color(0xFFFAE8BB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFC5A059).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFFC5A059).withValues(alpha: isDark ? 0.16 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFC5A059).withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC5A059).withValues(alpha: 0.25),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Color(0xFFC5A059),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "خصوصيتك أمانة ونحترمها",
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      "تطبيق مجاني 100% — بدون إعلانات وبدون تتبع",
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFC5A059),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: Color(0x33C5A059), height: 1),
          ),
          Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: Color(0xFFC5A059), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "لا جمع للبيانات ولا تتبع على أي خوادم خارجية.",
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: Color(0xFFC5A059), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "جميع بياناتك وإعداداتك تظل محلياً داخل هاتفك فقط.",
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── HIGH-END MICRO-ANIMATED ACCORDION CARD ────────────────────────────────
  Widget _buildExpandableCard({
    required int index,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String badgeText,
    required String explanation,
    required String technicalTag,
    required bool isDark,
  }) {
    final c = AppColors.of(context);
    final isExpanded = _expandedIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.fastOutSlowIn,
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpanded
              ? const Color(0xFFC5A059).withValues(alpha: 0.65)
              : (isDark ? c.borderColor : const Color(0xFFE2E8F0)),
          width: isExpanded ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded
                ? const Color(0xFFC5A059)
                    .withValues(alpha: isDark ? 0.16 : 0.08)
                : c.shadowColor,
            blurRadius: isExpanded ? 16 : 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            // Header Tappable Row
            InkWell(
              onTap: () => _toggleCard(index),
              borderRadius: BorderRadius.circular(18),
              splashColor: const Color(0xFFC5A059).withValues(alpha: 0.1),
              highlightColor: const Color(0xFFC5A059).withValues(alpha: 0.05),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: isDark ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: iconColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC5A059)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFC5A059),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Rotating Animated Chevron
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.fastOutSlowIn,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: isExpanded
                              ? const Color(0xFFC5A059).withValues(alpha: 0.15)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isExpanded
                              ? const Color(0xFFC5A059)
                              : c.textMuted,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Smooth Animated Size & Opacity Reveal Body (Zero Pixels Overflow)
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.fastOutSlowIn,
              child: isExpanded
                  ? AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: isExpanded ? 1.0 : 0.0,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 1),
                            const SizedBox(height: 14),
                            Text(
                              explanation,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: c.textSecondary,
                                height: 1.75,
                              ),
                            ),
                            const SizedBox(height: 14),
                            // Sleek Code Tag Badge with Protection against Horizontal Overflow
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.code_rounded,
                                    size: 14,
                                    color: c.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      child: Text(
                                        technicalTag,
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: c.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ],
        ),
      ),
    );
  }
}
