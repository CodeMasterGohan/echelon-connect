/// Workout Completion Screen - Shows score and asks for user attribution
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:echelon_connect/core/models/workout.dart';
import 'package:echelon_connect/core/services/completed_workout_storage.dart';
import 'package:echelon_connect/core/bluetooth/ble_manager.dart';
import 'package:echelon_connect/theme/app_theme.dart';

class WorkoutCompletionScreen extends ConsumerWidget {
  final Workout workout;
  final int score;
  final int totalDurationSeconds;

  const WorkoutCompletionScreen({
    super.key,
    required this.workout,
    required this.score,
    required this.totalDurationSeconds,
  });

  Color _scoreColor(BuildContext context) {
    if (score >= 80) return context.successColor;
    if (score >= 60) return context.warningColor;
    return context.errorColor;
  }

  String _letterGrade() {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }

  String _encouragement() {
    if (score >= 90) return 'Outstanding performance! 🔥';
    if (score >= 80) return 'Great job, keep it up! 💪';
    if (score >= 70) return 'Solid workout! 👍';
    if (score >= 60) return 'Good effort! Keep pushing! 🏋️';
    return 'Keep training, you\'ll improve! 🚀';
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _selectUser(BuildContext context, WidgetRef ref, String user) async {
    final completedWorkout = CompletedWorkout.create(
      workoutName: workout.name,
      workoutId: workout.id,
      score: score,
      user: user,
      totalDurationSeconds: totalDurationSeconds,
    );

    // Save to storage
    await ref.read(completedWorkoutsProvider.notifier).addCompletedWorkout(completedWorkout);

    // End BLE workout session
    ref.read(bleManagerProvider.notifier).endWorkout();

    // Navigate back to dashboard
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _scoreColor(context);
    final grade = _letterGrade();

    return PopScope(
      canPop: false, // Prevent back navigation
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Completion icon with glow
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.surfaceColor,
                      border: Border.all(color: color.withAlpha(128)),
                      boxShadow: [
                        BoxShadow(
                          color: color.withAlpha(77),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.emoji_events,
                      size: 56,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'WORKOUT COMPLETE!',
                    style: AppTypography.labelLarge.copyWith(
                      letterSpacing: 3,
                      color: context.textMutedColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    workout.name,
                    style: AppTypography.headlineMedium.copyWith(
                      color: context.textPrimaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Score display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: color.withAlpha(100)),
                      boxShadow: [
                        BoxShadow(
                          color: color.withAlpha(30),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'CADENCE SCORE',
                          style: AppTypography.labelMedium.copyWith(
                            color: context.textMutedColor,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              score.toString(),
                              style: AppTypography.displayLarge.copyWith(
                                fontSize: 72,
                                color: color,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '/100',
                              style: AppTypography.headlineMedium.copyWith(
                                color: context.textMutedColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Grade: $grade',
                            style: AppTypography.titleMedium.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _encouragement(),
                          style: AppTypography.bodyLarge.copyWith(
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Duration info
                  Text(
                    'Duration: ${_formatDuration(totalDurationSeconds)}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.textMutedColor,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // User selection
                  Text(
                    'WHO COMPLETED THIS WORKOUT?',
                    style: AppTypography.labelLarge.copyWith(
                      letterSpacing: 2,
                      color: context.textMutedColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _buildUserButton(
                          context,
                          ref,
                          name: 'Russell',
                          icon: Icons.person,
                          color: const Color(0xFF4FC3F7), // Light blue
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildUserButton(
                          context,
                          ref,
                          name: 'Haley',
                          icon: Icons.person,
                          color: const Color(0xFFE040FB), // Pink/purple
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserButton(
    BuildContext context,
    WidgetRef ref, {
    required String name,
    required IconData icon,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectUser(context, ref, name),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withAlpha(100)),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(20),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withAlpha(30),
                ),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: AppTypography.titleLarge.copyWith(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
