import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:biyahe_meter/core/theme/app_theme.dart';
import 'package:biyahe_meter/core/theme/theme_provider.dart';
import 'package:biyahe_meter/features/fare/fare_matrix_provider.dart';
import 'package:biyahe_meter/features/history/history_provider.dart';
import 'package:biyahe_meter/features/meter/meter_provider.dart';
import 'package:biyahe_meter/features/onboarding/agreements_provider.dart';
import 'package:biyahe_meter/features/onboarding/agreements_screen.dart';
import 'package:biyahe_meter/features/onboarding/premium_splash_view.dart';
import 'package:biyahe_meter/services/analytics_service.dart';
import 'package:biyahe_meter/services/history_service.dart';
import 'package:biyahe_meter/services/map_cache_service.dart';
import 'package:biyahe_meter/services/receipt_service.dart';
import 'package:biyahe_meter/services/sos_service.dart';

Future<void> main() async {
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Hive.initFlutter();

  final historyService = HistoryService();
  final mapCache = MapCacheService();
  final fareMatrix = FareMatrixProvider();
  final meter = MeterProvider()..applyFareMatrix(fareMatrix);
  final historyProvider = HistoryProvider(historyService, AnalyticsService());

  // Kick off non-blocking init — do not delay first frame / splash handoff.
  Future<void> warmUp() async {
    try {
      await historyService.init();
      await historyProvider.load();
    } catch (_) {}
    try {
      await mapCache.init();
    } catch (_) {}
  }

  warmUp();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    BiyaheMeterApp(
      fareMatrix: fareMatrix,
      meter: meter,
      history: historyProvider,
      mapCache: mapCache,
    ),
  );
}

class BiyaheMeterApp extends StatelessWidget {
  final FareMatrixProvider fareMatrix;
  final MeterProvider meter;
  final HistoryProvider history;
  final MapCacheService mapCache;

  const BiyaheMeterApp({
    super.key,
    required this.fareMatrix,
    required this.meter,
    required this.history,
    required this.mapCache,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AgreementsProvider()),
        ChangeNotifierProvider.value(value: fareMatrix),
        ChangeNotifierProvider.value(value: meter),
        ChangeNotifierProvider.value(value: history),
        ChangeNotifierProvider.value(value: mapCache),
        Provider(create: (_) => ReceiptService()),
        Provider(create: (_) => SosService()),
        Provider(create: (_) => AnalyticsService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final isDark = themeProvider.isDarkMode;
          final overlay = SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor:
                isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          );

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: overlay,
            child: MaterialApp(
              title: 'BiyaheMeter PH',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              home: const _SplashGate(),
            ),
          );
        },
      ),
    );
  }
}

/// Native/HTML splash → premium animated intro → agreements.
class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;
  bool _showAgreements = false;
  bool _nativeSplashRemoved = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _removeNativeSplash();

      final minDelay = Future.delayed(const Duration(milliseconds: 2000));
      try {
        if (!kIsWeb) {
          try {
            await Permission.locationWhenInUse.request();
          } catch (_) {}
        }
        await minDelay;
      } catch (_) {
        // Keep splash→agreements handoff even if permission/delay fails.
      }

      _removeNativeSplash();
      if (!mounted) return;
      setState(() => _showAgreements = true);
    });
  }

  void _removeNativeSplash() {
    if (_nativeSplashRemoved) return;
    _nativeSplashRemoved = true;
    try {
      FlutterNativeSplash.remove();
    } catch (_) {}
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _showAgreements
          ? const AgreementsScreen(key: ValueKey('agreements'))
          : PremiumSplashView(
              key: const ValueKey('splash'),
              controller: _intro,
            ),
    );
  }
}
