import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';

// Option F: Daily Quote Spark
class DailyQuoteSpark extends StatelessWidget {
  const DailyQuoteSpark({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.sparkles, size: 48, color: AppColors.solarAmber),
                const SizedBox(height: 16),
                Text(
                  '"The only bad workout is the one that didn\'t happen."',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '- Unknown',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.solarAmber.withValues(alpha: 0.1),
          border: Border.all(color: AppColors.solarAmber.withValues(alpha: 0.5), width: 1.5),
        ),
        child: const Icon(
          LucideIcons.zap,
          color: AppColors.solarAmber,
          size: 24,
        ),
      ),
    );
  }
}

// Option I: Lucky Spin Token
class LuckySpinToken extends StatefulWidget {
  const LuckySpinToken({super.key});

  @override
  State<LuckySpinToken> createState() => _LuckySpinTokenState();
}

class _LuckySpinTokenState extends State<LuckySpinToken> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<String> challenges = [
    "Do 20 pushups now!",
    "Drink a glass of water!",
    "Stretch for 2 minutes!",
    "Do 30 jumping jacks!",
    "Hold a plank for 30s!"
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spin() {
    if (_controller.isAnimating) return;
    
    _controller.forward(from: 0).then((_) {
      final challenge = challenges[Random().nextInt(challenges.length)];
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(LucideIcons.dices, color: AppColors.pulseRed),
              SizedBox(width: 8),
              Text('Bonus Challenge!'),
            ],
          ),
          content: Text(
            challenge,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Challenge Accepted!', style: TextStyle(color: AppColors.pulseRed)),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _spin,
      child: RotationTransition(
        turns: Tween(begin: 0.0, end: 3.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.pulseRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.pulseRed.withValues(alpha: 0.5)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.dices, color: AppColors.pulseRed, size: 20),
              SizedBox(width: 8),
              Text(
                'Spin',
                style: TextStyle(
                  color: AppColors.pulseRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Option K: Pixel Character Avatar
class PixelCharacterAvatar extends StatefulWidget {
  final int steps;
  const PixelCharacterAvatar({super.key, required this.steps});

  @override
  State<PixelCharacterAvatar> createState() => _PixelCharacterAvatarState();
}

class _PixelCharacterAvatarState extends State<PixelCharacterAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Very simple "pixel" vibe using an icon and bounce animation.
    // If steps > 0, it bounces faster!
    if (widget.steps > 0) {
      _bounceController.duration = const Duration(milliseconds: 300);
    } else {
      _bounceController.duration = const Duration(milliseconds: 800);
    }

    return AnimatedBuilder(
      animation: _bounceController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -5 * _bounceController.value),
          child: child,
        );
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.irisViolet.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.irisViolet.withValues(alpha: 0.3)),
        ),
        child: Icon(
          widget.steps > 0 ? LucideIcons.personStanding : LucideIcons.bed,
          color: AppColors.irisViolet,
          size: 28,
        ),
      ),
    );
  }
}
