/// Pre-defined workout programs.
/// These are hardcoded - no storage, no persistence, just reliable workouts.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:echelon_connect/core/models/workout.dart';

/// Provider for the list of available workouts
final workoutsProvider = Provider<List<Workout>>((ref) {
  return predefinedWorkouts;
});

/// All pre-defined workouts
final List<Workout> predefinedWorkouts = [
  // Interval Training - Quick HIIT
  Workout(
    id: 'interval_training',
    name: '⭐ Interval Training',
    steps: [
      WorkoutStep(name: 'Warmup', resistance: 10, durationSeconds: 120, targetCadence: 80),
      WorkoutStep(name: 'Push', resistance: 25, durationSeconds: 30, targetCadence: null), // MAX
      WorkoutStep(name: 'Recovery', resistance: 12, durationSeconds: 30, targetCadence: 70),
      WorkoutStep(name: 'Push', resistance: 25, durationSeconds: 30, targetCadence: null), // MAX
      WorkoutStep(name: 'Recovery', resistance: 12, durationSeconds: 30, targetCadence: 70),
      WorkoutStep(name: 'Push', resistance: 25, durationSeconds: 30, targetCadence: null), // MAX
      WorkoutStep(name: 'Cooldown', resistance: 8, durationSeconds: 120, targetCadence: 60),
    ],
    createdAt: DateTime(2024, 1, 1),
  ),

  // Hill Climb - Strength Focus
  Workout(
    id: 'hill_climb',
    name: '⭐ Hill Climb',
    steps: [
      WorkoutStep(name: 'Warmup', resistance: 10, durationSeconds: 180, targetCadence: 85),
      WorkoutStep(name: 'Climb 1', resistance: 18, durationSeconds: 60, targetCadence: 70),
      WorkoutStep(name: 'Climb 2', resistance: 22, durationSeconds: 60, targetCadence: 65),
      WorkoutStep(name: 'Climb 3', resistance: 26, durationSeconds: 60, targetCadence: 60),
      WorkoutStep(name: 'Summit', resistance: 30, durationSeconds: 30, targetCadence: 55),
      WorkoutStep(name: 'Descent', resistance: 15, durationSeconds: 90, targetCadence: 90),
      WorkoutStep(name: 'Cooldown', resistance: 8, durationSeconds: 120, targetCadence: 60),
    ],
    createdAt: DateTime(2024, 1, 1),
  ),

  // Tabata Sprints - 30 min HIIT
  Workout(
    id: 'tabata_30_min',
    name: '🔥 Tabata Sprints',
    steps: [
      // 5 min Warmup
      WorkoutStep(name: 'Warmup Easy', resistance: 10, durationSeconds: 120, targetCadence: 80),
      WorkoutStep(name: 'Warmup Moderate', resistance: 15, durationSeconds: 120, targetCadence: 85),
      WorkoutStep(name: 'Pre-Sprint Spin', resistance: 18, durationSeconds: 60, targetCadence: 90),
      // Set 1: 8x (20s ON / 10s OFF)
      for (int i = 0; i < 8; i++) ...[
        WorkoutStep(name: 'SPRINT!', resistance: 25, durationSeconds: 20, targetCadence: null),
        WorkoutStep(name: 'Rest', resistance: 8, durationSeconds: 10, targetCadence: 60),
      ],
      // 3 min Active Recovery
      WorkoutStep(name: 'Recovery Spin', resistance: 12, durationSeconds: 180, targetCadence: 75),
      // Set 2: 8x (20s ON / 10s OFF) - higher resistance
      for (int i = 0; i < 8; i++) ...[
        WorkoutStep(name: 'POWER SPRINT!', resistance: 28, durationSeconds: 20, targetCadence: null),
        WorkoutStep(name: 'Rest', resistance: 8, durationSeconds: 10, targetCadence: 60),
      ],
      // 3 min Active Recovery
      WorkoutStep(name: 'Recovery Spin', resistance: 12, durationSeconds: 180, targetCadence: 75),
      // Set 3: 4x (30s ON / 30s OFF) - Endurance Sprints
      for (int i = 0; i < 4; i++) ...[
        WorkoutStep(name: 'Long Sprint', resistance: 24, durationSeconds: 30, targetCadence: null),
        WorkoutStep(name: 'Easy Spin', resistance: 10, durationSeconds: 30, targetCadence: 70),
      ],
      // Cooldown
      WorkoutStep(name: 'Cooldown', resistance: 8, durationSeconds: 180, targetCadence: 60),
    ],
    createdAt: DateTime(2024, 1, 1),
  ),

  // Rolling Hills - 30 min Endurance
  Workout(
    id: 'rolling_hills_30',
    name: '⛰️ Rolling Hills',
    steps: [
      WorkoutStep(name: 'Warmup', resistance: 10, durationSeconds: 300, targetCadence: 85),
      // Hill 1
      WorkoutStep(name: 'Base Incline', resistance: 18, durationSeconds: 120, targetCadence: 75),
      WorkoutStep(name: 'Steep Climb', resistance: 26, durationSeconds: 120, targetCadence: 60),
      WorkoutStep(name: 'Hill Peak', resistance: 30, durationSeconds: 60, targetCadence: 55),
      // Valley
      WorkoutStep(name: 'Downhill', resistance: 15, durationSeconds: 120, targetCadence: 95),
      // Hill 2
      WorkoutStep(name: 'Base Incline', resistance: 20, durationSeconds: 120, targetCadence: 70),
      WorkoutStep(name: 'Steep Climb', resistance: 28, durationSeconds: 120, targetCadence: 55),
      WorkoutStep(name: 'Hill Peak', resistance: 32, durationSeconds: 60, targetCadence: 50),
      // Valley
      WorkoutStep(name: 'Downhill', resistance: 15, durationSeconds: 120, targetCadence: 95),
      // Final Sprint
      WorkoutStep(name: 'Flat Road Sprint', resistance: 22, durationSeconds: 180, targetCadence: null),
      // Cooldown
      WorkoutStep(name: 'Cooldown', resistance: 8, durationSeconds: 240, targetCadence: 60),
    ],
    createdAt: DateTime(2024, 1, 1),
  ),

  // Power Pyramid - 30 min Endurance
  Workout(
    id: 'endurance_pyramid',
    name: '🔺 Power Pyramid',
    steps: [
      WorkoutStep(name: 'Warmup', resistance: 10, durationSeconds: 300, targetCadence: 85),
      // The Ascent
      WorkoutStep(name: 'Step 1', resistance: 16, durationSeconds: 120, targetCadence: 80),
      WorkoutStep(name: 'Step 2', resistance: 20, durationSeconds: 120, targetCadence: 75),
      WorkoutStep(name: 'Step 3', resistance: 24, durationSeconds: 120, targetCadence: 65),
      // The Peak
      WorkoutStep(name: 'THE PEAK', resistance: 30, durationSeconds: 120, targetCadence: 55),
      // The Descent
      WorkoutStep(name: 'Step 3', resistance: 24, durationSeconds: 120, targetCadence: 65),
      WorkoutStep(name: 'Step 2', resistance: 20, durationSeconds: 120, targetCadence: 75),
      WorkoutStep(name: 'Step 1', resistance: 16, durationSeconds: 120, targetCadence: 80),
      // Final flush
      WorkoutStep(name: 'Fast Spin', resistance: 12, durationSeconds: 60, targetCadence: 100),
      // Cooldown
      WorkoutStep(name: 'Cooldown', resistance: 8, durationSeconds: 180, targetCadence: 60),
    ],
    createdAt: DateTime(2024, 1, 1),
  ),
];
