import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:latlong2/latlong.dart';
import 'package:biyahe_meter/core/utils/trip_calculator.dart';

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

  // User-configurable values
  double _kmPerLiter = 12.0;
  double _gasPricePerLiter = 62.50;
  double _baseFare = TripCalculator.baseFare;

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
  bool get canResumeTrip =>
      !_isRunning && (_distanceKm > 0 || _waitingMinutes > 0 || _routePoints.isNotEmpty);

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
    WakelockPlus.enable();
    notifyListeners();

    await _beginTracking();
  }

  Future<void> resumeTrip() async {
    if (_isRunning) return;

    final hasPermission = await _ensurePermissions();
    if (!hasPermission) return;

    _isRunning = true;
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

    // Start GPS tracking
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((position) {
      if (!_isRunning) return;
      _onPositionUpdate(position);
    });

    // Waiting timer — checks every 15 seconds if speed is below threshold
    _waitingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_currentSpeed < TripCalculator.waitingSpeedThreshold && _isRunning) {
        _waitingMinutes += 0.25;
        _recalculateFare();
        notifyListeners();
      }
    });
  }

  void _onPositionUpdate(Position position) {
    // Keep UI location live even when accuracy is temporarily poor.
    // Distance accumulation remains guarded below.
    final isReliableFix = position.accuracy <= 35.0;

    _currentPosition = LatLng(position.latitude, position.longitude);
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
    notifyListeners();
  }

  void _recalculateFare() {
    _totalFare = TripCalculator.calculateTotalFare(
      distanceKm: _distanceKm,
      kmPerLiter: _kmPerLiter,
      gasPricePerLiter: _gasPricePerLiter,
      waitingMinutes: _waitingMinutes,
      baseFare: _baseFare,
    );
  }

  void stopTrip() {
    _isRunning = false;
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
    _totalFare = TripCalculator.baseFare;
    _routePoints.clear();
    _currentPosition = null;
    _lastPosition = null;
    _lastUpdateTime = null;
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
