/// Workouts list screen - shows difficulty options for a category
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:echelon_connect/core/models/workout.dart';
import 'package:echelon_connect/core/services/workout_storage.dart';
import 'package:echelon_connect/core/bluetooth/ble_manager.dart';
import 'package:echelon_connect/theme/app_theme.dart';
import 'package:echelon_connect/features/workouts/active_workout_screen.dart';

class WorkoutsListScreen extends ConsumerWidget {
  final WorkoutCategory category;
  
  const WorkoutsListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = getWorkoutsForCategory(category);
    final bleState = ref.watch(bleManagerProvider);
    final isConnected = bleState.isConnected;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category.emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              category.displayName.toUpperCase(),
              style: AppTypography.titleMedium.copyWith(letterSpacing: 2),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Category description
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              category.description,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          
          // Difficulty cards
          for (final difficulty in WorkoutDifficulty.values)
            if (workouts.containsKey(difficulty))
              _buildDifficultyCard(
                context, 
                ref, 
                workouts[difficulty]!, 
                difficulty,
                isConnected,
              ),
        ],
      ),
    );
  }

  Widget _buildDifficultyCard(
    BuildContext context, 
    WidgetRef ref, 
    Workout workout, 
    WorkoutDifficulty difficulty,
    bool isConnected,
  ) {
    Color difficultyColor;
    switch (difficulty) {
      case WorkoutDifficulty.easy:
        difficultyColor = Colors.green;
        break;
      case WorkoutDifficulty.medium:
        difficultyColor = Colors.orange;
        break;
      case WorkoutDifficulty.hard:
        difficultyColor = Colors.red;
        break;
    }
    
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: difficultyColor.withOpacity(0.3), width: 1.5),
      ),
      child: InkWell(
        onTap: () => _showWorkoutOptions(context, ref, workout, difficulty, difficultyColor, isConnected),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with difficulty badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: difficultyColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: difficultyColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          difficulty.emoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          difficulty.displayName.toUpperCase(),
                          style: AppTypography.labelMedium.copyWith(
                            color: difficultyColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.play_circle_outline,
                    color: isConnected ? difficultyColor : AppColors.textMuted,
                    size: 32,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Stats row
              Row(
                children: [
                  _buildInfoChip(Icons.timer, workout.formattedTotalDuration),
                  const SizedBox(width: 16),
                  _buildInfoChip(Icons.format_list_numbered, '${workout.stepCount} steps'),
                  const SizedBox(width: 16),
                  _buildInfoChip(
                    Icons.fitness_center, 
                    'Max R${_getMaxResistance(workout)}',
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Step preview - show resistance levels
              SizedBox(
                height: 28,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: workout.steps.length.clamp(0, 8),
                  separatorBuilder: (_, __) => const SizedBox(width: 4),
                  itemBuilder: (context, index) {
                    final step = workout.steps[index];
                    final intensity = step.resistance / 32;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          AppColors.surfaceLight, 
                          difficultyColor.withOpacity(0.3), 
                          intensity,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'R${step.resistance}',
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: intensity > 0.7 ? FontWeight.bold : FontWeight.normal,
                        ),
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

  int _getMaxResistance(Workout workout) {
    return workout.steps.fold<int>(0, (max, step) => step.resistance > max ? step.resistance : max);
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

  void _showWorkoutOptions(
    BuildContext context, 
    WidgetRef ref, 
    Workout workout, 
    WorkoutDifficulty difficulty,
    Color difficultyColor,
    bool isConnected,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Difficulty badge centered
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: difficultyColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: difficultyColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    '${difficulty.emoji} ${difficulty.displayName.toUpperCase()}',
                    style: AppTypography.labelLarge.copyWith(
                      color: difficultyColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Category name
              Text(
                '${category.emoji} ${category.displayName}',
                style: AppTypography.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Stats
              Text(
                '${workout.stepCount} steps • ${workout.formattedTotalDuration} • Max R${_getMaxResistance(workout)}',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Start button
              ElevatedButton.icon(
                onPressed: isConnected
                    ? () {
                        Navigator.pop(ctx);
                        _startWorkout(context, workout);
                      }
                    : null,
                icon: const Icon(Icons.play_arrow, size: 28),
                label: Text(
                  isConnected ? 'START WORKOUT' : 'CONNECT BIKE TO START',
                  style: AppTypography.labelLarge,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: difficultyColor,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
