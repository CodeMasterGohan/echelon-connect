/// Metric Tile Widget - Displays a single workout metric
library;

import 'package:flutter/material.dart';
import 'package:echelon_connect/theme/app_theme.dart';

class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color? valueColor;
  final double? progress; // 0.0 to 1.0 for progress bar
  final Color? progressColor;
  final bool isLarge;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    this.valueColor,
    this.progress,
    this.progressColor,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 20 : 16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.surfaceBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: (valueColor ?? context.accentColor).withAlpha(25),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row with icon and label
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: valueColor ?? context.accentColor,
              ),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: AppTypography.labelLarge.copyWith(
                  color: context.textMutedColor,
                ),
              ),
            ],
          ),
          SizedBox(height: isLarge ? 16 : 12),
          
          // Value
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: isLarge
                    ? AppTypography.displayLarge.copyWith(
                        color: valueColor ?? context.textPrimaryColor,
                      )
                    : AppTypography.metricValue.copyWith(
                        color: valueColor ?? context.textPrimaryColor,
                        fontSize: 36,
                      ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: AppTypography.metricUnit.copyWith(
                  color: context.textMutedColor,
                ),
              ),
            ],
          ),
          
          // Progress bar (optional)
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                backgroundColor: context.surfaceLightColor,
                valueColor: AlwaysStoppedAnimation(
                  progressColor ?? valueColor ?? context.accentColor,
                ),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact metric for secondary stats
class CompactMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const CompactMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.surfaceBorderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: color ?? context.textMutedColor,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryColor,
                ),
              ),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: context.textMutedColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
