/// Echelon BLE Protocol Constants and Commands
/// Ported from QDomyos-Zwift echelonconnectsport.cpp
library;

import 'dart:typed_data';

/// Workout metrics data model
class WorkoutMetrics {
  final int elapsedSeconds;
  final double distance;
  final int cadence;
  final int resistance;
  final int power;
  final int heartRate;
  final double calories;
  final double speed;

  const WorkoutMetrics({
    this.elapsedSeconds = 0,
    this.distance = 0.0,
    this.cadence = 0,
    this.resistance = 0,
    this.power = 0,
    this.heartRate = 0,
    this.calories = 0.0,
    this.speed = 0.0,
  });

  WorkoutMetrics copyWith({
    int? elapsedSeconds,
    double? distance,
    int? cadence,
    int? resistance,
    int? power,
    int? heartRate,
    double? calories,
    double? speed,
  }) {
    return WorkoutMetrics(
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      distance: distance ?? this.distance,
      cadence: cadence ?? this.cadence,
      resistance: resistance ?? this.resistance,
      power: power ?? this.power,
      heartRate: heartRate ?? this.heartRate,
      calories: calories ?? this.calories,
      speed: speed ?? this.speed,
    );
  }

  @override
  String toString() =>
      'WorkoutMetrics(elapsed: ${elapsedSeconds}s, cadence: $cadence, resistance: $resistance, power: ${power}W)';
}

/// Echelon BLE Protocol implementation
/// Based on QDomyos-Zwift echelonconnectsport.cpp
class EchelonProtocol {
  // ============================================
  // BLE Service and Characteristic UUIDs
  // From stateChanged() in echelonconnectsport.cpp
  // ============================================
  static const String serviceUuid = '0bf669f1-45f2-11e7-9598-0800200c9a66';
  static const String writeCharUuid = '0bf669f2-45f2-11e7-9598-0800200c9a66';
  static const String notify1CharUuid = '0bf669f3-45f2-11e7-9598-0800200c9a66';
  static const String notify2CharUuid = '0bf669f4-45f2-11e7-9598-0800200c9a66';

  // Device name prefix for scanning
  static const String deviceNamePrefix = 'ECH';

  // Max resistance level
  static const int maxResistance = 32;

  // ============================================
  // Initialization Commands
  // From btinit() in echelonconnectsport.cpp
  // ============================================
  
  /// Get initialization sequence commands
  /// These must be sent in order during device init
  static List<Uint8List> getInitSequence() {
    return [
      // initData1 - sent 4 times
      Uint8List.fromList([0xf0, 0xa1, 0x00, 0x91]),
      Uint8List.fromList([0xf0, 0xa1, 0x00, 0x91]),
      Uint8List.fromList([0xf0, 0xa1, 0x00, 0x91]),
      Uint8List.fromList([0xf0, 0xa1, 0x00, 0x91]),
      // initData2
      Uint8List.fromList([0xf0, 0xa3, 0x00, 0x93]),
      // initData1 again
      Uint8List.fromList([0xf0, 0xa1, 0x00, 0x91]),
      // initData3
      Uint8List.fromList([0xf0, 0xb0, 0x01, 0x01, 0xa2]),
    ];
  }

  // ============================================
  // Poll Command
  // From sendPoll() in echelonconnectsport.cpp
  // ============================================
  
  /// Create poll command with counter
  /// Sent every 2 seconds to keep connection alive
  static Uint8List createPollCommand(int counter) {
    final cmd = [0xf0, 0xa0, 0x01, counter & 0xFF, 0x00];
    cmd[4] = _calculateChecksum(cmd);
    return Uint8List.fromList(cmd);
  }

  // ============================================
  // Resistance Command
  // From forceResistance() in echelonconnectsport.cpp
  // ============================================
  
  /// Create resistance change command
  static Uint8List createResistanceCommand(int resistance) {
    final clampedResistance = resistance.clamp(1, maxResistance);
    final cmd = [0xf0, 0xb1, 0x01, clampedResistance, 0x00];
    cmd[4] = _calculateChecksum(cmd);
    return Uint8List.fromList(cmd);
  }

  // ============================================
  // Packet Parsers
  // From characteristicChanged() in echelonconnectsport.cpp
  // ============================================

  /// Parse incoming resistance packet (5 bytes, starts with 0xf0 0xd2)
  static int? parseResistancePacket(List<int> data) {
    if (data.length == 5 && data[0] == 0xf0 && data[1] == 0xd2) {
      return data[3];
    }
    return null;
  }

