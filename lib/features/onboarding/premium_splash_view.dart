import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:biyahe_meter/features/onboarding/agreements_screen.dart';

/// Screen 1: Splash Screen (`SplashScreen`)
///
/// "Meter Lock" — a fare-meter badge finds its GPS fix, the brand types itself
/// in, the road drives across, then the badge zooms through into the app:
/// - 0.00–0.90s  GPS seed dot pops, ping rings ripple out, the badge blooms
///               and its cyan meter arc ticks up around a ₱ sign.
/// - 0.95–1.95s  "Biyahe" reveals letter by letter, "METER" clicks in, the
///               road streak drives in left→right with a light at its head.
/// - 1.80–2.15s  Tagline settles in. Brief hold.
/// - 2.45–3.20s  Text falls away, the badge pulls back, then zooms through
///               the screen (its navy disc fills it) into the Agreements screen.
///
/// PERFORMANCE ARCHITECTURE (see memory-bank/activeContext.md, do not regress):
/// - ONE [CustomPainter] repainted by the controller (`repaint:`): zero widget
///   rebuilds per frame. Static backdrop on its own [RepaintBoundary].
/// - Logo decoded to `ui.Image` BEFORE the clock starts; shaders warmed offscreen.
/// - No `saveLayer`: no ShaderMask/Opacity/BackdropFilter/blur MaskFilter.
///   Letter reveal = sliced `drawImageRect` + paint alpha; glows = cached
///   radial-gradient shaders drawn under a canvas transform.
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
  static const _total = Duration(milliseconds: 3200);

  late final AnimationController _anim;

  ImageStream? _stream;
  ImageStreamListener? _listener;
  ImageInfo? _logoInfo;
  bool _resolved = false;
  bool _started = false;
  bool _warming = false;

  Timer? _startFallback;
  Timer? _safetyTimer;
  final List<Timer> _haptics = [];

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(vsync: this, duration: _total);

    _anim.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _proceed();
      }
    });

    // Never block the app: covers slow decode + the (capped) shader warm-up.
    _startFallback = Timer(const Duration(milliseconds: 2200), _begin);
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
        _warmUpThenBegin();
      },
      onError: (_, _) => _begin(),
    );
    stream.addListener(_listener!);
  }

  TextStyle get _taglineStyle =>
      (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.2,
        color: const Color(0xFFB8C4D9), // ≥7:1 on the navy backdrop
      );

  /// Render a handful of frames offscreen (tiny, 1/4 scale) BEFORE the clock
  /// starts, so every gradient / clip / image pipeline is compiled before its
  /// first real appearance. Capped so it can never delay the splash noticeably.
  Future<void> _warmUpThenBegin() async {
    if (_started || _warming) return;
    _warming = true;
    try {
      await _warmUp().timeout(const Duration(milliseconds: 700));
    } catch (_) {}
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _begin());
  }

  Future<void> _warmUp() async {
    final img = _logoInfo?.image;
    if (img == null) return;
    final size = MediaQuery.sizeOf(context);
    const scale = 0.25;
    final w = math.max(1, (size.width * scale).ceil());
    final h = math.max(1, (size.height * scale).ceil());
    final painter = _SplashPainter(
      anim: const AlwaysStoppedAnimation<double>(0),
      image: img,
      taglineStyle: _taglineStyle,
    );

    // One time-point inside each effect: seed + pings, bloom + arc, letters +
    // road head, tagline, exit, zoom-through.
    for (final t in const [0.05, 0.20, 0.36, 0.50, 0.62, 0.80, 0.95]) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.scale(scale);
      painter.paintAt(canvas, size, t);
      final picture = recorder.endRecording();
      final out = await picture.toImage(w, h);
      out.dispose();
      picture.dispose();
    }
  }

  void _begin() {
    if (_started || !mounted) return;
    _started = true;
    _startFallback?.cancel();
    _startFallback = null;

    // Reduced motion: show the composed brand frame, no zoom, no haptics.
    if (MediaQuery.disableAnimationsOf(context)) {
      _anim.value = _SplashPainter.composedFrame;
      _safetyTimer = Timer(const Duration(milliseconds: 1000), _proceed);
      return;
    }

    _anim.forward();

    // Tactile cues: GPS fix, METER clicks in, zoom-through.
    if (!kIsWeb) {
      void at(int ms, Future<void> Function() fire) {
        _haptics.add(Timer(Duration(milliseconds: ms), () {
          if (!mounted) return;
          try {
            fire();
          } catch (_) {}
        }));
      }

      at(140, HapticFeedback.lightImpact);
      at(1500, HapticFeedback.selectionClick);
      at(2740, HapticFeedback.mediumImpact);
    }

    // Safety fallback
    _safetyTimer = Timer(_total + const Duration(milliseconds: 300), () {
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
    for (final t in _haptics) {
      t.cancel();
    }
    if (_listener != null) _stream?.removeListener(_listener!);
    _logoInfo?.dispose();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF03050B),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF03050C),
        body: Semantics(
          container: true,
          label: 'Biyahe Meter. Know your fare. Plan your byahe.',
          child: ExcludeSemantics(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Static backdrop (matches web/index.html's loader), rasterised once.
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
                      taglineStyle: _taglineStyle,
                    ),
                    isComplex: true,
                    willChange: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline helpers (all times in ms of the 3200 ms clock)
// ---------------------------------------------------------------------------

const double _totalMs = 3200;

/// Eased 0..1 progress of the current time across [aMs]..[bMs].
double _seg(double ms, double aMs, double bMs, [Curve curve = Curves.linear]) {
  return curve.transform(((ms - aMs) / (bMs - aMs)).clamp(0.0, 1.0));
}

/// Mild overshoot for the badge bloom (≈4%), never springy.
const Curve _bloom = Cubic(0.34, 1.25, 0.64, 1.0);

/// Slow start, then accelerates hard: the zoom-through.
const Curve _launch = Cubic(0.72, 0.0, 0.86, 0.0);

// ---------------------------------------------------------------------------
// Single-pass splash painter
// ---------------------------------------------------------------------------

class _SplashPainter extends CustomPainter {
  final Animation<double> anim;
  final ui.Image? image;
  final TextStyle taglineStyle;

  _SplashPainter({
    required this.anim,
    required this.image,
    required this.taglineStyle,
  }) : super(repaint: anim);

  /// Animation value where badge, wordmark and tagline are all fully in.
  static const double composedFrame = 2300 / _totalMs;

  static const _cyan = Color(0xFF38BDF8);
  static const _ice = Color(0xFFBAE6FD);

  // Regions of assets/images/logo_dark_hd.png (1308 × 452), in source pixels.
  static const double _srcLeft = 18, _srcRight = 1248;
  static const double _srcTop = 18; // top of "METER"
  static const Rect _meterSrc = Rect.fromLTRB(300, 18, 590, 90);
  static const double _lettersTop = 90, _lettersBottom = 372;
  static const Rect _roadSrc = Rect.fromLTRB(18, 372, 1248, 432);
  // Column boundaries between the letters of "Biyahe" (in the gaps).
  static const List<double> _letterCuts = [148, 353, 422, 609, 788, 980, 1165];

  // Reused paints (no per-frame allocation churn).
  final Paint _imagePaint = Paint()
    ..filterQuality = FilterQuality.medium
    ..isAntiAlias = true;
  final Paint _fill = Paint()..isAntiAlias = true;
  final Paint _line = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  // Unit-radius shaders, drawn under a canvas scale, so they're built once.
  static final ui.Shader _discShader = const RadialGradient(
    center: Alignment(-0.25, -0.35),
    colors: [Color(0xFF1A3466), Color(0xFF0B1733)],
  ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1));
  static final ui.Shader _glowShader = RadialGradient(
    colors: [
      _cyan.withValues(alpha: 0.30),
      _cyan.withValues(alpha: 0.10),
      _cyan.withValues(alpha: 0.0),
    ],
    stops: const [0.0, 0.45, 1.0],
  ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1));

  // ₱ in badge units (radius 1), centred on the badge.
  static final Path _pesoBody = Path()
    ..moveTo(-0.17, 0.36)
    ..lineTo(-0.17, -0.32)
    ..lineTo(0.04, -0.32)
    ..arcToPoint(
      const Offset(0.04, 0.06),
      radius: const Radius.circular(0.19),
    )
    ..lineTo(-0.17, 0.06);
  static final Path _pesoBars = Path()
    ..moveTo(-0.33, -0.19)
    ..lineTo(0.30, -0.19)
    ..moveTo(-0.33, -0.07)
    ..lineTo(0.30, -0.07);

  // Tagline layouts cached per alpha step (TextPainter can't change alpha).
  final Map<int, TextPainter> _taglineCache = {};

  @override
  void paint(Canvas canvas, Size size) => paintAt(canvas, size, anim.value);

  void paintAt(Canvas canvas, Size size, double t) {
    final ms = t * _totalMs;
    final g = _Layout(size);

    // ---- Exit choreography shared by everything.
    final textExit = _seg(ms, 2450, 2700, Curves.easeInCubic);
    final pullBack = _seg(ms, 2450, 2720, Curves.easeInOutCubic);
    final zoomP = _seg(ms, 2720, _totalMs, _launch);
    final zoomScale = g.coverScale / 0.9;

    // ---- Badge scale: seed dot → full badge → pull back → zoom through.
    final seed = _seg(ms, 0, 240, Curves.easeOutBack);
    final bloom = _seg(ms, 300, 900, _bloom);
    var k = 0.24 * seed + 0.76 * bloom;
    k *= 1.0 - 0.10 * pullBack;
    k *= 1.0 + (zoomScale - 1.0) * zoomP;

    final discAlpha = _seg(ms, 300, 620, Curves.easeOut);
    final arcP = _seg(ms, 420, 1080, Curves.easeInOutCubic);
    final pesoP = _seg(ms, 640, 960, Curves.easeOutCubic);
    final glow = discAlpha * (1.0 - _seg(ms, 2720, 3000, Curves.easeIn));

    _paintPings(canvas, g, ms);
    if (glow > 0.01) _paintGlow(canvas, g, k, glow);
    _paintBadge(canvas, g, k, ms, seed, discAlpha, arcP, pesoP, zoomP);

    // ---- Wordmark + road + tagline (fall away together on exit).
    final textAlpha = 1.0 - textExit;
    if (textAlpha > 0.01 && image != null) {
      final drop = 10.0 * textExit;
      _paintLetters(canvas, g, ms, textAlpha, drop);
      _paintMeterLabel(canvas, g, ms, textAlpha, drop);
      _paintRoad(canvas, g, ms, textAlpha, drop);
    }
    if (textAlpha > 0.01) _paintTagline(canvas, g, ms, textAlpha);
  }

  // GPS-lock pings: three at the fix, one more as the badge departs.
  void _paintPings(Canvas canvas, _Layout g, double ms) {
    for (final start in const [120.0, 360.0, 600.0, 2560.0]) {
      final p = _seg(ms, start, start + 950, Curves.easeOutCubic);
      if (p <= 0 || p >= 1) continue;
      final a = 0.55 * math.pow(1 - p, 1.4);
      _line
        ..shader = null
        ..strokeWidth = 1.6
        ..color = _cyan.withValues(alpha: a.toDouble());
      canvas.drawCircle(g.badge, g.r * (0.35 + 2.1 * p), _line);
    }
  }

  void _paintGlow(Canvas canvas, _Layout g, double k, double a) {
    canvas.save();
    canvas.translate(g.badge.dx, g.badge.dy);
    canvas.scale(g.r * math.max(k, 0.24) * 2.3);
    _fill
      ..shader = _glowShader
      ..color = Colors.white.withValues(alpha: a);
    canvas.drawCircle(Offset.zero, 1, _fill);
    canvas.restore();
    _fill.shader = null;
  }

  void _paintBadge(
    Canvas canvas,
    _Layout g,
    double k,
    double ms,
    double seed,
    double discAlpha,
    double arcP,
    double pesoP,
    double zoomP,
  ) {
    if (k <= 0) return;
    canvas.save();
    canvas.translate(g.badge.dx, g.badge.dy);
    canvas.scale(g.r * k);

    // Seed: the cyan GPS fix that the badge grows out of.
    final coreAlpha = seed * (1.0 - _seg(ms, 380, 760, Curves.easeIn));
    if (coreAlpha > 0.01) {
      _fill
        ..shader = null
        ..color = _cyan.withValues(alpha: coreAlpha);
      canvas.drawCircle(Offset.zero, 0.85, _fill);
      _fill.color = _ice.withValues(alpha: coreAlpha);
      canvas.drawCircle(Offset.zero, 0.5, _fill);
    }

    if (discAlpha > 0.01) {
      // Navy disc: at full zoom it fills the screen as the hand-off colour.
      _fill
        ..shader = _discShader
        ..color = Colors.white.withValues(alpha: discAlpha);
      canvas.drawCircle(Offset.zero, 1, _fill);
      _fill.shader = null;

      // Rim
      _line
        ..shader = null
        ..strokeWidth = 0.035
        ..color = _cyan.withValues(alpha: 0.45 * discAlpha);
      canvas.drawCircle(Offset.zero, 0.985, _line);

      // Meter arc: 270° gauge, gap at the bottom, ticking up clockwise.
      final detail = discAlpha * (1.0 - _seg(zoomP, 0.0, 0.55));
      if (detail > 0.01) {
        const start = math.pi * 0.75;
        const sweep = math.pi * 1.5;
        final arcRect = Rect.fromCircle(center: Offset.zero, radius: 0.72);
        _line
          ..strokeWidth = 0.11
          ..color = Colors.white.withValues(alpha: 0.10 * detail);
        canvas.drawArc(arcRect, start, sweep, false, _line);
        if (arcP > 0) {
          _line.color = _cyan.withValues(alpha: detail);
          canvas.drawArc(arcRect, start, sweep * arcP, false, _line);
          if (arcP < 1) {
            final a = start + sweep * arcP;
            final tip = Offset(math.cos(a) * 0.72, math.sin(a) * 0.72);
            _fill.color = Colors.white.withValues(alpha: detail);
            canvas.drawCircle(tip, 0.075, _fill);
          }
        }

        // ₱ — the fare at the heart of the meter.
        if (pesoP > 0) {
          canvas.save();
          canvas.scale(0.72 + 0.28 * pesoP);
          _line
            ..strokeWidth = 0.115
            ..color = Colors.white.withValues(alpha: pesoP * detail);
          canvas.drawPath(_pesoBody, _line);
          _line.strokeWidth = 0.085;
          canvas.drawPath(_pesoBars, _line);
          canvas.restore();
        }
      }
    }
    canvas.restore();
  }

  void _paintLetters(
      Canvas canvas, _Layout g, double ms, double alpha, double drop) {
    final img = image!;
    for (var i = 0; i < _letterCuts.length - 1; i++) {
      final start = 960.0 + i * 70;
      final p = _seg(ms, start, start + 360, Curves.easeOutCubic);
      if (p <= 0) continue;
      final src = Rect.fromLTRB(
          _letterCuts[i], _lettersTop, _letterCuts[i + 1], _lettersBottom);
      final dst = g.logoRect(src).shift(Offset(0, 12 * (1 - p) + drop));
      _imagePaint.color = Colors.white.withValues(alpha: p * alpha);
      canvas.drawImageRect(img, src, dst, _imagePaint);
    }
  }

  void _paintMeterLabel(
      Canvas canvas, _Layout g, double ms, double alpha, double drop) {
    final p = _seg(ms, 1460, 1760, Curves.easeOutCubic);
    if (p <= 0) return;
    final dst = g.logoRect(_meterSrc).shift(Offset(-10 * (1 - p), drop));
    _imagePaint.color = Colors.white.withValues(alpha: p * alpha);
    canvas.drawImageRect(image!, _meterSrc, dst, _imagePaint);
  }

  void _paintRoad(
      Canvas canvas, _Layout g, double ms, double alpha, double drop) {
    final q = _seg(ms, 1300, 1950, Curves.easeInOutCubic);
    if (q <= 0) return;
    final src = Rect.fromLTRB(_roadSrc.left, _roadSrc.top,
        _roadSrc.left + _roadSrc.width * q, _roadSrc.bottom);
    final dst = g.logoRect(src).shift(Offset(0, drop));
    _imagePaint.color = Colors.white.withValues(alpha: alpha);
    canvas.drawImageRect(image!, src, dst, _imagePaint);

    // Headlight at the leading edge while the road is still driving in.
    final head = (1.0 - _seg(q, 0.85, 1.0)) * alpha;
    if (head > 0.01) {
      final c = Offset(dst.right, dst.center.dy - 2);
      _fill.shader = null;
      for (final (rad, a) in const [(14.0, 0.10), (7.0, 0.28), (3.2, 0.95)]) {
        _fill.color =
            (a > 0.5 ? Colors.white : _cyan).withValues(alpha: a * head);
        canvas.drawCircle(c, rad, _fill);
      }
    }
  }

  void _paintTagline(Canvas canvas, _Layout g, double ms, double alpha) {
    final inP = _seg(ms, 1800, 2160, Curves.easeOutCubic);
    final p = inP * alpha;
    if (p <= 0.01) return;
    final step = (p * 20).round(); // 21 cached layouts at most
    final tp = _taglineCache.putIfAbsent(step, () {
      final base = taglineStyle.color ?? Colors.white;
      return TextPainter(
        text: TextSpan(
          text: 'Know your fare. Plan your byahe.',
          style: taglineStyle.copyWith(
            color: base.withValues(alpha: base.a * step / 20),
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
      )..layout(maxWidth: g.size.width - 48);
    });
    tp.paint(
      canvas,
      Offset((g.size.width - tp.width) / 2, g.taglineTop + 6 * (1 - inP)),
    );
  }

  @override
  bool shouldRepaint(covariant _SplashPainter old) =>
      old.image != image || old.taglineStyle != taglineStyle;
}

/// Responsive geometry: badge above the wordmark, the group centred on screen.
class _Layout {
  final Size size;
  late final double r; // badge radius
  late final Offset badge;
  late final double logoScale; // logical px per source px
  late final Offset logoOrigin; // where source (_srcLeft, _srcTop) lands
  late final double taglineTop;
  late final double coverScale; // badge scale that covers the whole screen

  _Layout(this.size) {
    final w = size.width, h = size.height;
    final isTablet = w >= 600;
    final d = (w * (isTablet ? 0.15 : 0.27)).clamp(84.0, 124.0);
    r = d / 2;
    final logoW = (w * (isTablet ? 0.40 : 0.64)).clamp(230.0, 360.0);
    logoScale = logoW / (_SplashPainter._srcRight - _SplashPainter._srcLeft);
    final logoH =
        (_SplashPainter._roadSrc.bottom - _SplashPainter._srcTop) * logoScale;

    final gapBadge = d * 0.34;
    const gapTag = 18.0, tagH = 20.0;
    final group = d + gapBadge + logoH + gapTag + tagH;
    final top = (h - group) / 2 - h * 0.02;

    badge = Offset(w / 2, top + r);
    logoOrigin = Offset((w - logoW) / 2, top + d + gapBadge);
    taglineTop = logoOrigin.dy + logoH + gapTag;

    final far = math.sqrt(math.pow(math.max(badge.dx, w - badge.dx), 2) +
        math.pow(math.max(badge.dy, h - badge.dy), 2));
    coverScale = far / r * 1.08;
  }

  Rect logoRect(Rect src) => Rect.fromLTRB(
        logoOrigin.dx + (src.left - _SplashPainter._srcLeft) * logoScale,
        logoOrigin.dy + (src.top - _SplashPainter._srcTop) * logoScale,
        logoOrigin.dx + (src.right - _SplashPainter._srcLeft) * logoScale,
        logoOrigin.dy + (src.bottom - _SplashPainter._srcTop) * logoScale,
      );
}
