import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:biyahe_meter/core/theme/theme_provider.dart';
import 'package:biyahe_meter/core/theme/app_theme.dart';
import 'package:biyahe_meter/features/meter/meter_provider.dart';
import 'package:biyahe_meter/services/map_cache_service.dart';
import 'package:biyahe_meter/features/meter/widgets/premium_buttons.dart';

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
    final mapCache = context.watch<MapCacheService>();
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
              tileProvider: mapCache.createTileProvider(),
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
                    strokeWidth: 4.5,
                    color: Theme.of(context).colorScheme.primary,
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
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.45),
                            blurRadius: 12,
                            spreadRadius: 3,
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
          child: SafeArea(
            left: false,
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      PremiumIconButton(
                        tooltip: 'Zoom in',
                        icon: Icons.add_rounded,
                        onPressed: () => _mapController.move(
                          _mapController.camera.center,
                          (_mapController.camera.zoom + 1).clamp(1.0, 19.0),
                        ),
                      ),
                      const SizedBox(height: 6),
                      PremiumIconButton(
                        tooltip: 'Zoom out',
                        icon: Icons.remove_rounded,
                        onPressed: () => _mapController.move(
                          _mapController.camera.center,
                          (_mapController.camera.zoom - 1).clamp(1.0, 19.0),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                PremiumIconButton(
                  tooltip: _isFollowing
                      ? 'Following your location'
                      : 'Recenter on my location',
                  icon: _isFollowing
                      ? Icons.my_location_rounded
                      : Icons.location_searching_rounded,
                  active: _isFollowing,
                  onPressed: _recenter,
                ),
                const SizedBox(height: 10),
                PremiumIconButton(
                  tooltip: 'Reset trip totals',
                  icon: Icons.refresh_rounded,
                  danger: true,
                  haptic: AppHaptic.medium,
                  onPressed: () => _confirmResetTrip(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmResetTrip(BuildContext context) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final muted = AppTheme.mutedOf(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.borderOf(sheetContext)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: muted.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Text(
                    'Reset trip?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'This clears fare, distance, waiting time, and the route path.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                  const SizedBox(height: 18),
                  Pressable(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    semanticLabel: 'Confirm reset trip',
                    haptic: AppHaptic.heavy,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.dangerOf(sheetContext),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Reset trip',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Pressable(
                    onPressed: () => Navigator.pop(sheetContext, false),
                    semanticLabel: 'Cancel reset',
                    haptic: AppHaptic.selection,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.borderOf(sheetContext),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmed == true && context.mounted) {
      context.read<MeterProvider>().resetTrip();
    }
  }
}