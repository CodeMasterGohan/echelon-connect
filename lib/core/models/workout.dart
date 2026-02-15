/// Data models for custom workouts with manual Hive adapters.
library;

import 'package:hive/hive.dart';

/// A single step in a workout (e.g., "Resistance 20 for 2 minutes")
class WorkoutStep {
  final String? name;
  final int resistance; // 1-32
  final int durationSeconds;
  final int? targetCadence; // null = MAX effort, otherwise target RPM

  WorkoutStep({
    this.name,
    required this.resistance,
    required this.durationSeconds,
    this.targetCadence,
  });

  /// Copy with modifications
  WorkoutStep copyWith({
    String? name,
    int? resistance,
    int? durationSeconds,
    int? targetCadence,
  }) {
    return WorkoutStep(
      name: name ?? this.name,
      resistance: resistance ?? this.resistance,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      targetCadence: targetCadence ?? this.targetCadence,
    );
  }

  /// Format duration as MM:SS
  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format target cadence as string (e.g., "80 RPM" or "MAX")
  String get formattedCadence => targetCadence != null ? '$targetCadence' : 'MAX';

  Map<String, dynamic> toJson() => {
    'name': name,
    'resistance': resistance,
    'durationSeconds': durationSeconds,
    'targetCadence': targetCadence,
  };

  factory WorkoutStep.fromJson(Map<String, dynamic> json) => WorkoutStep(
    name: json['name'] as String?,
    resistance: json['resistance'] as int,
    durationSeconds: json['durationSeconds'] as int,
    targetCadence: json['targetCadence'] as int?,
  );

  @override
  String toString() => 'WorkoutStep(${name ?? "Step"}: R$resistance for ${formattedDuration})';
}

/// A complete workout with multiple steps
class Workout {
  final String id;
  final String name;
  final List<WorkoutStep> steps;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  Workout({
    required this.id,
    required this.name,
    required this.steps,
    required this.createdAt,
    this.lastUsedAt,
  });

  /// Create a new workout with a generated ID
  factory Workout.create({
    required String name,
    required List<WorkoutStep> steps,
  }) {
    return Workout(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      steps: steps,
      createdAt: DateTime.now(),
    );
  }

