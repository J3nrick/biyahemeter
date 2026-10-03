import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:biyahe_meter/features/meter/home_screen.dart';
import 'package:biyahe_meter/features/meter/meter_provider.dart';
import 'package:biyahe_meter/features/onboarding/agreements_provider.dart';

/// Screen 2: Agreements Page (`AgreementsScreen`)
///
/// Features:
/// - Clean top header reading "Before You Ride"
/// - Animated LinearProgressIndicator with "X of 3 acknowledged" indicator
/// - 3 mandatory legal/safety items in elevated Cards with rounded corners & subtle shadows
///   (Checkboxes aligned cleanly to the right, no distracting or broken icon glyphs)
/// - Subdued "Trip Defaults" configuration tile (visually distinct, not a checkbox)
/// - Large sticky ElevatedButton at bottom, disabled until all 3 checkboxes are true
/// - Helper text below: "Acknowledge all 3 items to continue."
/// - Clean modular structure using standard setState with provider synchronization
class AgreementsScreen extends StatefulWidget {
  const AgreementsScreen({super.key});

  @override
  State<AgreementsScreen> createState() => _AgreementsScreenState();
}

class _AgreementsScreenState extends State<AgreementsScreen> {
  bool _fareEstimatesAccepted = false;
  bool _routePrivacyAccepted = false;
  bool _responsibleRateAccepted = false;

  int get _acknowledgedCount {
    int count = 0;
    if (_fareEstimatesAccepted) count++;
    if (_routePrivacyAccepted) count++;
    if (_responsibleRateAccepted) count++;
    return count;
  }

  bool get _allAccepted => _acknowledgedCount == 3;

