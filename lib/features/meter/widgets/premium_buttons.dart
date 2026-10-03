import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:biyahe_meter/core/theme/app_theme.dart';

enum AppHaptic {
  selection,
  light,
  medium,
  heavy,
}

/// Shared press interaction: scale + optional haptic.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final bool enabled;
  final AppHaptic haptic;
  final double pressedScale;
  final BorderRadius? borderRadius;

  const Pressable({
    super.key,
    required this.child,
    required this.onPressed,
    this.semanticLabel,
    this.enabled = true,
    this.haptic = AppHaptic.light,
    this.pressedScale = 0.97,
    this.borderRadius,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
    if (value && !kIsWeb) {
      HapticFeedback.lightImpact(); // Subtle vibration on press down
    }
  }

  Future<void> _fireHaptic() async {
    if (kIsWeb) return;
    try {
      switch (widget.haptic) {
        case AppHaptic.selection:
          await HapticFeedback.selectionClick();
        case AppHaptic.light:
          await HapticFeedback.lightImpact();
        case AppHaptic.medium:
          await HapticFeedback.mediumImpact();
        case AppHaptic.heavy:
          await HapticFeedback.heavyImpact();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && widget.onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: AnimatedScale(
        scale: _pressed && enabled ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled
                ? () {
                    // Fire action first so web never stalls on haptic futures.
                    widget.onPressed?.call();
                    _fireHaptic();
                  }
                : null,
            onTapDown: enabled ? (_) => _setPressed(true) : null,
            onTapUp: enabled ? (_) => _setPressed(false) : null,
            onTapCancel: enabled ? () => _setPressed(false) : null,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
            splashColor: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.12),
            highlightColor: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.06),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Premium interactive button combining dual-stage touch feedback (lightImpact on
/// press down, selectionClick on release), micro-animation physical depress scaling
/// (95% scale + shadow collapse for a "pushed in" feel), and dynamic responsive layout constraints.
class PremiumInteractiveButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool isLoading;
  final IconData? icon;
  final Widget? trailing;
  final Color? backgroundColor;
  final Color? textColor;
  final double maxWidth;
  final double height;
  final BorderRadius? borderRadius;

  const PremiumInteractiveButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled = true,
    this.isLoading = false,
    this.icon,
    this.trailing,
    this.backgroundColor,
    this.textColor,
    this.maxWidth = 420,
    this.height = 54,
    this.borderRadius,
  });

  @override
  State<PremiumInteractiveButton> createState() =>
      _PremiumInteractiveButtonState();
}

class _PremiumInteractiveButtonState extends State<PremiumInteractiveButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled || widget.isLoading) return;
    setState(() => _isPressed = true);
    if (!kIsWeb) {
      HapticFeedback.lightImpact(); // Subtle vibration on press
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled || widget.isLoading) return;
    setState(() => _isPressed = false);
    if (!kIsWeb) {
      HapticFeedback.selectionClick(); // Distinct tactile feedback on release
    }
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = widget.backgroundColor ?? theme.colorScheme.primary;
    final enabled =
        widget.enabled && !widget.isLoading && widget.onPressed != null;

    final disabledBg = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);
    final disabledFg = isDark
        ? const Color(0xFF64748B)
        : const Color(0xFF94A3B8);

    final effectiveBg = enabled ? primary : disabledBg;
    final effectiveFg =
        enabled ? (widget.textColor ?? Colors.white) : disabledFg;

    final br = widget.borderRadius ?? BorderRadius.circular(16);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        child: GestureDetector(
          onTapDown: enabled ? _handleTapDown : null,
          onTapUp: enabled ? _handleTapUp : null,
          onTapCancel: enabled ? _handleTapCancel : null,
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(
            scale: _isPressed && enabled ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              width: double.infinity, // Adapts to parent width up to maxWidth
              height: widget.height,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
              color: enabled
                  ? (_isPressed
                      ? Color.lerp(primary, Colors.black, 0.14)
                      : primary)
                  : effectiveBg,
              borderRadius: br,
              border: Border.all(
                color: enabled
                    ? Colors.white.withValues(alpha: 0.18)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05)),
                width: 1,
              ),
              boxShadow: enabled && !_isPressed
                  ? [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.32),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [], // Shadow collapses on press for a "pushed in" depth
            ),
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(effectiveFg),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: effectiveFg, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            widget.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: effectiveFg,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        if (widget.trailing != null) ...[
                          const SizedBox(width: 8),
                          widget.trailing!,
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    ),
  );
}
}

enum TripActionKind { start, resume, stop }

