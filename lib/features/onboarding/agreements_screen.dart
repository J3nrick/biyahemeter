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
import 'package:biyahe_meter/features/onboarding/brand_mark.dart';

class AgreementsScreen extends StatefulWidget {
  const AgreementsScreen({super.key});

  @override
  State<AgreementsScreen> createState() => _AgreementsScreenState();
}

class _AgreementsScreenState extends State<AgreementsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ag = context.watch<AgreementsProvider>();
    final meter = context.watch<MeterProvider>();
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isNarrow = width < 360;
    final horizontal = width >= 700 ? (width - 540) / 2 : 20.0;
    final isDark = theme.brightness == Brightness.dark;

    final acceptedCount = [
      ag.acceptedTerms,
      ag.acceptedPrivacy,
      ag.verifiedGasData,
    ].where((v) => v).length;

    Widget reveal(int index, Widget child) =>
        _Reveal(animation: _entrance, index: index, child: child);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Same street grid as the splash, so the hand-off feels continuous.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320,
            child: IgnorePointer(
              child: CustomPaint(
                painter: StreetGridPainter(
                  anchor: Offset(horizontal, 0),
                  spacing: 36,
                  focus: Offset(horizontal + 36, 36),
                  radius: 320,
                  color: theme.colorScheme.onSurface.withValues(
                    alpha: isDark ? 0.08 : 0.06,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      28,
                      horizontal,
                      20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        reveal(0, _Header(isNarrow: isNarrow)),
                        const SizedBox(height: 28),
                        reveal(
                          1,
                          _ChecklistHeader(
                            acceptedCount: acceptedCount,
                            total: 3,
                            onAcceptAll: ag.allAccepted
                                ? null
                                : () => context
                                      .read<AgreementsProvider>()
                                      .acceptAll(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        reveal(2, _AgreementsCard(ag: ag)),
                        const SizedBox(height: 28),
                        reveal(
                          3,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _SectionLabel(
                                title: 'Initial Trip Defaults',
                                subtitle:
                                    'Standard baseline values. Adjust anytime in settings.',
                              ),
                              const SizedBox(height: 10),
                              _DefaultsCard(meter: meter),
                            ],
                          ),
                        ),
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

/// One-time staggered fade + short rise for first-use content.
class _Reveal extends StatelessWidget {
  final Animation<double> animation;
  final int index;
  final Widget child;

  const _Reveal({
    required this.animation,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = index * 0.12;
    // drive() rather than CurvedAnimation: this rebuilds on every provider tick.
    final curved = animation.drive(
      CurveTween(
        curve: Interval(
          start,
          start + 0.62,
          curve: Easing.emphasizedDecelerate,
        ),
      ),
    );
    return FadeTransition(
      opacity: curved,
      child: AnimatedBuilder(
        animation: curved,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 12 * (1 - curved.value)),
          child: child,
        ),
        child: child,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: BrandWordmark(height: isNarrow ? 30 : 34),
        ),
        const SizedBox(height: 28),
        Semantics(
          header: true,
          child: Text(
            'Welcome to Byahe Meter',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: isNarrow ? 24 : 28,
              letterSpacing: -0.6,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Before you start your byahe, let\'s make sure we\'re on the same page.',
          style: theme.textTheme.bodyLarge?.copyWith(color: muted, height: 1.4),
        ),
      ],
    );
  }
}

/// Section title, step progress and the existing "Accept all" shortcut.
class _ChecklistHeader extends StatelessWidget {
  final int acceptedCount;
  final int total;
  final VoidCallback? onAcceptAll;

  const _ChecklistHeader({
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
    final duration = AppTheme.motion(context, Durations.medium1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel(
          title: 'Travel Safety & Usage Agreement',
          subtitle:
              'Acknowledge each point below to ensure safe and clear metering.',
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Semantics(
                liveRegion: true,
                label: '$acceptedCount of $total acknowledged',
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          for (var i = 0; i < total; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            Expanded(
                              child: AnimatedContainer(
                                duration: duration,
                                curve: Easing.standard,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: i < acceptedCount
                                      ? primary
                                      : theme.colorScheme.outlineVariant,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (isComplete) ...[
                            Icon(
                              CupertinoIcons.checkmark_seal_fill,
                              size: 15,
                              color: primary,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              isComplete
                                  ? 'All $total acknowledged'
                                  : '$acceptedCount of $total acknowledged',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: isComplete ? primary : muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (onAcceptAll != null) ...[
              const SizedBox(width: 12),
              TextButton(
                onPressed: onAcceptAll,
                style: TextButton.styleFrom(
                  foregroundColor: primary,
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Semantics(
                  label: 'Accept all $total agreements',
                  child: const ExcludeSemantics(
                    child: Text(
                      'Accept all',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
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
        Semantics(
          header: true,
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            _AgreementTile(
              icon: CupertinoIcons.doc_text_fill,
              title: 'Fare Estimates & Terms',
              subtitle:
                  'Understand that fares shown are estimates and may vary based on actual traffic conditions.',
              value: ag.acceptedTerms,
              onTap: () => context.read<AgreementsProvider>().toggleTerms(
                !ag.acceptedTerms,
              ),
            ),
            Divider(height: 1, color: AppTheme.borderOf(context)),
            _AgreementTile(
              icon: CupertinoIcons.location_fill,
              title: 'Route & Data Privacy',
              subtitle:
                  'Allow location access for real-time trip distance calculation. Your location data remains private.',
              value: ag.acceptedPrivacy,
              onTap: () => context.read<AgreementsProvider>().togglePrivacy(
                !ag.acceptedPrivacy,
              ),
            ),
            Divider(height: 1, color: AppTheme.borderOf(context)),
            _AgreementTile(
              icon: CupertinoIcons.gauge_badge_plus,
              title: 'Responsible Gas & Rate Use',
              subtitle:
                  'Fuel prices and rates are customizable guides to ensure fair calculations for your byahe.',
              value: ag.verifiedGasData,
              onTap: () => context.read<AgreementsProvider>().toggleGasData(
                !ag.verifiedGasData,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgreementTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final VoidCallback onTap;

  const _AgreementTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onTap,
  });

  @override
  State<_AgreementTile> createState() => _AgreementTileState();
}

class _AgreementTileState extends State<_AgreementTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final muted = AppTheme.mutedOf(context);
    final isDark = theme.brightness == Brightness.dark;
    final value = widget.value;
    final fast = AppTheme.motion(context, Durations.short4);

    return MergeSemantics(
      child: Semantics(
        checked: value,
        child: AnimatedContainer(
          duration: fast,
          curve: Easing.standard,
          color: value
              ? primary.withValues(alpha: isDark ? 0.10 : 0.05)
              : Colors.transparent,
          foregroundDecoration: _focused
              ? BoxDecoration(border: Border.all(color: primary, width: 2))
              : null,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onFocusChange: (f) => setState(() => _focused = f),
              hoverColor: primary.withValues(alpha: 0.04),
              highlightColor: primary.withValues(alpha: 0.06),
              splashColor: primary.withValues(alpha: 0.10),
              focusColor: Colors.transparent, // ring drawn above instead
              onTap: () {
                widget.onTap();
                try {
                  HapticFeedback.selectionClick();
                } catch (_) {}
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: fast,
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: value ? 0.16 : 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(widget.icon, size: 19, color: primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: muted,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _CheckIndicator(value: value),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Visual checkbox; state is announced by the tile's semantics, not here.
class _CheckIndicator extends StatelessWidget {
  final bool value;

  const _CheckIndicator({required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final fast = AppTheme.motion(context, Durations.short4);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: AnimatedContainer(
        duration: fast,
        curve: Easing.standard,
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: value ? primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? primary : AppTheme.controlBorderOf(context),
            width: 1.5,
          ),
        ),
        child: AnimatedScale(
          scale: value ? 1.0 : 0.4,
          duration: fast,
          curve: Easing.emphasizedDecelerate,
          child: AnimatedOpacity(
            opacity: value ? 1 : 0,
            duration: fast,
            child: Icon(
              Icons.check_rounded,
              size: 17,
              color: theme.colorScheme.onPrimary,
            ),
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
      ),
      child: Column(
        children: [
          _DefaultRow(
            icon: FontAwesomeIcons.gasPump,
            label: 'Fuel efficiency',
            value: '${meter.kmPerLiter.toStringAsFixed(1)} km/L',
            spokenValue:
                '${meter.kmPerLiter.toStringAsFixed(1)} kilometers per liter',
          ),
          Divider(height: 1, color: AppTheme.borderOf(context)),
          _DefaultRow(
            icon: FontAwesomeIcons.pesoSign,
            label: 'Gas price',
            value: '₱${meter.gasPricePerLiter.toStringAsFixed(2)}/L',
            spokenValue:
                '${meter.gasPricePerLiter.toStringAsFixed(2)} pesos per liter',
          ),
          Divider(height: 1, color: AppTheme.borderOf(context)),
          _DefaultRow(
            icon: FontAwesomeIcons.coins,
            label: 'Base fare',
            value: '₱${meter.baseFare.toStringAsFixed(0)}',
            spokenValue: '${meter.baseFare.toStringAsFixed(0)} pesos',
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
  final String spokenValue;

  const _DefaultRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.spokenValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Semantics(
      label: '$label: $spokenValue',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final bool enabled;
  final int acceptedCount;

  const _BottomActionBar({required this.enabled, required this.acceptedCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = AppTheme.mutedOf(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final remaining = 3 - acceptedCount;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: AppTheme.borderOf(context))),
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PremiumConfirmButton(
                label: 'Acknowledge & Continue',
                enabled: enabled,
                hintWhenDisabled: acceptedCount == 0
                    ? 'Acknowledge all 3 items to continue'
                    : '$remaining item${remaining == 1 ? '' : 's'} left to acknowledge',
                icon: Icons.arrow_forward_rounded,
                onPressed: enabled
                    ? () => Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const HomeScreen(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position:
                                          Tween<Offset>(
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
                  style: theme.textTheme.labelMedium?.copyWith(color: muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
