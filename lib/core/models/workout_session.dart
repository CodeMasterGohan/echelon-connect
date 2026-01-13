/// Data model for completed workout sessions
library;

import 'package:hive/hive.dart';

@HiveType(typeId: 12)
class WorkoutSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String workoutId;

  @HiveField(2)
  final String workoutName;

  @HiveField(3)
  final DateTime startTime;

  @HiveField(4)
  final DateTime endTime;

  @HiveField(5)
  final int durationSeconds;

  @HiveField(6)
  final int totalCalories;

  @HiveField(7)
  final int avgPower;

  @HiveField(8)
  final int avgCadence;

  @HiveField(9)
  final double avgSpeed;

  @HiveField(10)
  final double distanceMiles;

  WorkoutSession({
    required this.id,
    required this.workoutId,
    required this.workoutName,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.totalCalories,
    required this.avgPower,
    required this.avgCadence,
    required this.avgSpeed,
    required this.distanceMiles,
  });

  /// Format duration as MM:SS or HH:MM:SS
  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  String toString() => 'WorkoutSession($workoutName: ${formattedDuration}, ${totalCalories}kcal)';
}

/// Hive TypeAdapter for WorkoutSession
class WorkoutSessionAdapter extends TypeAdapter<WorkoutSession> {
  @override
  final int typeId = 12;

  @override
  WorkoutSession read(BinaryReader reader) {
    return WorkoutSession(
      id: reader.read(),
      workoutId: reader.read(),
      workoutName: reader.read(),
      startTime: DateTime.fromMillisecondsSinceEpoch(reader.read()),
      endTime: DateTime.fromMillisecondsSinceEpoch(reader.read()),
      durationSeconds: reader.read(),
      totalCalories: reader.read(),
      avgPower: reader.read(),
      avgCadence: reader.read(),
      avgSpeed: reader.read(),
      distanceMiles: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSession obj) {
    writer.write(obj.id);
    writer.write(obj.workoutId);
    writer.write(obj.workoutName);
    writer.write(obj.startTime.millisecondsSinceEpoch);
    writer.write(obj.endTime.millisecondsSinceEpoch);
    writer.write(obj.durationSeconds);
    writer.write(obj.totalCalories);
    writer.write(obj.avgPower);
    writer.write(obj.avgCadence);
    writer.write(obj.avgSpeed);
    writer.write(obj.distanceMiles);
  }
}
