import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';

// ── Quote data ─────────────────────────────────────────────
const List<Map<String, String>> _quotes = [
  {'q': 'The body achieves what the mind believes.', 'a': 'Unknown'},
  {'q': 'Your only limit is you.', 'a': 'Unknown'},
  {'q': 'Push yourself, because no one else is going to do it for you.', 'a': 'Unknown'},
  {'q': 'Great things never come from comfort zones.', 'a': 'Unknown'},
  {'q': 'Dream it. Wish it. Do it.', 'a': 'Unknown'},
  {'q': 'Success doesn\'t just find you. You have to go out and get it.', 'a': 'Unknown'},
  {'q': 'The harder you work for something, the greater you\'ll feel when you achieve it.', 'a': 'Unknown'},
  {'q': 'Don\'t stop when you\'re tired. Stop when you\'re done.', 'a': 'Unknown'},
  {'q': 'Wake up with determination. Go to bed with satisfaction.', 'a': 'Unknown'},
  {'q': 'Do something today that your future self will thank you for.', 'a': 'Unknown'},
  {'q': 'Little things make big days.', 'a': 'Unknown'},
  {'q': 'It\'s going to be hard, but hard is not impossible.', 'a': 'Unknown'},
  {'q': 'Don\'t wait for opportunity. Create it.', 'a': 'Unknown'},
  {'q': 'Sometimes later becomes never. Do it now.', 'a': 'Unknown'},
  {'q': 'Hard work beats talent when talent doesn\'t work hard.', 'a': 'Tim Notke'},
  {'q': 'Believe you can and you\'re halfway there.', 'a': 'Theodore Roosevelt'},
  {'q': 'It always seems impossible until it\'s done.', 'a': 'Nelson Mandela'},
  {'q': 'You are stronger than you think.', 'a': 'Unknown'},
  {'q': 'One step at a time. One day at a time.', 'a': 'Unknown'},
  {'q': 'Sweat is just fat crying.', 'a': 'Unknown'},
  {'q': 'You don\'t have to be great to start, but you have to start to be great.', 'a': 'Zig Ziglar'},
  {'q': 'A year from now you may wish you had started today.', 'a': 'Karen Lamb'},
  {'q': 'The secret of getting ahead is getting started.', 'a': 'Mark Twain'},
  {'q': 'If it doesn\'t challenge you, it won\'t change you.', 'a': 'Fred DeVito'},
  {'q': 'Pain is temporary. Quitting lasts forever.', 'a': 'Lance Armstrong'},
  {'q': 'You\'ve got what it takes, but it will take everything you\'ve got.', 'a': 'Unknown'},
  {'q': 'Be stronger than your excuses.', 'a': 'Unknown'},
  {'q': 'Your future self is watching you right now through memories.', 'a': 'Aubrey De Grey'},
  {'q': 'Champions keep playing until they get it right.', 'a': 'Billie Jean King'},
  {'q': 'Energy and persistence conquer all things.', 'a': 'Benjamin Franklin'},
  {'q': 'Keep going. Your hardest times often lead to the greatest moments of your life.', 'a': 'Roy T. Bennett'},
];

Map<String, String> _getDailyQuote() {
  final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
  return _quotes[dayOfYear % _quotes.length];
}

// ── Glowing Bolt Button ─────────────────────────────────────
class DailyQuoteSparkButton extends StatefulWidget {
  const DailyQuoteSparkButton({super.key});

  @override
  State<DailyQuoteSparkButton> createState() => _DailyQuoteSparkButtonState();
}

class _DailyQuoteSparkButtonState extends State<DailyQuoteSparkButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showQuoteCard(context),
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (context, child) {
          return Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1C1232),
              border: Border.all(
                color: AppColors.irisViolet.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.irisViolet.withValues(alpha: _glowAnim.value * 0.7),
                  blurRadius: 16 * _glowAnim.value,
                  spreadRadius: 2 * _glowAnim.value,
                ),
              ],
            ),
            child: child,
          );
        },
        child: const Icon(
          LucideIcons.zap,
          size: 20,
          color: AppColors.irisViolet,
        ),
      ),
    );
  }

  void _showQuoteCard(BuildContext context) {
    final quote = _getDailyQuote();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Quote',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(
            opacity: anim1,
            child: _QuoteCard(quote: quote['q']!, author: quote['a']!),
          ),
        );
      },
    );
  }
}

// ── Beautiful Quote Card ────────────────────────────────────
class _QuoteCard extends StatelessWidget {
  final String quote;
  final String author;

  const _QuoteCard({required this.quote, required this.author});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: size.width * 0.85,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A0E30), Color(0xFF0D0820)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.irisViolet.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.irisViolet.withValues(alpha: 0.35),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Spark header
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.irisViolet.withValues(alpha: 0.5),
                      AppColors.irisViolet.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: const Icon(LucideIcons.zap, size: 22, color: AppColors.irisViolet),
              ),
              const SizedBox(height: 8),
              Text(
                'Daily Spark ✨',
                style: TextStyle(
                  color: AppColors.irisViolet.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 24),

              // Decorative opening quote
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  '"',
                  style: TextStyle(
                    color: AppColors.irisViolet.withValues(alpha: 0.4),
                    fontSize: 60,
                    height: 0.8,
                    fontFamily: 'Georgia',
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                quote,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  height: 1.55,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 20),

              // Author
              if (author != 'Unknown')
                Text(
                  '— $author',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const SizedBox(height: 28),

              // Divider shimmer line
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.irisViolet.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Close button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.irisViolet.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: AppColors.irisViolet.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Got it! Let\'s go 🚀',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
