import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'package:biyahe_meter/core/theme/app_theme.dart';
import 'package:biyahe_meter/features/meter/home_screen.dart';
import 'package:biyahe_meter/features/meter/meter_provider.dart';
import 'package:biyahe_meter/features/meter/widgets/premium_buttons.dart';
import 'package:biyahe_meter/features/onboarding/agreements_provider.dart';

class AgreementsScreen extends StatelessWidget {
  const AgreementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ag = context.watch<AgreementsProvider>();
    final meter = context.watch<MeterProvider>();
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isNarrow = width < 360;
    final horizontal = width >= 700 ? (width - 540) / 2 : 20.0;

    final acceptedCount = [
      ag.acceptedTerms,
      ag.acceptedPrivacy,
      ag.verifiedGasData,
    ].where((v) => v).length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient background glow
          Positioned(
            top: -100,
            left: -60,
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.10),
                      theme.colorScheme.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        EdgeInsets.fromLTRB(horizontal, 20, horizontal, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Header(isNarrow: isNarrow),
                        const SizedBox(height: 20),
                        _ProgressPill(
                          acceptedCount: acceptedCount,
                          total: 3,
                          onAcceptAll: ag.allAccepted
                              ? null
                              : () => context
                                  .read<AgreementsProvider>()
                                  .acceptAll(),
                        ),
                        const SizedBox(height: 18),
                        const _SectionLabel(
                          title: 'Travel Safety & Usage Agreement',
                          subtitle:
                              'Acknowledge each point below to ensure safe and clear metering.',
                        ),
                        const SizedBox(height: 10),
                        _AgreementsCard(ag: ag),
                        const SizedBox(height: 22),
                        const _SectionLabel(
                          title: 'Initial Trip Defaults',
                          subtitle:
                              'Standard baseline values. Adjust anytime in settings.',
                        ),
                        const SizedBox(height: 10),
                        _DefaultsCard(meter: meter),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                _BottomActionBar(
                  enabled: ag.allAccepted,
                  acceptedCount: acceptedCount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isNarrow;

  const _Header({required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = AppTheme.mutedOf(context);

    return Column(
      children: [
        Hero(
          tag: 'biyahemeter-logo',
          child: Container(
            padding: EdgeInsets.all(isNarrow ? 14 : 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.borderOf(context)),
              boxShadow: AppTheme.softShadow(context),
            ),
            child: Image.asset(
              'assets/images/logo.png',
              height: isNarrow ? 68 : 80,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Welcome to Byahe Meter',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Before you start your byahe, let\'s make sure we\'re on the same page.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: muted,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ProgressPill extends StatelessWidget {
  final int acceptedCount;
  final int total;
  final VoidCallback? onAcceptAll;

  const _ProgressPill({
    required this.acceptedCount,
    required this.total,
    this.onAcceptAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = AppTheme.mutedOf(context);
    final primary = theme.colorScheme.primary;
    final isComplete = acceptedCount == total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderOf(context)),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: isComplete ? 0.16 : 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isComplete
                  ? CupertinoIcons.checkmark_seal_fill
                  : CupertinoIcons.checkmark_seal,
              size: 16,
              color: primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isComplete
                      ? '3 of 3 acknowledged'
                      : '$acceptedCount of $total acknowledged',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  isComplete
                      ? 'All requirements satisfied'
                      : 'Tap cards to acknowledge',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (onAcceptAll != null)
            TextButton(
              onPressed: onAcceptAll,
              style: TextButton.styleFrom(
                foregroundColor: primary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Accept all',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionLabel({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = AppTheme.mutedOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
      ],
    );
  }
}

class _AgreementsCard extends StatelessWidget {
  final AgreementsProvider ag;

  const _AgreementsCard({required this.ag});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderOf(context)),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: Column(
        children: [
          _AgreementTile(
            icon: CupertinoIcons.doc_text_fill,
            title: 'Fare Estimates & Terms',
            subtitle:
                'Understand that fares shown are estimates and may vary based on actual traffic conditions.',
            value: ag.acceptedTerms,
            isFirst: true,
            onTap: () => context
                .read<AgreementsProvider>()
                .toggleTerms(!ag.acceptedTerms),
          ),
          Divider(height: 1, color: AppTheme.borderOf(context)),
          _AgreementTile(
            icon: CupertinoIcons.location_fill,
            title: 'Route & Data Privacy',
            subtitle:
                'Allow location access for real-time trip distance calculation. Your location data remains private.',
            value: ag.acceptedPrivacy,
            onTap: () => context
                .read<AgreementsProvider>()
                .togglePrivacy(!ag.acceptedPrivacy),
          ),
          Divider(height: 1, color: AppTheme.borderOf(context)),
          _AgreementTile(
            icon: CupertinoIcons.gauge_badge_plus,
            title: 'Responsible Gas & Rate Use',
            subtitle:
                'Fuel prices and rates are customizable guides to ensure fair calculations for your byahe.',
            value: ag.verifiedGasData,
            isLast: true,
            onTap: () => context
                .read<AgreementsProvider>()
                .toggleGasData(!ag.verifiedGasData),
          ),
        ],
      ),
    );
  }
}

class _AgreementTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _AgreementTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final muted = AppTheme.mutedOf(context);
    final isDark = theme.brightness == Brightness.dark;

    final tileBg = value
        ? primary.withValues(alpha: isDark ? 0.08 : 0.04)
        : Colors.transparent;

    return Material(
      color: tileBg,
      child: InkWell(
        onTap: () {
          onTap();
          try {
            HapticFeedback.selectionClick();
          } catch (_) {}
        },
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(20) : Radius.zero,
          bottom: isLast ? const Radius.circular(20) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: value
                      ? primary.withValues(alpha: 0.16)
                      : primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 19,
                    color: primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Custom visually consistent checkbox indicator (○ / ✓)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: value ? primary : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: value ? primary : AppTheme.borderOf(context),
                    width: 1.5,
                  ),
                  boxShadow: value
                      ? [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: AnimatedScale(
                    scale: value ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: theme.colorScheme.onPrimary,
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

class _DefaultsCard extends StatelessWidget {
  final MeterProvider meter;

  const _DefaultsCard({required this.meter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderOf(context)),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: Column(
        children: [
          _DefaultRow(
            icon: FontAwesomeIcons.gasPump,
            label: 'Fuel efficiency',
            value: '${meter.kmPerLiter.toStringAsFixed(1)} km/L',
            isFirst: true,
          ),
          Divider(height: 1, color: AppTheme.borderOf(context)),
          _DefaultRow(
            icon: FontAwesomeIcons.pesoSign,
            label: 'Gas price',
            value: '₱${meter.gasPricePerLiter.toStringAsFixed(2)}/L',
          ),
          Divider(height: 1, color: AppTheme.borderOf(context)),
          _DefaultRow(
            icon: FontAwesomeIcons.coins,
            label: 'Base fare',
            value: '₱${meter.baseFare.toStringAsFixed(0)}',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _DefaultRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isFirst;
  final bool isLast;

  const _DefaultRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: FaIcon(icon, size: 13, color: primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final bool enabled;
  final int acceptedCount;

  const _BottomActionBar({
    required this.enabled,
    required this.acceptedCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = AppTheme.mutedOf(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(color: AppTheme.borderOf(context)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PremiumConfirmButton(
            label: 'Acknowledge & Continue',
            enabled: enabled,
            hintWhenDisabled: acceptedCount == 0
                ? 'Acknowledge all 3 items to continue'
                : 'Acknowledge the remaining item${3 - acceptedCount == 1 ? '' : 's'}',
            icon: Icons.arrow_forward_rounded,
            onPressed: enabled
                ? () => Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const HomeScreen(),
                        transitionsBuilder: (context, animation,
                                secondaryAnimation, child) =>
                            FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.03),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                            child: child,
                          ),
                        ),
                        transitionDuration: const Duration(milliseconds: 380),
                      ),
                    )
                : null,
          ),
          if (enabled) ...[
            const SizedBox(height: 8),
            Text(
              'You can update fare settings anytime from the dashboard.',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(color: muted),
            ),
          ],
        ],
      ),
    );
  }
}