  /// Parse incoming metrics packet (13 bytes)
  /// Returns partial metrics (cadence, elapsed, distance)
  static WorkoutMetrics? parseMetricsPacket(List<int> data) {
    if (data.length != 13) return null;

    // From GetElapsedFromPacket: (packet[3] << 8) | packet[4]
    final elapsedSeconds = (data[3] << 8) | data[4];
    
    // From GetDistanceFromPacket: ((packet[7] << 8) | packet[8]) / 100.0
    final distance = ((data[7] << 8) | data[8]) / 100.0;
    
    // Cadence is at byte 10
    final cadence = data[10];

    return WorkoutMetrics(
      elapsedSeconds: elapsedSeconds,
      distance: distance,
      cadence: cadence,
    );
  }

  /// Calculate checksum for commands
  /// Sum of all bytes except last, masked to 8 bits
  static int _calculateChecksum(List<int> data) {
    int sum = 0;
    for (int i = 0; i < data.length - 1; i++) {
      sum += data[i];
    }
    return sum & 0xFF;
  }

  // ============================================
  // Peloton Resistance Conversion
  // From bikeResistanceToPeloton() in echelonconnectsport.cpp
  // ============================================

  /// Convert Echelon resistance to Peloton scale
  /// Formula: 0.0097x³ - 0.4972x² + 10.126x - 37.08
  static double resistanceToPeloton(int resistance, {double gain = 1.0, double offset = 0.0}) {
    final r = resistance.toDouble();
    double p = (0.0097 * r * r * r) - (0.4972 * r * r) + (10.126 * r) - 37.08;
    if (p < 0) p = 0;
    return (p * gain) + offset;
  }

  /// Convert Peloton resistance to Echelon
  static int pelotonToResistance(int pelotonResistance, {double gain = 1.0, double offset = 0.0}) {
    for (int i = 1; i < maxResistance; i++) {
      final current = resistanceToPeloton(i, gain: gain, offset: offset);
      final next = resistanceToPeloton(i + 1, gain: gain, offset: offset);
      if (current <= pelotonResistance && next > pelotonResistance) {
        return i;
      }
    }
    if (pelotonResistance < resistanceToPeloton(1, gain: gain, offset: offset)) {
      return 1;
    }
    return maxResistance;
  }
}

/// Power (Watts) Calculator
/// Ported from wattsFromResistance() in echelonconnectsport.cpp
class PowerCalculator {
  static const double _epsilon = 4.94065645841247e-324;

