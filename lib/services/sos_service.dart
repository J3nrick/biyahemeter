import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:latlong2/latlong.dart';

class SosService {
  /// Shares a live trip safety payload with current GPS + fare status.
  /// True continuous tracking requires a backend; this emits a fresh
  /// shareable snapshot each tap (WhatsApp / Messenger / SMS friendly).
  Future<void> shareLiveRoute({
    required LatLng? position,
    required bool isRunning,
    required double totalFare,
    required double distanceKm,
    required String presetName,
  }) async {
    final money = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    final stamp = DateFormat('h:mm:ss a').format(DateTime.now());
    final status = isRunning ? 'LIVE TRIP' : 'IDLE / PAUSED';

    final buffer = StringBuffer()
      ..writeln('BiyaheMeter PH — Live Trip Share / SOS')
      ..writeln('Status: $status')
      ..writeln('Time: $stamp')
      ..writeln('Preset: $presetName')
      ..writeln('Fare so far: ${money.format(totalFare)}')
      ..writeln('Distance: ${distanceKm.toStringAsFixed(2)} km');

    if (position != null) {
      final lat = position.latitude.toStringAsFixed(6);
      final lng = position.longitude.toStringAsFixed(6);
      buffer
        ..writeln('GPS: $lat, $lng')
        ..writeln('Map: https://www.google.com/maps?q=$lat,$lng')
        ..writeln(
          'Deep link: biyahemeter://live?lat=$lat&lng=$lng'
          '&fare=${totalFare.toStringAsFixed(2)}&status=$status',
        );
    } else {
      buffer.writeln('GPS: unavailable — enable location and retry.');
    }

    buffer.writeln('Please check on me / track this route.');

    await SharePlus.instance.share(
      ShareParams(
        text: buffer.toString(),
        subject: 'BiyaheMeter PH Live Trip / SOS',
      ),
    );
  }
}
