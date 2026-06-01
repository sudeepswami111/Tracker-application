import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum RoutePreference {
  fastest,
  shortest,
  easy,
  scenic,
  lowTraffic,
  loop,
  nightSafe,
}

class RouteOption {
  final RoutePreference preference;
  final String label;
  final IconData icon;
  final bool isSupported;
  final String description;
  final String disabledMessage;

  const RouteOption({
    required this.preference,
    required this.label,
    required this.icon,
    required this.isSupported,
    required this.description,
    this.disabledMessage = 'Coming soon',
  });
}

const List<RouteOption> kRouteOptions = [
  RouteOption(
    preference: RoutePreference.fastest,
    label: 'Fastest',
    icon: LucideIcons.zap,
    isSupported: true,
    description: 'Best travel time',
  ),
  RouteOption(
    preference: RoutePreference.shortest,
    label: 'Shortest',
    icon: LucideIcons.ruler,
    isSupported: true,
    description: 'Lowest distance',
  ),
  RouteOption(
    preference: RoutePreference.easy,
    label: 'Easy',
    icon: LucideIcons.heart,
    isSupported: false,
    description: 'Lower effort',
    disabledMessage: 'Easy routes need elevation data — coming soon',
  ),
  RouteOption(
    preference: RoutePreference.scenic,
    label: 'Scenic',
    icon: LucideIcons.trees,
    isSupported: false,
    description: 'More pleasant route',
    disabledMessage: 'Scenic routing coming soon',
  ),
  RouteOption(
    preference: RoutePreference.lowTraffic,
    label: 'Low Traffic',
    icon: LucideIcons.shieldCheck,
    isSupported: false,
    description: 'Safer roads',
    disabledMessage: 'Low traffic routing coming soon',
  ),
  RouteOption(
    preference: RoutePreference.loop,
    label: 'Loop',
    icon: LucideIcons.refreshCw,
    isSupported: false,
    description: 'Returns to start',
    disabledMessage: 'Loop routes coming soon',
  ),
  RouteOption(
    preference: RoutePreference.nightSafe,
    label: 'Night Safe',
    icon: LucideIcons.moon,
    isSupported: false,
    description: 'Better-lit route',
    disabledMessage: 'Night-safe routing coming soon',
  ),
];
