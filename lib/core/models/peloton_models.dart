class PelotonRide {
  final String id;
  final String title;
  final String description;
  final String instructorId;
  final String imageUrl;
  final int duration; // in seconds
  final int? difficultyRating;
  final int? overallRating;
  final double? totalWork;
  final DateTime? originalAirTime;

  PelotonRide({
    required this.id,
    required this.title,
    required this.description,
    required this.instructorId,
    required this.imageUrl,
    required this.duration,
    this.difficultyRating,
    this.overallRating,
    this.totalWork,
    this.originalAirTime,
  });

  factory PelotonRide.fromJson(Map<String, dynamic> json) {
    return PelotonRide(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      instructorId: json['instructor_id'] ?? '',
      imageUrl: json['image_url'] ?? '',
      duration: json['duration'] ?? 0,
      difficultyRating: json['difficulty_rating_avg'] != null 
          ? (json['difficulty_rating_avg'] * 10).round() 
          : null,
      overallRating: json['overall_rating_avg'] != null 
          ? (json['overall_rating_avg'] * 10).round() 
          : null,
      totalWork: json['total_work']?.toDouble(),
      originalAirTime: json['original_air_time'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['original_air_time'] * 1000) 
          : null,
    );
  }
}

class PelotonInstructorCue {
  final int startOffset; // seconds from start
  final int endOffset; // seconds from start
  final int? lowerCadence;
  final int? upperCadence;
  final int? lowerResistance;
  final int? upperResistance;

  PelotonInstructorCue({
    required this.startOffset,
    required this.endOffset,
    this.lowerCadence,
    this.upperCadence,
    this.lowerResistance,
    this.upperResistance,
  });

  factory PelotonInstructorCue.fromJson(Map<String, dynamic> json) {
    // Peloton offsets are often in milliseconds in some endpoints, 
    // but typically instructor_cues use seconds or ms. Need to verify.
    // Based on old_app: instructor_cues.at(i).toObject()[QStringLiteral("offsets")].toObject()
    // It seems they are in seconds.
    final offsets = json['offsets'];
    final start = offsets['start'] as int;
    final end = offsets['end'] as int;

    // Resistance/Cadence might be missing
    final cadence = json['cadence_range'];
    final resistance = json['resistance_range'];

    return PelotonInstructorCue(
      startOffset: start,
      endOffset: end,
      lowerCadence: cadence != null ? cadence['lower'] as int? : null,
      upperCadence: cadence != null ? cadence['upper'] as int? : null,
      lowerResistance: resistance != null ? resistance['lower'] as int? : null,
      upperResistance: resistance != null ? resistance['upper'] as int? : null,
    );
  }
  
  @override
  String toString() {
    return 'Cue($startOffset-$endOffset s, Cad: $lowerCadence-$upperCadence, Res: $lowerResistance-$upperResistance)';
  }
}

class PelotonTargetMetric {
  final String name; // "resistance" or "cadence"
  final double value; // target value
  final int offset; // seconds

  PelotonTargetMetric({
    required this.name,
    required this.value,
    required this.offset,
  });
}
