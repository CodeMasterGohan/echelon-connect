/// Workout Styles Screen - shows workout categories to choose from
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:echelon_connect/core/services/workout_storage.dart';
import 'package:echelon_connect/theme/app_theme.dart';
import 'package:echelon_connect/features/workouts/workouts_list_screen.dart';

class WorkoutStylesScreen extends ConsumerWidget {
  const WorkoutStylesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'WORKOUT STYLES',
          style: AppTypography.titleMedium.copyWith(letterSpacing: 2),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: WorkoutCategory.values.length,
        itemBuilder: (context, index) {
          final category = WorkoutCategory.values[index];
          return _buildCategoryCard(context, category);
        },
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, WorkoutCategory category) {
    // Get workouts for this category to show stats
    final workouts = getWorkoutsForCategory(category);
    final mediumWorkout = workouts[WorkoutDifficulty.medium];
    
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.surfaceBorder),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkoutsListScreen(category: category),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with emoji and name
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        category.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.displayName,
                          style: AppTypography.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.description,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Difficulty options preview
              Row(
                children: [
                  _buildDifficultyChip(WorkoutDifficulty.easy),
                  const SizedBox(width: 8),
                  _buildDifficultyChip(WorkoutDifficulty.medium),
                  const SizedBox(width: 8),
                  _buildDifficultyChip(WorkoutDifficulty.hard),
                  const Spacer(),
                  if (mediumWorkout != null)
                    Text(
                      '~${mediumWorkout.formattedTotalDuration}',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(WorkoutDifficulty difficulty) {
    Color chipColor;
    switch (difficulty) {
      case WorkoutDifficulty.easy:
        chipColor = Colors.green;
        break;
      case WorkoutDifficulty.medium:
        chipColor = Colors.orange;
        break;
      case WorkoutDifficulty.hard:
        chipColor = Colors.red;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Text(
        difficulty.displayName,
        style: AppTypography.labelSmall.copyWith(
          color: chipColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
