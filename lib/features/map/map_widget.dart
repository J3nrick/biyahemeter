import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:provider/provider.dart';

import 'package:biyahe_meter/core/theme/app_theme.dart';
import 'package:biyahe_meter/core/theme/theme_provider.dart';
import 'package:biyahe_meter/features/meter/meter_provider.dart';
import 'package:biyahe_meter/features/meter/widgets/premium_buttons.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> with TickerProviderStateMixin {
  // Default center: Manila, Philippines
  static const ml.LatLng _defaultCenter = ml.LatLng(14.5995, 120.9842);

  ml.MaplibreMapController? _mapController;
  MeterProvider? _meterProvider;

  /// Whether the map should automatically pan to follow the user.
  bool _isFollowing = true;

  /// Location fetched once on startup (before a trip begins).
  ml.LatLng? _initialPosition;

  ml.Line? _activeLine;
  ml.Circle? _locationMarker;

  @override
  void initState() {
    super.initState();
    _fetchInitialPosition();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _meterProvider = context.read<MeterProvider>();
      _meterProvider!.addListener(_onPositionUpdate);
    });
  }

  @override
  void dispose() {
    _meterProvider?.removeListener(_onPositionUpdate);
    super.dispose();
  }

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
      final latlng = ml.LatLng(pos.latitude, pos.longitude);
      setState(() => _initialPosition = latlng);

      if (_mapController != null && _isFollowing) {
        _mapController!.animateCamera(
          ml.CameraUpdate.newLatLngZoom(latlng, 15.0),
        );
      }
    } catch (_) {}
  }

  void _onPositionUpdate() {
    if (!mounted || _mapController == null) return;
    final pos = context.read<MeterProvider>().currentPosition;
    if (pos != null) {
      final target = ml.LatLng(pos.latitude, pos.longitude);
      _updateLocationMarker(target);
      if (_isFollowing) {
        _mapController!.animateCamera(
          ml.CameraUpdate.newLatLng(target),
        );
      }
    }
    _updateRouteLine();
  }

  void _onMapCreated(ml.MaplibreMapController controller) {
    _mapController = controller;
    final pos = _meterProvider?.currentPosition;
    if (pos != null) {
      final target = ml.LatLng(pos.latitude, pos.longitude);
      _updateLocationMarker(target);
    } else if (_initialPosition != null) {
      _updateLocationMarker(_initialPosition!);
    }
  }

  void _updateLocationMarker(ml.LatLng position) {
    if (_mapController == null) return;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final primaryHex = _colorToHex(primaryColor);

    if (_locationMarker == null) {
      _mapController!
          .addCircle(
        ml.CircleOptions(
          geometry: position,
          circleColor: primaryHex,
          circleRadius: 8.0,
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 3.0,
        ),
      )
          .then((circle) {
        _locationMarker = circle;
      }).catchError((_) {});
    } else {
      _mapController!.updateCircle(
        _locationMarker!,
        ml.CircleOptions(geometry: position),
      );
    }
  }

  void _updateRouteLine() {
    if (_mapController == null || _meterProvider == null) return;
    final points = _meterProvider!.routePoints;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final primaryHex = _colorToHex(primaryColor);

    if (points.length < 2) {
      if (_activeLine != null) {
        _mapController!.removeLine(_activeLine!);
        _activeLine = null;
      }
      return;
    }

    final mlPoints =
        points.map((p) => ml.LatLng(p.latitude, p.longitude)).toList();

    if (_activeLine == null) {
      _mapController!
          .addLine(
        ml.LineOptions(
          geometry: mlPoints,
          lineColor: primaryHex,
          lineWidth: 5.0,
          lineOpacity: 0.9,
        ),
      )
          .then((line) {
        _activeLine = line;
      }).catchError((_) {});
    } else {
      _mapController!.updateLine(
        _activeLine!,
        ml.LineOptions(geometry: mlPoints),
      );
    }
  }

  String _colorToHex(Color color) {
    final int argb = color.toARGB32();
    return '#${argb.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  void _recenter() {
    final pos = context.read<MeterProvider>().currentPosition;
    final target = pos != null
        ? ml.LatLng(pos.latitude, pos.longitude)
        : (_initialPosition ?? _defaultCenter);

    setState(() => _isFollowing = true);
    _mapController?.animateCamera(
      ml.CameraUpdate.newLatLngZoom(target, 15.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    // MapLibre vector style with OpenStreetMap tiles
    final styleString = isDarkMode
        ? 'https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json'
        : 'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json';

    final pos = context.watch<MeterProvider>().currentPosition;
    final initialCenter = pos != null
        ? ml.LatLng(pos.latitude, pos.longitude)
        : (_initialPosition ?? _defaultCenter);

    final topInset = MediaQuery.of(context).padding.top;

    return Stack(
      fit: StackFit.expand,
      children: [
        ml.MaplibreMap(
          initialCameraPosition: ml.CameraPosition(
            target: initialCenter,
            zoom: 15.0,
          ),
          styleString: styleString,
          onMapCreated: _onMapCreated,
          onCameraTrackingDismissed: () {
            if (_isFollowing) {
              setState(() => _isFollowing = false);
            }
          },
          trackCameraPosition: true,
          myLocationEnabled: false,
          compassEnabled: false,
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
                        onPressed: () {
                          _mapController?.animateCamera(
                            ml.CameraUpdate.zoomIn(),
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      PremiumIconButton(
                        tooltip: 'Zoom out',
                        icon: Icons.remove_rounded,
                        onPressed: () {
                          _mapController?.animateCamera(
                            ml.CameraUpdate.zoomOut(),
                          );
                        },
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