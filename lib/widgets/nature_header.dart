import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NatureHeader extends StatefulWidget {
  final String city;

  const NatureHeader({
    super.key,
    required this.city,
  });

  @override
  State<NatureHeader> createState() => _NatureHeaderState();
}

class _NatureHeaderState extends State<NatureHeader> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF2F8F5), // Soft off-white/mint
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle watermark pattern (Mosque Icon Grid)
          Opacity(
            opacity: 0.05,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
              ),
              itemBuilder: (context, index) {
                return const Icon(
                  Icons.mosque_rounded,
                  color: Color(0xFF2D5A3F), // Forest green watermark
                  size: 32,
                );
              },
            ),
          ),

          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "مسلم",
                    style: GoogleFonts.cairo(
                      color: const Color(0xFFC9A96E), // Gold/Sand
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D5A3F).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: Color(0xFF2D5A3F), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          widget.city.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2D5A3F),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
