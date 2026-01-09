/// Workout history storage service using Hive for persistence.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:echelon_connect/core/models/workout_session.dart';

const String _historyBoxName = 'workout_history';

/// Provider for the workout history storage service
final workoutHistoryStorageProvider = StateNotifierProvider<WorkoutHistoryStorageNotifier, List<WorkoutSession>>((ref) {
  return WorkoutHistoryStorageNotifier();
});

/// Notifier that manages workout history persistence and state
class WorkoutHistoryStorageNotifier extends StateNotifier<List<WorkoutSession>> {
  Box<WorkoutSession>? _box;
  late Future<void> _initFuture;

  WorkoutHistoryStorageNotifier() : super([]) {
    _initFuture = _init();
  }

  Future<void> _init() async {
    // Register adapter if not already registered
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(WorkoutSessionAdapter());
    }

    _box = await Hive.openBox<WorkoutSession>(_historyBoxName);

    // Load initial state, sorted by date (newest first)
    _updateState();
  }

  void _updateState() {
    if (_box == null) return;

    final list = _box!.values.toList();
    // Sort by date descending
    list.sort((a, b) => b.endTime.compareTo(a.endTime));
    state = list;
  }

  /// Save a completed workout session
  Future<void> saveSession(WorkoutSession session) async {
    await _initFuture;
    await _box?.put(session.id, session);
    _updateState();
  }

  /// Delete a session by ID
  Future<void> deleteSession(String id) async {
    await _initFuture;
    await _box?.delete(id);
    _updateState();
  }

  /// Clear all history
  Future<void> clearHistory() async {
    await _initFuture;
    await _box?.clear();
    _updateState();
  }
}
