import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:biyahe_meter/core/theme/app_theme.dart';
import 'package:biyahe_meter/core/theme/theme_provider.dart';
import 'package:biyahe_meter/features/meter/meter_provider.dart';
import 'package:biyahe_meter/features/onboarding/agreements_provider.dart';
import 'package:biyahe_meter/features/onboarding/agreements_screen.dart';

void main() {
  // Preserve the splash screen until the first frame is rendered.
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const BiyaheMeterApp());
}

class BiyaheMeterApp extends StatelessWidget {
  const BiyaheMeterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AgreementsProvider()),
        ChangeNotifierProvider(create: (_) => MeterProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'BiyaheMeter PH',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const _SplashGate(child: AgreementsScreen()),
        ),
      ),
    );
  }
}

/// Removes the native splash screen after the first frame is drawn,
/// ensuring the [AgreementsScreen] is fully laid out before the
/// splash disappears — no white flash.
class _SplashGate extends StatefulWidget {
  final Widget child;
  const _SplashGate({required this.child});

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  @override
  void initState() {
    super.initState();
    // Run while the native splash is still pinned — driver sees the GPS
    // permission dialog before the app UI appears (clean, professional UX).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Hold splash visible for at least 1.5 s — avoids an instant flash on
      // fast devices and covers Flutter engine JS load time on web.
      final minDelay = Future.delayed(const Duration(milliseconds: 1500));
      // permission_handler is not supported on web — skip it to prevent
      // an UnimplementedError that would keep the splash pinned forever.
      if (!kIsWeb) {
        try {
          await Permission.locationWhenInUse.request();
        } catch (_) {}
      }
      await minDelay;
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
