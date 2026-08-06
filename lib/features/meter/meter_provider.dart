import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
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
      notifyListeners();
    }
  }

  set gasPricePerLiter(double value) {
    if (value > 0) {
      _gasPricePerLiter = value;
      _recalculateFare();
      notifyListeners();
    }
  }

  set baseFare(double value) {
    if (value >= 0) {
      _baseFare = value;
      _recalculateFare();
      notifyListeners();
    }
  }

  void setBatterySaver(bool value) {
    if (_batterySaver == value) return;
    _batterySaver = value;
    if (_isRunning) {
      unawaited(_restartTrackingStream());
    }
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
    notifyListeners();
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
  }

  Future<void> _restartTrackingStream() async {
    await _positionStream?.cancel();
    final filter = _batterySaver ? _distanceFilterMeters : 0;
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: filter,
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((position) {
      if (!_isRunning) return;
      _onPositionUpdate(position);
    });
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
    WakelockPlus.disable();
    super.dispose();
  }
}
