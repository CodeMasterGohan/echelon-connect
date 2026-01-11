/// Dashboard Screen - Main workout display
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:android_pip/android_pip.dart';
import 'package:android_pip/pip_widget.dart';
import 'package:echelon_connect/core/bluetooth/ble_manager.dart';
import 'package:echelon_connect/core/bluetooth/echelon_protocol.dart';
import 'package:echelon_connect/theme/app_theme.dart';
import 'package:echelon_connect/features/dashboard/widgets/metric_tile.dart';
import 'package:echelon_connect/features/dashboard/widgets/pip_overlay.dart';
import 'package:echelon_connect/core/providers/theme_provider.dart';
import 'package:echelon_connect/features/workouts/workout_styles_screen.dart';


class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only watch what is needed for the scaffolding and view switching.
    // This prevents the entire Scaffold (and AppBar) from rebuilding on every metric update.
    final isConnected = ref.watch(bleManagerProvider.select((s) => s.isConnected));
    final isWorkoutActive = ref.watch(bleManagerProvider.select((s) => s.isWorkoutActive));
    final connectionState = ref.watch(bleManagerProvider.select((s) => s.connectionState));
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    // Wrap entire scaffold in PipWidget - in PiP mode, only show the overlay (no AppBar)
    return PipWidget(
      pipBuilder: (context) => const PipOverlay(),
      builder: (context) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: context.backgroundColor,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bolt,
                color: isConnected ? context.successColor : context.textMutedColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'ECHELON CONNECT',
                style: AppTypography.titleMedium.copyWith(
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryColor,
                ),
              ),
            ],
          ),
          actions: [
            // Custom Workouts Button (always visible when connected)
            if (isConnected)
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WorkoutStylesScreen()),
                  );
                },
                icon: Icon(
                  Icons.fitness_center,
                  color: context.accentColor,
                ),
                tooltip: 'Custom Workouts',
              ),
            // Picture-in-Picture Button (only during workout)
            if (isWorkoutActive)
              IconButton(
                onPressed: () => AndroidPIP().enterPipMode(
                  aspectRatio: [16, 9],
                  autoEnter: true,
                ),
                icon: Icon(
                  Icons.picture_in_picture,
                  color: context.accentColor,
                ),
                tooltip: 'Enter Picture-in-Picture',
              ),
            // Theme Toggle Button
            IconButton(
              onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
              icon: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: context.accentColor,
              ),
              tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            ),
            // Connection status indicator
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isConnected
                    ? context.successColor.withAlpha(51)
                    : context.surfaceLightColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isConnected ? context.successColor : context.surfaceBorderColor,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnected ? context.successColor : context.textMutedColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isConnected ? 'Connected' : 'Disconnected',
                    style: AppTypography.labelMedium.copyWith(
                      color: isConnected ? context.successColor : context.textMutedColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: isWorkoutActive
              ? const ConnectedDashboardView()
              : connectionState == EchelonConnectionState.idle
                  ? const IdleDashboardView()
                  : const DisconnectedDashboardView(),
        ),
      ),
    );
  }
}

class ConnectedDashboardView extends ConsumerWidget {
  const ConnectedDashboardView({super.key});

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This widget listens to metrics updates, so it will rebuild frequently.
    // However, the parent DashboardScreen will NOT rebuild.
    final metrics = ref.watch(bleManagerProvider.select((s) => s.currentMetrics));
    final powerColor = AppColors.getPowerZoneColor(metrics.power, 200); // TODO: Get FTP from settings

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscapeTablet = constraints.maxWidth > 700 && constraints.maxHeight < constraints.maxWidth;
        
