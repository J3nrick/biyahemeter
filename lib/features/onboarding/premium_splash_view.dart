import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:biyahe_meter/features/onboarding/agreements_screen.dart';

/// Screen 1: Splash Screen (`SplashScreen`)
///
/// "Light Assembly" — made from nothing but the logo's own pixels:
/// - 0.00–1.10s  Inflow: the logo is sampled into ~6k points of light that
///               stream in from the left like headlights, leaving light trails,
///               and land on their exact pixel (left→right, like the road bar).
/// - 0.90–1.45s  Ignition: the crisp HD logo takes over with a brief flare.
/// - 1.35–1.95s  Sheen: a specular band sweeps the letters.
/// - 2.00–2.80s  Departure: the logo breaks back into light and launches off
///               to the right, leaving a clear screen for the app.
///
/// PERFORMANCE (see memory-bank/activeContext.md, do not regress):
/// - ONE [CustomPainter] repainted by the controller; zero widget rebuilds.
/// - Logo decoded + sampled into particles BEFORE the clock starts.
/// - Particles = two batched `drawRawPoints` calls per frame (white, cyan).
/// - No saveLayer / ShaderMask / Opacity / BackdropFilter / blur MaskFilter.
class SplashScreen extends StatefulWidget {
  final VoidCallback? onFinish;
  final AnimationController? controller; // Optional backward compatibility

  /// Repeat launches: same sequence played faster so the app opens sooner.
  final bool quick;

