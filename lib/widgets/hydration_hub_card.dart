import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'glass_card.dart';

class HydrationHubCard extends StatefulWidget {
  const HydrationHubCard({super.key});

  @override
  State<HydrationHubCard> createState() => _HydrationHubCardState();
}

class _HydrationHubCardState extends State<HydrationHubCard>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _bubbleController;
  late AnimationController _fillController;
  double _animatedFill = 0.0;
  double _targetFill = 0.0;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _bubbleController.dispose();
    _fillController.dispose();
    super.dispose();
  }

  String _getMotivationalMessage(double percent) {
    if (percent >= 1.0) {
      return 'Hydration Goal Smashed! 🌊 Great work!';
    } else if (percent >= 0.75) {
      return 'Almost at your peak! 1-2 glasses remaining.';
    } else if (percent >= 0.50) {
      return 'Halfway there! Keep your water rhythm going.';
    } else if (percent >= 0.25) {
      return 'Good start! Drink a glass after your workout.';
    } else {
      return 'Start fresh with a tall glass of cold water! 💧';
    }
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentGlasses = app.waterGlasses;
    final goalGlasses = app.waterGlassGoal > 0 ? app.waterGlassGoal : 8;
    final fillPercent = (currentGlasses / goalGlasses).clamp(0.0, 1.0);
    final currentLiters = app.waterIntake;
    final goalLiters = (goalGlasses * 0.25);

    _targetFill = fillPercent;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row: Title, Status Badge, Decrement Button ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.voltCyan.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.voltCyan.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.droplets,
                      color: AppColors.voltCyan,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hydration Hub',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Daily Water Intake',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  // Percentage Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.voltCyan.withValues(alpha: 0.2),
                          AppColors.blue.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.voltCyan.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '${(fillPercent * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppColors.voltCyan,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (currentGlasses > 0) ...[
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          _triggerHaptic();
                          app.removeWater();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.minus,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Center Content: Interactive Wave Flask + Metrics & Droplet Grid ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Animated Liquid Capsule / Glass ──
              _buildLiquidCapsule(fillPercent, isDark),

              const SizedBox(width: AppSpacing.md),

              // ── Right Column: Stats & Interactive Glass Dots ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Liters & Glasses Counter
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          currentLiters.toStringAsFixed(2),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: AppColors.voltCyan,
                          ),
                        ),
                        Text(
                          ' / ${goalLiters.toStringAsFixed(1)} L',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$currentGlasses of $goalGlasses cups',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── 8 Interactive Droplet / Glass Pills ──
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(goalGlasses, (index) {
                        final isFilled = index < currentGlasses;
                        return GestureDetector(
                          onTap: () {
                            _triggerHaptic();
                            // Set to tapped index + 1
                            final target = index + 1;
                            if (target > currentGlasses) {
                              while (app.waterGlasses < target) {
                                app.addWater();
                              }
                            } else if (target < currentGlasses) {
                              while (app.waterGlasses > target) {
                                app.removeWater();
                              }
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutBack,
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isFilled
                                  ? AppColors.voltCyan
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.black.withValues(alpha: 0.05)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isFilled
                                    ? AppColors.voltCyan
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : Colors.black.withValues(alpha: 0.1)),
                                width: 1.2,
                              ),
                              boxShadow: isFilled
                                  ? [
                                      BoxShadow(
                                        color: AppColors.voltCyan.withValues(alpha: 0.4),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Icon(
                                isFilled ? LucideIcons.check : LucideIcons.droplets,
                                size: 13,
                                color: isFilled
                                    ? Colors.black
                                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Motivational Note ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.sparkles,
                  color: AppColors.voltCyan,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getMotivationalMessage(fillPercent),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Quick Log Action Buttons ──
          Row(
            children: [
              // + 250 ml (1 Glass)
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _triggerHaptic();
                    app.addWater();
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(LucideIcons.droplets, color: AppColors.voltCyan, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '+250ml Logged! (${app.waterGlasses} of $goalGlasses glasses)',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF161F2E),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text(
                    '+ 1 Glass (250ml)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.voltCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // + 500 ml (Bottle)
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _triggerHaptic();
                    app.addWater();
                    app.addWater();
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(LucideIcons.droplets, color: AppColors.voltCyan, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '+500ml Bottle Logged! (${app.waterGlasses} glasses)',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF161F2E),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.droplets, size: 16, color: AppColors.voltCyan),
                  label: const Text(
                    '+ 500ml',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.voltCyan,
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.voltCyan.withValues(alpha: 0.6),
                      width: 1.4,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Liquid Wave Flask/Capsule Widget ──
  Widget _buildLiquidCapsule(double fillPercent, bool isDark) {
    return Container(
      width: 68,
      height: 96,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1B2B) : const Color(0xFFE6F7FA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.voltCyan.withValues(alpha: 0.35),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.voltCyan.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Wave Custom Paint
            AnimatedBuilder(
              animation: Listenable.merge([_waveController, _bubbleController]),
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(68, 96),
                  painter: _LiquidWavePainter(
                    waveAnimation: _waveController.value,
                    bubbleAnimation: _bubbleController.value,
                    fillLevel: fillPercent,
                  ),
                );
              },
            ),

            // Subtle Measurement Hash Marks on the Glass Edge
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(4, (i) {
                  return Container(
                    margin: const EdgeInsets.only(left: 4),
                    width: i == 1 || i == 3 ? 8 : 12,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.25),
                  );
                }),
              ),
            ),

            // Icon overlay at the center
            Center(
              child: Icon(
                LucideIcons.droplets,
                size: 24,
                color: fillPercent > 0.4
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppColors.voltCyan.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Custom Wave Painter ──
class _LiquidWavePainter extends CustomPainter {
  final double waveAnimation;
  final double bubbleAnimation;
  final double fillLevel;

  _LiquidWavePainter({
    required this.waveAnimation,
    required this.bubbleAnimation,
    required this.fillLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fillLevel <= 0) return;

    final baseHeight = size.height * (1.0 - fillLevel);

    // Front wave paint
    final frontPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.voltCyan,
          Color(0xFF0077B6),
        ],
      ).createShader(Rect.fromLTWH(0, baseHeight, size.width, size.height - baseHeight));

    // Back wave paint
    final backPaint = Paint()
      ..color = const Color(0xFF00B4D8).withValues(alpha: 0.5);

    // Back Wave Path
    final backPath = Path();
    backPath.moveTo(0, size.height);
    backPath.lineTo(0, baseHeight);
    for (double i = 0; i <= size.width; i++) {
      final y = baseHeight +
          math.sin((i / size.width * 2 * math.pi) + (waveAnimation * 2 * math.pi) + math.pi) * 3;
      backPath.lineTo(i, y);
    }
    backPath.lineTo(size.width, size.height);
    backPath.close();
    canvas.drawPath(backPath, backPaint);

    // Front Wave Path
    final frontPath = Path();
    frontPath.moveTo(0, size.height);
    frontPath.lineTo(0, baseHeight);
    for (double i = 0; i <= size.width; i++) {
      final y = baseHeight +
          math.sin((i / size.width * 2 * math.pi) + (waveAnimation * 2 * math.pi)) * 3.5;
      frontPath.lineTo(i, y);
    }
    frontPath.lineTo(size.width, size.height);
    frontPath.close();
    canvas.drawPath(frontPath, frontPaint);

    // Bubbles
    if (fillLevel > 0.2) {
      final bubblePaint = Paint()..color = Colors.white.withValues(alpha: 0.5);
      final b1Y = size.height - ((bubbleAnimation * (size.height - baseHeight)) % (size.height - baseHeight));
      final b2Y = size.height - (((bubbleAnimation + 0.5) * (size.height - baseHeight)) % (size.height - baseHeight));
      canvas.drawCircle(Offset(size.width * 0.35, b1Y), 2.5, bubblePaint);
      canvas.drawCircle(Offset(size.width * 0.7, b2Y), 2, bubblePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidWavePainter oldDelegate) {
    return oldDelegate.waveAnimation != waveAnimation ||
        oldDelegate.bubbleAnimation != bubbleAnimation ||
        oldDelegate.fillLevel != fillLevel;
  }
}
