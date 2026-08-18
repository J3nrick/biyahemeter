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
    final isComplete = acceptedCount == total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderOf(context)),
        boxShadow: AppTheme.softShadow(context),
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
                  color: isComplete
                      ? primary.withValues(alpha: 0.16)
                      : primary.withValues(alpha: 0.08),
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
                          ? 'All agreements accepted'
                          : '$acceptedCount of $total agreements accepted',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      isComplete
                          ? 'You are ready to begin metering'
                          : 'Tap items to read & accept',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (onAcceptAll != null)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onAcceptAll,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Text(
                        'Accept all',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '100%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0, end: progress),
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 5,
                  backgroundColor: AppTheme.borderOf(context),
                  color: primary,
                );
              },
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
            detailContent:
                'By using BiyaheMeter, you agree that this application serves as a real-time fare calculation assistant designed for Philippine transport conditions.\n\n'
                '• Drivers and operators remain fully responsible for safe vehicle operation and compliance with local traffic laws (LTFRB / LTO regulations).\n'
                '• Fare estimates are calculated based on live GPS distance and standard fare structures. They are provided for informational and transparency purposes.',
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
            detailContent:
                'BiyaheMeter respects your privacy and data security.\n\n'
                '• GPS access is required only while the trip meter is active to accurately calculate trip distance and speed.\n'
                '• Location and trip data stay strictly on your local device. We do not track, store, or transmit your location or personal information to cloud servers.',
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
            detailContent:
                'Gas prices and fuel efficiency presets are customizable defaults.\n\n'
                '• Default fuel rates reflect typical Philippine pump prices, but can vary by location and provider.\n'
                '• You can update your exact fuel efficiency (km/L), gas price per liter (₱/L), and base fare anytime in the trip defaults or app settings.',
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
  final String detailContent;
  final bool value;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _AgreementTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.detailContent,
    required this.value,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  void _showDetails(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderOf(sheetContext),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(icon, color: primary, size: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderOf(sheetContext)),
                ),
                child: Text(
                  detailContent,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.90),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (!value) {
                    onTap();
                  }
                  Navigator.pop(sheetContext);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  value ? 'Close' : 'Accept & Close',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
          top: isFirst ? const Radius.circular(22) : Radius.zero,
          bottom: isLast ? const Radius.circular(22) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: value
                      ? primary.withValues(alpha: 0.16)
                      : primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 20,
                    color: primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _showDetails(context),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Icon(
                              CupertinoIcons.info_circle,
                              size: 15,
                              color: muted.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
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
                child: AnimatedScale(
                  scale: value ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    Icons.check_rounded,
                    size: 17,
                    color: theme.colorScheme.onPrimary,
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
