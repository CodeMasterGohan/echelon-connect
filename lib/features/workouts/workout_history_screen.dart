/// Workout History Screen - Displays completed workout records
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:echelon_connect/core/models/workout.dart';
import 'package:echelon_connect/core/services/completed_workout_storage.dart';
import 'package:echelon_connect/theme/app_theme.dart';

class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  Color _scoreColor(BuildContext context, int score) {
    if (score >= 80) return context.successColor;
    if (score >= 60) return context.warningColor;
    return context.errorColor;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(completedWorkoutsProvider);

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Workout History'),
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: workouts.isEmpty
          ? _buildEmptyState(context)
          : _buildWorkoutList(context, workouts),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.surfaceColor,
              border: Border.all(color: context.surfaceBorderColor),
            ),
            child: Icon(
              Icons.fitness_center,
              size: 48,
              color: context.textMutedColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No workouts yet',
            style: AppTypography.headlineMedium.copyWith(
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete a workout to see your history here',
            style: AppTypography.bodyMedium.copyWith(
              color: context.textMutedColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutList(BuildContext context, List<CompletedWorkout> workouts) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: workouts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final workout = workouts[index];
        return _buildWorkoutCard(context, workout);
      },
    );
  }

  Widget _buildWorkoutCard(BuildContext context, CompletedWorkout workout) {
    final color = _scoreColor(context, workout.score);
    final userColor = workout.user == 'Russell'
        ? const Color(0xFF4FC3F7)
        : const Color(0xFFE040FB);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.surfaceBorderColor),
      ),
      child: Row(
        children: [
          // Score badge
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: color.withAlpha(25),
              border: Border.all(color: color.withAlpha(100)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  workout.score.toString(),
                  style: AppTypography.headlineMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                Text(
                  workout.letterGrade,
                  style: AppTypography.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Workout details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.workoutName,
                  style: AppTypography.titleMedium.copyWith(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: context.textMutedColor),
                    const SizedBox(width: 4),
                    Text(
                      workout.formattedDate,
                      style: AppTypography.labelSmall.copyWith(
                        color: context.textMutedColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.timer, size: 14, color: context.textMutedColor),
                    const SizedBox(width: 4),
                    Text(
                      workout.formattedDuration,
                      style: AppTypography.labelSmall.copyWith(
                        color: context.textMutedColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // User badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: userColor.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: userColor.withAlpha(80)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person, size: 14, color: userColor),
                const SizedBox(width: 4),
                Text(
                  workout.user,
                  style: AppTypography.labelSmall.copyWith(
                    color: userColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
