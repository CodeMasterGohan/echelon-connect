/// Pre-defined workout programs with difficulty variations.
/// These are hardcoded - no storage, no persistence, just reliable workouts.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:echelon_connect/core/models/workout.dart';

/// Workout difficulty levels
enum WorkoutDifficulty { easy, medium, hard }

/// Workout categories/styles
enum WorkoutCategory {
  intervalTraining,
  hillClimb,
  tabata,
  rollingHills,
  powerPyramid,
}

/// Extension for category display info
extension WorkoutCategoryExt on WorkoutCategory {
  String get displayName {
    switch (this) {
      case WorkoutCategory.intervalTraining:
        return 'Interval Training';
      case WorkoutCategory.hillClimb:
        return 'Hill Climb';
      case WorkoutCategory.tabata:
        return 'Tabata Sprints';
      case WorkoutCategory.rollingHills:
        return 'Rolling Hills';
      case WorkoutCategory.powerPyramid:
        return 'Power Pyramid';
    }
  }

  String get emoji {
    switch (this) {
      case WorkoutCategory.intervalTraining:
        return '⭐';
      case WorkoutCategory.hillClimb:
        return '⛰️';
      case WorkoutCategory.tabata:
        return '🔥';
      case WorkoutCategory.rollingHills:
        return '⛰️';
      case WorkoutCategory.powerPyramid:
        return '🔺';
    }
  }

  String get description {
    switch (this) {
      case WorkoutCategory.intervalTraining:
        return 'Alternating high and low intensity bursts';
      case WorkoutCategory.hillClimb:
        return 'Progressive resistance climb to the summit';
      case WorkoutCategory.tabata:
        return 'High intensity 20s ON / 10s OFF intervals';
      case WorkoutCategory.rollingHills:
        return 'Simulated terrain with peaks and valleys';
      case WorkoutCategory.powerPyramid:
        return 'Build up to peak resistance then descend';
    }
  }
}

/// Extension for difficulty display info
extension WorkoutDifficultyExt on WorkoutDifficulty {
  String get displayName {
    switch (this) {
      case WorkoutDifficulty.easy:
        return 'Easy';
      case WorkoutDifficulty.medium:
        return 'Medium';
      case WorkoutDifficulty.hard:
        return 'Hard';
    }
  }

  String get emoji {
    switch (this) {
      case WorkoutDifficulty.easy:
        return '🟢';
      case WorkoutDifficulty.medium:
        return '🟡';
      case WorkoutDifficulty.hard:
        return '🔴';
    }
  }
}

/// Provider for the list of available workouts
final workoutsProvider = Provider<List<Workout>>((ref) {
  return predefinedWorkouts;
});

/// Provider for workouts organized by category
final workoutsByCategoryProvider = Provider<Map<WorkoutCategory, Map<WorkoutDifficulty, Workout>>>((ref) {
  return workoutsByCategory;
});

/// Get workouts for a specific category
Map<WorkoutDifficulty, Workout> getWorkoutsForCategory(WorkoutCategory category) {
  return workoutsByCategory[category] ?? {};
}

