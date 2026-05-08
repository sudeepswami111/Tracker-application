import 'package:flutter/material.dart';

/// Configuration class for the visual style of [HybridTabBarScaffold].
///
/// Example:
/// ```dart
/// HybridTabStyle(
///   activeColor: Color(0xFF2B3A67),
///   blurAmount: 20,
///   outerBorderRadius: 28,
/// )
/// ```
class HybridTabStyle {
  /// Creates a [HybridTabStyle].
  const HybridTabStyle({
    this.activeColor,
    this.inactiveColor,
    this.glassTint,
    this.blurAmount = 20.0,
    this.outerBorderRadius = 28.0,
    this.segmentedPillRadius = 14.0,
    this.bottomPillRadius = 18.0,
    this.animationDuration = const Duration(milliseconds: 400),
    this.pillAnimationDuration = const Duration(milliseconds: 400),
    this.iconAnimationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOutCubic,
    this.iconAnimationCurve = Curves.easeOutBack,
    this.elevation = 8.0,
    this.indicatorPadding = const EdgeInsets.all(4),
    this.activeScale = 1.15,
    this.inactiveOpacity = 0.70,
    this.enableBlur = true,
    this.enableHaptics = false,
    this.enableGlow = false,
    this.glowColor,
    this.glassBorderOpacity = 0.35,
    this.glassTintOpacity = 0.50,
    this.segmentedLabelStyle,
    this.activeSegmentedLabelStyle,
    this.bottomLabelStyle,
    this.activeBottomLabelStyle,
    this.segmentedPillColor,
    this.bottomPillColor,
    this.containerShadowLight,
    this.containerShadowDark,
  });

  // ── Colors ──

  /// Color for active elements (text, icons). Defaults to dark navy.
  final Color? activeColor;

  /// Color for inactive elements. Defaults to medium slate.
  final Color? inactiveColor;

  /// Tint color of the glass background.
  final Color? glassTint;

  /// Opacity of the glass tint layer.
  final double glassTintOpacity;

  /// Opacity of the 1px inner border stroke.
  final double glassBorderOpacity;

  /// Color for the segmented control sliding pill.
  final Color? segmentedPillColor;

  /// Color for the bottom nav sliding pill.
  final Color? bottomPillColor;

  // ── Blur & Elevation ──

  /// Gaussian blur sigma for the glass container.
  final double blurAmount;

  /// Whether to enable the backdrop blur effect.
  final bool enableBlur;

  /// Shadow elevation.
  final double elevation;

  // ── Border Radius ──

  /// Border radius of the outer glass container (default 28).
  final double outerBorderRadius;

  /// Border radius of the segmented control pill (default 14).
  final double segmentedPillRadius;

  /// Border radius of the bottom nav pill (default 18).
  final double bottomPillRadius;

  // ── Indicator ──

  /// Padding around the segmented pill indicator.
  final EdgeInsets indicatorPadding;

  // ── Animation ──

  /// Duration for the pill slide animation.
  final Duration animationDuration;

  /// Duration for the pill slide.
  final Duration pillAnimationDuration;

  /// Duration for icon animation in bottom bar.
  final Duration iconAnimationDuration;

  /// Curve for the pill slide animation.
  final Curve animationCurve;

  /// Curve for the icon animation.
  final Curve iconAnimationCurve;

  // ── Scale / Opacity ──

  /// Scale factor for active items in bottom bar.
  final double activeScale;

  /// Opacity of inactive items.
  final double inactiveOpacity;

  // ── Extras ──

  /// Toggle haptic feedback.
  final bool enableHaptics;

  /// Show glow effect behind active items.
  final bool enableGlow;

  /// Color of the glow effect.
  final Color? glowColor;

  // ── Shadows ──

  /// Light highlight shadow (top-left).
  final BoxShadow? containerShadowLight;

  /// Dark soft shadow (bottom-right).
  final BoxShadow? containerShadowDark;

  // ── Text Styles ──

  /// Text style for inactive segmented labels.
  final TextStyle? segmentedLabelStyle;

  /// Text style for the active segmented label.
  final TextStyle? activeSegmentedLabelStyle;

  /// Text style for inactive bottom bar labels.
  final TextStyle? bottomLabelStyle;

  /// Text style for active bottom bar label.
  final TextStyle? activeBottomLabelStyle;

  // ── Resolvers ──

  /// Resolves the active color from style or theme.
  Color resolveActiveColor(BuildContext context) {
    return activeColor ?? Theme.of(context).colorScheme.primary;
  }

