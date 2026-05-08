import 'package:flutter/widgets.dart';

/// A dual-index controller for the hybrid navigation system.
///
/// Manages two levels of navigation:
/// - [bottomIndex]: which bottom nav item is active
/// - [segmentedIndex]: which segmented sub-tab is active for the current bottom item
///
/// Listeners are notified when either index changes.
///
/// Example:
/// ```dart
/// final controller = HybridTabController(bottomLength: 3);
/// controller.setBottomIndex(1);
/// controller.setSegmentedIndex(2);
/// controller.dispose();
/// ```
class HybridTabController extends ChangeNotifier {
  /// Creates a [HybridTabController].
  ///
  /// [bottomLength] is the number of bottom nav items. Must be >= 1.
  HybridTabController({
    required this.bottomLength,
    int initialBottomIndex = 0,
    int initialSegmentedIndex = 0,
    PageController? pageController,
  })  : assert(bottomLength >= 1, 'bottomLength must be >= 1'),
        assert(
          initialBottomIndex >= 0 && initialBottomIndex < bottomLength,
          'initialBottomIndex out of range.',
        ),
        _bottomIndex = initialBottomIndex,
        _segmentedIndex = initialSegmentedIndex,
        _pageController = pageController;

  /// Number of bottom nav items.
  final int bottomLength;

  int _bottomIndex;
  int _segmentedIndex;
  final PageController? _pageController;

  /// The currently selected bottom nav index.
  int get bottomIndex => _bottomIndex;

  /// The currently selected segmented sub-tab index.
  int get segmentedIndex => _segmentedIndex;

  /// Optional [PageController] to sync with page views.
  PageController? get pageController => _pageController;

  /// Sets the bottom nav index and resets segmented index to 0.
  void setBottomIndex(int value, {bool animate = true}) {
    assert(value >= 0 && value < bottomLength, 'bottomIndex out of range.');
    if (_bottomIndex == value) return;
    _bottomIndex = value;
    _segmentedIndex = 0; // reset sub-tab
    notifyListeners();

    if (_pageController != null && _pageController!.hasClients) {
      if (animate) {
        _pageController!.animateToPage(
          value,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
        );
      } else {
        _pageController!.jumpToPage(value);
      }
    }
  }

  /// Sets the segmented sub-tab index.
  void setSegmentedIndex(int value) {
    if (_segmentedIndex == value) return;
    _segmentedIndex = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }
}
