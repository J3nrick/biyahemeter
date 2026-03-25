import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:biyahe_meter/core/theme/theme_provider.dart';
import 'package:biyahe_meter/features/meter/meter_provider.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget>
  with TickerProviderStateMixin {
  // Default center: Manila, Philippines
  static const LatLng _defaultCenter = LatLng(14.5995, 120.9842);

  final MapController _mapController = MapController();
  MeterProvider? _meterProvider;

  /// Whether the map should automatically pan to follow the user.
  bool _isFollowing = true;

  AnimationController? _recenterController;

  /// Location fetched once on startup (before a trip begins).
  LatLng? _initialPosition;

  @override
  void initState() {
    super.initState();
    _fetchInitialPosition();
    // Attach provider listener after the first frame so context is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _meterProvider = context.read<MeterProvider>();
      _meterProvider!.addListener(_onPositionUpdate);
    });
  }

  @override
  void dispose() {
    _meterProvider?.removeListener(_onPositionUpdate);
    _recenterController?.dispose();
    super.dispose();
  }

  /// Silently get the device location so the map starts centered on the user
  /// even before any trip is started.
  Future<void> _fetchInitialPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (!mounted) return;
      final latlng = LatLng(pos.latitude, pos.longitude);
      setState(() => _initialPosition = latlng);
      _mapController.move(
        LatLng(latlng.latitude - _latOffsetForPanel(15.0), latlng.longitude),
        15.0,
      );
    } catch (_) {
      // Location unavailable — map stays at default center.
    }
  }

  /// Returns a latitude delta (degrees) to shift the camera centre south so
  /// the yellow GPS dot appears in the visible map area above the bottom panel.
  double _latOffsetForPanel(double zoom) {
    const pixelShift = 140.0;
    final metersPerPixel =
        40075016.686 / (256.0 * (1 << zoom.round().clamp(1, 22)));
    return (pixelShift * metersPerPixel) / 111111.0;
  }

  /// Called whenever MeterProvider notifies — pans the map if following.
  void _onPositionUpdate() {
    if (!mounted) return;
    final pos = context.read<MeterProvider>().currentPosition;
    if (pos != null && _isFollowing) {
      final zoom = _mapController.camera.zoom;
      _mapController.move(
        LatLng(pos.latitude - _latOffsetForPanel(zoom), pos.longitude),
        zoom,
      );
    }
  }

  void _animateMapMove(LatLng target, double targetZoom) {
    _recenterController?.dispose();
    final startCenter = _mapController.camera.center;
    final startZoom = _mapController.camera.zoom;

    final latTween =
        Tween<double>(begin: startCenter.latitude, end: target.latitude);
    final lngTween =
        Tween<double>(begin: startCenter.longitude, end: target.longitude);
    final zoomTween = Tween<double>(begin: startZoom, end: targetZoom);

    _recenterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    final animation = CurvedAnimation(
      parent: _recenterController!,
      curve: Curves.easeOutCubic,
    );

    _recenterController!.addListener(() {
      if (!mounted) return;
      _mapController.move(
        LatLng(
          latTween.evaluate(animation),
          lngTween.evaluate(animation),
        ),
        zoomTween.evaluate(animation),
      );
    });

    _recenterController!.forward();
  }

  /// Re-enable auto-follow and snap back to the current position.
  void _recenter() {
    final pos = context.read<MeterProvider>().currentPosition ??
        _initialPosition ??
        _defaultCenter;
    setState(() => _isFollowing = true);
    const zoom = 15.0;
    final target = LatLng(pos.latitude - _latOffsetForPanel(zoom), pos.longitude);
    _animateMapMove(target, zoom);
  }

  @override
  Widget build(BuildContext context) {
    final meter = context.watch<MeterProvider>();
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final markerPosition = meter.currentPosition ?? _initialPosition;
    final initialCenter =
        _initialPosition ?? meter.currentPosition ?? _defaultCenter;
    final topInset = MediaQuery.of(context).padding.top;

    return Stack(
      fit: StackFit.expand, // ← fills every pixel of the parent SizedBox
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 15.0,
            onPositionChanged: (camera, hasGesture) {
              if (hasGesture && _isFollowing) {
                setState(() => _isFollowing = false);
              }
            },
          ),
          children: [
            // CartoDB dark tiles — CORS-safe on all platforms including web
            TileLayer(
              urlTemplate: isDarkMode
                  ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: isDarkMode ? const ['a', 'b', 'c', 'd'] : const [],
              userAgentPackageName: 'com.biyahemeter.app',
              maxZoom: 19,
            ),

            // Attribution
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  '© OpenStreetMap contributors',
                  onTap: null,
                ),
                if (isDarkMode)
                  TextSourceAttribution(
                    '© CARTO',
                    onTap: null,
                  ),
              ],
            ),

            // Driven route polyline
            if (meter.routePoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: meter.routePoints,
                    strokeWidth: 4.0,
                    color: const Color(0xFF1A237E),
                  ),
                ],
              ),

            // Live position marker (falls back to initial device location).
            if (markerPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: markerPosition,
                    width: 28,
                    height: 28,
                    alignment: Alignment.center, // anchor dot at its center
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 0, 85, 255),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x55FFB800),
                            blurRadius: 12,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),

        // ── Right-side map controls: zoom + re-center ──
        Positioned(
          right: 12,
          top: topInset + 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _mapBtn(
                icon: Icons.add_rounded,
                onTap: () => _mapController.move(
                  _mapController.camera.center,
                  (_mapController.camera.zoom + 1).clamp(1.0, 19.0),
                ),
              ),
              const SizedBox(height: 4),
              _mapBtn(
                icon: Icons.remove_rounded,
                onTap: () => _mapController.move(
                  _mapController.camera.center,
                  (_mapController.camera.zoom - 1).clamp(1.0, 19.0),
                ),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'recenterFab',
                mini: true,
                elevation: 2,
                backgroundColor: Colors.white,
                onPressed: _recenter,
                child: Icon(
                  _isFollowing
                      ? Icons.my_location_rounded
                      : Icons.location_searching_rounded,
                  color: _isFollowing ? const Color(0xFF1A237E) : Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              _mapBtn(
                icon: Icons.refresh_rounded,
                onTap: () => context.read<MeterProvider>().resetTrip(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mapBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x25000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon,
            size: 18, color: iconColor ?? const Color(0xFF1C1C1E)),
      ),
    );
  }
}
