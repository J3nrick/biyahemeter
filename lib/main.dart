import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:biyahe_meter/core/theme/app_theme.dart';
import 'package:biyahe_meter/features/meter/meter_provider.dart';
import 'package:biyahe_meter/features/onboarding/agreements_provider.dart';
import 'package:biyahe_meter/features/onboarding/agreements_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        ChangeNotifierProvider(create: (_) => AgreementsProvider()),
        ChangeNotifierProvider(create: (_) => MeterProvider()),
      ],
      child: MaterialApp(
        title: 'BiyaheMeter PH',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AgreementsScreen(),
      ),
    );
  }
}
