import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:latlong2/latlong.dart';
import 'package:biyahe_meter/core/models/fare_preset.dart';
import 'package:biyahe_meter/core/utils/trip_calculator.dart';
import 'package:biyahe_meter/features/fare/fare_matrix_provider.dart';

class MeterProvider extends ChangeNotifier {
  // Trip state
  bool _isRunning = false;
  double _distanceKm = 0.0;
  double _waitingMinutes = 0.0;
  double _currentSpeed = 0.0;
  double _totalFare = TripCalculator.baseFare;
  LatLng? _currentPosition;
  LatLng? _lastPosition;
  final List<LatLng> _routePoints = [];
  DateTime? _lastUpdateTime;
  DateTime? _tripStartedAt;
  DateTime? _tripEndedAt;
  LatLng? _tripStartPosition;
  FareBreakdown? _lastBreakdown;

  // User-configurable values
  double _kmPerLiter = 12.0;
  double _gasPricePerLiter = 62.50;
  double _baseFare = TripCalculator.baseFare;

  // Fare matrix coupling (set from UI / main)
  FarePreset _activePreset = FarePreset.byId(FarePresetId.regularTaxi);
  bool _discountEnabled = false;

  // Battery optimization — adaptive GPS distance filter
  bool _batterySaver = true;
  int _distanceFilterMeters = 0;

  StreamSubscription<Position>? _positionStream;
  Timer? _waitingTimer;
  Timer? _snapshotTimer;

  // Survives app restarts; null until [restoreFrom] (e.g. in tests).
  Box<dynamic>? _store;
  static const _settingsKey = 'meter_settings';
  static const _tripKey = 'meter_trip';
  @visibleForTesting
  static Duration snapshotInterval = const Duration(seconds: 5);

  // Getters
  bool get isRunning => _isRunning;
  double get distanceKm => _distanceKm;
  double get waitingMinutes => _waitingMinutes;
  double get currentSpeed => _currentSpeed;
  double get totalFare => _totalFare;
  double get kmPerLiter => _kmPerLiter;
  double get gasPricePerLiter => _gasPricePerLiter;
  double get baseFare => _baseFare;
  LatLng? get currentPosition => _currentPosition;
  List<LatLng> get routePoints => List.unmodifiable(_routePoints);
  DateTime? get lastUpdateTime => _lastUpdateTime;
  DateTime? get tripStartedAt => _tripStartedAt;
  DateTime? get tripEndedAt => _tripEndedAt;
  LatLng? get tripStartPosition => _tripStartPosition;
  FareBreakdown? get lastBreakdown => _lastBreakdown;
  FarePreset get activePreset => _activePreset;
  bool get discountEnabled => _discountEnabled;
  bool get batterySaver => _batterySaver;
  bool get canResumeTrip =>
      !_isRunning && (_distanceKm > 0 || _waitingMinutes > 0 || _routePoints.isNotEmpty);

  Duration? get tripDuration {
    if (_tripStartedAt == null) return null;
    final end = _isRunning
        ? DateTime.now()
        : (_tripEndedAt ?? DateTime.now());
    return end.difference(_tripStartedAt!);
  }

  double get averageSpeedKmh {
    final d = tripDuration;
    if (d == null || d.inSeconds <= 0) return 0;
    return _distanceKm / (d.inSeconds / 3600.0);
  }

  set kmPerLiter(double value) {
    if (value > 0) {
      _kmPerLiter = value;
      _recalculateFare();
      _saveSettings();
      notifyListeners();
    }
  }

  set gasPricePerLiter(double value) {
    if (value > 0) {
      _gasPricePerLiter = value;
      _recalculateFare();
      _saveSettings();
      notifyListeners();
    }
  }

  set baseFare(double value) {
    if (value >= 0) {
      _baseFare = value;
      _recalculateFare();
      _saveSettings();
      notifyListeners();
    }
  }

  void setBatterySaver(bool value) {
    if (_batterySaver == value) return;
    _batterySaver = value;
    if (_isRunning) {
      unawaited(_restartTrackingStream());
    }
    _saveSettings();
    notifyListeners();
  }

  /// Sync fare matrix settings from [FareMatrixProvider] without owning it.
  void applyFareMatrix(FareMatrixProvider matrix) {
    _activePreset = matrix.activePreset;
    _discountEnabled = matrix.discountEnabled;
    if (!_activePreset.isFuelBased) {
      _baseFare = _activePreset.flagdown;
    }
    _recalculateFare();
    _saveSettings();
    notifyListeners();
  }

