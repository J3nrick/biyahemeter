import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
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
///
/// PERFORMANCE ARCHITECTURE (why this is smooth):
/// - The whole animation is ONE [CustomPainter] repainted directly by the
///   [AnimationController] (`repaint:`), so there are zero widget rebuilds per frame.
/// - The logo is decoded into a `ui.Image` BEFORE the clock starts, so no frame ever
///   pays for image decoding / texture upload.
/// - No `saveLayer` anywhere: no ShaderMask, no Opacity, no BackdropFilter, no blur
///   `MaskFilter`. Reveal is done with sliced `drawImageRect` + alpha; the glint is a
///   clipped, tinted re-draw of the logo. Glows are layered translucent shapes.
/// - Rays are batched into a handful of `drawPoints` calls instead of 24 shader paints.
/// - Static backdrop and animated canvas live in separate [RepaintBoundary] layers.
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
  static const _logoAsset = 'assets/images/logo_dark_hd.png';

  late final AnimationController _anim;

  ImageStream? _stream;
  ImageStreamListener? _listener;
  ImageInfo? _logoInfo;
  bool _resolved = false;
  bool _started = false;

  Timer? _startFallback;
  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _anim.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _proceed();
      }
    });

    // If the logo somehow can't be decoded quickly, never block the app.
    _startFallback = Timer(const Duration(milliseconds: 1500), _begin);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolved) return;
    _resolved = true;

    // Decode the logo up-front. The clock only starts once the pixels are ready,
    // so the first animated frame is already as cheap as the last one.
    final stream = const AssetImage(_logoAsset)
        .resolve(createLocalImageConfiguration(context));
    _stream = stream;
    _listener = ImageStreamListener(
      (info, synchronousCall) {
        _logoInfo?.dispose();
        _logoInfo = info.clone();
        if (!synchronousCall && mounted) setState(() {});
        WidgetsBinding.instance.addPostFrameCallback((_) => _begin());
      },
      onError: (_, _) => _begin(),
    );
    stream.addListener(_listener!);
  }

  void _begin() {
    if (_started || !mounted) return;
    _started = true;
    _startFallback?.cancel();
    _startFallback = null;

    _anim.forward();

    // Tactile haptic feedback cues
    if (!kIsWeb) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        try {
          HapticFeedback.lightImpact();
        } catch (_) {}
      });
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (!mounted) return;
        try {
          HapticFeedback.selectionClick();
        } catch (_) {}
      });
      Future.delayed(const Duration(milliseconds: 2450), () {
        if (!mounted) return;
        try {
          HapticFeedback.mediumImpact();
        } catch (_) {}
      });
    }

    // Safety fallback
    _safetyTimer = Timer(const Duration(milliseconds: 3300), () {
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
    _startFallback?.cancel();
    _safetyTimer?.cancel();
    if (_listener != null) _stream?.removeListener(_listener!);
    _logoInfo?.dispose();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;
    // The logo has an aspect ratio of approx 2.9 : 1 (1308 x 452)
    final logoWidth =
        (size.width * (isTablet ? 0.45 : 0.76)).clamp(270.0, 420.0);
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
            // Static backdrop: rasterised once on its own layer, never repainted.
            const RepaintBoundary(
              child: DecoratedBox(
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
            ),

            // The entire animation: one painter, repainted by the controller only.
            RepaintBoundary(
              child: CustomPaint(
                painter: _SplashPainter(
                  anim: _anim,
                  image: _logoInfo?.image,
                  logoWidth: logoWidth,
                  logoHeight: logoHeight,
                ),
                isComplex: true,
                willChange: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline helpers
// ---------------------------------------------------------------------------

/// Eased 0..1 progress of [t] across the window [a]..[b].
double _seg(double t, double a, double b, [Curve curve = Curves.linear]) {
  return curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));
}

/// Up-then-down pulse across [a]..[b], peaking at [peak] (0..1 of the window).
double _pulse(
  double t,
  double a,
  double b, {
  required double peak,
  Curve up = Curves.easeOut,
  Curve down = Curves.easeIn,
}) {
  if (t <= a || t >= b) return 0.0;
  final u = (t - a) / (b - a);
  if (u < peak) return up.transform(u / peak);
  return 1.0 - down.transform((u - peak) / (1.0 - peak));
}

// ---------------------------------------------------------------------------
// Single-pass splash painter
// ---------------------------------------------------------------------------

class _SplashPainter extends CustomPainter {
  final Animation<double> anim;
  final ui.Image? image;
  final double logoWidth;
  final double logoHeight;

  _SplashPainter({
    required this.anim,
    required this.image,
    required this.logoWidth,
    required this.logoHeight,
  }) : super(repaint: anim);

  static const _cyan = Color(0xFF38BDF8);
  static const _blue = Color(0xFF1D4ED8);
  static const _ice = Color(0xFFBAE6FD);

  // Reused paints (no per-frame allocation churn).
  final Paint _imagePaint = Paint()
    ..filterQuality = FilterQuality.medium
    ..isAntiAlias = true;
  final Paint _glintPaint = Paint()
    ..filterQuality = FilterQuality.medium
    ..isAntiAlias = true
    ..colorFilter = ColorFilter.mode(
      _ice.withValues(alpha: 0.34),
      BlendMode.srcATop,
    );
  final Paint _fill = Paint();
  final Paint _line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  // Cached horizontal shader for the wavefront band (x-only gradient).
  late final ui.Shader _waveShader = LinearGradient(
    colors: [
      Colors.transparent,
      _cyan.withValues(alpha: 0.65),
      Colors.white.withValues(alpha: 0.90),
      _cyan.withValues(alpha: 0.65),
      Colors.transparent,
    ],
    stops: const [0.0, 0.25, 0.50, 0.75, 1.0],
  ).createShader(Rect.fromLTWH(0, 0, logoWidth, 1));

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;

    final exit = 1.0 - _seg(t, 0.93, 1.0, Curves.easeIn);
    final beam = -0.15 + 1.30 * _seg(t, 0.02, 0.24, Curves.easeInOutCubic);
    final reveal = _seg(t, 0.20, 0.50, Curves.easeOutCubic);
    final meterFlash = _pulse(t, 0.44, 0.56, peak: 0.35);
    final specular = -1.2 + 3.4 * _seg(t, 0.50, 0.78, Curves.easeInOutCubic);
    final breathe = _breathe(t);
    final zoom = 1.0 + 2.4 * _seg(t, 0.80, 1.0, Curves.easeInCubic);
    final rays = _pulse(t, 0.78, 1.0,
        peak: 0.6, up: Curves.easeOutCubic, down: Curves.easeIn);

    final center = Offset(size.width / 2, size.height / 2);

    if (rays > 0.01) _paintRays(canvas, size, center, rays);

    _paintBloom(canvas, center, reveal * 0.42 * breathe * exit, zoom);

    // ---- Logo space: origin at the logo's top-left, scaled about its centre.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(zoom);
    canvas.translate(-logoWidth / 2, -logoHeight / 2);

    _paintLogo(canvas, reveal, exit);
    if (specular > -0.25 && specular < 1.25) _paintGlint(canvas, specular);
    _paintRoadBeam(canvas, beam, reveal);
    if (reveal > 0.02 && reveal < 0.98) _paintWavefront(canvas, reveal);
    if (meterFlash > 0.01) _paintMeterFlash(canvas, meterFlash);

    canvas.restore();

    // ---- Optical flash bloom at the moment of departure.
    if (t >= 0.88) {
      final flash = (math.sin((t - 0.88) / 0.12 * math.pi) * 0.45).clamp(0.0, 1.0);
      if (flash > 0.005) {
        _fill
          ..shader = null
          ..color = _ice.withValues(alpha: flash);
        canvas.drawRect(Offset.zero & size, _fill);
      }
    }
  }

  double _breathe(double t) {
    if (t <= 0.45) return 0.75;
    if (t >= 0.82) return 0.85;
    final u = (t - 0.45) / (0.82 - 0.45);
    if (u < 0.5) {
      return 0.75 + 0.25 * Curves.easeInOut.transform(u / 0.5);
    }
    return 1.0 - 0.15 * Curves.easeInOut.transform((u - 0.5) / 0.5);
  }

  // ----- Hyperspace rays: 4 batched draw calls, no shaders ------------------
  void _paintRays(Canvas canvas, Size size, Offset c, double intensity) {
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) / 2;

    const rayCount = 24;
    final thickTail = <Offset>[];
    final thinTail = <Offset>[];
    final thickHead = <Offset>[];
    final thinHead = <Offset>[];

    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * (2 * math.pi) + (i * 0.15);
      final innerDist = 60.0 + (i % 3 * 25.0);
      final outerDist = innerDist + ((maxRadius - innerDist) * intensity);
      final midDist = innerDist + (outerDist - innerDist) * 0.55;

      final cosA = math.cos(angle);
      final sinA = math.sin(angle);
      final p1 = Offset(c.dx + innerDist * cosA, c.dy + innerDist * sinA);
      final pm = Offset(c.dx + midDist * cosA, c.dy + midDist * sinA);
      final p2 = Offset(c.dx + outerDist * cosA, c.dy + outerDist * sinA);

      final thick = i % 4 == 0;
      (thick ? thickTail : thinTail).addAll([p1, p2]);
      (thick ? thickHead : thinHead).addAll([pm, p2]);
    }

    _line.shader = null;
    void batch(List<Offset> pts, double width, Color color) {
      _line
        ..strokeWidth = width
        ..color = color;
      canvas.drawPoints(ui.PointMode.lines, pts, _line);
    }

    final tail = _cyan.withValues(alpha: intensity * 0.30);
    final head = Colors.white.withValues(alpha: intensity * 0.60);
    batch(thickTail, 2.5, tail);
    batch(thinTail, 1.2, tail);
    batch(thickHead, 2.5, head);
    batch(thinHead, 1.2, head);
  }

  // ----- Ambient bloom: one radial-gradient circle --------------------------
  void _paintBloom(Canvas canvas, Offset c, double opacity, double zoom) {
    final a = opacity.clamp(0.0, 1.0);
    if (a <= 0.005) return;

    final s = zoom > 1.2 ? zoom * 0.7 : 1.0;
    final w1 = logoWidth * 1.6 * s;
    final h1 = logoHeight * 2.8 * s;
    final r = 0.65 * math.min(w1, h1);

    _fill
      ..color = Colors.white
      ..shader = RadialGradient(
        radius: 0.5,
        colors: [
          _cyan.withValues(alpha: a),
          _blue.withValues(alpha: a * 0.45),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, _fill);
    _fill.shader = null;
  }

  // ----- Logo: bottom-up soft reveal via sliced drawImageRect ---------------
  void _drawSlice(Canvas canvas, ui.Image img, double n0, double n1, double alpha) {
    if (n1 <= n0 || alpha <= 0.003) return;
    final iw = img.width.toDouble();
    final ih = img.height.toDouble();
    _imagePaint.color = Color.fromRGBO(255, 255, 255, alpha.clamp(0.0, 1.0));
    canvas.drawImageRect(
      img,
      Rect.fromLTRB(0, n0 * ih, iw, n1 * ih),
      Rect.fromLTRB(0, n0 * logoHeight, logoWidth, n1 * logoHeight),
      _imagePaint,
    );
  }

  void _paintLogo(Canvas canvas, double reveal, double exit) {
    final img = image;
    if (img == null || reveal <= 0.0) return;

    if (reveal >= 0.999) {
      _drawSlice(canvas, img, 0.0, 1.0, exit);
      return;
    }

    const feather = 0.12;
    final yLine = (1.0 + feather) * (1.0 - reveal);

    // Fully-revealed body below the wavefront.
    _drawSlice(canvas, img, yLine.clamp(0.0, 1.0), 1.0, exit);

    // Soft feathered leading edge above it.
    const strips = 8;
    for (int i = 0; i < strips; i++) {
      final s0 = (yLine - feather + feather * i / strips).clamp(0.0, 1.0);
      final s1 = (yLine - feather + feather * (i + 1) / strips).clamp(0.0, 1.0);
      if (s1 <= s0) continue;
      final mid = (s0 + s1) / 2;
      final a = (1.0 - (yLine - mid) / feather).clamp(0.0, 1.0);
      _drawSlice(canvas, img, s0, s1, a * exit);
    }
  }

  // ----- Specular glint: clipped, tinted re-draw (3 nested bands) -----------
  void _paintGlint(Canvas canvas, double specular) {
    final img = image;
    if (img == null) return;

    final begin = Offset(logoWidth * 0.1, 0);
    final d = Offset(logoWidth * 0.8, logoHeight);
    final len = d.distance;
    final perp = Offset(-d.dy, d.dx) / len * (logoWidth + logoHeight);

    final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, logoWidth, logoHeight);

    for (final half in const [0.22, 0.14, 0.07]) {
      final p0 = begin + d * (specular - half);
      final p1 = begin + d * (specular + half);
      final path = Path()
        ..moveTo(p0.dx + perp.dx, p0.dy + perp.dy)
        ..lineTo(p0.dx - perp.dx, p0.dy - perp.dy)
        ..lineTo(p1.dx - perp.dx, p1.dy - perp.dy)
        ..lineTo(p1.dx + perp.dx, p1.dy + perp.dy)
        ..close();
      canvas.save();
      canvas.clipPath(path);
      canvas.drawImageRect(img, src, dst, _glintPaint);
      canvas.restore();
    }
  }

  // ----- Neon laser along the road baseline ---------------------------------
  void _paintRoadBeam(Canvas canvas, double beamPos, double reveal) {
    // Road lives in the bottom 18px strip of the logo.
    final y = (logoHeight - 18) + 18 * 0.55;

    if (beamPos > 0.0) {
      final trailEnd = (beamPos * logoWidth).clamp(0.0, logoWidth);
      final trailStart = ((beamPos - 0.45) * logoWidth).clamp(0.0, logoWidth);

      if (trailEnd > trailStart) {
        final rect = Rect.fromLTRB(trailStart, y - 1, trailEnd, y + 1);

        // Neon aura: two stacked translucent bands instead of a blur filter.
        _fill.shader = LinearGradient(colors: [
          Colors.transparent,
          _blue.withValues(alpha: 0.20),
          _cyan.withValues(alpha: 0.30),
        ]).createShader(rect);
        canvas.drawRRect(
          RRect.fromLTRBR(trailStart, y - 6, trailEnd, y + 6, const Radius.circular(6)),
          _fill,
        );
        canvas.drawRRect(
          RRect.fromLTRBR(trailStart, y - 3.5, trailEnd, y + 3.5, const Radius.circular(3.5)),
          _fill,
        );

        // Sharp laser core.
        _fill.shader = LinearGradient(colors: [
          Colors.transparent,
          _cyan,
          Colors.white,
        ]).createShader(rect);
        canvas.drawRRect(
          RRect.fromLTRBR(trailStart, y - 1.2, trailEnd, y + 1.2, const Radius.circular(1.2)),
          _fill,
        );

        // Leading spark.
        final head = Offset(trailEnd, y);
        _fill.shader = RadialGradient(
          radius: 0.5,
          colors: [
            _cyan.withValues(alpha: 0.95),
            _cyan.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: head, radius: 14));
        canvas.drawCircle(head, 14, _fill);
        _fill
          ..shader = null
          ..color = Colors.white;
        canvas.drawCircle(head, 3.2, _fill);
      }
    }

    // Cascading ignition of the speed dashes along the right half.
    final dashStartX = logoWidth * 0.52;
    final dashEndX = logoWidth * 0.98;
    const dashCount = 18;
    _line
      ..shader = null
      ..strokeWidth = 2.0;

    for (int i = 0; i < dashCount; i++) {
      final k = i / (dashCount - 1);
      final dx = dashStartX + k * (dashEndX - dashStartX);
      final trigger = 0.52 + k * 0.46;

      double alpha = 0.0;
      if (beamPos >= trigger) {
        final dist = (beamPos - trigger).abs();
        alpha = dist < 0.12
            ? 1.0 - dist / 0.12
            : (0.28 * reveal).clamp(0.0, 0.45);
      }

      if (alpha > 0.02) {
        _line.color = _cyan.withValues(alpha: alpha);
        canvas.drawLine(Offset(dx, y - 2.5), Offset(dx, y + 2.5), _line);
      }
    }
  }

  // ----- Vertical wavefront band ---------------------------------------------
  void _paintWavefront(Canvas canvas, double reveal) {
    final top = (1.0 - reveal) * logoHeight - 6;
    _fill
      ..color = Colors.white
      ..shader = _waveShader;
    canvas.drawRect(Rect.fromLTWH(0, top, logoWidth, 12), _fill);
    _fill.shader = null;
  }

  // ----- "METER" electric pop -------------------------------------------------
  void _paintMeterFlash(Canvas canvas, double flash) {
    final c = Offset(logoWidth * 0.40, logoHeight * 0.20);
    final rect = Rect.fromCenter(center: c, width: logoWidth * 0.46, height: logoHeight * 0.62);
    _fill
      ..color = Colors.white
      ..shader = RadialGradient(
        radius: 0.5,
        colors: [
          _cyan.withValues(alpha: flash * 0.75),
          _cyan.withValues(alpha: 0.0),
        ],
      ).createShader(rect);
    canvas.drawOval(rect, _fill);
    _fill.shader = null;
  }

  @override
  bool shouldRepaint(covariant _SplashPainter old) {
    return old.image != image ||
        old.logoWidth != logoWidth ||
        old.logoHeight != logoHeight ||
        old.anim != anim;
  }
}

/// Backward compatibility alias
typedef PremiumSplashView = SplashScreen;
