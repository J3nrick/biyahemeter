import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:biyahe_meter/core/theme/app_theme.dart';

/// Soft glass / clay surface used by floating dashboard cards.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final double blurSigma;
  final Color? color;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.blurSigma = 0,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fill = color ??
        theme.colorScheme.surface.withValues(alpha: isDark ? 0.72 : 0.82);
    final border = AppTheme.borderOf(context).withValues(alpha: isDark ? 0.55 : 0.9);

    final surface = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border, width: 0.8),
      ),
      child: child,
    );

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: blurSigma > 0
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: surface,
            )
          : surface,
    );

    return Container(
      margin: margin ?? EdgeInsets.zero,
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(borderRadius),
                child: content,
              ),
            ),
    );
  }
}

/// Metric tile: icon + label + large value + unit.
class MetricCard extends StatelessWidget {
  final dynamic icon;
  final String label;
  final String value;
  final String unit;
  final Color? accent;

  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = accent ?? theme.colorScheme.primary;
    final muted = AppTheme.mutedOf(context);

    return Semantics(
      label: '$label $value $unit',
      child: Container(
        constraints: const BoxConstraints(minHeight: 112),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.72 : 0.85,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppTheme.borderOf(context).withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: icon is FaIconData
                        ? FaIcon(icon as FaIconData, size: 14, color: accentColor)
                        : Icon(icon as IconData, size: 14, color: accentColor),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(color: muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              unit,
              style: theme.textTheme.labelSmall?.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact status chip (GPS / trip / connection).
class StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool active;

  const StatusChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.active = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = AppTheme.mutedOf(context);

    return Semantics(
      label: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: active ? 0.14 : 0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: color.withValues(alpha: active ? 0.45 : 0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: active ? color : muted),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: active ? color : muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
