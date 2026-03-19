import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────

const kWelcomeBg = Color(0xFF005C4D);  // welcome screen background
const kGreen     = Color(0xFF1A3326);  // nav / dark accents
const kMint      = Color(0xFFECF5EC);  // app background
const kAccent    = Color(0xFF3DAA5C);  // green accent
const kBeige     = Color(0xFFF5EDD8);  // beige text / buttons

// ─── Typography helpers ───────────────────────────────────────────────────────

TextStyle serif(
  double size, {
  FontWeight weight = FontWeight.w500,
  Color? color,
  double? height,
}) =>
    GoogleFonts.playfairDisplay(
        fontSize: size, fontWeight: weight, color: color ?? const Color(0xFF1A1A1A), height: height);

TextStyle sans(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color? color,
  double? height,
}) =>
    GoogleFonts.dmSans(
        fontSize: size, fontWeight: weight, color: color, height: height);

// ─── Responsive Utilities ─────────────────────────────────────────────────────

class ResponsiveMaxWidth extends StatelessWidget {
  final Widget child;
  const ResponsiveMaxWidth({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: child,
      ),
    );
  }
}