  @override
  void initState() {
    super.initState();
    // Sync initial state from provider if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final ag = Provider.of<AgreementsProvider>(context, listen: false);
        if (ag.acceptedTerms || ag.acceptedPrivacy || ag.verifiedGasData) {
          setState(() {
            _fareEstimatesAccepted = ag.acceptedTerms;
            _routePrivacyAccepted = ag.acceptedPrivacy;
            _responsibleRateAccepted = ag.verifiedGasData;
          });
        }
      } catch (_) {}
    });
  }

  void _syncToProvider() {
    try {
      final ag = Provider.of<AgreementsProvider>(context, listen: false);
      ag.toggleTerms(_fareEstimatesAccepted);
      ag.togglePrivacy(_routePrivacyAccepted);
      ag.toggleGasData(_responsibleRateAccepted);
    } catch (_) {}
  }

  void _onContinue() {
    if (!_allAccepted) return;

    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    try {
      final ag = Provider.of<AgreementsProvider>(context, listen: false);
      ag.acceptAll();
    } catch (_) {}

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width >= 700 ? (width - 560) / 2 : 20.0;

    // Palette: Deep transit blues, crisp whites, subtle grays
    const transitBlue = Color(0xFF2563EB);
    final cardBg = isDark ? const Color(0xFF131F37) : Colors.white;
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0);
    final subduedBg =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable Content with hidden scrollbars
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    24,
                    horizontalPadding,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Header ──
                      const Text(
                        'Before You Ride',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Review and acknowledge key safety and fare policies before starting your trip.',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Mandatory Items (Cards) ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 2, bottom: 10),
                            child: Text(
                              'MANDATORY POLICIES',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: isDark
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          if (!_allAccepted)
                            Padding(
                              padding: const EdgeInsets.only(right: 2, bottom: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _fareEstimatesAccepted = true;
                                    _routePrivacyAccepted = true;
                                    _responsibleRateAccepted = true;
                                  });
                                  _syncToProvider();
                                  try {
                                    HapticFeedback.selectionClick();
                                  } catch (_) {}
                                },
                                child: const Text(
                                  'Acknowledge All',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: transitBlue,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                    // Card 1: Fare Estimates & Terms
                    _AgreementCard(
                      title: 'Fare Estimates & Terms',
                      description:
                          'Fare calculations follow standard rates based on distance and waiting time. Actual traffic conditions may vary.',
                      value: _fareEstimatesAccepted,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      transitBlue: transitBlue,
                      onChanged: (val) {
                        setState(() => _fareEstimatesAccepted = val ?? false);
                        _syncToProvider();
                      },
                    ),

                    const SizedBox(height: 12),

                    // Card 2: Route & Data Privacy
                    _AgreementCard(
                      title: 'Route & Data Privacy',
                      description:
                          'GPS location is accessed exclusively in real-time to compute accurate transit distance. No personal tracking data is stored.',
                      value: _routePrivacyAccepted,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      transitBlue: transitBlue,
                      onChanged: (val) {
                        setState(() => _routePrivacyAccepted = val ?? false);
                        _syncToProvider();
                      },
                    ),

                    const SizedBox(height: 12),

                    // Card 3: Responsible Rate Use
                    _AgreementCard(
                      title: 'Responsible Rate Use',
                      description:
                          'Calculations serve as transparent fare estimates. Ensure adherence to official transport regulations during your ride.',
                      value: _responsibleRateAccepted,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      transitBlue: transitBlue,
                      onChanged: (val) {
                        setState(
                            () => _responsibleRateAccepted = val ?? false);
                        _syncToProvider();
                      },
                    ),

                    const SizedBox(height: 28),

                    // ── Secondary Settings (Subdued Trip Defaults) ──
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 10),
                      child: Text(
                        'TRIP DEFAULTS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),

                    // Subdued configuration tile (visually distinct, not a legal checkbox)
                    Consumer<MeterProvider?>(
                      builder: (context, meter, _) {
                        final kmPerL = meter?.kmPerLiter ?? 12.0;
                        final gasPrice = meter?.gasPricePerLiter ?? 65.0;
                        final baseFare = meter?.baseFare ?? 45.0;

                        return Container(
                          decoration: BoxDecoration(
                            color: subduedBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Trip Configuration',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Default vehicle & fuel calculation metrics',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1, thickness: 0.5),
                              const SizedBox(height: 12),
                              // Metrics row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _DefaultMetricPill(
                                    label: 'Fuel Efficiency',
                                    value: '${kmPerL.toStringAsFixed(1)} km/L',
                                    isDark: isDark,
                                  ),
                                  _DefaultMetricPill(
                                    label: 'Gas Price',
                                    value: '₱${gasPrice.toStringAsFixed(2)}/L',
                                    isDark: isDark,
                                  ),
                                  _DefaultMetricPill(
                                    label: 'Base Fare',
                                    value: '₱${baseFare.toStringAsFixed(2)}',
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

            // ── Sticky Call to Action at Bottom ──
            Container(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                16,
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Large ElevatedButton dynamically disabled until 3 items acknowledged
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _allAccepted ? _onContinue : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: transitBlue,
                        disabledBackgroundColor: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                        elevation: _allAccepted ? 2 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _allAccepted
                            ? 'Continue to Meter'
                            : 'Accept All to Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Helper text
                  Text(
                    _allAccepted
                        ? 'All policies acknowledged — ready to ride.'
                        : 'Acknowledge all 3 items to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
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
}

/// Elevated Card for each mandatory agreement item
class _AgreementCard extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final Color cardBg;
  final Color cardBorder;
  final Color transitBlue;
  final ValueChanged<bool?> onChanged;

  const _AgreementCard({
    required this.title,
    required this.description,
    required this.value,
    required this.cardBg,
    required this.cardBorder,
    required this.transitBlue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: value ? 2.5 : 1.0,
      margin: EdgeInsets.zero,
      color: cardBg,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: value ? transitBlue.withValues(alpha: 0.4) : cardBorder,
          width: value ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () {
          onChanged(!value);
          try {
            HapticFeedback.selectionClick();
          } catch (_) {}
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Checkbox aligned to the right
              Transform.scale(
                scale: 1.15,
                child: Checkbox(
                  value: value,
                  activeColor: transitBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  onChanged: (val) {
                    onChanged(val);
                    try {
                      HapticFeedback.selectionClick();
                    } catch (_) {}
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact metric pill for defaults display
class _DefaultMetricPill extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _DefaultMetricPill({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
