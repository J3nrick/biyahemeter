import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:biyahe_meter/features/onboarding/agreements_screen.dart';

/// Screen 1: Splash Screen (`SplashScreen`)
///
/// Luxury transit startup experience for BiyaheMeter:
/// - Cinematic deep sapphire-obsidian transit atmosphere with perspective highway streams
/// - High-precision instrument dial with animated speedometer arc sweep
/// - Elevated 3D glass squircle emblem with specular light refraction
/// - Dynamic transit telemetry status capsule (GPS sync, fare calibration, ready)
/// - Precision hairline progress gauge synchronized to 3.0s launch sequence
/// - Seamless cinematic cross-dissolve departure transition
class SplashScreen extends StatefulWidget {
  final VoidCallback? onFinish;
  final AnimationController? controller; // Optional backward compatibility

  const SplashScreen({
    super.key,
    this.onFinish,
    this.controller,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  // Animation timeline phases (0.0s – 3.0s total)
  late final Animation<double> _entranceScale;
  late final Animation<double> _entranceOpacity;
  late final Animation<double> _gaugeSweep;
  late final Animation<double> _specularSweep;
  late final Animation<double> _gridFlow;
  late final Animation<double> _ambientBreathe;
  late final Animation<double> _exitScale;
  late final Animation<double> _exitOpacity;

  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // 1. Entrance: Emergence with smooth spring poise (0.0s – 0.8s)
    _entranceScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.0, 0.32, curve: Curves.easeOutBack),
      ),
    );

    _entranceOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.0, 0.24, curve: Curves.easeOut),
      ),
    );

    // 2. Instrument Speedometer Sweep (0.4s – 2.3s):
    // Needle/arc powers up like a luxury vehicle instrument cluster
    _gaugeSweep = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.15, 0.78, curve: Curves.easeInOutCubic),
      ),
    );

    // 3. Specular Sheen Pass (0.8s – 2.4s):
    _specularSweep = Tween<double>(begin: -1.2, end: 2.2).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.28, 0.80, curve: Curves.easeInOutCubic),
      ),
    );

    // 4. Perspective Transit Grid Flow (0.0s – 3.0s):
    _gridFlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _anim,
        curve: Curves.linear,
      ),
    );

    // 5. Ambient Light Breathing (0.6s – 2.6s):
    _ambientBreathe = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.65, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.85)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.20, 0.88),
      ),
    );

    // 6. Departure Transition (2.65s – 3.0s):
    _exitScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.88, 1.0, curve: Curves.easeInCubic),
      ),
    );

    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.92, 1.0, curve: Curves.easeIn),
      ),
    );

    _anim.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _proceed();
      }
    });

    _anim.forward();

    // Tactile launch sensation
    if (!kIsWeb) {
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          HapticFeedback.lightImpact();
        } catch (_) {}
      });
      Future.delayed(const Duration(milliseconds: 2300), () {
        try {
          HapticFeedback.selectionClick();
        } catch (_) {}
      });
    }

    // Safety fallback
    _safetyTimer = Timer(const Duration(milliseconds: 3050), () {
      if (mounted) _proceed();
    });
  }

  void _proceed() {
    _safetyTimer?.cancel();
    _safetyTimer = null;
    if (!mounted) return;

    if (widget.onFinish != null) {
      widget.onFinish!();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AgreementsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 450),
        ),
      );
    }
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;
    final emblemSize = (size.width * (isTablet ? 0.38 : 0.62)).clamp(220.0, 310.0);
    final dialDiameter = emblemSize + 68.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF03050B),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF030611),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: Atmospheric gradient backdrop
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.15),
                  radius: 1.35,
                  colors: [
                    Color(0xFF0B1938), // Midnight sapphire core
                    Color(0xFF060D20), // Deep indigo transit layer
                    Color(0xFF020409), // Obsidian perimeter
                  ],
                  stops: [0.0, 0.58, 1.0],
                ),
              ),
            ),

            // Layer 2: Perspective transit velocity streams & horizon grid
            AnimatedBuilder(
              animation: _gridFlow,
              builder: (context, _) {
                return CustomPaint(
                  painter: _TransitGridPainter(
                    progress: _gridFlow.value,
                    opacity: _entranceOpacity.value * _exitOpacity.value * 0.40,
                  ),
                );
              },
            ),

            // Layer 3: Central breathing ambient bloom
            Center(
              child: AnimatedBuilder(
                animation: _anim,
                builder: (context, _) {
                  final breathe = _ambientBreathe.value;
                  final opacity = _entranceOpacity.value *
                      _exitOpacity.value *
                      0.35 *
                      breathe;

                  return Container(
                    width: dialDiameter * 1.35,
                    height: dialDiameter * 1.35,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF38BDF8).withValues(alpha: opacity),
                          const Color(0xFF1D4ED8).withValues(alpha: opacity * 0.45),
                          Colors.transparent,
                        ],
                        radius: 0.65,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Layer 4: The Hero Instrument Dial & BiyaheMeter Emblem
            Center(
              child: AnimatedBuilder(
                animation: _anim,
                builder: (context, _) {
                  final currentScale = _entranceScale.value * _exitScale.value;
                  final currentOpacity =
                      (_entranceOpacity.value * _exitOpacity.value).clamp(0.0, 1.0);
                  final gaugeProgress = _gaugeSweep.value;
                  final sweep = _specularSweep.value;

                  return Opacity(
                    opacity: currentOpacity,
                    child: Transform.scale(
                      scale: currentScale,
                      child: SizedBox(
                        width: dialDiameter,
                        height: dialDiameter,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 4a. Precision Circular Speedometer Instrument Dial
                            CustomPaint(
                              size: Size(dialDiameter, dialDiameter),
                              painter: _SpeedometerDialPainter(
                                progress: gaugeProgress,
                                primaryColor: const Color(0xFF38BDF8),
                                secondaryColor: const Color(0xFF2563EB),
                                trackColor: Colors.white.withValues(alpha: 0.08),
                                ticksColor: Colors.white.withValues(alpha: 0.22),
                              ),
                            ),

                            // 4b. Elevated 3D Frosted Glass Emblem Squircle
                            Container(
                              width: emblemSize,
                              height: emblemSize * 0.72,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF0F1E3D).withValues(alpha: 0.90),
                                    const Color(0xFF081024).withValues(alpha: 0.94),
                                  ],
                                ),
                                border: Border.all(
                                  color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF38BDF8).withValues(alpha: 0.20 * gaugeProgress),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Subtle inner glow rim
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.white.withValues(alpha: 0.12),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // High Definition BiyaheMeter Logo with Specular Sheen Pass
                                  ShaderMask(
                                    shaderCallback: (bounds) {
                                      return LinearGradient(
                                        begin: const Alignment(-0.8, -1.0),
                                        end: const Alignment(0.8, 1.0),
                                        colors: const [
                                          Colors.white,
                                          Colors.white,
                                          Color(0xFFBAE6FD), // Luminous icy reflection
                                          Colors.white,
                                          Colors.white,
                                        ],
                                        stops: [
                                          0.0,
                                          (sweep - 0.22).clamp(0.0, 1.0),
                                          sweep.clamp(0.0, 1.0),
                                          (sweep + 0.22).clamp(0.0, 1.0),
                                          1.0,
                                        ],
                                      ).createShader(bounds);
                                    },
                                    blendMode: BlendMode.srcATop,
                                    child: Image.asset(
                                      'assets/images/logo_dark_hd.png',
                                      width: emblemSize * 0.88,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.high,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Image.asset(
                                          'assets/images/logo.png',
                                          width: emblemSize * 0.88,
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.high,
                                        );
                                      },
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
                },
              ),
            ),

            // Layer 5: Dynamic Transit Startup Telemetry Dock
            Positioned(
              left: 24,
              right: 24,
              bottom: (MediaQuery.paddingOf(context).bottom + 28).clamp(36.0, 72.0),
              child: AnimatedBuilder(
                animation: _anim,
                builder: (context, _) {
                  final opacity =
                      (_entranceOpacity.value * _exitOpacity.value).clamp(0.0, 1.0);
                  final progress = _gaugeSweep.value;

                  // Dynamic step stage
                  String stageText;
                  IconData stageIcon;
                  if (progress < 0.38) {
                    stageText = 'INITIALIZING SATELLITE GPS';
                    stageIcon = Icons.satellite_alt_rounded;
                  } else if (progress < 0.78) {
                    stageText = 'CALIBRATING FARE ENGINE';
                    stageIcon = Icons.speed_rounded;
                  } else {
                    stageText = 'BIYAHEMETER ARMED & READY';
                    stageIcon = Icons.verified_rounded;
                  }

                  final percent = (progress * 100).round();

                  return Opacity(
                    opacity: opacity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Frosted Telemetry Capsule Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1B35).withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.28),
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Pulsing beacon dot
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: progress > 0.78
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF38BDF8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (progress > 0.78
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF38BDF8))
                                          .withValues(alpha: 0.65),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(stageIcon, size: 14, color: const Color(0xFF93C5FD)),
                              const SizedBox(width: 6),
                              Text(
                                stageText,
                                style: const TextStyle(
                                  color: Color(0xFFE2E8F0),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '$percent%',
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Glowing Precision Progress Track
                        SizedBox(
                          width: (size.width * 0.58).clamp(180.0, 260.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: Stack(
                              children: [
                                // Track background
                                Container(
                                  height: 3.5,
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                                // Active glowing gradient fill
                                FractionallySizedBox(
                                  widthFactor: progress.clamp(0.02, 1.0),
                                  child: Container(
                                    height: 3.5,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF2563EB),
                                          Color(0xFF38BDF8),
                                          Color(0xFF67E8F9),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF38BDF8).withValues(alpha: 0.75),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Subdued Luxury Brand Signature
                        Text(
                          'PREMIUM TRANSIT & FARE TELEMETRY',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.32),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the circular automotive speedometer instrument dial.
class _SpeedometerDialPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final Color trackColor;
  final Color ticksColor;

  _SpeedometerDialPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.trackColor,
    required this.ticksColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8.0;

    // Classic 240-degree dial sweep from 150° (bottom-left) to 390° (bottom-right)
    const startAngle = 150.0 * (math.pi / 180.0);
    const totalSweepAngle = 240.0 * (math.pi / 180.0);

    // 1. Draw precision dial tick marks around the perimeter
    const tickCount = 36;
    for (int i = 0; i <= tickCount; i++) {
      final t = i / tickCount;
      final angle = startAngle + (t * totalSweepAngle);
      final isMajor = i % 6 == 0;
      final tickLength = isMajor ? 9.0 : 5.0;

      final p1 = Offset(
        center.dx + (radius * math.cos(angle)),
        center.dy + (radius * math.sin(angle)),
      );
      final p2 = Offset(
        center.dx + ((radius - tickLength) * math.cos(angle)),
        center.dy + ((radius - tickLength) * math.sin(angle)),
      );

      final isPast = t <= progress;
      final tickPaint = Paint()
        ..color = isPast
            ? primaryColor.withValues(alpha: isMajor ? 0.95 : 0.65)
            : ticksColor.withValues(alpha: isMajor ? 0.30 : 0.12)
        ..strokeWidth = isMajor ? 1.6 : 0.9
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p1, p2, tickPaint);
    }

    // 2. Background Track Arc
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 14.0),
      startAngle,
      totalSweepAngle,
      false,
      trackPaint,
    );

    // 3. Active Glowing Sweep Arc
    if (progress > 0.005) {
      final currentSweep = totalSweepAngle * progress;

      // Glow pass
      final glowPaint = Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + totalSweepAngle,
          colors: [
            secondaryColor.withValues(alpha: 0.15),
            primaryColor.withValues(alpha: 0.55),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius - 14.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0)
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 14.0),
        startAngle,
        currentSweep,
        false,
        glowPaint,
      );

      // Core sharp stroke
      final activePaint = Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + totalSweepAngle,
          colors: [
            secondaryColor,
            primaryColor,
            const Color(0xFFBAE6FD),
          ],
          stops: const [0.0, 0.75, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius - 14.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 14.0),
        startAngle,
        currentSweep,
        false,
        activePaint,
      );

      // 4. Luminous gauge needle tip particle
      final tipAngle = startAngle + currentSweep;
      final tipPos = Offset(
        center.dx + ((radius - 14.0) * math.cos(tipAngle)),
        center.dy + ((radius - 14.0) * math.sin(tipAngle)),
      );

      final tipGlow = Paint()
        ..color = primaryColor.withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
      canvas.drawCircle(tipPos, 4.5, tipGlow);

      final tipCore = Paint()..color = Colors.white;
      canvas.drawCircle(tipPos, 2.2, tipCore);
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedometerDialPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Perspective highway velocity streams flowing subtly towards the viewer.
class _TransitGridPainter extends CustomPainter {
  final double progress;
  final double opacity;

  _TransitGridPainter({required this.progress, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.01) return;

    final horizonY = size.height * 0.52;
    final centerX = size.width / 2;

    // Radiating perspective road lines
    const lineCount = 7;
    for (int i = 0; i < lineCount; i++) {
      final t = i / (lineCount - 1); // 0.0 to 1.0
      final bottomX = (size.width * -0.2) + (t * (size.width * 1.4));

      final linePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF38BDF8).withValues(alpha: opacity * 0.35),
            const Color(0xFF2563EB).withValues(alpha: opacity * 0.55),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromLTRB(0, horizonY, size.width, size.height))
        ..strokeWidth = (i == 3) ? 1.4 : 0.8;

      canvas.drawLine(
        Offset(centerX + ((bottomX - centerX) * 0.12), horizonY),
        Offset(bottomX, size.height),
        linePaint,
      );
    }

    // Moving horizontal crossbars (velocity pulses)
    const barCount = 5;
    for (int i = 0; i < barCount; i++) {
      final shifted = (progress + (i / barCount)) % 1.0;
      // Exponential curve for perspective distance compression
      final y = horizonY + (math.pow(shifted, 2.2) * (size.height - horizonY));
      final spread = math.pow(shifted, 1.8) * size.width * 0.85;

      final barOpacity = (shifted * (1.0 - shifted) * 4.0 * opacity * 0.32).clamp(0.0, 1.0);
      final barPaint = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: barOpacity)
        ..strokeWidth = 1.0 + (shifted * 1.5);

      canvas.drawLine(
        Offset(centerX - spread, y),
        Offset(centerX + spread, y),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TransitGridPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.opacity != opacity;
  }
}

/// Backward compatibility alias
typedef PremiumSplashView = SplashScreen;