  /// Resolves the inactive color.
  Color resolveInactiveColor(BuildContext context) {
    if (inactiveColor != null) return inactiveColor!;
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF8A95A8)
        : const Color(0xFF7A8A9E);
  }

  /// Resolves the glass tint color.
  Color resolveGlassTint(BuildContext context) {
    if (glassTint != null) return glassTint!;
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF1E2030)
        : const Color(0xFFE8ECF2);
  }

  /// Resolves the segmented control pill color.
  Color resolveSegmentedPillColor(BuildContext context) {
    if (segmentedPillColor != null) return segmentedPillColor!;
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFD6DAE8);
  }

  /// Resolves the bottom nav pill color.
  Color resolveBottomPillColor(BuildContext context) {
    if (bottomPillColor != null) return bottomPillColor!;
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.10)
        : const Color(0xFFECEEF4);
  }

  /// Container shadow list.
  List<BoxShadow> resolveContainerShadows() {
    return [
      containerShadowLight ??
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.70),
            blurRadius: 10,
            offset: const Offset(-4, -4),
          ),
      containerShadowDark ??
          BoxShadow(
            color: const Color(0xFFB0B8C8).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(5, 5),
          ),
    ];
  }

  /// Returns a copy with fields replaced.
  HybridTabStyle copyWith({
    Color? activeColor,
    Color? inactiveColor,
    Color? glassTint,
    double? glassTintOpacity,
    double? glassBorderOpacity,
    Color? segmentedPillColor,
    Color? bottomPillColor,
    double? blurAmount,
    bool? enableBlur,
    double? elevation,
    double? outerBorderRadius,
    double? segmentedPillRadius,
    double? bottomPillRadius,
    EdgeInsets? indicatorPadding,
    Duration? animationDuration,
    Duration? pillAnimationDuration,
    Duration? iconAnimationDuration,
    Curve? animationCurve,
    Curve? iconAnimationCurve,
    double? activeScale,
    double? inactiveOpacity,
    bool? enableHaptics,
    bool? enableGlow,
    Color? glowColor,
    BoxShadow? containerShadowLight,
    BoxShadow? containerShadowDark,
    TextStyle? segmentedLabelStyle,
    TextStyle? activeSegmentedLabelStyle,
    TextStyle? bottomLabelStyle,
    TextStyle? activeBottomLabelStyle,
  }) {
    return HybridTabStyle(
      activeColor: activeColor ?? this.activeColor,
      inactiveColor: inactiveColor ?? this.inactiveColor,
      glassTint: glassTint ?? this.glassTint,
      glassTintOpacity: glassTintOpacity ?? this.glassTintOpacity,
      glassBorderOpacity: glassBorderOpacity ?? this.glassBorderOpacity,
      segmentedPillColor: segmentedPillColor ?? this.segmentedPillColor,
      bottomPillColor: bottomPillColor ?? this.bottomPillColor,
      blurAmount: blurAmount ?? this.blurAmount,
      enableBlur: enableBlur ?? this.enableBlur,
      elevation: elevation ?? this.elevation,
      outerBorderRadius: outerBorderRadius ?? this.outerBorderRadius,
      segmentedPillRadius: segmentedPillRadius ?? this.segmentedPillRadius,
      bottomPillRadius: bottomPillRadius ?? this.bottomPillRadius,
      indicatorPadding: indicatorPadding ?? this.indicatorPadding,
      animationDuration: animationDuration ?? this.animationDuration,
      pillAnimationDuration:
          pillAnimationDuration ?? this.pillAnimationDuration,
      iconAnimationDuration:
          iconAnimationDuration ?? this.iconAnimationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
      iconAnimationCurve: iconAnimationCurve ?? this.iconAnimationCurve,
      activeScale: activeScale ?? this.activeScale,
      inactiveOpacity: inactiveOpacity ?? this.inactiveOpacity,
      enableHaptics: enableHaptics ?? this.enableHaptics,
      enableGlow: enableGlow ?? this.enableGlow,
      glowColor: glowColor ?? this.glowColor,
      containerShadowLight: containerShadowLight ?? this.containerShadowLight,
      containerShadowDark: containerShadowDark ?? this.containerShadowDark,
      segmentedLabelStyle: segmentedLabelStyle ?? this.segmentedLabelStyle,
      activeSegmentedLabelStyle:
          activeSegmentedLabelStyle ?? this.activeSegmentedLabelStyle,
      bottomLabelStyle: bottomLabelStyle ?? this.bottomLabelStyle,
      activeBottomLabelStyle:
          activeBottomLabelStyle ?? this.activeBottomLabelStyle,
    );
  }

  /// Light theme style matching the Dribbble reference.
  static const HybridTabStyle light = HybridTabStyle(
    activeColor: Color(0xFF2B3A67),
    inactiveColor: Color(0xFF7A8A9E),
    glassTint: Color(0xFFE8ECF2),
    glassTintOpacity: 0.55,
    glassBorderOpacity: 0.40,
    enableBlur: true,
    blurAmount: 20,
    elevation: 8,
    outerBorderRadius: 28,
    segmentedPillRadius: 14,
    bottomPillRadius: 18,
    activeScale: 1.15,
    inactiveOpacity: 0.70,
  );

  /// Dark theme style.
  static const HybridTabStyle dark = HybridTabStyle(
    activeColor: Color(0xFFB0BCDE),
    inactiveColor: Color(0xFF6A7A8A),
    glassTint: Color(0xFF1E2030),
    glassTintOpacity: 0.60,
    glassBorderOpacity: 0.12,
    enableBlur: true,
    blurAmount: 24,
    elevation: 12,
    outerBorderRadius: 28,
    segmentedPillRadius: 14,
    bottomPillRadius: 18,
    activeScale: 1.15,
    inactiveOpacity: 0.55,
  );
}