  /// Watt table from echelonconnectsport.cpp
  /// [resistance 0-32][cadence_step 0-10]
  /// cadence_step = cadence / 10
  static const List<List<double>> wattTable = [
    [_epsilon, 1.0, 2.2, 4.8, 9.5, 13.6, 16.7, 22.6, 26.3, 29.2, 47.0],
    [_epsilon, 1.0, 2.2, 4.8, 9.5, 13.6, 16.7, 22.6, 26.3, 29.2, 47.0],
    [_epsilon, 1.3, 3.0, 5.4, 10.4, 14.5, 18.5, 24.6, 27.6, 33.5, 49.5],
    [_epsilon, 1.5, 3.7, 6.7, 11.7, 15.9, 19.6, 26.1, 30.8, 35.2, 51.2],
    [_epsilon, 1.6, 4.7, 7.5, 13.7, 17.6, 22.6, 29.0, 36.9, 42.6, 57.2],
    [_epsilon, 1.8, 5.2, 8.0, 14.8, 19.1, 23.5, 32.5, 37.5, 50.8, 61.8],
    [_epsilon, 1.9, 5.7, 8.7, 15.6, 20.2, 25.5, 33.5, 39.6, 52.1, 65.3],
    [_epsilon, 2.0, 6.2, 9.5, 16.8, 21.8, 28.1, 37.0, 42.8, 57.8, 68.4],
    [_epsilon, 2.1, 6.8, 10.8, 18.2, 23.6, 29.5, 40.0, 47.6, 60.5, 72.1],
    [_epsilon, 2.2, 7.3, 11.5, 19.3, 26.3, 33.5, 45.3, 51.8, 66.7, 76.8],
    [_epsilon, 2.4, 7.9, 12.7, 20.8, 29.8, 37.6, 52.2, 56.2, 73.5, 83.6],
    [_epsilon, 2.6, 8.5, 13.5, 23.5, 33.6, 41.9, 55.1, 59.0, 78.6, 89.7],
    [_epsilon, 2.7, 9.1, 14.2, 25.6, 35.4, 45.3, 57.3, 62.8, 81.3, 95.0],
    [_epsilon, 2.9, 9.6, 16.8, 29.1, 37.5, 49.6, 62.5, 69.0, 84.7, 99.3],
    [_epsilon, 3.0, 10.0, 22.3, 31.2, 40.3, 51.8, 65.0, 70.0, 92.6, 108.2],
    [_epsilon, 3.2, 10.4, 24.0, 36.6, 42.5, 56.3, 74.0, 85.0, 98.2, 123.5],
    [_epsilon, 3.5, 10.9, 25.1, 38.5, 47.6, 65.4, 83.0, 93.0, 114.8, 136.8],
    [_epsilon, 3.7, 11.5, 26.0, 41.0, 53.2, 71.6, 90.0, 100.0, 121.7, 149.2],
    [_epsilon, 4.0, 12.1, 27.5, 43.6, 56.0, 82.3, 101.0, 113.6, 143.0, 162.8],
    [_epsilon, 4.2, 12.7, 29.7, 46.7, 64.2, 87.9, 109.2, 128.9, 154.0, 172.3],
    [_epsilon, 4.5, 13.7, 32.0, 50.0, 71.8, 95.6, 113.8, 135.6, 165.0, 185.0],
    [_epsilon, 4.7, 14.9, 34.5, 54.2, 77.0, 100.7, 127.0, 147.6, 180.0, 200.0],
    [_epsilon, 5.0, 15.8, 36.5, 58.3, 83.4, 110.1, 136.0, 168.1, 196.0, 213.5],
    [_epsilon, 5.6, 17.0, 39.5, 64.3, 88.8, 123.4, 154.0, 182.0, 210.0, 235.0],
    [_epsilon, 6.1, 18.2, 44.0, 70.7, 99.9, 133.3, 166.0, 198.0, 230.0, 253.5],
    [_epsilon, 6.8, 19.4, 49.0, 79.0, 108.8, 147.2, 185.0, 217.0, 255.2, 278.0],
    [_epsilon, 7.6, 22.0, 54.8, 88.0, 127.0, 167.0, 212.0, 244.0, 287.0, 305.0],
    [_epsilon, 8.7, 26.0, 62.0, 100.0, 145.0, 190.0, 242.0, 281.0, 315.1, 350.0],
    [_epsilon, 9.2, 30.0, 71.0, 114.4, 161.6, 215.1, 275.1, 317.0, 358.5, 390.0],
    [_epsilon, 9.8, 36.0, 82.5, 134.5, 195.3, 252.5, 313.7, 360.0, 420.3, 460.0],
    [_epsilon, 10.5, 43.0, 95.0, 157.1, 228.4, 300.1, 374.1, 403.8, 487.8, 540.0],
    [_epsilon, 12.5, 48.0, 99.3, 162.2, 232.9, 310.4, 400.3, 435.5, 530.5, 589.0],
    [_epsilon, 13.0, 53.0, 102.0, 170.3, 242.0, 320.0, 427.9, 475.2, 570.0, 625.0],
  ];

  /// Calculate watts from resistance and cadence
  /// Direct port from wattsFromResistance() in echelonconnectsport.cpp
  static int calculateWatts(int resistance, int cadence) {
    if (cadence == 0) return 0;

    final level = resistance.clamp(0, wattTable.length - 1);
    final wattsOfLevel = wattTable[level];

    final cadenceStep = (cadence / 10).floor();
    if (cadenceStep >= 10) {
      // Extrapolate for high cadence
      return ((cadence / 100.0) * wattsOfLevel[10]).round();
    }

    final wattBase = wattsOfLevel[cadenceStep];
    final wattNext = wattsOfLevel[cadenceStep + 1];
    
    // Interpolate between steps
    return (((wattNext - wattBase) / 10.0) * (cadence % 10) + wattBase).round();
  }

  /// Calculate speed from cadence
  /// From echelonconnectsport.cpp: Speed = 0.37497622 * cadence
  static double calculateSpeed(int cadence) {
    return 0.37497622 * cadence;
  }

  /// Calculate calories burned
  /// Formula from echelonconnectsport.cpp
  static double calculateCaloriesPerSecond(int watts, double weightKg) {
    if (watts == 0) return 0;
    // (( (0.048* Output in watts +1.19) * body weight in kg * 3.5) / 200 ) / 60
    return ((0.048 * watts + 1.19) * weightKg * 3.5) / 200.0 / 60.0;
  }
}
