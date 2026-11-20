import 'package:flutter/material.dart';

import '../../app/atlas_academy_app.dart';
import '../../theme/atlas_spacing.dart';

class AtlasLinearProgress extends StatelessWidget {
  const AtlasLinearProgress({
    super.key,
    required this.progress,
    this.height = 8,
    this.backgroundColor,
    this.progressColor,
    this.showPercentage = false,
    this.animationDuration = const Duration(
      milliseconds: 900,
    ),
  });

  final double progress;
  final double height;
  final Color? backgroundColor;
  final Color? progressColor;
  final bool showPercentage;
  final Duration animationDuration;

  double get normalizedProgress =>
      progress.clamp(0.0, 1.0).toDouble();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showPercentage) ...[
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(normalizedProgress * 100).round()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AtlasColors.deepTeal,
              ),
            ),
          ),
          const SizedBox(height: 7),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(
            AtlasRadius.pill,
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(
              begin: 0,
              end: normalizedProgress,
            ),
            duration: animationDuration,
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                minHeight: height,
                backgroundColor: backgroundColor ??
                    AtlasColors.softTeal,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progressColor ?? AtlasColors.oceanTeal,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class AtlasCircularProgress extends StatelessWidget {
  const AtlasCircularProgress({
    super.key,
    required this.progress,
    this.size = 110,
    this.strokeWidth = 9,
    this.progressColor,
    this.backgroundColor,
    this.label,
    this.showPercentage = true,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Color? progressColor;
  final Color? backgroundColor;
  final String? label;
  final bool showPercentage;

  double get normalizedProgress =>
      progress.clamp(0.0, 1.0).toDouble();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(
          begin: 0,
          end: normalizedProgress,
        ),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: strokeWidth,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    backgroundColor ??
                        AtlasColors.softTeal,
                  ),
                ),
              ),
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: strokeWidth,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progressColor ??
                        AtlasColors.oceanTeal,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showPercentage)
                    Text(
                      '${(normalizedProgress * 100).round()}%',
                      style: TextStyle(
                        fontSize: size * 0.22,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface,
                      ),
                    ),
                  if (label != null)
                    Text(
                      label!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: size * 0.105,
                        fontWeight: FontWeight.w600,
                        color: AtlasColors.secondaryText,
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class AtlasProgressTile extends StatelessWidget {
  const AtlasProgressTile({
    super.key,
    required this.title,
    required this.completed,
    required this.total,
    this.icon,
    this.progressColor,
  });

  final String title;
  final int completed;
  final int total;
  final IconData? icon;
  final Color? progressColor;

  double get progress {
    if (total <= 0) return 0;
    return (completed / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 19,
                color: AtlasColors.oceanTeal,
              ),
              const SizedBox(width: 9),
            ],
            Expanded(
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Text(
              '$completed/$total',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AtlasColors.oceanTeal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AtlasLinearProgress(
          progress: progress,
          height: 7,
          progressColor: progressColor,
        ),
      ],
    );
  }
}

class AtlasScoreIndicator extends StatelessWidget {
  const AtlasScoreIndicator({
    super.key,
    required this.score,
    this.label = 'Exam Score',
    this.size = 92,
  });

  final double score;
  final String label;
  final double size;

  Color get scoreColor {
    if (score >= 80) return AtlasColors.success;
    if (score >= 50) return AtlasColors.gold;
    return AtlasColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final normalizedScore =
        (score / 100).clamp(0.0, 1.0).toDouble();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AtlasCircularProgress(
          progress: normalizedScore,
          size: size,
          strokeWidth: 8,
          progressColor: scoreColor,
          showPercentage: false,
          label: '${score.round()}%',
        ),
        const SizedBox(height: 9),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
