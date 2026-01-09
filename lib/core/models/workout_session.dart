/// WorkoutSession - Hive model for persisting completed workouts
library;

import 'package:hive/hive.dart';

/// Represents a completed workout session
class WorkoutSession extends HiveObject {
  /// Unique identifier for the session
  final String id;

  /// When the workout started
  final DateTime startTime;

  /// When the workout ended
  final DateTime endTime;

  /// Total duration in seconds
  final int durationSeconds;

  /// Total distance in kilometers
  final double distanceKm;

  /// Average cadence (RPM)
  final int averageCadence;

  /// Average resistance level (1-32)
  final int averageResistance;

  /// Average power in watts
  final int averagePower;

  /// Total energy output in kilojoules
  final double totalOutputKj;

  /// Total calories burned
  final double calories;

  WorkoutSession({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.distanceKm,
    required this.averageCadence,
    required this.averageResistance,
    required this.averagePower,
    required this.totalOutputKj,
    required this.calories,
  });

  /// Calculate duration as a formatted string (HH:MM:SS or MM:SS)
  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  String toString() =>
      'WorkoutSession(id: $id, duration: $formattedDuration, power: ${averagePower}W, output: ${totalOutputKj.toStringAsFixed(1)}kJ)';
}

/// Hive TypeAdapter for WorkoutSession
/// Type ID: 0
class WorkoutSessionAdapter extends TypeAdapter<WorkoutSession> {
  @override
  final int typeId = 0;

  @override
  WorkoutSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutSession(
      id: fields[0] as String,
      startTime: fields[1] as DateTime,
      endTime: fields[2] as DateTime,
      durationSeconds: fields[3] as int,
      distanceKm: fields[4] as double,
      averageCadence: fields[5] as int,
      averageResistance: fields[6] as int,
      averagePower: fields[7] as int,
      totalOutputKj: fields[8] as double,
      calories: fields[9] as double,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSession obj) {
    writer
      ..writeByte(10) // Number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.durationSeconds)
      ..writeByte(4)
      ..write(obj.distanceKm)
      ..writeByte(5)
      ..write(obj.averageCadence)
      ..writeByte(6)
      ..write(obj.averageResistance)
      ..writeByte(7)
      ..write(obj.averagePower)
      ..writeByte(8)
      ..write(obj.totalOutputKj)
      ..writeByte(9)
      ..write(obj.calories);
  }
}
