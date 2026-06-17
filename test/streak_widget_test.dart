import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lifepulse/widgets/streak_badge.dart';
import 'package:lifepulse/theme/app_colors.dart';

void main() {
  group('StreakBadge Widget Tests', () {
    testWidgets('Renders Flame icon when streak is active and not pending', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreakBadge(
              count: 5,
              isActive: true,
              icon: LucideIcons.flame,
              activeColor: AppColors.solarAmber,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.flame), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('Renders Hourglass icon when streak is pending', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreakBadge(
              count: 5,
              isActive: true,
              icon: LucideIcons.hourglass,
              activeColor: AppColors.borderSubtle,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.hourglass), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('Renders inactive state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreakBadge(
              count: 0,
              isActive: false,
              icon: LucideIcons.flame,
              activeColor: AppColors.solarAmber,
            ),
          ),
        ),
      );

      // Icon should be present, count is 0
      expect(find.byIcon(LucideIcons.flame), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });
  });
}
