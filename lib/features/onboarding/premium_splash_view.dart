import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:biyahe_meter/features/onboarding/agreements_screen.dart';

/// Screen 1: Splash Screen (`SplashScreen`)
///
/// Neon Transit Beam Reveal & Hyperspace Zoom:
/// - Phase 1 (0.0s – 0.65s): A high-energy neon cyan laser streak rushes horizontally across
///   the baseline, drawing the road bar and cascading through the speed dashes with tactile haptics.
/// - Phase 2 (0.65s – 1.45s): An electric energy wavefront sweeps upward from the road bar,
///   illuminating "Biyahe" and snapping "METER" into focus with digital precision.
/// - Phase 3 (1.45s – 2.40s): Full HD brand lock with a brilliant diagonal specular glint pass
///   and breathing ambient sapphire aura.
/// - Phase 4 (2.40s – 3.00s): Hyperspace Departure — the logo accelerates forward into the camera
///   with radial velocity light streams, dissolving seamlessly into the Agreements screen.
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

  // Timeline intervals for 3.0-second sequence
  late final Animation<double> _horizontalBeam; // 0.0s – 0.65s
  late final Animation<double> _verticalReveal; // 0.60s – 1.45s
  late final Animation<double> _meterFlash;     // 1.30s – 1.65s
  late final Animation<double> _specularSweep;  // 1.50s – 2.30s
  late final Animation<double> _ambientBreathe; // 1.20s – 2.50s
  late final Animation<double> _hyperspaceZoom; // 2.45s – 3.00s
  late final Animation<double> _hyperspaceRays; // 2.40s – 3.00s
  late final Animation<double> _exitOpacity;    // 2.85s – 3.00s

  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Phase 1: Horizontal transit beam sweeps across the road bar
    _horizontalBeam = Tween<double>(begin: -0.15, end: 1.15).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.02, 0.24, curve: Curves.easeInOutCubic),
      ),
    );

    // Phase 2: Vertical upward scan reveals "Biyahe" and "METER"
    _verticalReveal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.20, 0.50, curve: Curves.easeOutCubic),
      ),
    );

    // Phase 2b: Electric pop on "METER" header
    _meterFlash = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 65,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.44, 0.56),
      ),
    );

    // Phase 3: Diagonal liquid specular glint sweeping across the letters
    _specularSweep = Tween<double>(begin: -1.2, end: 2.2).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.50, 0.78, curve: Curves.easeInOutCubic),
      ),
    );

    // Phase 3b: Subtle ambient breathing
    _ambientBreathe = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.75, end: 1.0)
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
        curve: const Interval(0.45, 0.82),
      ),
    );

    // Phase 4: Hyperspace Forward Zoom (1.0 -> 3.4x)
    _hyperspaceZoom = Tween<double>(begin: 1.0, end: 3.4).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.80, 1.0, curve: Curves.easeInCubic),
      ),
    );

    // Radial velocity light rays intensity
    _hyperspaceRays = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.78, 1.0),
      ),
    );

    // Cross-dissolve exit at the climax
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.93, 1.0, curve: Curves.easeIn),
      ),
    );

    _anim.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _proceed();
      }
    });

    _anim.forward();

    // Tactile haptic feedback cues
    if (!kIsWeb) {
      Future.delayed(const Duration(milliseconds: 120), () {
        try {
          HapticFeedback.lightImpact();
        } catch (_) {}
      });
      Future.delayed(const Duration(milliseconds: 1600), () {
        try {
          HapticFeedback.selectionClick();
        } catch (_) {}
      });
      Future.delayed(const Duration(milliseconds: 2450), () {
        try {
          HapticFeedback.mediumImpact();
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
    // The logo has an aspect ratio of approx 2.9 : 1 (1308 x 452)
    final logoWidth = (size.width * (isTablet ? 0.45 : 0.76)).clamp(270.0, 420.0);
    final logoHeight = logoWidth / 2.894;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF03050B),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF03050C),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Deep obsidian-to-midnight sapphire backdrop
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.05),
                  radius: 1.35,
                  colors: [
                    Color(0xFF0C1B3E), // Midnight sapphire core
                    Color(0xFF060D20), // Deep indigo transition
                    Color(0xFF020409), // Pure obsidian perimeter
                  ],
                  stops: [0.0, 0.58, 1.0],
                ),
              ),
            ),

            // Hyperspace velocity rays (ignited during Phase 4 zoom)
            AnimatedBuilder(
              animation: _hyperspaceRays,
              builder: (context, _) {
                final rays = _hyperspaceRays.value;
                if (rays <= 0.01) return const SizedBox.shrink();

                return CustomPaint(
                  painter: _HyperspaceRaysPainter(intensity: rays),
                );
              },
            ),

            // Central ambient light bloom behind the logo
            Center(
              child: AnimatedBuilder(
                animation: _anim,
                builder: (context, _) {
                  final reveal = _verticalReveal.value;
                  final breathe = _ambientBreathe.value;
                  final zoom = _hyperspaceZoom.value;
                  final opacity = (reveal * 0.42 * breathe * _exitOpacity.value).clamp(0.0, 1.0);

                  return Container(
                    width: logoWidth * 1.6 * (zoom > 1.2 ? zoom * 0.7 : 1.0),
                    height: logoHeight * 2.8 * (zoom > 1.2 ? zoom * 0.7 : 1.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(logoWidth),
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

            // THE HERO: Animated BiyaheMeter Logo with Multi-Stage Energy Shaders
            Center(
              child: AnimatedBuilder(
                animation: _anim,
                builder: (context, _) {
                  final beamPos = _horizontalBeam.value;
                  final reveal = _verticalReveal.value;
                  final meterFlash = _meterFlash.value;
                  final specular = _specularSweep.value;
                  final zoom = _hyperspaceZoom.value;
                  final exitOp = _exitOpacity.value;

                  return Opacity(
                    opacity: exitOp,
                    child: Transform.scale(
                      scale: zoom,
                      child: SizedBox(
                        width: logoWidth,
                        height: logoHeight,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            // 1. The Core HD Logo with Vertical Energy Wavefront Scan & Specular Sheen
                            ShaderMask(
                              shaderCallback: (bounds) {
                                // Vertical reveal sweep (from y=1.0 up to 0.0) combined with specular glint
                                return LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: const [
                                    Colors.white,
                                    Colors.white,
                                    Colors.transparent,
                                  ],
                                  stops: [
                                    0.0,
                                    (reveal * 1.15).clamp(0.0, 1.0),
                                    (reveal * 1.15 + 0.12).clamp(0.0, 1.0),
                                  ],
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.dstIn,
                              child: ShaderMask(
                                // Specular light reflection sweeping diagonally across the letters
                                shaderCallback: (bounds) {
                                  return LinearGradient(
                                    begin: const Alignment(-0.8, -1.0),
                                    end: const Alignment(0.8, 1.0),
                                    colors: const [
                                      Colors.white,
                                      Colors.white,
                                      Color(0xFFBAE6FD), // Luminous icy azure gleam
                                      Colors.white,
                                      Colors.white,
                                    ],
                                    stops: [
                                      0.0,
                                      (specular - 0.22).clamp(0.0, 1.0),
                                      specular.clamp(0.0, 1.0),
                                      (specular + 0.22).clamp(0.0, 1.0),
                                      1.0,
                                    ],
                                  ).createShader(bounds);
                                },
                                blendMode: BlendMode.srcATop,
                                child: Image.asset(
                                  'assets/images/logo_dark_hd.png',
                                  width: logoWidth,
                                  height: logoHeight,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/images/logo.png',
                                      width: logoWidth,
                                      height: logoHeight,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.high,
                                    );
                                  },
                                ),
                              ),
                            ),

                            // 2. High-Energy Horizontal Transit Beam running across the road baseline
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              height: 18,
                              child: CustomPaint(
                                painter: _TransitRoadBeamPainter(
                                  beamPosition: beamPos,
                                  revealProgress: reveal,
                                ),
                              ),
                            ),

                            // 3. Leading Vertical Energy Wavefront Glow Line
                            if (reveal > 0.02 && reveal < 0.98)
                              Positioned(
                                left: 0,
                                right: 0,
                                top: (1.0 - reveal) * logoHeight - 6,
                                height: 12,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        const Color(0xFF38BDF8).withValues(alpha: 0.65),
                                        Colors.white.withValues(alpha: 0.90),
                                        const Color(0xFF38BDF8).withValues(alpha: 0.65),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.25, 0.50, 0.75, 1.0],
                                    ),
                                  ),
                                ),
                              ),

                            // 4. "METER" Electric Pop Flash Overlay
                            if (meterFlash > 0.01)
                              Positioned(
                                top: 0,
                                left: logoWidth * 0.24,
                                width: logoWidth * 0.32,
                                height: logoHeight * 0.40,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF38BDF8).withValues(alpha: meterFlash * 0.75),
                                        blurRadius: 28,
                                        spreadRadius: 8,
                                      ),
                                    ],
                                  ),
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

            // Hyperspace Departure Optical Flash Bloom (at the moment of transition)
            AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                final progress = _anim.value;
                if (progress < 0.88) return const SizedBox.shrink();

                // Gentle luminous white/cyan aperture flash
                final flashIntensity = math.sin((progress - 0.88) / 0.12 * math.pi) * 0.45;

                return IgnorePointer(
                  child: Container(
                    color: const Color(0xFFBAE6FD).withValues(alpha: flashIntensity.clamp(0.0, 1.0)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter that renders the neon laser beam racing along the road baseline
/// and igniting the trailing speed dash pulses.
class _TransitRoadBeamPainter extends CustomPainter {
  final double beamPosition; // -0.15 to 1.15
  final double revealProgress; // 0.0 to 1.0

  _TransitRoadBeamPainter({
    required this.beamPosition,
    required this.revealProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * 0.55;

    // Glowing horizontal streak trail
    if (beamPosition > 0.0) {
      final trailEnd = (beamPosition * size.width).clamp(0.0, size.width);
      final trailStart = ((beamPosition - 0.45) * size.width).clamp(0.0, size.width);

      if (trailEnd > trailStart) {
        // Outer neon aura
        final auraPaint = Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              const Color(0xFF1D4ED8).withValues(alpha: 0.45),
              const Color(0xFF38BDF8).withValues(alpha: 0.85),
            ],
          ).createShader(Rect.fromLTRB(trailStart, y - 4, trailEnd, y + 4))
          ..strokeWidth = 6.0
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

        canvas.drawLine(Offset(trailStart, y), Offset(trailEnd, y), auraPaint);

        // Sharp core laser stroke
        final corePaint = Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              const Color(0xFF38BDF8),
              Colors.white,
            ],
          ).createShader(Rect.fromLTRB(trailStart, y - 1.5, trailEnd, y + 1.5))
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(Offset(trailStart, y), Offset(trailEnd, y), corePaint);

        // Leading luminous spark particle
        final headX = trailEnd;
        final sparkAura = Paint()
          ..color = const Color(0xFF38BDF8).withValues(alpha: 0.95)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
        canvas.drawCircle(Offset(headX, y), 7.0, sparkAura);

        final sparkCore = Paint()..color = Colors.white;
        canvas.drawCircle(Offset(headX, y), 3.2, sparkCore);
      }
    }

    // Cascading ignition of speed dashes along the right half
    final dashStartX = size.width * 0.52;
    final dashEndX = size.width * 0.98;
    const dashCount = 18;

    for (int i = 0; i < dashCount; i++) {
      final t = i / (dashCount - 1);
      final dx = dashStartX + (t * (dashEndX - dashStartX));
      final dashTrigger = 0.52 + (t * 0.46);

      // Dash glows when beam passes, then settles at ambient glow
      double dashAlpha = 0.0;
      if (beamPosition >= dashTrigger) {
        final dist = (beamPosition - dashTrigger).abs();
        if (dist < 0.12) {
          dashAlpha = (1.0 - (dist / 0.12)); // Peak flash
        } else {
          dashAlpha = (0.28 * revealProgress).clamp(0.0, 0.45); // Settled glow
        }
      }

      if (dashAlpha > 0.02) {
        final dashPaint = Paint()
          ..color = const Color(0xFF38BDF8).withValues(alpha: dashAlpha)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(Offset(dx, y - 2.5), Offset(dx, y + 2.5), dashPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TransitRoadBeamPainter oldDelegate) {
    return oldDelegate.beamPosition != beamPosition ||
        oldDelegate.revealProgress != revealProgress;
  }
}

/// Custom painter for radial hyperspace velocity streams radiating from center.
class _HyperspaceRaysPainter extends CustomPainter {
  final double intensity;

  _HyperspaceRaysPainter({required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0.01) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) / 2;

    const rayCount = 24;
    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * (2 * math.pi) + (i * 0.15);
      final innerDist = 60.0 + (i % 3 * 25.0);
      final outerDist = innerDist + ((maxRadius - innerDist) * intensity);

      final p1 = Offset(
        center.dx + (innerDist * math.cos(angle)),
        center.dy + (innerDist * math.sin(angle)),
      );
      final p2 = Offset(
        center.dx + (outerDist * math.cos(angle)),
        center.dy + (outerDist * math.sin(angle)),
      );

      final rayPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.center,
          end: Alignment.bottomRight,
          colors: [
            Colors.transparent,
            const Color(0xFF38BDF8).withValues(alpha: intensity * 0.35),
            Colors.white.withValues(alpha: intensity * 0.60),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromPoints(p1, p2))
        ..strokeWidth = (i % 4 == 0) ? 2.5 : 1.2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p1, p2, rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HyperspaceRaysPainter oldDelegate) {
    return oldDelegate.intensity != intensity;
  }
}

/// Backward compatibility alias
typedef PremiumSplashView = SplashScreen;

