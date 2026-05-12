import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lifepulse/providers/app_provider.dart';

void main() {
  group('Streak Logic Unit Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('Gap 0: Idempotent - safe to call multiple times per day', () {
      DateTime mockTime = DateTime(2026, 5, 10);
      final provider = AppProvider(prefs, clock: () => mockTime);

      // First call
      provider.updateStreak();
      expect(provider.currentStreak, 1);
      expect(provider.lastActivityDate.startsWith('2026-05-10'), true);

      // Second call same day
      provider.updateStreak();
      expect(provider.currentStreak, 1); // Should not increase
    });

    test('Gap 1: Normal consecutive day increment', () {
      DateTime mockTime = DateTime(2026, 5, 10);
      final provider = AppProvider(prefs, clock: () => mockTime);
      provider.updateStreak();
      expect(provider.currentStreak, 1);

      // Next day
      provider.clock = () => DateTime(2026, 5, 11);
      provider.updateStreak();
      expect(provider.currentStreak, 2);
    });

    test('Gap 2+freeze: 2 days gap with a freeze saves the streak', () {
      DateTime mockTime = DateTime(2026, 5, 10);
      final provider = AppProvider(prefs, clock: () => mockTime);
      provider.updateStreak();
      provider.streakFreezes = 1;

      // 2 days later (Missed the 11th, activity on 12th)
      provider.clock = () => DateTime(2026, 5, 12);
      provider.updateStreak();
      expect(provider.currentStreak, 2); // Streak continues
      expect(provider.streakFreezes, 0); // Freeze consumed
    });

    test('Gap 2-freeze: 2 days gap without a freeze resets the streak', () {
      DateTime mockTime = DateTime(2026, 5, 10);
      final provider = AppProvider(prefs, clock: () => mockTime);
      provider.updateStreak();
      provider.streakFreezes = 0; // No freeze

      // 2 days later
      provider.clock = () => DateTime(2026, 5, 12);
      provider.updateStreak();
      expect(provider.currentStreak, 1); // Streak reset
    });

    test('Gap 3+: 3 or more days gap resets the streak regardless of 1 freeze', () {
      DateTime mockTime = DateTime(2026, 5, 10);
      final provider = AppProvider(prefs, clock: () => mockTime);
      provider.updateStreak();
      provider.streakFreezes = 1;

      // 3 days later
      provider.clock = () => DateTime(2026, 5, 13);
      provider.updateStreak();
      expect(provider.currentStreak, 1); // Streak reset
      expect(provider.streakFreezes, 1); // Freeze not consumed because it cannot save a 3+ gap
    });
  });
}
