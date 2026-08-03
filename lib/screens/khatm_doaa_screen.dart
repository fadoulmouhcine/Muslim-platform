import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../models/khatm_doaa.dart';

// ─────────────────────────────────────────────────────────
// Thematic section icons — one per part (cycled if needed)
// ─────────────────────────────────────────────────────────
const List<IconData> _sectionIcons = [
  Icons.auto_awesome_rounded, // Opening Praise
  Icons.menu_book_rounded, // Quran Blessing
  Icons.light_mode_rounded, // Light/Guidance
  Icons.healing_rounded, // Healing / Mercy
  Icons.favorite_rounded, // Heart supplication
  Icons.cloud_rounded, // Hereafter
  Icons.star_rounded, // Honour
  Icons.spa_rounded, // Peace / Tranquillity
  Icons.workspace_premium_rounded, // Elevation
  Icons.water_drop_rounded, // Sustenance
  Icons.shield_rounded, // Protection
  Icons.history_edu_rounded, // Intercession
  Icons.nights_stay_rounded, // Night worship
  Icons.emoji_nature_rounded, // Creation
  Icons.local_florist_rounded, // Salawat
];

class KhatmDoaaScreen extends StatefulWidget {
  const KhatmDoaaScreen({super.key});

  @override
  State<KhatmDoaaScreen> createState() => _KhatmDoaaScreenState();
}