  const SplashScreen({
    super.key,
    this.onFinish,
    this.controller,
    this.quick = false,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _logoAsset = 'assets/images/logo_dark_hd.png';
  static const _total = Duration(milliseconds: 2800);

  late final AnimationController _anim;

  ImageStream? _stream;
  ImageStreamListener? _listener;
  ImageInfo? _logoInfo;
  _Particles? _particles;
  bool _resolved = false;
  bool _started = false;
  bool _warming = false;

  Timer? _startFallback;
  Timer? _safetyTimer;
  final List<Timer> _haptics = [];

  double get _speed => widget.quick ? 0.55 : 1.0;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(vsync: this, duration: _total * _speed);

    _anim.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _proceed();
      }
    });

    // Never block the app: covers slow decode + sampling + shader warm-up.
    _startFallback = Timer(const Duration(milliseconds: 2200), _begin);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolved) return;
    _resolved = true;

    final stream = const AssetImage(
      _logoAsset,
    ).resolve(createLocalImageConfiguration(context));
    _stream = stream;
    _listener = ImageStreamListener((info, synchronousCall) {
      _logoInfo?.dispose();
      _logoInfo = info.clone();
      _prepareThenBegin();
    }, onError: (_, _) => _begin());
    stream.addListener(_listener!);
  }

  /// Sample particles and warm shaders offscreen BEFORE the clock starts, so
  /// the first animated frame costs the same as the last. Capped so it can
  /// never delay the splash noticeably.
  Future<void> _prepareThenBegin() async {
    if (_started || _warming) return;
    _warming = true;
    try {
      await (() async {
        _particles = await _Particles.sample(_logoInfo!.image);
        if (mounted) setState(() {});
        await _warmUp();
      })().timeout(const Duration(milliseconds: 900));
    } catch (_) {}
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _begin());
  }

  Future<void> _warmUp() async {
    final img = _logoInfo?.image;
    if (img == null || !mounted) return;
    final size = MediaQuery.sizeOf(context);
    const scale = 0.25;
    final w = math.max(1, (size.width * scale).ceil());
    final h = math.max(1, (size.height * scale).ceil());
    final painter = _SplashPainter(
      anim: const AlwaysStoppedAnimation<double>(0),
      image: img,
      particles: _particles,
    );
    // One time-point inside each effect: inflow, ignition, sheen, departure.
    for (final t in const [0.20, 0.42, 0.58, 0.80]) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..scale(scale);
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

    // Reduced motion: the crisp logo, still, then on to the app.
    if (MediaQuery.disableAnimationsOf(context)) {
      _anim.value = _SplashPainter.composedFrame;
      _safetyTimer = Timer(const Duration(milliseconds: 900), _proceed);
      return;
    }

    _anim.forward();

    // Tactile cues: ignition, departure.
    if (!kIsWeb) {
      void at(int ms, Future<void> Function() fire) {
        _haptics.add(
          Timer(Duration(milliseconds: (ms * _speed).round()), () {
            if (!mounted) return;
            try {
              fire();
            } catch (_) {}
          }),
        );
      }

      at(1150, HapticFeedback.lightImpact);
      at(2050, HapticFeedback.mediumImpact);
    }

    // Safety fallback
    _safetyTimer = Timer(
      _anim.duration! + const Duration(milliseconds: 300),
      () {
        if (mounted) _proceed();
      },
    );
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
          label: 'Biyahe Meter',
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
                          Color(0xFF0C1B3E),
                          Color(0xFF060D20),
                          Color(0xFF020409),
                        ],
                        stops: [0.0, 0.58, 1.0],
                      ),
                    ),
                  ),
                ),
                RepaintBoundary(
                  child: CustomPaint(
                    painter: _SplashPainter(
                      anim: _anim,
                      image: _logoInfo?.image,
                      particles: _particles,
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
// Logo → particles
// ---------------------------------------------------------------------------

/// Points sampled from the logo's opaque pixels, in logo-crop units (0..1),
/// with per-point random seeds. Built once from the decoded image.
class _Particles {
  final Float32List x, y, r1, r2, r3;
  final List<bool> cyan;
  final double dot; // sampling step as a fraction of the crop width

  _Particles(this.x, this.y, this.r1, this.r2, this.r3, this.cyan, this.dot);

  int get length => cyan.length;

  static const _maxPoints = 6500;

  static Future<_Particles?> sample(ui.Image img) async {
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return null;
    final w = img.width;
    final crop = _SplashPainter.cropOf(w);

    bool opaque(int px, int py) => data.getUint8((py * w + px) * 4 + 3) > 140;

    // Coarsest step that still keeps the count under budget.
    var step = 4;
    while (true) {
      var n = 0;
      for (var py = crop.top.toInt(); py < crop.bottom; py += step) {
        for (var px = crop.left.toInt(); px < crop.right; px += step) {
          if (opaque(px, py)) n++;
        }
      }
      if (n <= _maxPoints || step >= 12) break;
      step++;
    }

    final xs = <double>[], ys = <double>[], cy = <bool>[];
    for (var py = crop.top.toInt(); py < crop.bottom; py += step) {
      for (var px = crop.left.toInt(); px < crop.right; px += step) {
        if (!opaque(px, py)) continue;
        final i = (py * w + px) * 4;
        final r = data.getUint8(i), b = data.getUint8(i + 2);
        xs.add((px - crop.left) / crop.width);
        ys.add((py - crop.top) / crop.height);
        cy.add(b > 180 && r < 160); // METER + road are cyan, letters white
      }
    }
    final n = cy.length;
    final rnd = math.Random(7);
    Float32List seeds() =>
        Float32List.fromList(List.generate(n, (_) => rnd.nextDouble()));
    return _Particles(
      Float32List.fromList(xs),
      Float32List.fromList(ys),
      seeds(),
      seeds(),
      seeds(),
      cy,
      step / crop.width,
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline helpers (ms of the 2800 ms clock)
// ---------------------------------------------------------------------------

const double _totalMs = 2800;

double _seg(double ms, double aMs, double bMs, [Curve curve = Curves.linear]) =>
    curve.transform(((ms - aMs) / (bMs - aMs)).clamp(0.0, 1.0));

// ---------------------------------------------------------------------------
// Single-pass splash painter
// ---------------------------------------------------------------------------

class _SplashPainter extends CustomPainter {
  final Animation<double> anim;
  final ui.Image? image;
  final _Particles? particles;

  _SplashPainter({
    required this.anim,
    required this.image,
    required this.particles,
  }) : super(repaint: anim);

  /// Value where the crisp logo is fully in and still (reduced motion).
  static const double composedFrame = 1990 / _totalMs;

  static const _cyan = Color(0xFF38BDF8);

  /// Visible logo inside logo_dark_hd.png (1308 × 452), scaled to [imgW].
  static Rect cropOf(int imgW) {
    final s = imgW / 1308;
    return Rect.fromLTRB(18 * s, 18 * s, 1248 * s, 432 * s);
  }

  final Paint _imagePaint = Paint()
    ..filterQuality = FilterQuality.medium
    ..isAntiAlias = true;
  final Paint _sheenPaint = Paint()
    ..filterQuality = FilterQuality.medium
    ..colorFilter = const ColorFilter.mode(
      Color(0x8CFFFFFF),
      BlendMode.srcATop,
    );
  final Paint _white = Paint()
    ..strokeCap = StrokeCap.round
    ..blendMode = BlendMode.plus; // overlapping trails add up like real light
  final Paint _blue = Paint()
    ..strokeCap = StrokeCap.round
    ..blendMode = BlendMode.plus;

  Float32List? _whiteBuf, _blueBuf;

  @override
  void paint(Canvas canvas, Size size) => paintAt(canvas, size, anim.value);

  void paintAt(Canvas canvas, Size size, double t) {
    final ms = t * _totalMs;
    final w = size.width, h = size.height;
    final logoW = (w * (w >= 600 ? 0.46 : 0.78)).clamp(260.0, 440.0);
    final logoH = logoW * 414 / 1230;
    final logo = Rect.fromCenter(
      center: Offset(w / 2, h / 2 - h * 0.02),
      width: logoW,
      height: logoH,
    );

    final p = particles;
    final ignite = _seg(ms, 900, 1350, Curves.easeInOut);
    final breakUp = _seg(ms, 2000, 2280, Curves.easeIn);
    // Without particles (sampling failed) the crisp logo simply fades in.
    final imageAlpha = (p == null ? _seg(ms, 0, 500) : ignite) * (1 - breakUp);
    final particleAlpha =
        math.max(1 - ignite, breakUp) * (1 - _seg(ms, 2550, _totalMs));

    if (p != null && particleAlpha > 0.01) {
      _paintParticles(canvas, size, logo, p, ms, particleAlpha);
    }

    final img = image;
    if (img == null || imageAlpha <= 0.01) return;
    final src = cropOf(img.width);
    _imagePaint
      ..blendMode = BlendMode.srcOver
      ..color = Colors.white.withValues(alpha: imageAlpha);
    canvas.drawImageRect(img, src, logo, _imagePaint);

    // Ignition flare: the logo drawn over itself additively, once.
    final flare = math.sin(_seg(ms, 1100, 1550) * math.pi) * 0.55;
    if (flare > 0.01) {
      _imagePaint
        ..blendMode = BlendMode.plus
        ..color = Colors.white.withValues(alpha: flare * imageAlpha);
      canvas.drawImageRect(img, src, logo, _imagePaint);
    }

    // Sheen: a slanted band of light, clipped, re-drawing only logo pixels.
    final s = _seg(ms, 1350, 1950, Curves.easeInOutSine);
    if (s > 0 && s < 1) {
      final cx = logo.left - logoW * 0.25 + logoW * 1.5 * s;
      final band = logoW * 0.09;
      final slant = logoH * 0.6;
      canvas.save();
      canvas.clipPath(
        Path()
          ..moveTo(cx - band + slant, logo.top)
          ..lineTo(cx + band + slant, logo.top)
          ..lineTo(cx + band - slant, logo.bottom)
          ..lineTo(cx - band - slant, logo.bottom)
          ..close(),
      );
      _sheenPaint.color = Colors.white.withValues(alpha: imageAlpha);
      canvas.drawImageRect(img, src, logo, _sheenPaint);
      canvas.restore();
    }
  }

  /// Each particle is a short line from where it was a moment ago to where it
  /// is now, so fast ones become light trails and settled ones become dots.
  void _paintParticles(
    Canvas canvas,
    Size size,
    Rect logo,
    _Particles p,
    double ms,
    double alpha,
  ) {
    final n = p.length;
    final wb = _whiteBuf ??= Float32List(n * 4);
    final bb = _blueBuf ??= Float32List(n * 4);
    var wi = 0, bi = 0;
    final w = size.width, h = size.height;

    for (var i = 0; i < n; i++) {
      final tx = logo.left + p.x[i] * logo.width;
      final ty = logo.top + p.y[i] * logo.height;
      double hx, hy, ox, oy;

      if (ms < 2000) {
        // Inflow: lanes from off-screen left; left side of the logo lands first.
        final u = (ms / 1100 - (0.42 * p.x[i] + 0.30 * p.r1[i])) / 0.5;
        if (u <= 0) continue;
        final sx = -(0.08 + 0.9 * p.r2[i]) * w;
        final sy = ty + (p.r3[i] - 0.5) * h * 0.16;
        final a = u > 1 ? 1.0 : u,
            b = u - 0.07 < 0 ? 0.0 : (u - 0.07 > 1 ? 1.0 : u - 0.07);
        final ia = 1 - a, ib = 1 - b;
        // x: easeOutQuart, y: easeOutCubic (lanes merge a touch later).
        hx = sx + (tx - sx) * (1 - ia * ia * ia * ia);
        hy = sy + (ty - sy) * (1 - ia * ia * ia);
        ox = sx + (tx - sx) * (1 - ib * ib * ib * ib);
        oy = sy + (ty - sy) * (1 - ib * ib * ib);
      } else {
        // Departure: right side launches first, accelerating off-screen.
        final v =
            ((ms - 2000) / 800 - (0.22 * (1 - p.x[i]) + 0.10 * p.r1[i])) / 0.62;
        final a = v < 0 ? 0.0 : (v > 1 ? 1.0 : v);
        final b = v - 0.06 < 0 ? 0.0 : (v - 0.06 > 1 ? 1.0 : v - 0.06);
        final reach = w * 1.2 + p.r2[i] * w * 0.8;
        final drift = (p.r3[i] - 0.5) * h * 0.07;
        final ea = a * a * a, eb = b * b * b; // easeInCubic
        hx = tx + ea * reach;
        hy = ty + ea * drift;
        ox = tx + eb * reach;
        oy = ty + eb * drift;
      }

      if (p.cyan[i]) {
        bb[bi++] = ox;
        bb[bi++] = oy;
        bb[bi++] = hx;
        bb[bi++] = hy;
      } else {
        wb[wi++] = ox;
        wb[wi++] = oy;
        wb[wi++] = hx;
        wb[wi++] = hy;
      }
    }

    // Moving light is thin and dim (additive trails would saturate to a
    // solid wedge); it thickens and brightens as points land.
    final landed = ms < 2000 ? _seg(ms, 600, 1000) : 0.0;
    final dot = math.max(1.2, p.dot * logo.width * 1.15);
    final width = dot * (0.42 + 0.58 * landed);
    final glow = alpha * (0.22 + 0.70 * landed);
    _white
      ..strokeWidth = width
      ..color = Colors.white.withValues(alpha: glow);
    _blue
      ..strokeWidth = width
      ..color = _cyan.withValues(alpha: math.min(1.0, glow * 1.15));
    if (wi > 0) {
      canvas.drawRawPoints(
        ui.PointMode.lines,
        Float32List.sublistView(wb, 0, wi),
        _white,
      );
    }
    if (bi > 0) {
      canvas.drawRawPoints(
        ui.PointMode.lines,
        Float32List.sublistView(bb, 0, bi),
        _blue,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SplashPainter old) =>
      old.image != image || old.particles != particles;
}
