import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';

// ── Daily Quote Data ─────────────────────────────────────────
class _QuoteData {
  final String text;
  final String author;
  const _QuoteData(this.text, this.author);
}

const List<_QuoteData> _dailyQuotes = [
  _QuoteData("The only bad workout is the one that didn't happen.", "Unknown"),
  _QuoteData("Take care of your body. It's the only place you have to live.", "Jim Rohn"),
  _QuoteData("An early morning walk is a blessing for the whole day.", "Henry David Thoreau"),
  _QuoteData("To keep the body in good health is a duty, otherwise we shall not be able to keep our mind strong and clear.", "Buddha"),
  _QuoteData("The groundwork of all happiness is health.", "Leigh Hunt"),
  _QuoteData("Health is not about the weight you lose, but about the life you gain.", "Unknown"),
  _QuoteData("Movement is medicine for creating change in a person's physical, emotional, and mental states.", "Carol Welch"),
  _QuoteData("Your body can stand almost anything. It's your mind that you have to convince.", "Unknown"),
  _QuoteData("A one-hour workout is 4% of your day. No excuses.", "Unknown"),
  _QuoteData("Motivation is what gets you started. Habit is what keeps you going.", "Jim Ryun"),
  _QuoteData("Success usually comes to those who are too busy to be looking for it.", "Henry David Thoreau"),
  _QuoteData("Don't wish for it. Work for it.", "Unknown"),
  _QuoteData("The difference between try and triumph is a little 'umph'.", "Marvin Phillips"),
  _QuoteData("If it doesn't challenge you, it doesn't change you.", "Fred DeVito"),
  _QuoteData("Push yourself because no one else is going to do it for you.", "Unknown"),
  _QuoteData("Small steps in the right direction are better than giant leaps in the wrong one.", "Unknown"),
  _QuoteData("It's not about perfect. It's about effort.", "Jillian Michaels"),
  _QuoteData("Your health is an investment, not an expense.", "Unknown"),
  _QuoteData("Wake up with determination. Go to bed with satisfaction.", "Unknown"),
  _QuoteData("Don't count the days. Make the days count.", "Muhammad Ali"),
  _QuoteData("Energy and persistence conquer all things.", "Benjamin Franklin"),
  _QuoteData("What hurts today makes you stronger tomorrow.", "Jay Cutler"),
  _QuoteData("You don't have to be great to start, but you have to start to be great.", "Zig Ziglar"),
  _QuoteData("The secret of getting ahead is getting started.", "Mark Twain"),
  _QuoteData("All progress takes place outside the comfort zone.", "Michael John Bobak"),
  _QuoteData("Once you see results, it becomes an addiction.", "Unknown"),
  _QuoteData("Strive for progress, not perfection.", "Unknown"),
  _QuoteData("You are one workout away from a good mood.", "Unknown"),
  _QuoteData("Strength does not come from the physical capacity. It comes from an indomitable will.", "Mahatma Gandhi"),
  _QuoteData("The pain you feel today will be the strength you feel tomorrow.", "Unknown"),
  _QuoteData("Take care of your body and your body will take care of you.", "Unknown"),
  _QuoteData("A healthy outside starts from the inside.", "Robert Urich"),
  _QuoteData("Your body is a reflection of your lifestyle.", "Unknown"),
  _QuoteData("Every step is progress, no matter how small.", "Unknown"),
  _QuoteData("Do something today that your future self will thank you for.", "Sean Patrick Flanery"),
];

_QuoteData _getTodaysQuote() {
  final now = DateTime.now();
  final dayOfYear = now.difference(DateTime(now.year)).inDays;
  return _dailyQuotes[dayOfYear % _dailyQuotes.length];
}

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
                Builder(
                  builder: (context) {
                    final quote = _getTodaysQuote();
                    final now = DateTime.now();
                    return Column(
                      children: [
                        Text(
                          'Day ${now.difference(DateTime(now.year)).inDays + 1} of the year',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '"${quote.text}"',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '— ${quote.author}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          icon: const Icon(LucideIcons.copy, size: 16),
                          label: const Text('Copy'),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: '"${quote.text}" — ${quote.author}'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Quote copied!')),
                            );
                          },
                        ),
                      ],
                    );
                  },
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
          LucideIcons.quote,
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
