import 'package:flutter/animation.dart';

/// Centralised animation constants for the hybrid tab bar system.
///
/// All durations and curves used across the package are defined here
/// for consistency and easy tuning.

// ── Durations ──

/// Pill slide animation duration.
const Duration kPillSlideDuration = Duration(milliseconds: 400);

/// Icon bounce animation duration.
const Duration kIconBounceDuration = Duration(milliseconds: 300);

/// Text style crossfade duration.
const Duration kTextFadeDuration = Duration(milliseconds: 200);

/// Glass container entrance animation duration.
const Duration kContainerEntranceDuration = Duration(milliseconds: 400);

// ── Curves ──

/// Primary easing curve for the pill slide.
const Curve kPillSlideCurve = Curves.easeInOutCubic;

/// Bounce curve for icon animations.
const Curve kIconBounceCurve = Curves.easeOutBack;

/// Smooth entrance curve (no spring).
const Curve kEntranceCurve = Curves.easeOutCubic;
