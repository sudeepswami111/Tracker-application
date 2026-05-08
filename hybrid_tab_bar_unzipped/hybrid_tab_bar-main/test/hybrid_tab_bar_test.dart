import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_tab_bar/hybrid_tab_bar.dart';

void main() {
  group('HybridTabController', () {
    test('initialises with correct indices', () {
      final controller = HybridTabController(bottomLength: 3);
      expect(controller.bottomIndex, 0);
      expect(controller.segmentedIndex, 0);
      controller.dispose();
    });

    test('setBottomIndex updates bottomIndex and resets segmentedIndex', () {
      final controller = HybridTabController(bottomLength: 3);
      controller.setSegmentedIndex(2);
      expect(controller.segmentedIndex, 2);

      controller.setBottomIndex(1);
      expect(controller.bottomIndex, 1);
      expect(controller.segmentedIndex, 0);
      controller.dispose();
    });

    test('setBottomIndex with same value does not notify', () {
      final controller = HybridTabController(bottomLength: 3);
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.setBottomIndex(0);
      expect(notifyCount, 0);
      controller.dispose();
    });

    test('setSegmentedIndex updates and notifies', () {
      final controller = HybridTabController(bottomLength: 3);
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.setSegmentedIndex(1);
      expect(controller.segmentedIndex, 1);
      expect(notifyCount, 1);
      controller.dispose();
    });
  });

  group('HybridNavItem', () {
    test('item without segmented tabs', () {
      const item = HybridNavItem(
        icon: Icons.settings,
        label: 'Configs',
      );
      expect(item.hasSegmentedTabs, false);
    });

    test('item with segmented tabs', () {
      const item = HybridNavItem(
        icon: Icons.explore,
        label: 'Explore',
        segmentedTabs: ['Rooms', 'Inspiration'],
      );
      expect(item.hasSegmentedTabs, true);
      expect(item.segmentedTabs!.length, 2);
    });
  });

  group('HybridTabStyle', () {
    test('light preset has correct active color', () {
      expect(HybridTabStyle.light.activeColor, const Color(0xFF2B3A67));
    });

    test('dark preset has correct tint', () {
      expect(HybridTabStyle.dark.glassTint, const Color(0xFF1E2030));
    });

    test('copyWith replaces values', () {
      final modified = HybridTabStyle.light.copyWith(blurAmount: 40);
      expect(modified.blurAmount, 40);
      expect(modified.activeColor, HybridTabStyle.light.activeColor);
    });
  });
}
