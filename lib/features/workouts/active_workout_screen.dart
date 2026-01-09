/// Active workout screen - executes a workout with auto-resistance
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:android_pip/android_pip.dart';
import 'package:android_pip/pip_widget.dart';
import 'package:echelon_connect/core/models/workout.dart';
import 'package:echelon_connect/core/models/workout_session.dart';
import 'package:echelon_connect/core/services/workout_history_storage.dart';
import 'package:echelon_connect/core/bluetooth/ble_manager.dart';
import 'package:echelon_connect/core/bluetooth/echelon_protocol.dart';
import 'package:echelon_connect/theme/app_theme.dart';
import 'package:echelon_connect/features/workouts/session_summary_screen.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final Workout workout;

  const ActiveWorkoutScreen({super.key, required this.workout});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  int _currentStepIndex = 0;
  int _stepElapsedSeconds = 0;
  int _totalElapsedSeconds = 0;
  Timer? _timer;
  bool _isPaused = false;

  // Metrics accumulation for average calculation
  int _totalPower = 0;
  int _totalCadence = 0;
  double _totalSpeed = 0.0;
  int _sampleCount = 0;
  final DateTime _startTime = DateTime.now();

  WorkoutStep get _currentStep => widget.workout.steps[_currentStepIndex];
  int get _stepRemainingSeconds => _currentStep.durationSeconds - _stepElapsedSeconds;
  bool get _isLastStep => _currentStepIndex >= widget.workout.steps.length - 1;

  @override
  void initState() {
    super.initState();
    _startWorkout();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startWorkout() {
    // Start the BLE workout session
    ref.read(bleManagerProvider.notifier).startWorkout();
    
    // Set initial resistance
    _setResistance(_currentStep.resistance);
    
    // Start timer
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_isPaused) return;

    // Accumulate metrics
    final metrics = ref.read(bleManagerProvider).currentMetrics;
    _totalPower += metrics.power;
    _totalCadence += metrics.cadence;
    _totalSpeed += metrics.speed;
    _sampleCount++;

    setState(() {
      _stepElapsedSeconds++;
      _totalElapsedSeconds++;

      // Check if current step is complete
      if (_stepElapsedSeconds >= _currentStep.durationSeconds) {
        if (_isLastStep) {
          _completeWorkout();
        } else {
          _advanceToNextStep();
        }
      }
    });
  }

  void _advanceToNextStep() {
    setState(() {
      _currentStepIndex++;
      _stepElapsedSeconds = 0;
    });
    _setResistance(_currentStep.resistance);
  }

  void _setResistance(int resistance) {
    ref.read(bleManagerProvider.notifier).setResistance(resistance);
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _skipStep() {
    if (!_isLastStep) {
      // Add the remaining time of current step to total elapsed
      _totalElapsedSeconds += _stepRemainingSeconds;
      _advanceToNextStep();
    }
  }

  void _completeWorkout() {
    _timer?.cancel();
    _saveAndShowSummary();
  }

  void _saveAndShowSummary() {
    // Calculate averages
    final avgPower = _sampleCount > 0 ? (_totalPower / _sampleCount).round() : 0;
    final avgCadence = _sampleCount > 0 ? (_totalCadence / _sampleCount).round() : 0;
    final avgSpeed = _sampleCount > 0 ? (_totalSpeed / _sampleCount) : 0.0;

    // Estimate calories
    // Formula: kcal = (AvgPower * DurationSeconds * 0.000996)
    // Using a simpler conversion: 1 Joule = 0.000239 kcal
    // Energy (J) = Power (W) * Time (s)
    // Metabolic Efficiency ~24% => Divide by 0.24
    final energyJoules = avgPower * _totalElapsedSeconds;
    final totalCalories = (energyJoules * 0.000239006 / 0.24).round();

    // Distance (approximate based on avg speed in mph if speed is mph, or if speed is kph?)
    // Echelon speed is usually MPH. Let's assume MPH based on UI.
    // Distance = Speed * Time(h)
    final distanceMiles = avgSpeed * (_totalElapsedSeconds / 3600);

    final session = WorkoutSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      workoutId: widget.workout.id,
      workoutName: widget.workout.name,
      startTime: _startTime,
      endTime: DateTime.now(),
      durationSeconds: _totalElapsedSeconds,
      totalCalories: totalCalories,
      avgPower: avgPower,
      avgCadence: avgCadence,
      avgSpeed: avgSpeed,
      distanceMiles: distanceMiles,
    );

    // Save to storage
    ref.read(workoutHistoryStorageProvider.notifier).saveSession(session);

    // End BLE workout
    ref.read(bleManagerProvider.notifier).endWorkout();

    // Navigate to summary
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SessionSummaryScreen(session: session),
      ),
    );
  }

  void _endWorkoutEarly() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('End Workout?'),
        content: const Text('Are you sure you want to end this workout early?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CONTINUE'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _timer?.cancel();
              ref.read(bleManagerProvider.notifier).endWorkout();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('END'),
          ),
        ],
      ),
    );
  }


  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ref.watch(bleManagerProvider).currentMetrics;
    final powerColor = AppColors.getPowerZoneColor(metrics.power, 200);

    // PiP overlay content - shows current step, time, and cadence
    return PipWidget(
      pipBuilder: (context) => Container(
        color: AppColors.background,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Step name and time
            Text(
              _currentStep.name ?? 'Step ${_currentStepIndex + 1}',
              style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDuration(_stepRemainingSeconds),
              style: AppTypography.displayLarge.copyWith(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: _stepRemainingSeconds <= 10 ? AppColors.warning : AppColors.accent,
              ),
            ),
            const SizedBox(height: 8),
            // Cadence: Current / Target
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Current cadence
                Column(
                  children: [
                    Text('CADENCE', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                    Text(
                      '${metrics.cadence}',
                      style: AppTypography.titleLarge.copyWith(color: AppColors.accent),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('/', style: AppTypography.titleLarge.copyWith(color: AppColors.textMuted)),
                ),
                // Target cadence
                Column(
                  children: [
                    Text('TARGET', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                    Text(
                      _currentStep.formattedCadence,
                      style: AppTypography.titleLarge.copyWith(
                        color: _currentStep.targetCadence == null ? AppColors.warning : AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      builder: (context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: Text(
            widget.workout.name.toUpperCase(),
            style: AppTypography.titleMedium.copyWith(letterSpacing: 2),
          ),
          automaticallyImplyLeading: false,
          actions: [
            // Picture-in-Picture button
            IconButton(
              onPressed: () => AndroidPIP().enterPipMode(
                aspectRatio: [16, 9],
                autoEnter: true,
              ),
              icon: const Icon(
                Icons.picture_in_picture,
                color: AppColors.accent,
              ),
              tooltip: 'Picture-in-Picture',
            ),
            // Skip step button (visible if not on last step)
            if (!_isLastStep)
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: _skipStep,
                tooltip: 'Skip step',
              ),
            IconButton(
              icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
              onPressed: _togglePause,
              tooltip: _isPaused ? 'Resume' : 'Pause',
            ),
            IconButton(
              icon: const Icon(Icons.stop, color: AppColors.error),
              onPressed: _endWorkoutEarly,
              tooltip: 'End workout',
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Current step card
                _buildCurrentStepCard(),
                const SizedBox(height: 16),

                // Progress indicator
                _buildProgressIndicator(),
                const SizedBox(height: 24),

                // Live metrics grid
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _buildMetricTile('Power', '${metrics.power}', 'W', Icons.flash_on, powerColor),
                      _buildMetricTile('Cadence', '${metrics.cadence}', 'RPM', Icons.speed, AppColors.accent),
                      _buildMetricTile('Speed', (metrics.speed * 0.621371).toStringAsFixed(1), 'MPH', Icons.directions_bike, AppColors.textPrimary),
                      _buildMetricTile('Resistance', '${metrics.resistance}/${EchelonProtocol.maxResistance}', '', Icons.fitness_center, AppColors.secondary),
                    ],
                  ),
                ),

                // Next step preview
                if (!_isLastStep) _buildNextStepPreview(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent.withOpacity(0.3), AppColors.secondary.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          // Step indicator
          Text(
            'STEP ${_currentStepIndex + 1} OF ${widget.workout.steps.length}',
            style: AppTypography.labelMedium,
          ),
          const SizedBox(height: 8),

          // Step name
          Text(
            _currentStep.name ?? 'Step ${_currentStepIndex + 1}',
            style: AppTypography.headlineLarge,
          ),
          const SizedBox(height: 16),

          // Time remaining
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isPaused ? Icons.pause_circle : Icons.timer,
                size: 32,
                color: _isPaused ? AppColors.warning : AppColors.textPrimary,
              ),
              const SizedBox(width: 12),
              Text(
                _formatDuration(_stepRemainingSeconds),
                style: AppTypography.displayLarge.copyWith(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: _stepRemainingSeconds <= 10 ? AppColors.warning : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Target resistance
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'TARGET: R${_currentStep.resistance}',
              style: AppTypography.titleMedium.copyWith(color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final totalDuration = widget.workout.totalDurationSeconds;
    final progress = totalDuration > 0 ? _totalElapsedSeconds / totalDuration : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatDuration(_totalElapsedSeconds), style: AppTypography.labelMedium),
            Text(_formatDuration(totalDuration - _totalElapsedSeconds), style: AppTypography.labelMedium),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation(AppColors.accent),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(label.toUpperCase(), style: AppTypography.labelSmall),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: AppTypography.displayMedium.copyWith(color: color, fontSize: 28),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(unit, style: AppTypography.labelMedium),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepPreview() {
    final nextStep = widget.workout.steps[_currentStepIndex + 1];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.skip_next, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NEXT', style: AppTypography.labelSmall),
                Text(
                  '${nextStep.name ?? "Step ${_currentStepIndex + 2}"} • R${nextStep.resistance} • ${nextStep.formattedDuration}',
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
