/// Workouts list screen - shows saved workouts
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:echelon_connect/core/models/workout.dart';
import 'package:echelon_connect/core/services/workout_storage.dart';
import 'package:echelon_connect/core/bluetooth/ble_manager.dart';
import 'package:echelon_connect/theme/app_theme.dart';
import 'package:echelon_connect/features/workouts/workout_editor_screen.dart';
import 'package:echelon_connect/features/workouts/active_workout_screen.dart';

class WorkoutsListScreen extends ConsumerStatefulWidget {
  const WorkoutsListScreen({super.key});

  @override
  ConsumerState<WorkoutsListScreen> createState() => _WorkoutsListScreenState();
}

class _WorkoutsListScreenState extends ConsumerState<WorkoutsListScreen> {
  @override
  void initState() {
    super.initState();
    // Sample workouts are now created automatically in WorkoutStorageNotifier._init()
  }

  @override
  Widget build(BuildContext context) {
    final workouts = ref.watch(workoutStorageProvider);
    final bleState = ref.watch(bleManagerProvider);
    final isConnected = bleState.isConnected;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'MY WORKOUTS',
          style: AppTypography.titleMedium.copyWith(letterSpacing: 2),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: workouts.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: workouts.length,
              itemBuilder: (context, index) {
                final workout = workouts[index];
                return _buildWorkoutCard(workout, isConnected);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEditor(null),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add),
        label: const Text('NEW WORKOUT'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No Workouts Yet',
            style: AppTypography.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first custom workout',
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(Workout workout, bool isConnected) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.surfaceBorder),
      ),
      child: InkWell(
        onTap: () => _showWorkoutOptions(workout, isConnected),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      workout.name,
                      style: AppTypography.titleMedium,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, workout),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                    icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                  ),
                ],
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
              // Step preview
              SizedBox(
                height: 24,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: workout.steps.length.clamp(0, 5),
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

  void _showWorkoutOptions(Workout workout, bool isConnected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
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
                        Navigator.pop(context); // Close bottom sheet
                        _startWorkout(workout);
                      }
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: Text(isConnected ? 'START WORKOUT' : 'CONNECT BIKE TO START'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToEditor(workout);
                },
                icon: const Icon(Icons.edit),
                label: const Text('EDIT WORKOUT'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(String action, Workout workout) {
    switch (action) {
      case 'edit':
        _navigateToEditor(workout);
        break;
      case 'delete':
        _confirmDelete(workout);
        break;
    }
  }

  void _confirmDelete(Workout workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Workout?'),
        content: Text('Are you sure you want to delete "${workout.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              ref.read(workoutStorageProvider.notifier).deleteWorkout(workout.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _navigateToEditor(Workout? workout) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutEditorScreen(workout: workout),
      ),
    );
  }

  void _startWorkout(Workout workout) {
    ref.read(workoutStorageProvider.notifier).markAsUsed(workout.id);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveWorkoutScreen(workout: workout),
      ),
    );
  }
}