  /// Loads saved settings and any trip that was running when the app died,
  /// then keeps [store] up to date. A restored trip comes back paused
  /// ([canResumeTrip]) so the user resumes it explicitly.
  void restoreFrom(Box<dynamic> store) {
    _store = store;
    final settings = store.get(_settingsKey);
    if (settings is Map) {
      double? num_(String k) => (settings[k] as num?)?.toDouble();
      _kmPerLiter = num_('kmPerLiter') ?? _kmPerLiter;
      _gasPricePerLiter = num_('gasPricePerLiter') ?? _gasPricePerLiter;
      _baseFare = num_('baseFare') ?? _baseFare;
      final presetId =
          FarePresetId.values.asNameMap()[settings['presetId'] as String?];
      if (presetId != null) _activePreset = FarePreset.byId(presetId);
      _discountEnabled = settings['discountEnabled'] as bool? ?? false;
      _batterySaver = settings['batterySaver'] as bool? ?? true;
    }

    final trip = store.get(_tripKey);
    if (trip is Map && trip['isRunning'] == true) {
      LatLng? point(String lat, String lng) => trip[lat] is num
          ? LatLng((trip[lat] as num).toDouble(), (trip[lng] as num).toDouble())
          : null;
      _distanceKm = (trip['distanceKm'] as num?)?.toDouble() ?? 0;
      _waitingMinutes = (trip['waitingMinutes'] as num?)?.toDouble() ?? 0;
      final startedMs = trip['tripStartedAt'] as int?;
      _tripStartedAt = startedMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(startedMs);
      final route = (trip['route'] as List?)?.cast<num>() ?? const <num>[];
      _routePoints
        ..clear()
        ..addAll([
          for (var i = 0; i + 1 < route.length; i += 2)
            LatLng(route[i].toDouble(), route[i + 1].toDouble()),
        ]);
      _lastPosition = point('lastLat', 'lastLng');
      _currentPosition = _lastPosition;
      _tripStartPosition = point('startLat', 'startLng');
    }
    _recalculateFare();
    notifyListeners();
  }

  void _saveSettings() {
    _store?.put(_settingsKey, {
      'kmPerLiter': _kmPerLiter,
      'gasPricePerLiter': _gasPricePerLiter,
      'baseFare': _baseFare,
      'presetId': _activePreset.id.name,
      'discountEnabled': _discountEnabled,
      'batterySaver': _batterySaver,
    });
  }

  void _saveTrip() {
    _store?.put(_tripKey, {
      'isRunning': _isRunning,
      'distanceKm': _distanceKm,
      'waitingMinutes': _waitingMinutes,
      'tripStartedAt': _tripStartedAt?.millisecondsSinceEpoch,
      // Flat [lat, lng, ...] keeps the snapshot small for long trips.
      'route': [for (final p in _routePoints) ...[p.latitude, p.longitude]],
      'lastLat': _lastPosition?.latitude,
      'lastLng': _lastPosition?.longitude,
      'startLat': _tripStartPosition?.latitude,
      'startLng': _tripStartPosition?.longitude,
    });
  }

  Future<bool> _ensurePermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  Future<void> startTrip() async {
    if (_isRunning) return;

    final hasPermission = await _ensurePermissions();
    if (!hasPermission) return;

    _isRunning = true;
    _distanceKm = 0.0;
    _waitingMinutes = 0.0;
    _currentSpeed = 0.0;
    _totalFare = _baseFare;
    _routePoints.clear();
    _lastPosition = null;
    _tripStartedAt = DateTime.now();
    _tripEndedAt = null;
    _tripStartPosition = null;
    _distanceFilterMeters = 0;
    WakelockPlus.enable();
    notifyListeners();

    await _beginTracking();
  }

  Future<void> resumeTrip() async {
    if (_isRunning) return;

    final hasPermission = await _ensurePermissions();
    if (!hasPermission) return;

    _isRunning = true;
    _tripEndedAt = null;
    WakelockPlus.enable();
    notifyListeners();

    await _beginTracking();
  }

