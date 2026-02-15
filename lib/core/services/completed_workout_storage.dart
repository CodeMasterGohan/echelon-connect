/// Completed workout storage - Hive-backed persistence for workout history.
library;

import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:echelon_connect/core/models/workout.dart';

/// Box name for completed workouts
const String completedWorkoutsBoxName = 'completed_workouts';

/// Storage service for completed workouts
class CompletedWorkoutStorage {
  late Box<CompletedWorkout> _box;

  /// Initialize the storage (open Hive box)
  Future<void> init() async {
    _box = await Hive.openBox<CompletedWorkout>(completedWorkoutsBoxName);
  }

  /// Save a completed workout
  Future<void> saveCompletedWorkout(CompletedWorkout workout) async {
    await _box.put(workout.id, workout);
  }

  /// Get all completed workouts, sorted by date descending (most recent first)
  List<CompletedWorkout> getAllCompletedWorkouts() {
    final workouts = _box.values.toList();
    workouts.sort((a, b) => b.completionDate.compareTo(a.completionDate));
    return workouts;
  }

  /// Delete a completed workout by ID
  Future<void> deleteCompletedWorkout(String id) async {
    await _box.delete(id);
  }

  /// Get completed workouts for a specific user
  List<CompletedWorkout> getWorkoutsForUser(String user) {
    return getAllCompletedWorkouts()
        .where((w) => w.user == user)
        .toList();
  }

  /// Get the number of completed workouts
  int get count => _box.length;
}

/// Singleton instance provider for the storage service
final completedWorkoutStorageProvider = Provider<CompletedWorkoutStorage>((ref) {
  return CompletedWorkoutStorage();
});

/// State notifier for the list of completed workouts (reactive updates)
class CompletedWorkoutsNotifier extends StateNotifier<List<CompletedWorkout>> {
  final CompletedWorkoutStorage _storage;

  CompletedWorkoutsNotifier(this._storage) : super(_storage.getAllCompletedWorkouts());

  /// Add a completed workout and refresh the list
  Future<void> addCompletedWorkout(CompletedWorkout workout) async {
    await _storage.saveCompletedWorkout(workout);
    state = _storage.getAllCompletedWorkouts();
  }

  /// Remove a completed workout and refresh the list
  Future<void> removeCompletedWorkout(String id) async {
    await _storage.deleteCompletedWorkout(id);
    state = _storage.getAllCompletedWorkouts();
  }

  /// Refresh the list from storage
  void refresh() {
    state = _storage.getAllCompletedWorkouts();
  }
}

/// Provider for the completed workouts list (reactive)
final completedWorkoutsProvider =
    StateNotifierProvider<CompletedWorkoutsNotifier, List<CompletedWorkout>>((ref) {
  final storage = ref.watch(completedWorkoutStorageProvider);
  return CompletedWorkoutsNotifier(storage);
});
