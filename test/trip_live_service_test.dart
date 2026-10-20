import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biyahe_meter/features/meter/meter_provider.dart';
import 'package:biyahe_meter/services/trip_live_service.dart';

/// Drives the public getters TripLiveService reads, without GPS.
class _FakeMeter extends MeterProvider {
  bool running = false;
  double fare = 45;

  @override
  bool get isRunning => running;
  @override
  double get totalFare => fare;

  void emit() => notifyListeners();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    // Plugin platform classes aren't auto-registered in VM tests.
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'initialize' ||
                  call.method == 'requestNotificationsPermission'
              ? true
              : null;
        });
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  Future<void> settle() => Future<void>.delayed(Duration.zero);
  Iterable<MethodCall> named(String m) => calls.where((c) => c.method == m);

  test('mirrors a trip in the ongoing notification, throttled', () async {
    final meter = _FakeMeter();
    await TripLiveService().init(meter);

    meter.emit(); // idle: nothing shown
    await settle();
    expect(named('show'), isEmpty);

    meter
      ..running = true
      ..emit();
    await settle();
    expect(named('requestNotificationsPermission'), hasLength(1));
    expect(named('show'), hasLength(1));
    final args = named('show').first.arguments as Map;
    expect(args['id'], 75415); // geolocator's foreground-service notification
    expect(args['title'], '₱45.00 · Trip in progress');

    // A new fare within 3 s is coalesced, not posted on every GPS fix.
    meter
      ..fare = 58.5
      ..emit();
    await settle();
    expect(named('show'), hasLength(1));

    meter
      ..running = false
      ..emit();
    await settle();
    expect(named('cancel'), hasLength(1));
  });

  test('does nothing on web/desktop', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final meter = _FakeMeter();
    await TripLiveService().init(meter);
    meter
      ..running = true
      ..emit();
    await settle();
    expect(calls, isEmpty);
  });
}