  Future<void> _beginTracking() async {
    _positionStream?.cancel();
    _waitingTimer?.cancel();

    // Prime the tracker immediately so the map marker/fare card updates
    // before the stream's first periodic event arrives.
    try {
      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _onPositionUpdate(initialPosition);
    } catch (_) {}

    await _restartTrackingStream();

    // Waiting timer — checks every 15 seconds if speed is below threshold
    _waitingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_currentSpeed < TripCalculator.waitingSpeedThreshold && _isRunning) {
        _waitingMinutes += 0.25;
        _recalculateFare();
        notifyListeners();
      }
    });

    _snapshotTimer?.cancel();
    _snapshotTimer = Timer.periodic(snapshotInterval, (_) => _saveTrip());
  }

  Future<void> _restartTrackingStream() async {
    await _positionStream?.cancel();
    final filter = _batterySaver ? _distanceFilterMeters : 0;
    final locationSettings = _trackingSettings(filter);

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((position) {
      if (!_isRunning) return;
      _onPositionUpdate(position);
    });
  }

  /// Keeps the stream alive with the screen off: an Android location
  /// foreground service, iOS background updates (blue status-bar pill).
  static LocationSettings _trackingSettings(int distanceFilter) {
    if (kIsWeb) {
      return LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter,
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'Trip in progress',
            notificationText: 'Byahe Meter is measuring your trip.',
            notificationChannelName: 'Trip in progress',
            // Partial CPU wake lock so the waiting-time timer keeps ticking.
            enableWakeLock: true,
            setOngoing: true,
          ),
        );
      case TargetPlatform.iOS:
        return AppleSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter,
          activityType: ActivityType.automotiveNavigation,
          pauseLocationUpdatesAutomatically: false,
          allowBackgroundLocationUpdates: true,
          showBackgroundLocationIndicator: true,
        );
      default:
        return LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter,
        );
    }
  }

  void _maybeAdaptGpsThrottle() {
    if (!_batterySaver || !_isRunning) return;
    final target = _currentSpeed < TripCalculator.waitingSpeedThreshold ? 5 : 0;
    if (target != _distanceFilterMeters) {
      _distanceFilterMeters = target;
      unawaited(_restartTrackingStream());
    }
  }

  void _onPositionUpdate(Position position) {
    // Keep UI location live even when accuracy is temporarily poor.
    // Distance accumulation remains guarded below.
    final isReliableFix = position.accuracy <= 35.0;

    _currentPosition = LatLng(position.latitude, position.longitude);
    _tripStartPosition ??= _currentPosition;
    // Negative speed means the device couldn't measure it — treat as 0.
    _currentSpeed = position.speed < 0
        ? 0.0
        : (position.speed * 3.6).clamp(0.0, 300.0); // m/s → km/h
    _lastUpdateTime = DateTime.now();
    if (isReliableFix) {
      _routePoints.add(_currentPosition!);
    }

    if (isReliableFix && _lastPosition != null) {
      final meters = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      // Ignore GPS teleportation glitches from invalid samples.
      if (meters.isFinite && meters > 0 && meters < 500) {
        _distanceKm += meters / 1000.0;
      }
    }
    if (isReliableFix) {
      _lastPosition = _currentPosition;
    }

    _recalculateFare();
    _maybeAdaptGpsThrottle();
    notifyListeners();
  }

  void _recalculateFare() {
    final breakdown = TripCalculator.calculateBreakdown(
      preset: _activePreset,
      distanceKm: _distanceKm,
      waitingMinutes: _waitingMinutes,
      kmPerLiter: _kmPerLiter,
      gasPricePerLiter: _gasPricePerLiter,
      customFlagdown: _baseFare,
      applyDiscount: _discountEnabled,
      discountPercent: FareMatrixProvider.discountPercent,
    );
    _lastBreakdown = breakdown;
    _totalFare = breakdown.total;
  }

  void stopTrip() {
    _isRunning = false;
    _tripEndedAt = DateTime.now();
    _positionStream?.cancel();
    _positionStream = null;
    _waitingTimer?.cancel();
    _waitingTimer = null;
    _snapshotTimer?.cancel();
    _snapshotTimer = null;
    _saveTrip();
    WakelockPlus.disable();
    notifyListeners();
  }

  void resetTrip() {
    stopTrip();
    _distanceKm = 0.0;
    _waitingMinutes = 0.0;
    _currentSpeed = 0.0;
    _totalFare = _baseFare;
    _routePoints.clear();
    _currentPosition = null;
    _lastPosition = null;
    _lastUpdateTime = null;
    _tripStartedAt = null;
    _tripEndedAt = null;
    _tripStartPosition = null;
    _lastBreakdown = null;
    _distanceFilterMeters = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _waitingTimer?.cancel();
    _snapshotTimer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }
}
