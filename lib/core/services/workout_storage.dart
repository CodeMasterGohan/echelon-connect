/// Workout storage service using Hive for persistence.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:echelon_connect/core/models/workout.dart';

const String _workoutsBoxName = 'workouts';

/// Provider for the workout storage service
final workoutStorageProvider = StateNotifierProvider<WorkoutStorageNotifier, List<Workout>>((ref) {
  return WorkoutStorageNotifier();
});

/// Notifier that manages workout persistence and state
class WorkoutStorageNotifier extends StateNotifier<List<Workout>> {
  Box<Workout>? _box;

  WorkoutStorageNotifier() : super([]) {
    _init();
  }

  Future<void> _init() async {
    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(WorkoutStepAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(WorkoutAdapter());
    }

    _box = await Hive.openBox<Workout>(_workoutsBoxName);
    
    // Ensure sample workouts exist on startup
    await ensureSampleWorkouts();
  }

  /// Add a new workout
  Future<void> addWorkout(Workout workout) async {
    await _box?.put(workout.id, workout);
    state = _box?.values.toList() ?? [];
  }

  /// Update an existing workout
  Future<void> updateWorkout(Workout workout) async {
    await _box?.put(workout.id, workout);
    state = _box?.values.toList() ?? [];
  }

  /// Delete a workout by ID
  Future<void> deleteWorkout(String id) async {
    await _box?.delete(id);
    state = _box?.values.toList() ?? [];
  }

  /// Get a workout by ID
  Workout? getWorkout(String id) {
    return _box?.get(id);
  }

  /// Mark workout as used (updates lastUsedAt)
  Future<void> markAsUsed(String id) async {
    final workout = _box?.get(id);
    if (workout != null) {
      final updated = workout.copyWith(lastUsedAt: DateTime.now());
      await _box?.put(id, updated);
      state = _box?.values.toList() ?? [];
    }
  }

  /// Sample workout IDs (fixed so they persist)
  static const String _sampleIntervalId = 'sample_interval_training';
  static const String _sampleHillClimbId = 'sample_hill_climb';

  /// Ensure sample workouts always exist
  Future<void> ensureSampleWorkouts() async {
    if (_box == null) return;

    // Check if sample workouts exist by their fixed IDs
    if (_box!.get(_sampleIntervalId) == null) {
      await _box!.put(
        _sampleIntervalId,
        Workout(
          id: _sampleIntervalId,
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
      );
    }

    if (_box!.get(_sampleHillClimbId) == null) {
      await _box!.put(
        _sampleHillClimbId,
        Workout(
          id: _sampleHillClimbId,
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
      );
    }

    // Tabata Sprints - 30 min HIIT
    if (_box!.get('tabata_30_min') == null) {
      await _box!.put(
        'tabata_30_min',
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
              WorkoutStep(name: 'SPRINT!', resistance: 25, durationSeconds: 20, targetCadence: null), // MAX
              WorkoutStep(name: 'Rest', resistance: 8, durationSeconds: 10, targetCadence: 60),
            ],
            // 3 min Active Recovery
            WorkoutStep(name: 'Recovery Spin', resistance: 12, durationSeconds: 180, targetCadence: 75),
            // Set 2: 8x (20s ON / 10s OFF) - higher resistance
            for (int i = 0; i < 8; i++) ...[
              WorkoutStep(name: 'POWER SPRINT!', resistance: 28, durationSeconds: 20, targetCadence: null), // MAX
              WorkoutStep(name: 'Rest', resistance: 8, durationSeconds: 10, targetCadence: 60),
            ],
            // 3 min Active Recovery
            WorkoutStep(name: 'Recovery Spin', resistance: 12, durationSeconds: 180, targetCadence: 75),
            // Set 3: 4x (30s ON / 30s OFF) - Endurance Sprints
            for (int i = 0; i < 4; i++) ...[
              WorkoutStep(name: 'Long Sprint', resistance: 24, durationSeconds: 30, targetCadence: null), // MAX
              WorkoutStep(name: 'Easy Spin', resistance: 10, durationSeconds: 30, targetCadence: 70),
            ],
            // Cooldown
            WorkoutStep(name: 'Cooldown', resistance: 8, durationSeconds: 180, targetCadence: 60),
          ],
          createdAt: DateTime(2024, 1, 1),
        ),
      );
    }

    // Rolling Hills - 30 min Endurance
    if (_box!.get('rolling_hills_30') == null) {
      await _box!.put(
        'rolling_hills_30',
        Workout(
          id: 'rolling_hills_30',
          name: '⛰️ Rolling Hills',
          steps: [
            // 5 min Warmup
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
            WorkoutStep(name: 'Flat Road Sprint', resistance: 22, durationSeconds: 180, targetCadence: null), // MAX
            // Cooldown
            WorkoutStep(name: 'Cooldown', resistance: 8, durationSeconds: 240, targetCadence: 60),
          ],
          createdAt: DateTime(2024, 1, 1),
        ),
      );
    }

    // Power Pyramid - 30 min Endurance
    if (_box!.get('endurance_pyramid') == null) {
      await _box!.put(
        'endurance_pyramid',
        Workout(
          id: 'endurance_pyramid',
          name: '🔺 Power Pyramid',
          steps: [
            // Warmup
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
      );
    }

    state = _box!.values.toList();
  }
}