/// All workouts organized by category and difficulty
final Map<WorkoutCategory, Map<WorkoutDifficulty, Workout>> workoutsByCategory = {
  // ============ INTERVAL TRAINING ============
  WorkoutCategory.intervalTraining: {
    WorkoutDifficulty.easy: Workout(
      id: 'interval_easy',
      name: '⭐ Interval Training - Easy',
      steps: [
        WorkoutStep(name: 'Warmup', resistance: 8, durationSeconds: 180, targetCadence: 75),
        WorkoutStep(name: 'Push', resistance: 18, durationSeconds: 30, targetCadence: 90),
        WorkoutStep(name: 'Recovery', resistance: 10, durationSeconds: 45, targetCadence: 70),
        WorkoutStep(name: 'Push', resistance: 18, durationSeconds: 30, targetCadence: 90),
        WorkoutStep(name: 'Recovery', resistance: 10, durationSeconds: 45, targetCadence: 70),
        WorkoutStep(name: 'Push', resistance: 18, durationSeconds: 30, targetCadence: 90),
        WorkoutStep(name: 'Cooldown', resistance: 6, durationSeconds: 180, targetCadence: 60),
      ],
      createdAt: DateTime(2024, 1, 1),
    ),
    WorkoutDifficulty.medium: Workout(
      id: 'interval_medium',
      name: '⭐ Interval Training - Medium',
      steps: [
        WorkoutStep(name: 'Warmup', resistance: 10, durationSeconds: 120, targetCadence: 80),
        WorkoutStep(name: 'Push', resistance: 25, durationSeconds: 30, targetCadence: null),
        WorkoutStep(name: 'Recovery', resistance: 12, durationSeconds: 30, targetCadence: 70),
        WorkoutStep(name: 'Push', resistance: 25, durationSeconds: 30, targetCadence: null),
        WorkoutStep(name: 'Recovery', resistance: 12, durationSeconds: 30, targetCadence: 70),
        WorkoutStep(name: 'Push', resistance: 25, durationSeconds: 30, targetCadence: null),
        WorkoutStep(name: 'Cooldown', resistance: 8, durationSeconds: 120, targetCadence: 60),
      ],
      createdAt: DateTime(2024, 1, 1),
    ),
    WorkoutDifficulty.hard: Workout(
      id: 'interval_hard',
      name: '⭐ Interval Training - Hard',
      steps: [
        WorkoutStep(name: 'Warmup', resistance: 12, durationSeconds: 120, targetCadence: 85),
        WorkoutStep(name: 'Push', resistance: 30, durationSeconds: 40, targetCadence: null),
        WorkoutStep(name: 'Recovery', resistance: 14, durationSeconds: 20, targetCadence: 75),
        WorkoutStep(name: 'Push', resistance: 30, durationSeconds: 40, targetCadence: null),
        WorkoutStep(name: 'Recovery', resistance: 14, durationSeconds: 20, targetCadence: 75),
        WorkoutStep(name: 'Push', resistance: 30, durationSeconds: 40, targetCadence: null),
        WorkoutStep(name: 'Recovery', resistance: 14, durationSeconds: 20, targetCadence: 75),
        WorkoutStep(name: 'Push', resistance: 32, durationSeconds: 40, targetCadence: null),
        WorkoutStep(name: 'Cooldown', resistance: 8, durationSeconds: 120, targetCadence: 60),
      ],
      createdAt: DateTime(2024, 1, 1),
    ),
  },

  // ============ HILL CLIMB ============
  WorkoutCategory.hillClimb: {
    WorkoutDifficulty.easy: Workout(
      id: 'hill_easy',
      name: '⛰️ Hill Climb - Easy',
      steps: [
        WorkoutStep(name: 'Warmup', resistance: 8, durationSeconds: 180, targetCadence: 85),
        WorkoutStep(name: 'Climb 1', resistance: 14, durationSeconds: 60, targetCadence: 75),
        WorkoutStep(name: 'Climb 2', resistance: 18, durationSeconds: 60, targetCadence: 70),
        WorkoutStep(name: 'Summit', resistance: 22, durationSeconds: 45, targetCadence: 65),
        WorkoutStep(name: 'Descent', resistance: 12, durationSeconds: 120, targetCadence: 90),
        WorkoutStep(name: 'Cooldown', resistance: 6, durationSeconds: 120, targetCadence: 60),
      ],
      createdAt: DateTime(2024, 1, 1),
    ),
    WorkoutDifficulty.medium: Workout(
      id: 'hill_medium',
      name: '⛰️ Hill Climb - Medium',
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
    WorkoutDifficulty.hard: Workout(
      id: 'hill_hard',
      name: '⛰️ Hill Climb - Hard',
      steps: [
        WorkoutStep(name: 'Warmup', resistance: 12, durationSeconds: 180, targetCadence: 85),
        WorkoutStep(name: 'Climb 1', resistance: 20, durationSeconds: 60, targetCadence: 70),
        WorkoutStep(name: 'Climb 2', resistance: 24, durationSeconds: 60, targetCadence: 65),
        WorkoutStep(name: 'Climb 3', resistance: 28, durationSeconds: 60, targetCadence: 60),
        WorkoutStep(name: 'Climb 4', resistance: 30, durationSeconds: 60, targetCadence: 55),
        WorkoutStep(name: 'Summit', resistance: 32, durationSeconds: 60, targetCadence: 50),
        WorkoutStep(name: 'Recovery', resistance: 18, durationSeconds: 60, targetCadence: 75),
        WorkoutStep(name: 'Second Peak', resistance: 32, durationSeconds: 45, targetCadence: null),
        WorkoutStep(name: 'Descent', resistance: 15, durationSeconds: 90, targetCadence: 90),
        WorkoutStep(name: 'Cooldown', resistance: 8, durationSeconds: 120, targetCadence: 60),
      ],
      createdAt: DateTime(2024, 1, 1),
    ),
  },

  // ============ TABATA SPRINTS ============
  WorkoutCategory.tabata: {
    WorkoutDifficulty.easy: Workout(
      id: 'tabata_easy',
      name: '🔥 Tabata Sprints - Easy',
      steps: [
        WorkoutStep(name: 'Warmup Easy', resistance: 8, durationSeconds: 180, targetCadence: 80),
        WorkoutStep(name: 'Warmup Moderate', resistance: 12, durationSeconds: 120, targetCadence: 85),
        // 4x (20s ON / 10s OFF) at lower resistance
        for (int i = 0; i < 4; i++) ...[
          WorkoutStep(name: 'SPRINT!', resistance: 20, durationSeconds: 20, targetCadence: null),
          WorkoutStep(name: 'Rest', resistance: 8, durationSeconds: 15, targetCadence: 60),
        ],
        WorkoutStep(name: 'Recovery Spin', resistance: 10, durationSeconds: 180, targetCadence: 75),
        // Another 4x at slightly higher
        for (int i = 0; i < 4; i++) ...[
          WorkoutStep(name: 'SPRINT!', resistance: 22, durationSeconds: 20, targetCadence: null),
          WorkoutStep(name: 'Rest', resistance: 8, durationSeconds: 15, targetCadence: 60),
        ],
        WorkoutStep(name: 'Cooldown', resistance: 6, durationSeconds: 180, targetCadence: 60),
      ],
      createdAt: DateTime(2024, 1, 1),
    ),
    WorkoutDifficulty.medium: Workout(
      id: 'tabata_medium',
      name: '🔥 Tabata Sprints - Medium',
      steps: [
        WorkoutStep(name: 'Warmup Easy', resistance: 10, durationSeconds: 120, targetCadence: 80),
        WorkoutStep(name: 'Warmup Moderate', resistance: 15, durationSeconds: 120, targetCadence: 85),
        WorkoutStep(name: 'Pre-Sprint Spin', resistance: 18, durationSeconds: 60, targetCadence: 90),
        // Set 1: 8x (20s ON / 10s OFF)
        for (int i = 0; i < 8; i++) ...[
          WorkoutStep(name: 'SPRINT!', resistance: 25, durationSeconds: 20, targetCadence: null),
          WorkoutStep(name: 'Rest', resistance: 8, durationSeconds: 10, targetCadence: 60),
        ],
        WorkoutStep(name: 'Recovery Spin', resistance: 12, durationSeconds: 180, targetCadence: 75),
        // Set 2: 8x (20s ON / 10s OFF) - higher resistance
        for (int i = 0; i < 8; i++) ...[
          WorkoutStep(name: 'POWER SPRINT!', resistance: 28, durationSeconds: 20, targetCadence: null),
          WorkoutStep(name: 'Rest', resistance: 8, durationSeconds: 10, targetCadence: 60),
        ],
        WorkoutStep(name: 'Recovery Spin', resistance: 12, durationSeconds: 180, targetCadence: 75),
        // Set 3: 4x (30s ON / 30s OFF)
        for (int i = 0; i < 4; i++) ...[
          WorkoutStep(name: 'Long Sprint', resistance: 24, durationSeconds: 30, targetCadence: null),
          WorkoutStep(name: 'Easy Spin', resistance: 10, durationSeconds: 30, targetCadence: 70),
        ],
        WorkoutStep(name: 'Cooldown', resistance: 8, durationSeconds: 180, targetCadence: 60),
      ],
      createdAt: DateTime(2024, 1, 1),
    ),
    WorkoutDifficulty.hard: Workout(
      id: 'tabata_hard',
      name: '🔥 Tabata Sprints - Hard',
      steps: [
        WorkoutStep(name: 'Warmup Easy', resistance: 12, durationSeconds: 120, targetCadence: 80),
        WorkoutStep(name: 'Warmup Moderate', resistance: 18, durationSeconds: 120, targetCadence: 85),
        WorkoutStep(name: 'Pre-Sprint', resistance: 22, durationSeconds: 60, targetCadence: 95),
        // Set 1: 10x (20s ON / 8s OFF) at high resistance
        for (int i = 0; i < 10; i++) ...[
          WorkoutStep(name: 'MAX SPRINT!', resistance: 30, durationSeconds: 20, targetCadence: null),
          WorkoutStep(name: 'Rest', resistance: 10, durationSeconds: 8, targetCadence: 60),
        ],
        WorkoutStep(name: 'Recovery', resistance: 14, durationSeconds: 120, targetCadence: 75),
        // Set 2: 10x (20s ON / 8s OFF) at max resistance
        for (int i = 0; i < 10; i++) ...[
          WorkoutStep(name: 'ULTIMATE!', resistance: 32, durationSeconds: 20, targetCadence: null),
          WorkoutStep(name: 'Rest', resistance: 10, durationSeconds: 8, targetCadence: 60),
        ],
        WorkoutStep(name: 'Recovery', resistance: 14, durationSeconds: 120, targetCadence: 75),
        // Finisher: 5x (30s ON / 15s OFF)
        for (int i = 0; i < 5; i++) ...[
          WorkoutStep(name: 'FINISHER!', resistance: 28, durationSeconds: 30, targetCadence: null),
          WorkoutStep(name: 'Brief Rest', resistance: 12, durationSeconds: 15, targetCadence: 70),
        ],
        WorkoutStep(name: 'Cooldown', resistance: 8, durationSeconds: 180, targetCadence: 60),
      ],
      createdAt: DateTime(2024, 1, 1),
    ),
  },

  // ============ ROLLING HILLS ============
  WorkoutCategory.rollingHills: {
    WorkoutDifficulty.easy: Workout(
      id: 'rolling_easy',
      name: '⛰️ Rolling Hills - Easy',
      steps: [
        WorkoutStep(name: 'Warmup', resistance: 8, durationSeconds: 300, targetCadence: 85),
        // Hill 1 - gentle
        WorkoutStep(name: 'Base Incline', resistance: 14, durationSeconds: 120, targetCadence: 80),
        WorkoutStep(name: 'Gentle Climb', resistance: 18, durationSeconds: 90, targetCadence: 70),
        WorkoutStep(name: 'Hill Peak', resistance: 22, durationSeconds: 45, targetCadence: 65),
        WorkoutStep(name: 'Downhill', resistance: 12, durationSeconds: 150, targetCadence: 95),
        // Hill 2 - similar
        WorkoutStep(name: 'Base Incline', resistance: 16, durationSeconds: 120, targetCadence: 75),
        WorkoutStep(name: 'Gentle Climb', resistance: 20, durationSeconds: 90, targetCadence: 70),
        WorkoutStep(name: 'Hill Peak', resistance: 24, durationSeconds: 45, targetCadence: 60),
        WorkoutStep(name: 'Downhill', resistance: 12, durationSeconds: 150, targetCadence: 95),
        WorkoutStep(name: 'Cooldown', resistance: 6, durationSeconds: 240, targetCadence: 60),
      ],
      createdAt: DateTime(2024, 1, 1),
    ),
    WorkoutDifficulty.medium: Workout(
      id: 'rolling_medium',
      name: '⛰️ Rolling Hills - Medium',
      steps: [
        WorkoutStep(name: 'Warmup', resistance: 10, durationSeconds: 300, targetCadence: 85),
        // Hill 1
        WorkoutStep(name: 'Base Incline', resistance: 18, durationSeconds: 120, targetCadence: 75),
        WorkoutStep(name: 'Steep Climb', resistance: 26, durationSeconds: 120, targetCadence: 60),
        WorkoutStep(name: 'Hill Peak', resistance: 30, durationSeconds: 60, targetCadence: 55),
        WorkoutStep(name: 'Downhill', resistance: 15, durationSeconds: 120, targetCadence: 95),
        // Hill 2
        WorkoutStep(name: 'Base Incline', resistance: 20, durationSeconds: 120, targetCadence: 70),
        WorkoutStep(name: 'Steep Climb', resistance: 28, durationSeconds: 120, targetCadence: 55),
        WorkoutStep(name: 'Hill Peak', resistance: 32, durationSeconds: 60, targetCadence: 50),
        WorkoutStep(name: 'Downhill', resistance: 15, durationSeconds: 120, targetCadence: 95),
        // Final Sprint
        WorkoutStep(name: 'Flat Road Sprint', resistance: 22, durationSeconds: 180, targetCadence: null),
        WorkoutStep(name: 'Cooldown', resistance: 8, durationSeconds: 240, targetCadence: 60),
      ],
      createdAt: DateTime(2024, 1, 1),
    ),
    WorkoutDifficulty.hard: Workout(
      id: 'rolling_hard',
      name: '⛰️ Rolling Hills - Hard',
      steps: [
        WorkoutStep(name: 'Warmup', resistance: 12, durationSeconds: 300, targetCadence: 85),
        // Hill 1 - steep
        WorkoutStep(name: 'Base Incline', resistance: 20, durationSeconds: 90, targetCadence: 75),
        WorkoutStep(name: 'Steep Climb', resistance: 28, durationSeconds: 90, targetCadence: 60),
        WorkoutStep(name: 'Summit Push', resistance: 32, durationSeconds: 60, targetCadence: null),
        WorkoutStep(name: 'Downhill', resistance: 16, durationSeconds: 90, targetCadence: 95),
        // Hill 2 - steeper
        WorkoutStep(name: 'Base Incline', resistance: 22, durationSeconds: 90, targetCadence: 70),
        WorkoutStep(name: 'Steep Climb', resistance: 30, durationSeconds: 90, targetCadence: 55),
        WorkoutStep(name: 'Summit Push', resistance: 32, durationSeconds: 75, targetCadence: null),
        WorkoutStep(name: 'Downhill', resistance: 16, durationSeconds: 90, targetCadence: 95),
        // Hill 3 - max
        WorkoutStep(name: 'Base Incline', resistance: 24, durationSeconds: 90, targetCadence: 65),
        WorkoutStep(name: 'Max Climb', resistance: 32, durationSeconds: 120, targetCadence: null),
        WorkoutStep(name: 'Downhill', resistance: 16, durationSeconds: 90, targetCadence: 95),
        // Final sprint
        WorkoutStep(name: 'Flat Road Sprint', resistance: 26, durationSeconds: 180, targetCadence: null),
        WorkoutStep(name: 'Cooldown', resistance: 8, durationSeconds: 240, targetCadence: 60),
      ],
      createdAt: DateTime(2024, 1, 1),
    ),
  },

  // ============ POWER PYRAMID ============
  WorkoutCategory.powerPyramid: {
    WorkoutDifficulty.easy: Workout(
      id: 'pyramid_easy',
      name: '🔺 Power Pyramid - Easy',
      steps: [
        WorkoutStep(name: 'Warmup', resistance: 8, durationSeconds: 300, targetCadence: 85),
        // Ascent
        WorkoutStep(name: 'Step 1', resistance: 12, durationSeconds: 120, targetCadence: 85),
        WorkoutStep(name: 'Step 2', resistance: 16, durationSeconds: 120, targetCadence: 80),
        WorkoutStep(name: 'Step 3', resistance: 20, durationSeconds: 120, targetCadence: 70),
        // Peak
        WorkoutStep(name: 'THE PEAK', resistance: 24, durationSeconds: 90, targetCadence: 65),
        // Descent
        WorkoutStep(name: 'Step 3', resistance: 20, durationSeconds: 120, targetCadence: 70),
        WorkoutStep(name: 'Step 2', resistance: 16, durationSeconds: 120, targetCadence: 80),
        WorkoutStep(name: 'Step 1', resistance: 12, durationSeconds: 120, targetCadence: 85),
        WorkoutStep(name: 'Fast Spin', resistance: 10, durationSeconds: 60, targetCadence: 100),
        WorkoutStep(name: 'Cooldown', resistance: 6, durationSeconds: 180, targetCadence: 60),
      ],
      createdAt: DateTime(2024, 1, 1),
    ),
    WorkoutDifficulty.medium: Workout(
      id: 'pyramid_medium',
      name: '🔺 Power Pyramid - Medium',
      steps: [
        WorkoutStep(name: 'Warmup', resistance: 10, durationSeconds: 300, targetCadence: 85),
        // Ascent
        WorkoutStep(name: 'Step 1', resistance: 16, durationSeconds: 120, targetCadence: 80),
        WorkoutStep(name: 'Step 2', resistance: 20, durationSeconds: 120, targetCadence: 75),
        WorkoutStep(name: 'Step 3', resistance: 24, durationSeconds: 120, targetCadence: 65),
        // Peak
        WorkoutStep(name: 'THE PEAK', resistance: 30, durationSeconds: 120, targetCadence: 55),
        // Descent
        WorkoutStep(name: 'Step 3', resistance: 24, durationSeconds: 120, targetCadence: 65),
        WorkoutStep(name: 'Step 2', resistance: 20, durationSeconds: 120, targetCadence: 75),
        WorkoutStep(name: 'Step 1', resistance: 16, durationSeconds: 120, targetCadence: 80),
        WorkoutStep(name: 'Fast Spin', resistance: 12, durationSeconds: 60, targetCadence: 100),
        WorkoutStep(name: 'Cooldown', resistance: 8, durationSeconds: 180, targetCadence: 60),
      ],
      createdAt: DateTime(2024, 1, 1),
    ),
    WorkoutDifficulty.hard: Workout(
      id: 'pyramid_hard',
      name: '🔺 Power Pyramid - Hard',
      steps: [
        WorkoutStep(name: 'Warmup', resistance: 12, durationSeconds: 300, targetCadence: 85),
        // Ascent
        WorkoutStep(name: 'Step 1', resistance: 18, durationSeconds: 90, targetCadence: 80),
        WorkoutStep(name: 'Step 2', resistance: 22, durationSeconds: 90, targetCadence: 75),
        WorkoutStep(name: 'Step 3', resistance: 26, durationSeconds: 90, targetCadence: 65),
        WorkoutStep(name: 'Step 4', resistance: 30, durationSeconds: 90, targetCadence: 55),
        // Peak - extended
        WorkoutStep(name: 'THE PEAK', resistance: 32, durationSeconds: 180, targetCadence: null),
        // Descent
        WorkoutStep(name: 'Step 4', resistance: 30, durationSeconds: 90, targetCadence: 55),
        WorkoutStep(name: 'Step 3', resistance: 26, durationSeconds: 90, targetCadence: 65),
        WorkoutStep(name: 'Step 2', resistance: 22, durationSeconds: 90, targetCadence: 75),
        WorkoutStep(name: 'Step 1', resistance: 18, durationSeconds: 90, targetCadence: 80),
        // Second mini pyramid
        WorkoutStep(name: 'Quick Peak', resistance: 28, durationSeconds: 60, targetCadence: null),
        WorkoutStep(name: 'Drop', resistance: 16, durationSeconds: 60, targetCadence: 90),
        WorkoutStep(name: 'Fast Spin', resistance: 14, durationSeconds: 60, targetCadence: 105),
        WorkoutStep(name: 'Cooldown', resistance: 8, durationSeconds: 180, targetCadence: 60),
      ],
      createdAt: DateTime(2024, 1, 1),
    ),
  },
};

/// Flat list of all workouts (for backward compatibility)
final List<Workout> predefinedWorkouts = workoutsByCategory.values
    .expand((difficultyMap) => difficultyMap.values)
    .toList();
