import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:biyahe_meter/core/utils/reduced_motion.dart';
import 'package:biyahe_meter/features/meter/meter_provider.dart';
import 'package:biyahe_meter/features/onboarding/agreements_provider.dart';
import 'package:biyahe_meter/features/onboarding/agreements_screen.dart';
import 'package:biyahe_meter/features/onboarding/brand_mark.dart';
import 'package:biyahe_meter/features/onboarding/premium_splash_view.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('BrandLogo splash geometry', () {
    for (final size in const [
      Size(320, 568),
      Size(375, 812),
      Size(812, 375),
      Size(1024, 1366),
    ]) {
      test('wordmark stays on screen at $size', () {
        final r = BrandLogo.splashContentRect(size);
        expect(r.left, greaterThan(0));
        expect(r.right, lessThan(size.width));
        expect(r.top, greaterThan(0));
        expect(r.bottom, lessThan(size.height));
        // Matches web/index.html: clamp(260px, 72vmin, 400px).
        expect(
          BrandLogo.splashCanvasWidth(size),
          (size.shortestSide * 0.72).clamp(260.0, 400.0),
        );
      });
    }
  });

  testWidgets('Continue stays disabled until all three are acknowledged', (
    tester,
  ) async {
    final ag = AgreementsProvider();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: ag),
          ChangeNotifierProvider(create: (_) => MeterProvider()),
        ],
        child: const MaterialApp(home: AgreementsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final handle = tester.ensureSemantics();

    Finder tile(String title) => find.text(title);
    Future<void> toggle(String title) async {
      await tester.ensureVisible(tile(title));
      await tester.pumpAndSettle();
      await tester.tap(tile(title));
      await tester.pumpAndSettle();
    }

    expect(
      tester.getSemantics(tile('Fare Estimates & Terms')),
      matchesSemantics(
        hasCheckedState: true,
        isChecked: false,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
        label:
            'Fare Estimates & Terms\nUnderstand that fares shown are estimates and may vary based on actual traffic conditions.',
      ),
    );

    await toggle('Fare Estimates & Terms');
    await toggle('Route & Data Privacy');
    expect(ag.allAccepted, isFalse);
    expect(find.text('1 item left to acknowledge'), findsOneWidget);

    await toggle('Responsible Gas & Rate Use');
    expect(ag.allAccepted, isTrue);
    expect(find.text('All 3 acknowledged'), findsOneWidget);
    expect(find.text('Accept all'), findsNothing);

    // Unchecking one re-locks Continue.
    await toggle('Route & Data Privacy');
    expect(ag.allAccepted, isFalse);
    handle.dispose();
  });

  testWidgets('reduced motion shows onboarding content with no entrance', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AgreementsProvider()),
          ChangeNotifierProvider(create: (_) => MeterProvider()),
        ],
        child: const MaterialApp(
          builder: applyReducedMotion,
          home: AgreementsScreen(),
        ),
      ),
    );
    await tester.pump();
    final fades = tester.widgetList<FadeTransition>(
      find.ancestor(
        of: find.text('Welcome to Byahe Meter'),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(fades, isNotEmpty);
    expect(fades.every((f) => f.opacity.value == 1), isTrue);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  for (final width in const [150.0, 151.5, 360.0]) {
    testWidgets('splash paints its final frame at width $width', (
      tester,
    ) async {
      final controller = AnimationController(vsync: tester, value: 1);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: width,
              height: 640,
              child: PremiumSplashView(controller: controller),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text(PremiumSplashView.tagline), findsOneWidget);
    });
  }
}
