/// Dashboard Screen - Main workout display
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:echelon_connect/core/bluetooth/ble_manager.dart';
import 'package:echelon_connect/core/bluetooth/echelon_protocol.dart';
import 'package:echelon_connect/core/services/voice_control_service.dart';
import 'package:echelon_connect/theme/app_theme.dart';
import 'package:echelon_connect/features/dashboard/widgets/metric_tile.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize voice control on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceControlProvider.notifier).initialize();
    });
  }

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
  Widget build(BuildContext context) {
    final bleState = ref.watch(bleManagerProvider);
    final metrics = bleState.currentMetrics;

    // Auto-enable/disable voice control based on workout state
    ref.listen<BleManagerState>(bleManagerProvider, (previous, next) {
      final wasActive = previous?.isWorkoutActive ?? false;
      final isActive = next.isWorkoutActive;
      
      if (!wasActive && isActive) {
        // Workout just started - auto-enable voice control
        ref.read(voiceControlProvider.notifier).setEnabled(true);
      } else if (wasActive && !isActive) {
        // Workout ended - disable voice control
        ref.read(voiceControlProvider.notifier).setEnabled(false);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bolt,
              color: bleState.isConnected ? AppColors.success : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'ECHELON CONNECT',
              style: AppTypography.titleMedium.copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          // Voice control toggle (only show during workout)
          if (bleState.isWorkoutActive)
            _buildVoiceControlButton(ref),
          // Connection status indicator
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: bleState.isConnected 
                  ? AppColors.success.withOpacity(0.2)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: bleState.isConnected ? AppColors.success : AppColors.surfaceBorder,
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
                    color: bleState.isConnected ? AppColors.success : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  bleState.isConnected ? 'Connected' : 'Disconnected',
                  style: AppTypography.labelMedium.copyWith(
                    color: bleState.isConnected ? AppColors.success : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: bleState.isWorkoutActive
            ? _buildConnectedView(context, ref, metrics)
            : bleState.connectionState == EchelonConnectionState.idle
                ? _buildIdleView(context, ref, bleState)
                : _buildDisconnectedView(context, ref, bleState),
      ),
    );
  }

  Widget _buildConnectedView(BuildContext context, WidgetRef ref, WorkoutMetrics metrics) {
    final powerColor = AppColors.getPowerZoneColor(metrics.power, 200); // TODO: Get FTP from settings

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Main metrics grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth > 600;
              final crossAxisCount = isTablet ? 3 : 2;
              final spacing = 12.0;
              
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: isTablet ? 1.3 : 1.1,
                children: [
                  // Power
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
                  // Cadence
                  MetricTile(
                    label: 'Cadence',
                    value: metrics.cadence.toString(),
                    unit: 'RPM',
                    icon: Icons.speed,
                    valueColor: AppColors.accent,
                    progress: (metrics.cadence / 120).clamp(0.0, 1.0),
                  ),
                  // Resistance
                  MetricTile(
                    label: 'Resistance',
                    value: '${metrics.resistance}/${EchelonProtocol.maxResistance}',
                    unit: '',
                    icon: Icons.fitness_center,
                    valueColor: AppColors.secondary,
                    progress: metrics.resistance / EchelonProtocol.maxResistance,
                    progressColor: AppColors.secondary,
                  ),
                  // Speed
                  MetricTile(
                    label: 'Speed',
                    value: metrics.speed.toStringAsFixed(1),
                    unit: 'km/h',
                    icon: Icons.directions_bike,
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Secondary metrics row
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
                  value: '${metrics.distance.toStringAsFixed(2)} km',
                  icon: Icons.straighten,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CompactMetricTile(
                  label: 'Calories',
                  value: metrics.calories.toStringAsFixed(0),
                  icon: Icons.local_fire_department,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Resistance controls
          _buildResistanceControls(ref, metrics.resistance),
          
          const SizedBox(height: 24),
          
          // Stop workout button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(bleManagerProvider.notifier).endWorkout();
              },
              icon: const Icon(Icons.stop),
              label: const Text('END WORKOUT'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceControlButton(WidgetRef ref) {
    final voiceState = ref.watch(voiceControlProvider);
    final isActive = voiceState.isEnabled && voiceState.isListening;
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: IconButton(
        onPressed: () async {
          final notifier = ref.read(voiceControlProvider.notifier);
          if (!voiceState.isAvailable) {
            await notifier.initialize();
          }
          await notifier.toggle();
        },
        icon: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive 
                ? AppColors.accent.withOpacity(0.2)
                : AppColors.surfaceLight,
            border: Border.all(
              color: isActive ? AppColors.accent : AppColors.surfaceBorder,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Icon(
            voiceState.isEnabled ? Icons.mic : Icons.mic_off,
            color: isActive ? AppColors.accent : AppColors.textMuted,
            size: 20,
          ),
        ),
        tooltip: voiceState.isEnabled ? 'Voice control ON' : 'Voice control OFF',
      ),
    );
  }

  Widget _buildResistanceControls(WidgetRef ref, int currentResistance) {
    final voiceState = ref.watch(voiceControlProvider);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Text(
            'RESISTANCE CONTROL',
            style: AppTypography.labelLarge,
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
                color: AppColors.accent,
              ),
              const SizedBox(width: 24),
              // Current level
              Column(
                children: [
                  Text(
                    currentResistance.toString(),
                    style: AppTypography.displayMedium.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                  Text(
                    'of ${EchelonProtocol.maxResistance}',
                    style: AppTypography.bodyMedium,
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
                color: AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Helper buttons (10, 20, 30)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPresetButton(ref, 10),
              _buildPresetButton(ref, 20),
              _buildPresetButton(ref, 30),
            ],
          ),
          // Voice control status indicator
          if (voiceState.isEnabled) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: voiceState.isListening 
                    ? AppColors.accent.withOpacity(0.1)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: voiceState.isListening 
                      ? AppColors.accent.withOpacity(0.5)
                      : AppColors.surfaceBorder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    voiceState.isListening ? Icons.mic : Icons.mic_off,
                    color: voiceState.isListening ? AppColors.accent : AppColors.textMuted,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    voiceState.lastRecognizedResistance != null
                        ? 'Set to ${voiceState.lastRecognizedResistance}'
                        : voiceState.isListening
                            ? 'Say "Echelon [1-32]"'
                            : 'Voice control enabled',
                    style: AppTypography.labelMedium.copyWith(
                      color: voiceState.isListening ? AppColors.accent : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPresetButton(WidgetRef ref, int targetResistance) {
    return ElevatedButton(
      onPressed: () => ref.read(bleManagerProvider.notifier).setResistance(targetResistance),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(
        targetResistance.toString(),
        style: AppTypography.titleMedium.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildIdleView(BuildContext context, WidgetRef ref, BleManagerState bleState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Connected indicator with glow
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.success.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.3),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 64,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Workout Complete!',
              style: AppTypography.headlineLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Connected to ${bleState.connectedDevice?.name ?? "Echelon"}',
              style: AppTypography.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Start new workout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(bleManagerProvider.notifier).startWorkout();
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('START NEW WORKOUT'),
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
                  foregroundColor: AppColors.textMuted,
                  side: BorderSide(color: AppColors.surfaceBorder),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisconnectedView(BuildContext context, WidgetRef ref, BleManagerState bleState) {
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
                color: AppColors.surface,
                border: Border.all(color: AppColors.surfaceBorder),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.directions_bike,
                size: 64,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Connect Your Echelon',
              style: AppTypography.headlineLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Scan for nearby Echelon bikes to start your workout',
              style: AppTypography.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Error message
            if (bleState.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        bleState.errorMessage!,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
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
                onPressed: bleState.isScanning
                    ? null
                    : () => ref.read(bleManagerProvider.notifier).startScan(),
                icon: bleState.isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.background),
                        ),
                      )
                    : const Icon(Icons.bluetooth_searching),
                label: Text(bleState.isScanning ? 'SCANNING...' : 'SCAN FOR DEVICES'),
              ),
            ),
            
            // Discovered devices list
            if (bleState.discoveredDevices.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'DISCOVERED DEVICES',
                style: AppTypography.labelLarge,
              ),
              const SizedBox(height: 12),
              ...bleState.discoveredDevices.map((device) => _buildDeviceCard(ref, device)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(WidgetRef ref, EchelonDeviceInfo device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => ref.read(bleManagerProvider.notifier).connectToDevice(device),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_bike,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: AppTypography.titleMedium,
                      ),
                      Text(
                        'Signal: ${device.rssi} dBm',
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
