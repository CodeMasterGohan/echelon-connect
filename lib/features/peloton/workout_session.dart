import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/peloton_models.dart';
import '../../core/bluetooth/ble_manager.dart';
import '../../core/bluetooth/echelon_protocol.dart';

class WorkoutSessionState {
  final bool isActive;
  final bool isPaused;
  final int elapsedTime; // seconds
  final PelotonRide? activeRide;
  final List<PelotonInstructorCue> cues;
  final PelotonInstructorCue? currentCue;
  final bool autoResistanceEnabled;
  final int? targetResistance;
  final int? targetCadence;

  const WorkoutSessionState({
    this.isActive = false,
    this.isPaused = false,
    this.elapsedTime = 0,
    this.activeRide,
    this.cues = const [],
    this.currentCue,
    this.autoResistanceEnabled = true,
    this.targetResistance,
    this.targetCadence,
  });

  WorkoutSessionState copyWith({
    bool? isActive,
    bool? isPaused,
    int? elapsedTime,
    PelotonRide? activeRide,
    List<PelotonInstructorCue>? cues,
    PelotonInstructorCue? currentCue,
    bool? autoResistanceEnabled,
    int? targetResistance,
    int? targetCadence,
  }) {
    return WorkoutSessionState(
      isActive: isActive ?? this.isActive,
      isPaused: isPaused ?? this.isPaused,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      activeRide: activeRide ?? this.activeRide,
      cues: cues ?? this.cues,
      currentCue: currentCue ?? this.currentCue,
      autoResistanceEnabled: autoResistanceEnabled ?? this.autoResistanceEnabled,
      targetResistance: targetResistance ?? this.targetResistance,
      targetCadence: targetCadence ?? this.targetCadence,
    );
  }
}

class WorkoutSessionNotifier extends StateNotifier<WorkoutSessionState> {
  final BleManagerNotifier bleManager;
  Timer? _timer;

  WorkoutSessionNotifier(this.bleManager) : super(const WorkoutSessionState());

  void startWorkout(PelotonRide ride, List<PelotonInstructorCue> cues) {
    state = WorkoutSessionState(
      isActive: true,
      activeRide: ride,
      cues: cues,
    );
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.isPaused) {
        final newTime = state.elapsedTime + 1;
        
        // Find current cue
        PelotonInstructorCue? currentCue;
        for (final cue in state.cues) {
           if (newTime >= cue.startOffset && newTime <= cue.endOffset) {
             currentCue = cue;
             break;
           }
        }

        int? targetRes;
        int? targetCad;

        if (currentCue != null) {
          // Average the range for target
          // Using old_app logic from peloton.cpp ~1180: average_requested_peloton_resistance = (lower + upper) / 2
          if (currentCue.lowerResistance != null && currentCue.upperResistance != null) {
             final avgPelotonRes = (currentCue.lowerResistance! + currentCue.upperResistance!) ~/ 2;
             // Convert to Echelon resistance
             targetRes = EchelonProtocol.pelotonToResistance(avgPelotonRes);
          }
          
          if (currentCue.lowerCadence != null && currentCue.upperCadence != null) {
            targetCad = (currentCue.lowerCadence! + currentCue.upperCadence!) ~/ 2;
          }
        }

        // Auto Resistance Logic
        if (state.autoResistanceEnabled && targetRes != null) {
           // Only send if changed? BleManager handles redundant writes usually, but let's be safe.
           // Ideally we check current resistance but that's async. 
           // We'll just fire and forget for now, maybe add a check against last sent value if needed.
           bleManager.setResistance(targetRes);
        }

        state = state.copyWith(
          elapsedTime: newTime,
          currentCue: currentCue,
          targetResistance: targetRes,
          targetCadence: targetCad,
        );
      }
    });
  }

  void pause() {
    state = state.copyWith(isPaused: true);
  }

  void resume() {
    state = state.copyWith(isPaused: false);
  }

  void stop() {
    _timer?.cancel();
    state = const WorkoutSessionState();
  }
  
  void toggleAutoResistance() {
    state = state.copyWith(autoResistanceEnabled: !state.autoResistanceEnabled);
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final workoutSessionProvider = StateNotifierProvider<WorkoutSessionNotifier, WorkoutSessionState>((ref) {
  final bleManager = ref.watch(bleManagerProvider.notifier);
  return WorkoutSessionNotifier(bleManager);
});