/// Primary meter CTA — color, copy, and haptic match the action purpose.
class TripActionButton extends StatelessWidget {
  final TripActionKind kind;
  final VoidCallback onPressed;
  final bool compact;

  const TripActionButton({
    super.key,
    required this.kind,
    required this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    late final Color accent;
    late final String title;
    late final String subtitle;
    late final IconData icon;
    late final AppHaptic haptic;

    switch (kind) {
      case TripActionKind.start:
        accent = primary;
        title = 'Start Trip';
        subtitle = 'Begin live GPS metering';
        icon = Icons.play_arrow_rounded;
        haptic = AppHaptic.medium;
      case TripActionKind.resume:
        accent = primary;
        title = 'Resume Trip';
        subtitle = 'Continue from current totals';
        icon = Icons.play_circle_fill_rounded;
        haptic = AppHaptic.medium;
      case TripActionKind.stop:
        accent = AppTheme.dangerOf(context);
        title = 'Stop Trip';
        subtitle = 'Pause tracking & keep totals';
        icon = Icons.stop_rounded;
        haptic = AppHaptic.heavy;
    }

    final depth = Color.lerp(accent, Colors.black, 0.22)!;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Pressable(
          onPressed: onPressed,
          semanticLabel: '$title. $subtitle',
          haptic: haptic,
          pressedScale: 0.97,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            height: compact ? 58 : 64,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent, depth],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: compact ? 36 : 40,
                  height: compact ? 36 : 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: compact ? 22 : 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          height: 1.1,
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact glass icon control for headers and map chrome.
class PremiumIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Color? iconColor;
  final Color? accent;
  final bool active;
  final bool danger;
  final AppHaptic haptic;

  const PremiumIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.iconColor,
    this.accent,
    this.active = false,
    this.danger = false,
    this.haptic = AppHaptic.selection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tone = danger
        ? AppTheme.dangerOf(context)
        : (accent ?? theme.colorScheme.primary);
    final fg = iconColor ??
        (active || danger ? tone : theme.colorScheme.onSurface);

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: Pressable(
        onPressed: onPressed,
        semanticLabel: tooltip,
        haptic: haptic,
        pressedScale: 0.94,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: active
                ? tone.withValues(alpha: isDark ? 0.22 : 0.14)
                : theme.colorScheme.surface.withValues(alpha: isDark ? 0.88 : 0.94),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active || danger
                  ? tone.withValues(alpha: 0.55)
                  : AppTheme.borderOf(context).withValues(alpha: 0.85),
              width: active ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
                blurRadius: active ? 14 : 10,
                offset: const Offset(0, 4),
              ),
              if (active)
                BoxShadow(
                  color: tone.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 0.5,
                ),
            ],
          ),
          child: Icon(icon, size: 22, color: fg),
        ),
      ),
    );
  }
}

/// Secondary surface CTA (settings entry, etc.).
class PremiumSurfaceButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final Color? accent;

  const PremiumSurfaceButton({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = AppTheme.mutedOf(context);
    final tone = accent ?? theme.colorScheme.primary;

    return Pressable(
      onPressed: onPressed,
      semanticLabel: '$title. $subtitle',
      haptic: AppHaptic.light,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderOf(context)),
          boxShadow: AppTheme.softShadow(context),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: tone, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chevron_right_rounded, color: tone, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width confirm CTA with clear enabled/disabled purpose.
class PremiumConfirmButton extends StatelessWidget {
  final String label;
  final String? hintWhenDisabled;
  final bool enabled;
  final VoidCallback? onPressed;
  final IconData icon;

  const PremiumConfirmButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.hintWhenDisabled,
    this.icon = Icons.arrow_forward_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final muted = AppTheme.mutedOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Pressable(
          onPressed: enabled ? onPressed : null,
          enabled: enabled,
          semanticLabel: enabled
              ? label
              : (hintWhenDisabled ?? 'Complete required items first'),
          haptic: AppHaptic.medium,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              gradient: enabled
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primary,
                        Color.lerp(primary, Colors.black, 0.16)!,
                      ],
                    )
                  : null,
              color: enabled
                  ? null
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: enabled
                    ? Colors.white.withValues(alpha: 0.16)
                    : AppTheme.borderOf(context),
              ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.32),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: enabled ? 1 : 0.55,
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: enabled
                          ? theme.colorScheme.onPrimary
                          : muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: enabled
                        ? Colors.white.withValues(alpha: 0.18)
                        : muted.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: enabled ? theme.colorScheme.onPrimary : muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!enabled && hintWhenDisabled != null) ...[
          const SizedBox(height: 8),
          Text(
            hintWhenDisabled!,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(color: muted),
          ),
        ],
      ],
    );
  }
}
