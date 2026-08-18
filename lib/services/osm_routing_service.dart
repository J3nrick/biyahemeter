import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Result container for OSM-based route queries (OSRM / Valhalla).
class OSMRouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  const OSMRouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  double get distanceKm => distanceMeters / 1000.0;
  double get durationMinutes => durationSeconds / 60.0;
}

/// Service for calculating driving routes using open OpenStreetMap endpoints.
class OSMRoutingService {
  static const String _osrmBaseUrl =
      'https://router.project-osrm.org/route/v1/driving';

  /// Fetches driving route between [origin] and [destination].
  /// Returns [OSMRouteResult] if successful, or null on error.
  static Future<OSMRouteResult?> fetchRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final url = Uri.parse(
        '$_osrmBaseUrl/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson',
      );

      final response = await http
          .get(url, headers: {'User-Agent': 'BiyaheMeter/1.0 (PH)'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final firstRoute = routes[0] as Map<String, dynamic>;
          final distance = (firstRoute['distance'] as num).toDouble();
          final duration = (firstRoute['duration'] as num).toDouble();
          final geometry = firstRoute['geometry'] as Map<String, dynamic>?;

          final coordinates = geometry?['coordinates'] as List<dynamic>?;
          final List<LatLng> points = [];

          if (coordinates != null) {
            for (final coord in coordinates) {
              if (coord is List && coord.length >= 2) {
                final lng = (coord[0] as num).toDouble();
                final lat = (coord[1] as num).toDouble();
                points.add(LatLng(lat, lng));
              }
            }
          }

          return OSMRouteResult(
            points: points,
            distanceMeters: distance,
            durationSeconds: duration,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('OSMRoutingService route fetch failed: $e');
      }
    }
    return null;
  }
}
