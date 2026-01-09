/// Workouts list screen - shows pre-defined workouts
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:echelon_connect/core/models/workout.dart';
import 'package:echelon_connect/core/services/workout_storage.dart';
import 'package:echelon_connect/core/bluetooth/ble_manager.dart';
import 'package:echelon_connect/theme/app_theme.dart';
import 'package:echelon_connect/features/workouts/active_workout_screen.dart';

class WorkoutsListScreen extends ConsumerWidget {
  const WorkoutsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(workoutsProvider);
    final bleState = ref.watch(bleManagerProvider);
    final isConnected = bleState.isConnected;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'WORKOUTS',
          style: AppTypography.titleMedium.copyWith(letterSpacing: 2),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: workouts.length,
        itemBuilder: (context, index) {
          final workout = workouts[index];
          return _buildWorkoutCard(context, ref, workout, isConnected);
        },
      ),
    );
  }

  Widget _buildWorkoutCard(BuildContext context, WidgetRef ref, Workout workout, bool isConnected) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.surfaceBorder),
      ),
      child: InkWell(
        onTap: () => _showWorkoutOptions(context, ref, workout, isConnected),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                workout.name,
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildInfoChip(Icons.timer, workout.formattedTotalDuration),
                  const SizedBox(width: 12),
                  _buildInfoChip(Icons.format_list_numbered, '${workout.stepCount} steps'),
                ],
              ),
              const SizedBox(height: 12),
              // Step preview - show first 6 resistance levels
              SizedBox(
                height: 24,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: workout.steps.length.clamp(0, 6),
                  separatorBuilder: (_, __) => const SizedBox(width: 4),
                  itemBuilder: (context, index) {
                    final step = workout.steps[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'R${step.resistance}',
                        style: AppTypography.labelSmall,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.bodyMedium),
      ],
    );
  }

  void _showWorkoutOptions(BuildContext context, WidgetRef ref, Workout workout, bool isConnected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                workout.name,
                style: AppTypography.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${workout.stepCount} steps • ${workout.formattedTotalDuration}',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: isConnected
                    ? () {
                        Navigator.pop(ctx); // Close bottom sheet
                        _startWorkout(context, workout);
                      }
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: Text(isConnected ? 'START WORKOUT' : 'CONNECT BIKE TO START'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startWorkout(BuildContext context, Workout workout) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveWorkoutScreen(workout: workout),
      ),
    );
  }
}
