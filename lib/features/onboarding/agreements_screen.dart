import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'package:biyahe_meter/features/meter/home_screen.dart';
import 'package:biyahe_meter/features/meter/meter_provider.dart';
import 'package:biyahe_meter/features/onboarding/agreements_provider.dart';

class AgreementsScreen extends StatelessWidget {
  const AgreementsScreen({super.key});

  static const _green   = Color(0xFF2E7D32);
  static const _label   = Color(0xFF1C1C1E);
  static const _sub     = Color(0xFF6B6B6B);
  static const _divClr  = Color(0xFFE8E8E8);
  static const _cardBg  = Color(0xFFF9F9F9);
  static const _border  = Color(0xFFDDDDDD);

  @override
  Widget build(BuildContext context) {
    final ag    = context.watch<AgreementsProvider>();
    final meter = context.watch<MeterProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 36, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildAgreementsCard(context, ag),
              const SizedBox(height: 14),
              _buildDataCard(meter),
              const SizedBox(height: 26),
              _buildAcceptButton(context, ag.allAccepted),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: const [
        Image(
          image: AssetImage('assets/images/logo.png'),
          height: 160,
          fit: BoxFit.contain,
          alignment: Alignment.center,
        ),
        SizedBox(height: 12),
        Text(
          'Before you begin, please read and agree to the following.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _sub,
            fontSize: 20,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  // ── Agreements Card ──────────────────────────────────────────
  Widget _buildAgreementsCard(BuildContext context, AgreementsProvider ag) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        children: [
          _checkRow(
            context: context,
            title: 'Terms & Conditions',
            subtitle: 'I agree to the usage rules and liability terms.',
            value: ag.acceptedTerms,
            onTap: () => context.read<AgreementsProvider>().toggleTerms(!ag.acceptedTerms),
          ),
          Divider(height: 1, thickness: 1, color: _divClr),
          _checkRow(
            context: context,
            title: 'Data Privacy & GPS Tracking',
            subtitle: 'I allow location access for trip distance tracking.',
            value: ag.acceptedPrivacy,
            onTap: () => context.read<AgreementsProvider>().togglePrivacy(!ag.acceptedPrivacy),
          ),
          Divider(height: 1, thickness: 1, color: _divClr),
          _checkRow(
            context: context,
            title: 'PH Gas Price Acknowledgment',
            subtitle: 'I understand that gas prices are manually updated.',
            value: ag.verifiedGasData,
            onTap: () => context.read<AgreementsProvider>().toggleGasData(!ag.verifiedGasData),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: value ? _green : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value ? _green : const Color(0xFFBBBBBB),
                  width: 1.5,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _label,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _sub,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Active PH Data Card ──────────────────────────────────────
  Widget _buildDataCard(MeterProvider meter) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 10),
            child: Text(
              'Current trip defaults',
              style: TextStyle(
                color: _sub,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Divider(height: 1, thickness: 1, color: _divClr),
          _dataRow(
            icon: FontAwesomeIcons.gasPump,
            label: 'Fuel Efficiency',
            value: '${meter.kmPerLiter.toStringAsFixed(1)} km/L',
          ),
          Divider(height: 1, thickness: 1, color: _divClr),
          _dataRow(
            icon: FontAwesomeIcons.pesoSign,
            label: 'Gas Price',
            value: '₱${meter.gasPricePerLiter.toStringAsFixed(2)}/L',
          ),
          Divider(height: 1, thickness: 1, color: _divClr),
          _dataRow(
            icon: FontAwesomeIcons.coins,
            label: 'Base Fare',
            value: '₱${meter.baseFare.toStringAsFixed(0)}',
          ),
        ],
      ),
    );
  }

  Widget _dataRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          FaIcon(icon, size: 13, color: _sub),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(color: _label, fontSize: 13)),
          ),
          Text(value,
              style: const TextStyle(
                  color: _label,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ── Accept Button ─────────────────────────────────────────────
  Widget _buildAcceptButton(BuildContext context, bool enabled) {
    return GestureDetector(
      onTap: enabled
          ? () => Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const HomeScreen(),
                  transitionsBuilder: (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
                  transitionDuration: const Duration(milliseconds: 350),
                ),
              )
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 50,
        decoration: BoxDecoration(
          color: enabled ? _green : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Accept & Continue',
            style: TextStyle(
              color: enabled ? Colors.white : const Color(0xFFAAAAAA),
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
