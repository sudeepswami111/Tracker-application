import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'botanical_decorations.dart';

/// Scenic Mountain Sunrise Hero Banner on the Home / Dashboard Screen
class ScenicHeroBanner extends StatelessWidget {
  final double height;
  final VoidCallback? onTap;

  const ScenicHeroBanner({
    super.key,
    this.height = 145,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Sunrise sky gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFFDAB9), // Warm peach sunrise
                      Color(0xFFFFE4C4), // Bisque
                      Color(0xFFE8F1F5), // Misty lake
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Sun disc
              Positioned(
                top: 25,
                left: 70,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFF3D4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFC371).withValues(alpha: 0.5),
                        blurRadius: 28,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              // Mountain silhouettes custom painter
              CustomPaint(
                painter: _ScenicMountainPainter(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScenicMountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Distant soft mountains
    final distantPaint = Paint()
      ..color = const Color(0xFF7A9E8A).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    final distantPath = Path();
    distantPath.moveTo(0, h * 0.7);
    distantPath.lineTo(w * 0.25, h * 0.42);
    distantPath.lineTo(w * 0.55, h * 0.65);
    distantPath.lineTo(w * 0.8, h * 0.38);
    distantPath.lineTo(w, h * 0.6);
    distantPath.lineTo(w, h);
    distantPath.lineTo(0, h);
    distantPath.close();
    canvas.drawPath(distantPath, distantPaint);

    // Mid-ground green hills
    final midPaint = Paint()
      ..color = const Color(0xFF436B56).withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;
    final midPath = Path();
    midPath.moveTo(0, h * 0.85);
    midPath.cubicTo(w * 0.2, h * 0.6, w * 0.45, h * 0.75, w * 0.7, h * 0.55);
    midPath.lineTo(w, h * 0.75);
    midPath.lineTo(w, h);
    midPath.lineTo(0, h);
    midPath.close();
    canvas.drawPath(midPath, midPaint);

    // Lake water reflection
    final lakePaint = Paint()
      ..color = const Color(0xFF6B9B88).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, h * 0.75, w, h * 0.25), lakePaint);

    // Foreground cliff & silhouette person sitting
    final fgPaint = Paint()
      ..color = const Color(0xFF16382B)
      ..style = PaintingStyle.fill;
    final fgPath = Path();
    fgPath.moveTo(0, h * 0.45);
    fgPath.cubicTo(w * 0.12, h * 0.48, w * 0.25, h * 0.75, w * 0.35, h);
    fgPath.lineTo(0, h);
    fgPath.close();
    canvas.drawPath(fgPath, fgPaint);

    // Sitting person silhouette
    final pX = w * 0.14;
    final pY = h * 0.50;
    // Head
    canvas.drawCircle(Offset(pX, pY - 12), 4.5, fgPaint);
    // Torso & legs
    final personPath = Path();
    personPath.moveTo(pX - 3, pY - 7);
    personPath.lineTo(pX + 4, pY - 5);
    personPath.lineTo(pX + 8, pY + 6);
    personPath.lineTo(pX - 5, pY + 6);
    personPath.close();
    canvas.drawPath(personPath, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _ScenicMountainPainter oldDelegate) => false;
}

/// Scenic Trail Runner Banner used in Steps Screen & Bottom Carousel
class ScenicRunnerBanner extends StatelessWidget {
  final String title;
  final double height;

  const ScenicRunnerBanner({
    super.key,
    this.title = 'Every step brings you closer to your goals.',
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Warm golden trail gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFF39C6B),
                    Color(0xFFE88B58),
                    Color(0xFF355442),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
            ),
            // Forest tree silhouettes
            CustomPaint(
              painter: _ScenicTrailPainter(),
            ),
            // Motivational Quote on left
            Positioned(
              left: 20,
              top: 24,
              right: 120,
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.35,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScenicTrailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Golden sun glow
    final sunPaint = Paint()
      ..color = const Color(0xFFFFD59E).withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset(w * 0.75, h * 0.35), 32, sunPaint);

    // Trail path perspective
    final pathPaint = Paint()
      ..color = const Color(0xFFC48B68).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(w * 0.74, h * 0.45);
    path.lineTo(w * 0.76, h * 0.45);
    path.lineTo(w * 0.90, h);
    path.lineTo(w * 0.60, h);
    path.close();
    canvas.drawPath(path, pathPaint);

    // Trees on left and right
    final treePaint = Paint()
      ..color = const Color(0xFF1E3A2B)
      ..style = PaintingStyle.fill;

    _drawTree(canvas, treePaint, Offset(w * 0.52, h * 0.55), 18, 45);
    _drawTree(canvas, treePaint, Offset(w * 0.42, h * 0.65), 24, 60);
    _drawTree(canvas, treePaint, Offset(w * 0.88, h * 0.52), 22, 55);
    _drawTree(canvas, treePaint, Offset(w * 0.95, h * 0.68), 28, 70);

    // Runner silhouette on trail
    final rX = w * 0.75;
    final rY = h * 0.62;
    final runnerPaint = Paint()
      ..color = const Color(0xFF162B20)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(rX, rY - 14), 4, runnerPaint);
    final rBody = Path();
    rBody.moveTo(rX - 3, rY - 9);
    rBody.lineTo(rX + 3, rY - 7);
    rBody.lineTo(rX + 5, rY + 8);
    rBody.lineTo(rX - 4, rY + 8);
    rBody.close();
    canvas.drawPath(rBody, runnerPaint);
  }

  void _drawTree(Canvas canvas, Paint paint, Offset base, double width, double height) {
    final path = Path();
    path.moveTo(base.dx, base.dy - height);
    path.lineTo(base.dx + width / 2, base.dy);
    path.lineTo(base.dx - width / 2, base.dy);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScenicTrailPainter oldDelegate) => false;
}

/// Motivational Daily Thought Banner ("Progress, not perfection. 🍃" or "Discipline today builds the freedom tomorrow.")
class MotivationalCard extends StatelessWidget {
  final String quote;
  final Color backgroundColor;
  final Color textColor;
  final bool hasLeaf;

  const MotivationalCard({
    super.key,
    required this.quote,
    this.backgroundColor = const Color(0xFFF3EFE6),
    this.textColor = AppColors.forestGreen,
    this.hasLeaf = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          if (hasLeaf) ...[
            const BotanicalLeafIcon(size: 26, color: AppColors.sageGreen),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Text(
              quote,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
