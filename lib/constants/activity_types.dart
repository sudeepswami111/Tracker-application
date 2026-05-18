import 'package:flutter/material.dart';

class ActivityType {
  final String label;
  final IconData icon;
  final String category;
  
  const ActivityType({required this.label, required this.icon, required this.category});
}

const Map<String, List<ActivityType>> kSportsCategories = {
  'Cardio': [
    ActivityType(label: 'Outdoor Run', icon: Icons.directions_run, category: 'Cardio'),
    ActivityType(label: 'Treadmill', icon: Icons.fitness_center, category: 'Cardio'),
    ActivityType(label: 'Trail Run', icon: Icons.park, category: 'Cardio'),
    ActivityType(label: 'Cycling', icon: Icons.directions_bike, category: 'Cardio'),
  ],
  'Fitness': [
    ActivityType(label: 'Workout', icon: Icons.fitness_center, category: 'Fitness'),
    ActivityType(label: 'HIIT', icon: Icons.timer, category: 'Fitness'),
    ActivityType(label: 'Dance', icon: Icons.music_note, category: 'Fitness'),
  ],
  'Water': [
    ActivityType(label: 'Swim', icon: Icons.pool, category: 'Water'),
    ActivityType(label: 'Surf', icon: Icons.surfing, category: 'Water'),
    ActivityType(label: 'Stand Up Paddle', icon: Icons.rowing, category: 'Water'),
    ActivityType(label: 'Kayak', icon: Icons.kayaking, category: 'Water'),
  ],
  'Winter': [
    ActivityType(label: 'Ice Skate', icon: Icons.ice_skating, category: 'Winter'),
    ActivityType(label: 'Snowboard', icon: Icons.snowboarding, category: 'Winter'),
  ],
  'Team': [
    ActivityType(label: 'Football', icon: Icons.sports_soccer, category: 'Team'),
    ActivityType(label: 'Basketball', icon: Icons.sports_basketball, category: 'Team'),
    ActivityType(label: 'Volleyball', icon: Icons.sports_volleyball, category: 'Team'),
    ActivityType(label: 'Cricket', icon: Icons.sports_cricket, category: 'Team'),
  ],
  'Other': [
    ActivityType(label: 'Skateboard', icon: Icons.skateboarding, category: 'Other'),
    ActivityType(label: 'Golf', icon: Icons.sports_golf, category: 'Other'),
  ],
};

// Flat list of all activity types for the Add Plan Sheet
final List<ActivityType> kActivityTypes = kSportsCategories.values.expand((list) => list).toList();
