import 'package:flutter/material.dart';

class WorkoutPhase {
  final String title;
  final int durationMinutes;
  final IconData icon;
  final String description;
  final bool isCompleted;

  const WorkoutPhase({
    required this.title,
    required this.durationMinutes,
    required this.icon,
    required this.description,
    this.isCompleted = false,
  });

  WorkoutPhase copyWith({
    String? title,
    int? durationMinutes,
    IconData? icon,
    String? description,
    bool? isCompleted,
  }) {
    return WorkoutPhase(
      title: title ?? this.title,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
