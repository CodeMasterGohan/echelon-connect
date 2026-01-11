/// PiP overlay widget for Picture-in-Picture mode
/// Displays Cadence, Speed, and Peloton Resistance % in a compact overlay
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:echelon_connect/core/bluetooth/ble_manager.dart';
import 'package:echelon_connect/core/bluetooth/echelon_protocol.dart';
import 'package:echelon_connect/theme/app_theme.dart';

/// Compact PiP overlay that shows essential workout metrics
class PipOverlay extends ConsumerWidget {
  const PipOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ⚡ Performance: Only rebuild when currentMetrics changes, not on any state change
    final metrics = ref.watch(bleManagerProvider.select((s) => s.currentMetrics));
    final pelotonResistance = PowerCalculator.bikeResistanceToPeloton(metrics.resistance);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildPipMetric(
                label: 'CAD',
                value: metrics.cadence.toString(),
                color: AppColors.accent,
              ),
              _buildDivider(),
              _buildPipMetric(
                label: 'SPD',
                value: (metrics.speed * 0.621371).toStringAsFixed(1),
                color: AppColors.textPrimary,
              ),
              _buildDivider(),
              _buildPipMetric(
                label: 'RES',
                value: '$pelotonResistance%',
                color: AppColors.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPipMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.displayMedium.copyWith(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.surfaceBorder,
    );
  }
}
