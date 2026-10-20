import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:live_activities/live_activities.dart';
import 'package:uuid/uuid.dart';
import 'package:biyahe_meter/features/meter/meter_provider.dart';

/// Shows a running trip outside the app while the phone is locked:
/// Android's ongoing "trip in progress" notification and an iOS Live Activity
/// (Lock Screen + Dynamic Island). Read-only view of [MeterProvider].
class TripLiveService {
  /// Must match the App Group enabled for Runner and the BiyaheMeterWidget
  /// extension in Xcode (see ios/BiyaheMeterWidget/README.md).
  static const appGroupId = 'group.ph.biyahemeter.app';

  // shortcut: reuses geolocator_android's private foreground-service
  // notification id/channel (GeolocatorLocationService.java) so we update its
  // text instead of posting a second notification. Re-check on geolocator upgrades.
  static const _androidNotificationId = 75415;
  static const _androidChannelId = 'geolocator_channel_01';
  static const _androidChannelName = 'Trip in progress';

  static const _minInterval = Duration(seconds: 3);

  final _notifications = FlutterLocalNotificationsPlugin();
  final _liveActivities = LiveActivities();

  bool _ready = false;
  bool _wasRunning = false;
  String? _activityId;
  String? _lastShown;
  DateTime _lastPush = DateTime.fromMillisecondsSinceEpoch(0);

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> init(MeterProvider meter) async {
    if (!_isAndroid && !_isIOS) return;
    try {
      if (_isAndroid) {
        await _notifications.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          ),
        );
      } else {
        // Notification permission is asked when the first trip starts.
        await _liveActivities.init(
          appGroupId: appGroupId,
          requireNotificationPermission: false,
        );
        // A killed app can leave its Lock Screen card behind for hours.
        await _liveActivities.endAllActivities();
      }
      _ready = true;
      meter.addListener(() => _sync(meter));
    } catch (e) {
      // Metering works without it; only the lock-screen mirror is lost.
      debugPrint('TripLiveService unavailable: $e');
    }
  }

  Future<void> _sync(MeterProvider meter) async {
    if (!_ready) return;
    final running = meter.isRunning;
    try {
      if (running && !_wasRunning) {
        _wasRunning = true;
        await _onStart();
      } else if (!running && _wasRunning) {
        _wasRunning = false;
        await _onStop();
        return;
      }
      if (!running) return;

      final status = _status(meter);
      final now = DateTime.now();
      if (status.summary == _lastShown ||
          now.difference(_lastPush) < _minInterval) {
        return;
      }
      _lastShown = status.summary;
      _lastPush = now;
      await (_isAndroid ? _showAndroid(status) : _showIOS(status));
    } catch (e) {
      debugPrint('TripLiveService update failed: $e');
    }
  }

  Future<void> _onStart() async {
    _lastShown = null;
    if (_isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } else if (await _liveActivities.areActivitiesEnabled()) {
      _activityId ??= const Uuid().v4();
    }
  }

  Future<void> _onStop() async {
    if (_isAndroid) {
      // geolocator removes its notification when the stream stops; this also
      // clears an update that raced the stop.
      await _notifications.cancel(id: _androidNotificationId);
    } else if (_activityId != null) {
      await _liveActivities.endActivity(_activityId!);
      _activityId = null;
    }
  }

  Future<void> _showAndroid(_TripStatus s) {
    return _notifications.show(
      id: _androidNotificationId,
      title: '${s.fare} · Trip in progress',
      body: s.details,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          silent: true,
          showWhen: false,
          importance: Importance.low,
          priority: Priority.low,
          category: AndroidNotificationCategory.service,
        ),
      ),
    );
  }

  Future<void> _showIOS(_TripStatus s) async {
    final id = _activityId;
    if (id == null) return; // Live Activities disabled by the user.
    await _liveActivities.createOrUpdateActivity(id, s.toLiveActivityData());
  }

  static _TripStatus _status(MeterProvider meter) {
    final minutes = meter.tripDuration?.inMinutes ?? 0;
    return _TripStatus(
      fare: '₱${meter.totalFare.toStringAsFixed(2)}',
      distance: '${meter.distanceKm.toStringAsFixed(2)} km',
      elapsed: '$minutes min',
      waiting: meter.waitingMinutes > 0
          ? '${meter.waitingMinutes.toStringAsFixed(0)} min waiting'
          : null,
      preset: meter.activePreset.name,
    );
  }
}

class _TripStatus {
  final String fare;
  final String distance;
  final String elapsed;
  final String? waiting;
  final String preset;

  const _TripStatus({
    required this.fare,
    required this.distance,
    required this.elapsed,
    required this.waiting,
    required this.preset,
  });

  String get details => [distance, elapsed, ?waiting].join(' · ');

  String get summary => '$fare|$details';

  /// Keys read by ios/BiyaheMeterWidget/BiyaheMeterLiveActivity.swift.
  Map<String, dynamic> toLiveActivityData() => {
    'fare': fare,
    'distance': distance,
    'elapsed': elapsed,
    'waiting': waiting ?? '',
    'preset': preset,
  };
}