        if (isLandscapeTablet) {
          // Landscape tablet layout - side by side (metrics left, controls right)
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Metrics
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Main metrics - 2x2 grid, compact
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.6,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildCompactMetric(context, 'Power', metrics.power.toString(), 'W', Icons.flash_on, powerColor),
                            _buildCompactMetric(context, 'Cadence', metrics.cadence.toString(), 'RPM', Icons.speed, context.accentColor),
                            _buildCompactMetric(context, 'Speed', (metrics.speed * 0.621371).toStringAsFixed(1), 'MPH', Icons.directions_bike, context.textPrimaryColor),
                            _buildCompactMetric(context, 'Resistance', '${metrics.resistance}/${EchelonProtocol.maxResistance} (${PowerCalculator.bikeResistanceToPeloton(metrics.resistance)}%)', '', Icons.fitness_center, context.secondaryColor),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Secondary metrics row
                      Row(
                        children: [
                          Expanded(child: _buildMiniMetric(context, Icons.timer_outlined, _formatDuration(metrics.elapsedSeconds))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildMiniMetric(context, Icons.straighten, '${(metrics.distance * 0.621371).toStringAsFixed(2)} mi')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildMiniMetric(context, Icons.local_fire_department, '${metrics.calories.toStringAsFixed(0)} cal', context.warningColor)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right side - Resistance controls + End button
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(child: _buildCompactResistanceControls(context, ref, metrics.resistance)),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => ref.read(bleManagerProvider.notifier).endWorkout(),
                          icon: const Icon(Icons.stop, size: 18),
                          label: const Text('END'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.errorColor,
                            side: BorderSide(color: context.errorColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        
        // Portrait / phone layout - original vertical scrolling
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Main metrics grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  MetricTile(
                    label: 'Power',
                    value: metrics.power.toString(),
                    unit: 'W',
                    icon: Icons.flash_on,
                    valueColor: powerColor,
                    progress: (metrics.power / 400).clamp(0.0, 1.0),
                    progressColor: powerColor,
                    isLarge: true,
                  ),
                  MetricTile(
                    label: 'Cadence',
                    value: metrics.cadence.toString(),
                    unit: 'RPM',
                    icon: Icons.speed,
                    valueColor: context.accentColor,
                    progress: (metrics.cadence / 120).clamp(0.0, 1.0),
                  ),
                  MetricTile(
                    label: 'Resistance',
                    value: '${metrics.resistance}/${EchelonProtocol.maxResistance}',
                    unit: '(${PowerCalculator.bikeResistanceToPeloton(metrics.resistance)}%)',
                    icon: Icons.fitness_center,
                    valueColor: context.secondaryColor,
                    progress: metrics.resistance / EchelonProtocol.maxResistance,
                    progressColor: context.secondaryColor,
                  ),
                  MetricTile(
                    label: 'Speed',
                    value: (metrics.speed * 0.621371).toStringAsFixed(1),
                    unit: 'MPH',
                    icon: Icons.directions_bike,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CompactMetricTile(
                      label: 'Elapsed',
                      value: _formatDuration(metrics.elapsedSeconds),
                      icon: Icons.timer_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CompactMetricTile(
                      label: 'Distance',
                      value: '${(metrics.distance * 0.621371).toStringAsFixed(2)} mi',
                      icon: Icons.straighten,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CompactMetricTile(
                      label: 'Calories',
                      value: metrics.calories.toStringAsFixed(0),
                      icon: Icons.local_fire_department,
                      color: context.warningColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildResistanceControls(context, ref, metrics.resistance),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(bleManagerProvider.notifier).endWorkout(),
                  icon: const Icon(Icons.stop),
                  label: const Text('END WORKOUT'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.errorColor,
                    side: BorderSide(color: context.errorColor),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Compact metric tile for landscape tablet layout
  Widget _buildCompactMetric(BuildContext context, String label, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.surfaceBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(label.toUpperCase(), style: AppTypography.labelSmall.copyWith(color: context.textMutedColor)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: AppTypography.displayMedium.copyWith(color: color, fontSize: 28)),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(unit, style: AppTypography.labelMedium.copyWith(color: context.textMutedColor)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Mini metric for secondary stats in landscape
  Widget _buildMiniMetric(BuildContext context, IconData icon, String value, [Color? color]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.surfaceBorderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color ?? context.textMutedColor),
          const SizedBox(width: 6),
          Flexible(child: Text(value, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600, color: context.textPrimaryColor), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  // Compact resistance controls for landscape tablet
  Widget _buildCompactResistanceControls(BuildContext context, WidgetRef ref, int currentResistance) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.surfaceBorderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('RESISTANCE', style: AppTypography.labelMedium.copyWith(color: context.textMutedColor)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: currentResistance > 1
                    ? () => ref.read(bleManagerProvider.notifier).setResistance(currentResistance - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 40,
                color: context.accentColor,
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  Text(currentResistance.toString(), style: AppTypography.displayMedium.copyWith(color: context.secondaryColor)),
                  Text('of ${EchelonProtocol.maxResistance}', style: AppTypography.labelSmall.copyWith(color: context.textMutedColor)),
                ],
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: currentResistance < EchelonProtocol.maxResistance
                    ? () => ref.read(bleManagerProvider.notifier).setResistance(currentResistance + 1)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 40,
                color: context.accentColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSmallPresetButton(context, ref, 10),
              _buildSmallPresetButton(context, ref, 20),
              _buildSmallPresetButton(context, ref, 30),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallPresetButton(BuildContext context, WidgetRef ref, int targetResistance) {
    return ElevatedButton(
      onPressed: () => ref.read(bleManagerProvider.notifier).setResistance(targetResistance),
      style: ElevatedButton.styleFrom(
        backgroundColor: context.surfaceLightColor,
        foregroundColor: context.textPrimaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(50, 36),
      ),
      child: Text(targetResistance.toString(), style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold, color: context.textPrimaryColor)),
    );
  }

  Widget _buildResistanceControls(BuildContext context, WidgetRef ref, int currentResistance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.surfaceBorderColor),
      ),
      child: Column(
        children: [
          Text(
            'RESISTANCE CONTROL',
            style: AppTypography.labelLarge.copyWith(color: context.textMutedColor),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Decrease button
              IconButton(
                onPressed: currentResistance > 1
                    ? () => ref.read(bleManagerProvider.notifier).setResistance(currentResistance - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 48,
                color: context.accentColor,
              ),
              const SizedBox(width: 24),
              // Current level
              Column(
                children: [
                  Text(
                    currentResistance.toString(),
                    style: AppTypography.displayMedium.copyWith(
                      color: context.secondaryColor,
                    ),
                  ),
                  Text(
                    'of ${EchelonProtocol.maxResistance}',
                    style: AppTypography.bodyMedium.copyWith(color: context.textSecondaryColor),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Increase button
              IconButton(
                onPressed: currentResistance < EchelonProtocol.maxResistance
                    ? () => ref.read(bleManagerProvider.notifier).setResistance(currentResistance + 1)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 48,
                color: context.accentColor,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Helper buttons (10, 20, 30)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPresetButton(context, ref, 10),
              _buildPresetButton(context, ref, 20),
              _buildPresetButton(context, ref, 30),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton(BuildContext context, WidgetRef ref, int targetResistance) {
    return ElevatedButton(
      onPressed: () => ref.read(bleManagerProvider.notifier).setResistance(targetResistance),
      style: ElevatedButton.styleFrom(
        backgroundColor: context.surfaceLightColor,
        foregroundColor: context.textPrimaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(
        targetResistance.toString(),
        style: AppTypography.titleMedium.copyWith(
          fontWeight: FontWeight.bold,
          color: context.textPrimaryColor,
        ),
      ),
    );
  }
}

class IdleDashboardView extends ConsumerWidget {
  const IdleDashboardView({super.key});

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ⚡ Performance: Only rebuild when relevant state changes
    final connectedDevice = ref.watch(bleManagerProvider.select((s) => s.connectedDevice));
    final lastWorkoutMetrics = ref.watch(bleManagerProvider.select((s) => s.lastWorkoutMetrics));

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Connected indicator with glow
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.surfaceColor,
                border: Border.all(color: context.successColor.withAlpha(128)),
                boxShadow: [
                  BoxShadow(
                    color: context.successColor.withAlpha(77),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 64,
                color: context.successColor,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Workout Complete!',
              style: AppTypography.headlineLarge.copyWith(color: context.textPrimaryColor),
            ),
            const SizedBox(height: 12),
            Text(
              'Connected to ${connectedDevice?.name ?? "Echelon"}',
              style: AppTypography.bodyLarge.copyWith(color: context.textSecondaryColor),
              textAlign: TextAlign.center,
            ),
            
            if (lastWorkoutMetrics != null && lastWorkoutMetrics.elapsedSeconds > 0) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.surfaceBorderColor),
                ),
                child: Column(
                  children: [
                    Text(
                      'PREVIOUS WORKOUT',
                      style: AppTypography.labelLarge.copyWith(color: context.textMutedColor),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          context: context,
                          label: 'TIME',
                          value: _formatDuration(lastWorkoutMetrics.elapsedSeconds),
                          icon: Icons.timer_outlined,
                        ),
                        _buildStatItem(
                          context: context,
                          label: 'DIST',
                          value: '${(lastWorkoutMetrics.distance * 0.621371).toStringAsFixed(2)} mi',
                          icon: Icons.straighten,
                        ),
                        _buildStatItem(
                          context: context,
                          label: 'CALS',
                          value: lastWorkoutMetrics.calories.toStringAsFixed(0),
                          icon: Icons.local_fire_department,
                          color: context.warningColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
            
            // Start new workout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(bleManagerProvider.notifier).startWorkout();
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('START FREE WORKOUT'),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Custom workouts button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WorkoutStylesScreen()),
                  );
                },
                icon: const Icon(Icons.fitness_center),
                label: const Text('CUSTOM WORKOUTS'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.accentColor,
                  side: BorderSide(color: context.accentColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Disconnect button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(bleManagerProvider.notifier).disconnect();
                },
                icon: const Icon(Icons.bluetooth_disabled),
                label: const Text('DISCONNECT'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.textMutedColor,
                  side: BorderSide(color: context.surfaceBorderColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? context.textMutedColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: context.textPrimaryColor,
          ),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: context.textMutedColor),
        ),
      ],
    );
  }
}

class DisconnectedDashboardView extends ConsumerWidget {
  const DisconnectedDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch relevant state for disconnected view
    final isScanning = ref.watch(bleManagerProvider.select((s) => s.isScanning));
    final errorMessage = ref.watch(bleManagerProvider.select((s) => s.errorMessage));
    final discoveredDevices = ref.watch(bleManagerProvider.select((s) => s.discoveredDevices));

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bike icon with glow
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.surfaceColor,
                border: Border.all(color: context.surfaceBorderColor),
                boxShadow: [
                  BoxShadow(
                    color: context.accentColor.withAlpha(51),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.directions_bike,
                size: 64,
                color: context.accentColor,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Connect Your Echelon',
              style: AppTypography.headlineLarge.copyWith(color: context.textPrimaryColor),
            ),
            const SizedBox(height: 12),
            Text(
              'Scan for nearby Echelon bikes to start your workout',
              style: AppTypography.bodyLarge.copyWith(color: context.textSecondaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Error message
            if (errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.errorColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.errorColor.withAlpha(77)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: context.errorColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: AppTypography.bodyMedium.copyWith(color: context.errorColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Scan button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isScanning
                    ? null
                    : () => ref.read(bleManagerProvider.notifier).startScan(),
                icon: isScanning
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(context.backgroundColor),
                        ),
                      )
                    : const Icon(Icons.bluetooth_searching),
                label: Text(isScanning ? 'SCANNING...' : 'SCAN FOR DEVICES'),
              ),
            ),
            
            // Discovered devices list
            if (discoveredDevices.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'DISCOVERED DEVICES',
                style: AppTypography.labelLarge.copyWith(color: context.textMutedColor),
              ),
              const SizedBox(height: 12),
              ...discoveredDevices.map((device) => _buildDeviceCard(context, ref, device)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(BuildContext context, WidgetRef ref, EchelonDeviceInfo device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => ref.read(bleManagerProvider.notifier).connectToDevice(device),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.surfaceBorderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.accentColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.directions_bike,
                    color: context.accentColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: AppTypography.titleMedium.copyWith(color: context.textPrimaryColor),
                      ),
                      Text(
                        'Signal: ${device.rssi} dBm',
                        style: AppTypography.bodyMedium.copyWith(color: context.textSecondaryColor),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: context.textMutedColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