  /// Copy with modifications
  Workout copyWith({
    String? id,
    String? name,
    List<WorkoutStep>? steps,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      steps: steps ?? this.steps,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  /// Total duration of all steps
  int get totalDurationSeconds =>
      steps.fold(0, (sum, step) => sum + step.durationSeconds);

  /// Format total duration
  String get formattedTotalDuration {
    final total = totalDurationSeconds;
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  /// Number of steps
  int get stepCount => steps.length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'steps': steps.map((s) => s.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'lastUsedAt': lastUsedAt?.toIso8601String(),
  };

  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
    id: json['id'] as String,
    name: json['name'] as String,
    steps: (json['steps'] as List).map((s) => WorkoutStep.fromJson(s as Map<String, dynamic>)).toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastUsedAt: json['lastUsedAt'] != null ? DateTime.parse(json['lastUsedAt'] as String) : null,
  );

  @override
  String toString() => 'Workout($name: $stepCount steps, $formattedTotalDuration)';
}

/// Hive TypeAdapter for WorkoutStep
class WorkoutStepAdapter extends TypeAdapter<WorkoutStep> {
  @override
  final int typeId = 10;

  @override
  WorkoutStep read(BinaryReader reader) {
    return WorkoutStep(
      name: reader.read() as String?,
      resistance: reader.read() as int,
      durationSeconds: reader.read() as int,
      targetCadence: reader.read() as int?,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutStep obj) {
    writer.write(obj.name);
    writer.write(obj.resistance);
    writer.write(obj.durationSeconds);
    writer.write(obj.targetCadence);
  }
}

/// Hive TypeAdapter for Workout
class WorkoutAdapter extends TypeAdapter<Workout> {
  @override
  final int typeId = 11;

  @override
  Workout read(BinaryReader reader) {
    final id = reader.read() as String;
    final name = reader.read() as String;
    final steps = (reader.read() as List).cast<WorkoutStep>();
    final createdAtMs = reader.read() as int;
    final lastUsedAtMs = reader.read() as int?;
    
    return Workout(
      id: id,
      name: name,
      steps: steps,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      lastUsedAt: lastUsedAtMs != null ? DateTime.fromMillisecondsSinceEpoch(lastUsedAtMs) : null,
    );
  }

  @override
  void write(BinaryWriter writer, Workout obj) {
    writer.write(obj.id);
    writer.write(obj.name);
    writer.write(obj.steps);
    writer.write(obj.createdAt.millisecondsSinceEpoch);
    writer.write(obj.lastUsedAt?.millisecondsSinceEpoch);
  }
}

/// A completed workout record with score and user attribution
class CompletedWorkout {
  final String id;
  final String workoutName;
  final String workoutId;
  final DateTime completionDate;
  final int score; // 0-100
  final String user; // "Russell" or "Haley"
  final int totalDurationSeconds;

  CompletedWorkout({
    required this.id,
    required this.workoutName,
    required this.workoutId,
    required this.completionDate,
    required this.score,
    required this.user,
    required this.totalDurationSeconds,
  });

  /// Create a new completed workout with a generated ID
  factory CompletedWorkout.create({
    required String workoutName,
    required String workoutId,
    required int score,
    required String user,
    required int totalDurationSeconds,
  }) {
    return CompletedWorkout(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      workoutName: workoutName,
      workoutId: workoutId,
      completionDate: DateTime.now(),
      score: score.clamp(0, 100),
      user: user,
      totalDurationSeconds: totalDurationSeconds,
    );
  }

  /// Letter grade based on score
  String get letterGrade {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }

  /// Formatted completion date
  String get formattedDate {
    final d = completionDate;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  /// Formatted duration
  String get formattedDuration {
    final hours = totalDurationSeconds ~/ 3600;
    final minutes = (totalDurationSeconds % 3600) ~/ 60;
    final seconds = totalDurationSeconds % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'workoutName': workoutName,
    'workoutId': workoutId,
    'completionDate': completionDate.toIso8601String(),
    'score': score,
    'user': user,
    'totalDurationSeconds': totalDurationSeconds,
  };

  factory CompletedWorkout.fromJson(Map<String, dynamic> json) => CompletedWorkout(
    id: json['id'] as String,
    workoutName: json['workoutName'] as String,
    workoutId: json['workoutId'] as String,
    completionDate: DateTime.parse(json['completionDate'] as String),
    score: json['score'] as int,
    user: json['user'] as String,
    totalDurationSeconds: json['totalDurationSeconds'] as int,
  );

  @override
  String toString() => 'CompletedWorkout($workoutName by $user: $score/100 on $formattedDate)';
}

/// Hive TypeAdapter for CompletedWorkout
class CompletedWorkoutAdapter extends TypeAdapter<CompletedWorkout> {
  @override
  final int typeId = 12;

  @override
  CompletedWorkout read(BinaryReader reader) {
    return CompletedWorkout(
      id: reader.read() as String,
      workoutName: reader.read() as String,
      workoutId: reader.read() as String,
      completionDate: DateTime.fromMillisecondsSinceEpoch(reader.read() as int),
      score: reader.read() as int,
      user: reader.read() as String,
      totalDurationSeconds: reader.read() as int,
    );
  }

  @override
  void write(BinaryWriter writer, CompletedWorkout obj) {
    writer.write(obj.id);
    writer.write(obj.workoutName);
    writer.write(obj.workoutId);
    writer.write(obj.completionDate.millisecondsSinceEpoch);
    writer.write(obj.score);
    writer.write(obj.user);
    writer.write(obj.totalDurationSeconds);
  }
}
