import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:biyahe_meter/features/onboarding/agreements_screen.dart';

/// Screen 1: Splash Screen (`SplashScreen`)
///
/// A short, clean logo reveal (Maya-style), about 1.3 s:
/// - 0.00–0.45s  Pop: the logo scales up into place with a soft overshoot.
/// - 0.35–0.65s  The tagline fades in.
/// - 0.45–0.85s  Sheen: one band of light sweeps the letters.
/// - 0.95s       Hand-off: the app starts fading in underneath.
/// - 0.95–1.30s  Exit: the logo grows slightly and fades out.
/// Tap anywhere to skip.
///
/// PERFORMANCE: one [CustomPainter] repainted by the controller; per frame it
/// draws one image (two during the sheen) and one short text. No particles,
/// no layers, no image sampling, nothing to prepare before the clock starts.
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

  late final AnimationController _anim;

  ImageStream? _stream;
  ImageStreamListener? _listener;
  ImageInfo? _logoInfo;
  bool _resolved = false;
  bool _started = false;
  bool _done = false;

  Timer? _startFallback;
  Timer? _safetyTimer;
  Timer? _haptic;

  double get _speed => widget.quick ? 0.65 : 1.0;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (_SplashPainter.totalMs * _speed).round(),
      ),
    );
    _anim.addStatusListener((status) {
      if (status == AnimationStatus.completed) _proceed();
    });
    // Hand off early in the exit so the app fades in behind the logo.
    _anim.addListener(() {
      if (_anim.value >= _SplashPainter.handoffFrame) _proceed();
    });
    // The logo is a 42 KB asset; if decoding is ever slow, don't wait on it.
    _startFallback = Timer(const Duration(milliseconds: 400), _begin);
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
    _listener = ImageStreamListener((info, _) {
      _logoInfo?.dispose();
      _logoInfo = info.clone();
      if (mounted) setState(() {});
      _begin();
    }, onError: (_, _) => _begin());
    stream.addListener(_listener!);
  }

  void _begin() {
    if (_started || !mounted) return;
    _started = true;
    _startFallback?.cancel();

    // Reduced motion: the logo, still, then on to the app.
    if (MediaQuery.disableAnimationsOf(context)) {
      _anim.value = _SplashPainter.restFrame;
      _safetyTimer = Timer(const Duration(milliseconds: 700), _proceed);
      return;
    }

    _anim.forward();
    if (!kIsWeb) {
      // A light tap as the logo lands.
      _haptic = Timer(Duration(milliseconds: (380 * _speed).round()), () {
        if (mounted) HapticFeedback.lightImpact().catchError((_) {});
      });
    }
    _safetyTimer = Timer(
      _anim.duration! + const Duration(milliseconds: 300),
      _proceed,
    );
  }

  void _proceed() {
    _safetyTimer?.cancel();
    if (!mounted || _done) return;
    _done = true;

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
    _haptic?.cancel();
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
        systemNavigationBarColor: _SplashPainter.navy,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        // Same flat navy as the native launch screen, so there's no blink.
        backgroundColor: _SplashPainter.navy,
        body: Semantics(
          container: true,
          label: 'Biyahe Meter',
          onTapHint: 'Skip',
          onTap: _proceed,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _proceed,
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _SplashPainter(anim: _anim, image: _logoInfo?.image),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

double _seg(double ms, double aMs, double bMs, [Curve curve = Curves.linear]) =>
    curve.transform(((ms - aMs) / (bMs - aMs)).clamp(0.0, 1.0));

class _SplashPainter extends CustomPainter {
  final Animation<double> anim;
  final ui.Image? image;

  _SplashPainter({required this.anim, required this.image})
    : super(repaint: anim);

  static const double totalMs = 1300;

  /// Logo fully in and still (used for reduced motion).
  static const double restFrame = 900 / totalMs;

  /// Where [SplashScreen.onFinish] fires, early in the exit.
  static const double handoffFrame = 950 / totalMs;

  static const navy = Color(0xFF060D20);
  static const _tagline = 'Sakay na.';

  /// Visible logo inside logo_dark_hd.png (1308 × 452), scaled to [imgW].
  static Rect cropOf(int imgW) {
    final s = imgW / 1308;
    return Rect.fromLTRB(18 * s, 18 * s, 1248 * s, 432 * s);
  }

  // Soft overshoot: lands a touch past full size, then settles.
  static const _pop = Cubic(0.34, 1.36, 0.64, 1);

  final Paint _imagePaint = Paint()
    ..filterQuality = FilterQuality.medium
    ..isAntiAlias = true;
  final Paint _sheenPaint = Paint()
    ..filterQuality = FilterQuality.medium
    ..colorFilter = const ColorFilter.mode(
      Color(0x8CFFFFFF),
      BlendMode.srcATop,
    );

  @override
  void paint(Canvas canvas, Size size) {
    final ms = anim.value * totalMs;
    final w = size.width, h = size.height;
    final logoW = (w * (w >= 600 ? 0.42 : 0.70)).clamp(220.0, 400.0);
    final logoH = logoW * 414 / 1230;
    final center = Offset(w / 2, h / 2 - h * 0.03);

    final exit = _seg(ms, 950, totalMs, Curves.easeInCubic);
    final scale = (0.82 + 0.18 * _seg(ms, 0, 450, _pop)) * (1 + 0.12 * exit);
    final alpha = _seg(ms, 0, 280, Curves.easeOut) * (1 - exit);
    if (alpha <= 0.01) return;

    final logo = Rect.fromCenter(
      center: center,
      width: logoW * scale,
      height: logoH * scale,
    );

    final tagAlpha = _seg(ms, 350, 650, Curves.easeOut) * (1 - exit);
    if (tagAlpha > 0.01) {
      final fontSize = (logoW * 0.062).clamp(14.0, 22.0);
      final tp = TextPainter(
        text: TextSpan(
          text: _tagline,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72 * tagAlpha),
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            letterSpacing: fontSize * 0.18,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final y = center.dy + logoH / 2 + logoH * 0.22 + (1 - tagAlpha) * 6;
      tp.paint(canvas, Offset(center.dx - tp.width / 2, y));
      tp.dispose();
    }

    final img = image;
    if (img == null) return;
    final src = cropOf(img.width);
    _imagePaint.color = Colors.white.withValues(alpha: alpha);
    canvas.drawImageRect(img, src, logo, _imagePaint);

    // Sheen: a slanted band of light, clipped, re-drawing only logo pixels.
    final s = _seg(ms, 450, 850, Curves.easeInOutSine);
    if (s > 0 && s < 1) {
      final cx = logo.left - logo.width * 0.25 + logo.width * 1.5 * s;
      final band = logo.width * 0.08;
      final slant = logo.height * 0.6;
      canvas.save();
      canvas.clipPath(
        Path()
          ..moveTo(cx - band + slant, logo.top)
          ..lineTo(cx + band + slant, logo.top)
          ..lineTo(cx + band - slant, logo.bottom)
          ..lineTo(cx - band - slant, logo.bottom)
          ..close(),
      );
      _sheenPaint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawImageRect(img, src, logo, _sheenPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SplashPainter old) => old.image != image;
}
