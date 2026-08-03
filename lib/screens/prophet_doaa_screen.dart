import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/prophet_doaa.dart';
import '../services/app_colors.dart';

class ProphetDoaaScreen extends StatefulWidget {
  const ProphetDoaaScreen({super.key});

  @override
  State<ProphetDoaaScreen> createState() => _ProphetDoaaScreenState();
}

class _ProphetDoaaScreenState extends State<ProphetDoaaScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.85);

  List<ProphetDoaa> _duas = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDuas();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadDuas() async {
    try {
      final String response =
          await rootBundle.loadString('assets/json/prophet_doaa.json');
      final List<dynamic> data = json.decode(response);

      if (mounted) {
        setState(() {
          _duas = data.map((json) => ProphetDoaa.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading duas: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "حدث خطأ في تحميل الأدعية: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("خطأ")),
        body: Center(child: Text(_errorMessage!, textAlign: TextAlign.center)),
      );
    }

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "من أدعيته ﷺ",
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: c.textPrimary,
            fontSize: 20, // Keep premium size
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: c.cardBg,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: c.shadowColor,
                    blurRadius: 10,
                  )
                ]),
            child:
                Icon(Icons.arrow_back_ios_new, color: c.textPrimary, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFC5A059)))
          : Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _duas.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final doaa = _duas[index];
                      // Animation Scale
                      return AnimatedScale(
                        duration: const Duration(milliseconds: 300),
                        scale: _currentIndex == index ? 1.0 : 0.95,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 20),
                          decoration: BoxDecoration(
                            color: c.cardBg,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: c.shadowColor,
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // 1. Header with Icon
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(
                                            alpha: c.isDark
                                                ? 0.2
                                                : 0.1), // Blue for Prophet
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                          Icons
                                              .volunteer_activism_rounded, // Hand icon for Dua
                                          size: 40,
                                          color: Color(0xFF3B82F6)),
                                    ),
                                    const SizedBox(height: 30),

                                    // 2. Dua Text
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24),
                                      child: Text(
                                        doaa.text,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.amiri(
                                          // Amiri is perfect for Quran/Hadith
                                          fontSize: 24,
                                          height: 1.8,
                                          fontWeight: FontWeight.bold,
                                          color: c.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 40),

                                    // 3. Source Info
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 24),
                                      decoration: BoxDecoration(
                                        color: c.isDark
                                            ? Colors.black
                                                .withValues(alpha: 0.3)
                                            : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(20),
                                        border:
                                            Border.all(color: c.borderColor),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.book_rounded,
                                              size: 16, color: c.textMuted),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              doaa.source,
                                              style: GoogleFonts.cairo(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: c.textMuted,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Indicator
                Container(
                  padding: const EdgeInsets.only(bottom: 30, top: 10),
                  child: Text(
                    "${_currentIndex + 1} / ${_duas.length}",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: c.textMuted,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
