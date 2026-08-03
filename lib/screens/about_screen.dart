import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/app_colors.dart';
import '../services/settings_provider.dart';
import '../services/vibration_service.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _shareApp() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    VibrationService.triggerHaptic(settings, type: HapticType.medium);
    SharePlus.instance.share(
      ShareParams(
        text:
            "تطبيق مسلم 🌿 - رفيقك اليومي لذكر الله وصلاتك.\nتطبيق مجاني 100% بدون إعلانات وبدون تتبع.\nحمله الآن واكسب الأجر!",
      ),
    );
  }

  void _copyContactEmail() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    VibrationService.triggerHaptic(settings, type: HapticType.medium);
    Clipboard.setData(const ClipboardData(text: "support@muslimapp.org"));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "تم نسخ البريد الإلكتروني للتواصل 📩",
          style: GoogleFonts.cairo(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFC5A059),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = c.isDark;
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "عن التطبيق",
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
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                // ── 1. HERO BRANDING HEADER ─────────────────────────────────
                _buildHeroBrandingCard(isDark, settings),

                const SizedBox(height: 20),

                // ── 2. QUICK METRIC PILLS ────────────────────────────────────
                _buildMetricPillsRow(isDark),

                const SizedBox(height: 24),

                // ── 3. STORYTELLING SECTIONS ─────────────────────────────────

                // Section 1: App Mission
                _buildStoryCard(
                  context: context,
                  icon: Icons.star_rounded,
                  iconColor: const Color(0xFFC5A059),
                  title: "رسالة التطبيق",
                  subtitle: "رؤيتنا ودافعنا",
                  bodyText:
                      "تم صياغة تطبيق \"مسلم\" برؤية إسلامية خاملة من الإعلانات والمشتريات. هدفنا تقديم تجربة رقمية إيمانية دقيقة، نصرةً لكتاب الله وسنة نبيه ﷺ، وخدمة للمسلمين في مشارق الأرض ومغاربها.",
                  isDark: isDark,
                ),

                const SizedBox(height: 14),

                // Section 2: Architecture & Privacy
                _buildStoryCard(
                  context: context,
                  icon: Icons.memory_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: "الهندسة والتكنولوجيا",
                  subtitle: "أداء عالٍ وخصوصية مطلقة",
                  bodyText:
                      "يعتمد التطبيق على خوارزميات حسابية أصلية وتخزين محلي 100%. يتم حساب أوقات الصلاة والقبلة دون الاستعانة ببيانات خوادم خارجية، مما يضمن أقصى درجات السرعة وحفظ الخصوصية.",
                  isDark: isDark,
                ),

                const SizedBox(height: 14),

                // Section 3: Craftsmanship & Dedication
                _buildStoryCard(
                  context: context,
                  icon: Icons.favorite_rounded,
                  iconColor: const Color(0xFFE11D48),
                  title: "المطور وإهداء العمل",
                  subtitle: "عمل خالص لوجه الله",
                  bodyText:
                      "هذا العمل إهداء لكل مسلم ومسلمة، وصدقة جارية عن أمواتنا وأموات المسلمين. نسأل الله أن يتقبله بقبول حسن، وأن يجعله خفيفاً في الميزان، وشفيعاً لنا يوم نلقاه.",
                  isDark: isDark,
                ),

                const SizedBox(height: 14),

                // ── 4. DEVELOPER CREDITS CARD (فكرة وإنجاز - محسن فضول) ───────
                _buildDeveloperCreditsCard(context, isDark),

                const SizedBox(height: 20),

                // ── 5. CONNECT & SUPPORT BUTTONS ──────────────────────────────
                _buildActionButtonsRow(context, isDark),

                const SizedBox(height: 32),

                // Footer Signature
                Text(
                  "صُنع بحب وإتقان لخدمة الأمة الإسلامية ❤️",
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    color: c.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── HERO BRANDING HEADER (COMPACT RESIZED) ───────────────────────────────
  Widget _buildHeroBrandingCard(bool isDark, SettingsProvider settings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF07241A),
                  const Color(0xFF0F3A2C),
                  const Color(0xFF0A261D)
                ]
              : [
                  const Color(0xFF1B3B2B),
                  const Color(0xFF2D5A44),
                  const Color(0xFF1B3B2B)
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC5A059).withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC5A059).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          // App Logo Emblem with Gold Aura (Scaled Down to ~52dp)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFC5A059).withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFC5A059).withValues(alpha: 0.15),
                border: Border.all(
                  color: const Color(0xFFC5A059).withValues(alpha: 0.6),
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40C5A059),
                    blurRadius: 12,
                  )
                ],
              ),
              child: const Icon(
                Icons.mosque_rounded,
                color: Color(0xFFC5A059),
                size: 26,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // App Title (Compact Size)
          Text(
            "تطبيق مُسْلِم",
            style: GoogleFonts.amiri(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFC5A059),
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 4),

          // Version Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFC5A059).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              "الإصدار ${settings.replaceDigits("1.0.0")} المستقر",
              style: GoogleFonts.outfit(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle Tagline
          Text(
            "« رفيقك اليومي لذكر الله وصلاتك »",
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  // ── QUICK METRIC PILLS ROW ────────────────────────────────────────────────
  Widget _buildMetricPillsRow(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildPillItem(Icons.volunteer_activism_rounded, "100% مجاني", isDark),
        _buildPillItem(Icons.block_rounded, "بدون إعلانات", isDark),
        _buildPillItem(Icons.lock_outline_rounded, "خصوصية تامة", isDark),
        _buildPillItem(Icons.wifi_off_rounded, "بدون أنترنت", isDark),
      ],
    );
  }

  Widget _buildPillItem(IconData icon, String label, bool isDark) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B).withValues(alpha: 0.6)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFC5A059).withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFC5A059), size: 18),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── STORYTELLING CARD WIDGET ──────────────────────────────────────────────
  Widget _buildStoryCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String bodyText,
    required bool isDark,
  }) {
    final c = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? c.borderColor : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: c.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.16 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: c.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        color: const Color(0xFFC5A059),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Text(
            bodyText,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: c.textSecondary,
              height: 1.75,
            ),
          ),
        ],
      ),
    );
  }

  // ── ACTION BUTTONS ROW (CONNECT & SUPPORT) ────────────────────────────────
  Widget _buildActionButtonsRow(BuildContext context, bool isDark) {
    return Row(
      children: [
        // Share App Button
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC5A059),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
            onPressed: _shareApp,
            icon: const Icon(Icons.share_rounded, size: 18),
            label: Text(
              "مشاركة التطبيق",
              style: GoogleFonts.cairo(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Contact Support Button
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFC5A059),
              side: const BorderSide(color: Color(0xFFC5A059), width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _copyContactEmail,
            icon: const Icon(Icons.mail_outline_rounded, size: 18),
            label: Text(
              "التواصل والدعم",
              style: GoogleFonts.cairo(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── DEVELOPER CREDITS CARD (فكرة وإنجاز - محسن فضول) ─────────────────────
  Widget _buildDeveloperCreditsCard(BuildContext context, bool isDark) {
    final c = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC5A059).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFFC5A059).withValues(alpha: isDark ? 0.1 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFC5A059).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFC5A059).withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: Color(0xFFC5A059),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "فكرة وإنجاز",
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFC5A059),
                  ),
                ),
                Text(
                  "محسن فضول",
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  "عمل خالص لوجه الله تعالى 🤲",
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    color: c.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
