import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/botanical_decorations.dart';

class HydrationHubScreen extends StatefulWidget {
  const HydrationHubScreen({super.key});

  @override
  State<HydrationHubScreen> createState() => _HydrationHubScreenState();
}

class _HydrationHubScreenState extends State<HydrationHubScreen> {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final currentLiters = app.waterIntake > 0 ? app.waterIntake : 1.8;
    const targetLiters = 2.5;
    final glassesCount = (currentLiters / 0.5).clamp(0, 5).round();

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.lightBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Hydration Hub',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Botanical background decorations in bottom corners
          Positioned(
            left: -20,
            bottom: -20,
            child: SizedBox(
              width: 130,
              height: 150,
              child: CustomPaint(
                painter: BotanicalBranchPainter(
                  color: const Color(0xFF38664D).withValues(alpha: 0.35),
                  leafScale: 1.2,
                ),
              ),
            ),
          ),
          Positioned(
            right: -20,
            bottom: -10,
            child: SizedBox(
              width: 140,
              height: 160,
              child: Transform.flip(
                flipX: true,
                child: CustomPaint(
                  painter: BotanicalBranchPainter(
                    color: const Color(0xFF38664D).withValues(alpha: 0.35),
                    leafScale: 1.3,
                  ),
                ),
              ),
            ),
          ),

          // Scrollable Content
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),

                // ── 1. Carafe Graphic with Circular Ring Gauge ──
                WaterCarafeWidget(
                  currentLiters: currentLiters,
                  targetLiters: targetLiters,
                ),
                const SizedBox(height: 24),

                // ── 2. Row of 5 Water Glasses ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final isFilled = index < glassesCount;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          app.setWaterIntake((index + 1) * 0.5);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 44,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isFilled ? const Color(0xFFD4E9F7) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isFilled ? AppColors.skyBlue : AppColors.cardBorder,
                              width: 1.5,
                            ),
                            boxShadow: isFilled
                                ? [
                                    BoxShadow(
                                      color: AppColors.skyBlue.withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : AppColors.cardShadow,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                LucideIcons.glassWater,
                                size: 22,
                                color: isFilled ? AppColors.skyBlue : const Color(0xFFB5C4BC),
                              ),
                              if (isFilled)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(1.5),
                                    decoration: const BoxDecoration(
                                      color: AppColors.sageGreen,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check, size: 8, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),

                // ── 3. Big Dark Forest Green Pill Button: Log Water + ──
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      app.addWater();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '💧 +250ml water logged! Total: ${(app.waterIntake + 0.25).toStringAsFixed(2)} L',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: AppColors.forestGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Log Water +',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── 4. Hydration Tips Card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFEF3E8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.lightbulb,
                              size: 18,
                              color: AppColors.accentOrange,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Hydration Tips',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Drink water at regular intervals. It boosts energy, improves focus and keeps your body functioning at its best.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
