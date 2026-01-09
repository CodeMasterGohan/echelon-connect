/// History Repository - Manages workout session persistence
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'package:echelon_connect/core/models/workout_session.dart';

/// Repository for managing workout history persistence
class HistoryRepository {
  static const String boxName = 'workout_sessions';

  final Box<WorkoutSession> _box;

  HistoryRepository(this._box);

  /// Save a completed workout session
  Future<void> saveSession(WorkoutSession session) async {
    await _box.put(session.id, session);
  }

  /// Get all workout sessions, sorted by start time (newest first)
  List<WorkoutSession> getAllSessions() {
    final sessions = _box.values.toList();
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    return sessions;
  }

  /// Delete a workout session by ID
  Future<void> deleteSession(String id) async {
    await _box.delete(id);
  }

  /// Get sessions since a specific date
  List<WorkoutSession> getSessionsSince(DateTime since) {
    return getAllSessions()
        .where((session) => session.startTime.isAfter(since))
        .toList();
  }

  /// Get total workout count
  int get sessionCount => _box.length;

  /// Get sessions from the last N days
  List<WorkoutSession> getRecentSessions(int days) {
    final since = DateTime.now().subtract(Duration(days: days));
    return getSessionsSince(since);
  }

  /// Calculate total workout time in seconds for all sessions
  int getTotalWorkoutSeconds() {
    return _box.values.fold(0, (sum, session) => sum + session.durationSeconds);
  }

  /// Calculate total distance across all sessions
  double getTotalDistance() {
    return _box.values.fold(0.0, (sum, session) => sum + session.distanceKm);
  }

  /// Calculate total calories burned across all sessions
  double getTotalCalories() {
    return _box.values.fold(0.0, (sum, session) => sum + session.calories);
  }
}

/// Provider for the History Repository
/// Requires the Hive box to be opened before use
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final box = Hive.box<WorkoutSession>(HistoryRepository.boxName);
  return HistoryRepository(box);
});

/// Provider for the list of all workout sessions (auto-updates)
final workoutSessionsProvider = Provider<List<WorkoutSession>>((ref) {
  final repository = ref.watch(historyRepositoryProvider);
  return repository.getAllSessions();
});