class _KhatmDoaaScreenState extends State<KhatmDoaaScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────
  KhatmDoaa? _khatmDoaa;
  bool _isLoading = true;
  String? _errorMessage;
  double _fontSize = 20.0;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  // ── Design tokens ──────────────────────────────────────
  static const Color _gold = Color(0xFFC5A059);
  static const Color _goldMuted = Color(0xFF8C733E);
  static const Color _darkSurface = Color(0xFF1E1E1E);
  static const Color _lightSurface = Color(0xFFFFFDF7);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────
  Future<void> _loadData() async {
    try {
      final String response =
          await rootBundle.loadString('assets/json/quran/doaa_khatm.json');
      final Map<String, dynamic> data = json.decode(response);
      if (mounted) {
        setState(() {
          _khatmDoaa = KhatmDoaa.fromJson(data);
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      debugPrint('Error loading khatm doaa: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'حدث خطأ في تحميل الدعاء: $e';
        });
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────
  void _copyAll() {
    if (_khatmDoaa == null) return;
    final text =
        '${_khatmDoaa!.bismillah}\n\n${_khatmDoaa!.parts.join('\n\n')}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ دعاء ختم القرآن الكريم كاملاً بنجاح',
            style: GoogleFonts.cairo(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _gold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareAll() {
    if (_khatmDoaa == null) return;
    final text =
        '${_khatmDoaa!.title}\n\n${_khatmDoaa!.bismillah}\n\n${_khatmDoaa!.parts.join('\n\n')}\n\nتم الإرسال عبر تطبيق مسلم';
    SharePlus.instance.share(ShareParams(text: text));
  }

  // ── Build ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          title: Text('دعاء الختم', style: GoogleFonts.cairo()),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    color: Colors.redAccent, size: 56),
                const SizedBox(height: 16),
                Text(_errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(color: onSurface, fontSize: 15)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: _isLoading || _khatmDoaa == null
          ? _buildLoader(isDark)
          : _buildContent(isDark, onSurface),
    );
  }

  // ── Loader ─────────────────────────────────────────────
  Widget _buildLoader(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: _gold, strokeWidth: 3),
          const SizedBox(height: 16),
          Text('جاري تحميل دعاء الختم...',
              style: GoogleFonts.cairo(
                  color: isDark ? Colors.white70 : const Color(0xFF4A4A4A),
                  fontSize: 14)),
        ],
      ),
    );
  }

  // ── Main Content ───────────────────────────────────────
  Widget _buildContent(bool isDark, Color onSurface) {
    final data = _khatmDoaa!;
    return FadeTransition(
      opacity: _fadeAnim,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──────────────────────────────────
          _buildSliverAppBar(isDark, data),

          // ── Bismillah Hero ───────────────────────────
          SliverToBoxAdapter(child: _buildBismillahHero(isDark, data)),

          // ── Font Size Control ────────────────────────
          SliverToBoxAdapter(child: _buildFontControls(isDark)),

          // ── Dua Parts ────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList.separated(
              itemCount: data.parts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) =>
                  _buildDuaCard(isDark, onSurface, data.parts[index], index),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sliver App Bar ─────────────────────────────────────
  Widget _buildSliverAppBar(bool isDark, KhatmDoaa data) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? const Color(0xFF121212) : _lightSurface,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : const Color(0xFF2C2C2C), size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Copy
        IconButton(
          tooltip: 'نسخ',
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.copy_rounded, color: _gold, size: 18),
          ),
          onPressed: _copyAll,
        ),
        // Share
        IconButton(
          tooltip: 'مشاركة',
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share_rounded, color: _gold, size: 18),
          ),
          onPressed: _shareAll,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16),
        title: Text(
          data.title,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.amiri(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: _gold,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
                blurRadius: 8,
              )
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1A1208), const Color(0xFF121212)]
                      : [const Color(0xFFF5EDD8), _lightSurface],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Decorative radial glow
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _gold.withValues(alpha: isDark ? 0.12 : 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Quran icon watermark
            Positioned(
              top: 20,
              right: 20,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 60,
                color: _gold.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 60,
                color: _gold.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bismillah Hero ─────────────────────────────────────
  Widget _buildBismillahHero(bool isDark, KhatmDoaa data) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF2A1E0A), const Color(0xFF1A1208)]
                : [const Color(0xFFFDF3DC), const Color(0xFFFAE8BB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _gold.withValues(alpha: isDark ? 0.4 : 0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _gold.withValues(alpha: isDark ? 0.15 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top ornament
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    width: 40, height: 1, color: _gold.withValues(alpha: 0.4)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.star_rounded,
                      color: _gold.withValues(alpha: 0.6), size: 16),
                ),
                Container(
                    width: 40, height: 1, color: _gold.withValues(alpha: 0.4)),
              ],
            ),
            const SizedBox(height: 16),
            // Bismillah text
            Text(
              data.bismillah,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(
                fontSize: _fontSize + 2,
                fontWeight: FontWeight.bold,
                color: _gold,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 16),
            // Bottom ornament
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    width: 40, height: 1, color: _gold.withValues(alpha: 0.4)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.star_rounded,
                      color: _gold.withValues(alpha: 0.6), size: 16),
                ),
                Container(
                    width: 40, height: 1, color: _gold.withValues(alpha: 0.4)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Font Size Controls ─────────────────────────────────
  Widget _buildFontControls(bool isDark) {
    final surface = isDark ? _darkSurface : Colors.white;
    final textColor = isDark ? Colors.white70 : const Color(0xFF4A4A4A);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _gold.withValues(alpha: 0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('حجم الخط',
                style: GoogleFonts.cairo(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            Row(
              children: [
                _fontBtn(
                  icon: Icons.text_decrease_rounded,
                  isDark: isDark,
                  onTap: () =>
                      setState(() => _fontSize = (_fontSize - 1).clamp(14, 30)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '${_fontSize.toInt()}',
                    style: GoogleFonts.outfit(
                        color: _gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                _fontBtn(
                  icon: Icons.text_increase_rounded,
                  isDark: isDark,
                  onTap: () =>
                      setState(() => _fontSize = (_fontSize + 1).clamp(14, 30)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fontBtn(
      {required IconData icon,
      required bool isDark,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _gold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _gold.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, color: _gold, size: 18),
      ),
    );
  }

  // ── Dua Card ───────────────────────────────────────────
  Widget _buildDuaCard(bool isDark, Color onSurface, String text, int index) {
    final surface = isDark ? _darkSurface : Colors.white;
    final icon = _sectionIcons[index % _sectionIcons.length];
    final isLast = _khatmDoaa != null && index == _khatmDoaa!.parts.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLast
              ? _gold.withValues(alpha: isDark ? 0.5 : 0.4)
              : _gold.withValues(alpha: isDark ? 0.18 : 0.12),
          width: isLast ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section Header ──────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _gold, size: 18),
              ),
              // Copy icon for this card
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم نسخ هذا الجزء من الدعاء بنجاح',
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      backgroundColor: _goldMuted,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Icon(Icons.copy_rounded,
                    color: isDark
                        ? Colors.white24
                        : Colors.black.withValues(alpha: 0.15),
                    size: 16),
              ),
            ],
          ),

          // ── Divider ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      _gold.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                )),
          ),

          // ── Dua Text ────────────────────────────────
          Text(
            text,
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.amiri(
              fontSize: _fontSize,
              height: 1.9,
              fontWeight: FontWeight.w500,
              color: onSurface,
            ),
          ),

          // Special Salawat footer for last card
          if (isLast) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF2A1E0A), const Color(0xFF1E1208)]
                      : [const Color(0xFFFDF3DC), const Color(0xFFFAE8BB)],
                ),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: _gold.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_florist_rounded,
                      color: _gold.withValues(alpha: 0.7), size: 16),
                  const SizedBox(width: 8),
                  Text('صلى الله عليه وسلم',
                      style: GoogleFonts.amiri(
                          color: _gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(width: 8),
                  Icon(Icons.local_florist_rounded,
                      color: _gold.withValues(alpha: 0.7), size: 16),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
