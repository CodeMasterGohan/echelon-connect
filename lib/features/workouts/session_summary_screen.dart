/// Screen to display workout summary after completion
library;

import 'package:flutter/material.dart';
import 'package:echelon_connect/core/models/workout_session.dart';
import 'package:echelon_connect/theme/app_theme.dart';
import 'package:intl/intl.dart';

class SessionSummaryScreen extends StatelessWidget {
  final WorkoutSession session;

  const SessionSummaryScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'WORKOUT SUMMARY',
          style: AppTypography.titleMedium.copyWith(letterSpacing: 2),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.emoji_events,
                        size: 64,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Great Job!',
                      style: AppTypography.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      session.workoutName,
                      style: AppTypography.titleMedium.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat.yMMMd().add_jm().format(session.endTime),
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Main Stats Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    'CALORIES',
                    '${session.totalCalories}',
                    'kcal',
                    Icons.local_fire_department,
                    AppColors.error,
                  ),
                  _buildStatCard(
                    'DURATION',
                    session.formattedDuration,
                    '',
                    Icons.timer,
                    AppColors.primary,
                  ),
                  _buildStatCard(
                    'AVG POWER',
                    '${session.avgPower}',
                    'W',
                    Icons.flash_on,
                    AppColors.warning,
                  ),
                  _buildStatCard(
                    'AVG CADENCE',
                    '${session.avgCadence}',
                    'RPM',
                    Icons.speed,
                    AppColors.accent,
                  ),
                  _buildStatCard(
                    'AVG SPEED',
                    session.avgSpeed.toStringAsFixed(1),
                    'MPH',
                    Icons.directions_bike,
                    AppColors.textPrimary,
                  ),
                  _buildStatCard(
                    'DISTANCE',
                    session.distanceMiles.toStringAsFixed(2),
                    'mi',
                    Icons.map,
                    AppColors.secondary,
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Done Button
              ElevatedButton(
                onPressed: () {
                  // Pop until we are back at the main screen (WorkoutsListScreen or Dashboard)
                  // Assuming WorkoutsListScreen was the entry point before ActiveWorkoutScreen
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.accent,
                ),
                child: const Text('DONE'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String unit, IconData icon, Color color) {
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
              Text(label, style: AppTypography.labelSmall),
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
                  style: AppTypography.headlineMedium.copyWith(color: color),
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
}
