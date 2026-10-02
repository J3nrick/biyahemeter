import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'package:biyahe_meter/core/theme/app_theme.dart';
import 'package:biyahe_meter/features/meter/home_screen.dart';
import 'package:biyahe_meter/features/meter/meter_provider.dart';
import 'package:biyahe_meter/features/onboarding/agreements_provider.dart';

/// Agreements / onboarding screen.
///
/// Design: iOS Settings-style grouped inset lists on a clean canvas.
/// No orbs, no decorative noise. Grouped translucent cards, inset
/// dividers, full-width pill CTA. Every surface is earned.
class AgreementsScreen extends StatefulWidget {
  const AgreementsScreen({super.key});

  @override
  State<AgreementsScreen> createState() => _AgreementsScreenState();
}

class _AgreementsScreenState extends State<AgreementsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ag = context.watch<AgreementsProvider>();
    final meter = context.watch<MeterProvider>();
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= 700 ? (width - 520) / 2 : 24.0;

    final accepted = [ag.acceptedTerms, ag.acceptedPrivacy, ag.verifiedGasData]
        .where((v) => v)
        .length;

    // ── Staggered intervals ──
    final f1 = CurvedAnimation(
        parent: _entry,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOut));
    final s1 = _slideAnim(0.0, 0.45);
    final f2 = CurvedAnimation(
        parent: _entry,
        curve: const Interval(0.10, 0.48, curve: Curves.easeOut));
    final f3 = CurvedAnimation(
        parent: _entry,
        curve: const Interval(0.20, 0.58, curve: Curves.easeOut));
    final s3 = _slideAnim(0.20, 0.62);
    final f4 = CurvedAnimation(
        parent: _entry,
        curve: const Interval(0.32, 0.70, curve: Curves.easeOut));
    final f5 = CurvedAnimation(
        parent: _entry,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOut));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ──
                    SlideTransition(
                      position: s1,
                      child: FadeTransition(
                        opacity: f1,
                        child: _Header(),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Progress ──
                    FadeTransition(
                      opacity: f2,
                      child: _Progress(accepted: accepted, total: 3,
                        onAcceptAll: ag.allAccepted
                            ? null
                            : () => context.read<AgreementsProvider>().acceptAll(),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Agreements section ──
                    SlideTransition(
                      position: s3,
                      child: FadeTransition(
                        opacity: f3,
                        child: _buildSection(
                          context,
                          label: 'SAFETY & USAGE',
                          child: _AgreementsList(ag: ag),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Defaults section ──
                    FadeTransition(
                      opacity: f4,
                      child: _buildSection(
                        context,
                        label: 'TRIP DEFAULTS',
                        child: _DefaultsList(meter: meter),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Bottom bar ──
            FadeTransition(
              opacity: f5,
              child: _BottomBar(
                enabled: ag.allAccepted,
                accepted: accepted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Animation<Offset> _slideAnim(double start, double end) {
    return Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entry,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    ));
  }

  Widget _buildSection(BuildContext ctx,
      {required String label, required Widget child}) {
    final theme = Theme.of(ctx);
    final primary = theme.colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: primary.withValues(alpha: 0.70),
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  HEADER
// ═══════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = AppTheme.mutedOf(context);
    final onSurface = theme.colorScheme.onSurface;

    return Column(
      children: [
        // Logo — small, restrained, no glow
        Hero(
          tag: 'biyahemeter-logo',
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface
                  .withValues(alpha: isDark ? 0.60 : 0.95),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: onSurface.withValues(alpha: isDark ? 0.08 : 0.06),
                width: 0.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14.5),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Title — Large Title weight, tight tracking
        Text(
          'Before You Ride',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            fontSize: 28,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle — crisp, one-line
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Review and acknowledge these items to get started.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: muted,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PROGRESS
// ═══════════════════════════════════════════════════════════════

class _Progress extends StatelessWidget {
  final int accepted;
  final int total;
  final VoidCallback? onAcceptAll;

  const _Progress({
    required this.accepted,
    required this.total,
    this.onAcceptAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final muted = AppTheme.mutedOf(context);
    final onSurface = theme.colorScheme.onSurface;
    final done = accepted == total;
    final frac = accepted / total;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: isDark ? 0.55 : 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: onSurface.withValues(alpha: isDark ? 0.07 : 0.05),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Status icon
              Icon(
                done
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.circle,
                size: 20,
                color: done ? primary : muted.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  done
                      ? 'All set — you\'re ready.'
                      : '$accepted of $total acknowledged',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (onAcceptAll != null)
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  onPressed: onAcceptAll,
                  child: Text(
                    'Accept All',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Thin progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(1.5),
            child: SizedBox(
              height: 3,
              child: Stack(
                children: [
                  Container(color: onSurface.withValues(alpha: isDark ? 0.06 : 0.04)),
                  AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    widthFactor: frac,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1.5),
                        color: primary.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  AGREEMENTS LIST
// ═══════════════════════════════════════════════════════════════

class _AgreementsList extends StatelessWidget {
  final AgreementsProvider ag;

  const _AgreementsList({required this.ag});

  @override
  Widget build(BuildContext context) {
    return _GroupedCard(
      children: [
        _AgreementRow(
          icon: CupertinoIcons.doc_text,
          title: 'Fare Estimates & Terms',
          subtitle: 'Fares are estimates and may vary with traffic.',
          value: ag.acceptedTerms,
          onTap: () => context
              .read<AgreementsProvider>()
              .toggleTerms(!ag.acceptedTerms),
        ),
        _AgreementRow(
          icon: CupertinoIcons.location,
          title: 'Route & Data Privacy',
          subtitle: 'Location for distance calculation. Data stays private.',
          value: ag.acceptedPrivacy,
          onTap: () => context
              .read<AgreementsProvider>()
              .togglePrivacy(!ag.acceptedPrivacy),
        ),
        _AgreementRow(
          icon: CupertinoIcons.gauge,
          title: 'Responsible Rate Use',
          subtitle: 'Fuel prices are customizable guides for fair metering.',
          value: ag.verifiedGasData,
          onTap: () => context
              .read<AgreementsProvider>()
              .toggleGasData(!ag.verifiedGasData),
        ),
      ],
    );
  }
}

class _AgreementRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final VoidCallback onTap;

  const _AgreementRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final muted = AppTheme.mutedOf(context);

    return Material(
      color: value
          ? primary.withValues(alpha: isDark ? 0.05 : 0.025)
          : Colors.transparent,
      child: InkWell(
        onTap: () {
          onTap();
          try { HapticFeedback.selectionClick(); } catch (_) {}
        },
        splashColor: primary.withValues(alpha: 0.04),
        highlightColor: primary.withValues(alpha: 0.02),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon — outline style, not filled
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(icon, size: 18, color: primary.withValues(alpha: 0.70)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: muted,
                        height: 1.35,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Checkbox — clean, no glow/shadow
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: _Checkbox(value: value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  final bool value;
  const _Checkbox({required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: value ? primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: value
              ? primary
              : onSurface.withValues(alpha: isDark ? 0.15 : 0.18),
          width: value ? 0 : 1.5,
        ),
      ),
      child: AnimatedScale(
        scale: value ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: Icon(
          Icons.check_rounded,
          size: 14,
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  DEFAULTS LIST
// ═══════════════════════════════════════════════════════════════

class _DefaultsList extends StatelessWidget {
  final MeterProvider meter;

  const _DefaultsList({required this.meter});

  @override
  Widget build(BuildContext context) {
    return _GroupedCard(
      children: [
        _DefaultRow(
          icon: FontAwesomeIcons.gasPump,
          label: 'Fuel efficiency',
          value: '${meter.kmPerLiter.toStringAsFixed(1)} km/L',
        ),
        _DefaultRow(
          icon: FontAwesomeIcons.pesoSign,
          label: 'Gas price',
          value: '₱${meter.gasPricePerLiter.toStringAsFixed(2)}/L',
        ),
        _DefaultRow(
          icon: FontAwesomeIcons.coins,
          label: 'Base fare',
          value: '₱${meter.baseFare.toStringAsFixed(0)}',
        ),
      ],
    );
  }
}

class _DefaultRow extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final String value;

  const _DefaultRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          FaIcon(icon, size: 13, color: primary.withValues(alpha: 0.65)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  GROUPED CARD (reusable iOS-style inset group)
// ═══════════════════════════════════════════════════════════════

class _GroupedCard extends StatelessWidget {
  final List<Widget> children;

  const _GroupedCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    final divider = Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Container(
        height: 0.5,
        color: onSurface.withValues(alpha: isDark ? 0.07 : 0.06),
      ),
    );

    final items = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) items.add(divider);
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: isDark ? 0.55 : 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: onSurface.withValues(alpha: isDark ? 0.07 : 0.05),
          width: 0.5,
        ),
      ),
      child: Column(children: items),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  BOTTOM BAR
// ═══════════════════════════════════════════════════════════════

class _BottomBar extends StatelessWidget {
  final bool enabled;
  final int accepted;

  const _BottomBar({required this.enabled, required this.accepted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final muted = AppTheme.mutedOf(context);
    final onSurface = theme.colorScheme.onSurface;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 12, 24, bottom + 14),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withValues(alpha: isDark ? 0.80 : 0.88),
            border: Border(
              top: BorderSide(
                color: onSurface.withValues(alpha: isDark ? 0.06 : 0.05),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Full-width pill CTA ──
              _PillButton(
                label: 'Continue',
                enabled: enabled,
                onPressed: enabled
                    ? () => Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, a, _) => const HomeScreen(),
                            transitionsBuilder: (context, a, _, child) =>
                                FadeTransition(
                              opacity: CurvedAnimation(
                                parent: a,
                                curve: Curves.easeOut,
                              ),
                              child: child,
                            ),
                            transitionDuration:
                                const Duration(milliseconds: 350),
                          ),
                        )
                    : null,
              ),

              // Hint text
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: enabled
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'You can adjust settings anytime.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: muted.withValues(alpha: 0.60),
                            fontSize: 11,
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          accepted == 0
                              ? 'Acknowledge all 3 items to continue'
                              : '${3 - accepted} remaining',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: muted.withValues(alpha: 0.50),
                            fontSize: 11,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width pill button — 52pt height, solid accent, immediate press
/// feedback via scale. No gradient, no shadow circus.
class _PillButton extends StatefulWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onPressed;

  const _PillButton({
    required this.label,
    required this.enabled,
    this.onPressed,
  });

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final muted = AppTheme.mutedOf(context);
    final active = widget.enabled && widget.onPressed != null;

    return GestureDetector(
      onTapDown: active ? (_) => setState(() => _pressed = true) : null,
      onTapUp: active
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
              try { HapticFeedback.mediumImpact(); } catch (_) {}
            }
          : null,
      onTapCancel: active ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? primary
                : theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: isDark ? 0.50 : 0.80),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            widget.label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: active ? theme.colorScheme.onPrimary : muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
