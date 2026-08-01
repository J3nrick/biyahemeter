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
    final width = MediaQuery.sizeOf(context).width;
    final isNarrow = width < 360;
    final horizontal = width >= 700 ? (width - 520) / 2 : 22.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, isNarrow, muted),
              const SizedBox(height: 28),
              _buildAgreementsCard(context, ag),
              const SizedBox(height: 14),
              _buildDataCard(context, meter),
              const SizedBox(height: 26),
              _buildAcceptButton(context, ag.allAccepted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isNarrow, Color muted) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Hero(
          tag: 'biyahemeter-logo',
          child: Image(
            image: const AssetImage('assets/images/logo.png'),
            height: isNarrow ? 120 : 148,
            fit: BoxFit.contain,
            alignment: Alignment.center,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'BiyaheMeter',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Before you begin, please read and agree to the following.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: muted,
            height: 1.45,
            fontSize: isNarrow ? 15 : 16,
          ),
        ),
      ],
    );
  }

  Widget _buildAgreementsCard(BuildContext context, AgreementsProvider ag) {
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
          _checkRow(
            context: context,
            title: 'Terms & Conditions',
            subtitle: 'I agree to the usage rules and liability terms.',
            value: ag.acceptedTerms,
            onTap: () =>
                context.read<AgreementsProvider>().toggleTerms(!ag.acceptedTerms),
          ),
          Divider(height: 1, color: AppTheme.borderOf(context)),
          _checkRow(
            context: context,
            title: 'Data Privacy & GPS Tracking',
            subtitle: 'I allow location access for trip distance tracking.',
            value: ag.acceptedPrivacy,
            onTap: () => context
                .read<AgreementsProvider>()
                .togglePrivacy(!ag.acceptedPrivacy),
          ),
          Divider(height: 1, color: AppTheme.borderOf(context)),
          _checkRow(
            context: context,
            title: 'PH Gas Price Acknowledgment',
            subtitle: 'I understand that gas prices are manually updated.',
            value: ag.verifiedGasData,
            onTap: () => context
                .read<AgreementsProvider>()
                .toggleGasData(!ag.verifiedGasData),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _checkRow({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final muted = AppTheme.mutedOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.vertical(
          top: title.startsWith('Terms')
              ? const Radius.circular(20)
              : Radius.zero,
          bottom: isLast ? const Radius.circular(20) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                margin: const EdgeInsets.only(top: 1),
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
                            color: primary.withValues(alpha: 0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: value
                    ? Icon(Icons.check_rounded,
                        color: theme.colorScheme.onPrimary, size: 16)
                    : const SizedBox.shrink(),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataCard(BuildContext context, MeterProvider meter) {
    final theme = Theme.of(context);
    final muted = AppTheme.mutedOf(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderOf(context)),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              'Current trip defaults',
              style: theme.textTheme.labelMedium?.copyWith(
                color: muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Divider(height: 1, color: AppTheme.borderOf(context)),
          _dataRow(
            context: context,
            icon: FontAwesomeIcons.gasPump,
            label: 'Fuel Efficiency',
            value: '${meter.kmPerLiter.toStringAsFixed(1)} km/L',
          ),
          Divider(height: 1, color: AppTheme.borderOf(context)),
          _dataRow(
            context: context,
            icon: FontAwesomeIcons.pesoSign,
            label: 'Gas Price',
            value: '₱${meter.gasPricePerLiter.toStringAsFixed(2)}/L',
          ),
          Divider(height: 1, color: AppTheme.borderOf(context)),
          _dataRow(
            context: context,
            icon: FontAwesomeIcons.coins,
            label: 'Base Fare',
            value: '₱${meter.baseFare.toStringAsFixed(0)}',
          ),
        ],
      ),
    );
  }

  Widget _dataRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final muted = AppTheme.mutedOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          FaIcon(icon, size: 14, color: muted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptButton(BuildContext context, bool enabled) {
    return PremiumConfirmButton(
      label: 'Accept & Continue',
      enabled: enabled,
      hintWhenDisabled: 'Check all agreements to continue',
      icon: Icons.arrow_forward_rounded,
      onPressed: enabled
          ? () => Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const HomeScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          FadeTransition(opacity: animation, child: child),
                  transitionDuration: const Duration(milliseconds: 350),
                ),
              )
          : null,
    );
  }
}
