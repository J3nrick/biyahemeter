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
    final muted = AppTheme.mutedOf(context);
    final primary = theme.colorScheme.primary;
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
                      primary.withValues(alpha: 0.10),
                      primary.withValues(alpha: 0),
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
                    padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Header(isNarrow: isNarrow, muted: muted),
                        const SizedBox(height: 22),
                        _ProgressPill(
                          acceptedCount: acceptedCount,
                          total: 3,
                          onAcceptAll: ag.allAccepted
                              ? null
                              : () => context
                                  .read<AgreementsProvider>()
                                  .acceptAll(),
                        ),
                        const SizedBox(height: 16),
                        _SectionLabel(
                          title: 'Agreements',
                          subtitle: 'Required before starting the meter',
                        ),
                        const SizedBox(height: 10),
                        _AgreementsCard(ag: ag),
                        const SizedBox(height: 18),
                        _SectionLabel(
                          title: 'Trip defaults',
                          subtitle: 'You can fine-tune these anytime in settings',
                        ),
                        const SizedBox(height: 10),
                        _DefaultsCard(meter: meter),
                        const SizedBox(height: 12),
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
  final Color muted;

  const _Header({required this.isNarrow, required this.muted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

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
              height: isNarrow ? 72 : 86,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'BiyaheMeter',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'PH DRIVER READY',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Review the essentials once, then start metering with clarity and control.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: muted,
            height: 1.45,
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
    final progress = acceptedCount / total;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.checkmark_seal, size: 16, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$acceptedCount of $total agreements accepted',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onAcceptAll != null)
                TextButton(
                  onPressed: onAcceptAll,
                  style: TextButton.styleFrom(
                    foregroundColor: primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Accept all'),
                )
              else
                Text(
                  '${(progress * 100).round()}%',
                  style: theme.textTheme.labelMedium?.copyWith(color: muted),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppTheme.borderOf(context),
              color: primary,
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
    // Avoid BackdropFilter here — on Flutter web it can break hit-testing on
    // sibling tiles so later agreements never receive taps.
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderOf(context)),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: Column(
        children: [
          _AgreementTile(
            icon: CupertinoIcons.doc_text_fill,
            title: 'Terms & Conditions',
            subtitle: 'Usage rules, liability terms, and driver responsibility.',
            value: ag.acceptedTerms,
            isFirst: true,
            onTap: () => context
                .read<AgreementsProvider>()
                .toggleTerms(!ag.acceptedTerms),
          ),
          Divider(height: 1, color: AppTheme.borderOf(context)),
          _AgreementTile(
            icon: CupertinoIcons.location_solid,
            title: 'Data Privacy & GPS',
            subtitle: 'Allow location access for accurate trip distance.',
            value: ag.acceptedPrivacy,
            onTap: () => context
                .read<AgreementsProvider>()
                .togglePrivacy(!ag.acceptedPrivacy),
          ),
          Divider(height: 1, color: AppTheme.borderOf(context)),
          _AgreementTile(
            icon: CupertinoIcons.gauge,
            title: 'PH Gas Price Notice',
            subtitle: 'Gas prices are manually set and may change locally.',
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onTap();
          try {
            HapticFeedback.selectionClick();
          } catch (_) {}
        },
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(22) : Radius.zero,
          bottom: isLast ? const Radius.circular(22) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(icon, size: 18, color: primary),
                ),
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
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: value ? primary : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: value ? primary : AppTheme.borderOf(context),
                    width: 1.5,
                  ),
                ),
                child: value
                    ? Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: theme.colorScheme.onPrimary,
                      )
                    : const SizedBox.shrink(),
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
        borderRadius: BorderRadius.circular(22),
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
            label: 'Accept & Continue',
            enabled: enabled,
            hintWhenDisabled: acceptedCount == 0
                ? 'Accept all three agreements to continue'
                : 'Accept the remaining agreement${3 - acceptedCount == 1 ? '' : 's'}',
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
