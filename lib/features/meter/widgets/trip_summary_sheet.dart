import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:biyahe_meter/core/models/trip_record.dart';
import 'package:biyahe_meter/core/theme/app_theme.dart';
import 'package:biyahe_meter/core/utils/trip_calculator.dart';
import 'package:biyahe_meter/features/history/history_provider.dart';
import 'package:biyahe_meter/features/meter/meter_provider.dart';
import 'package:biyahe_meter/features/meter/widgets/premium_buttons.dart';
import 'package:biyahe_meter/features/meter/widgets/trip_card.dart';
import 'package:biyahe_meter/services/receipt_service.dart';

Future<void> showTripSummarySheet(BuildContext context) async {
  final meter = context.read<MeterProvider>();
  if (meter.tripStartedAt == null) return;

  final breakdown = meter.lastBreakdown;
  final fuelLiters = TripCalculator.estimateFuelLiters(
    distanceKm: meter.distanceKm,
    kmPerLiter: meter.kmPerLiter,
  );
  final fuelCost = TripCalculator.estimateFuelCost(
    distanceKm: meter.distanceKm,
    kmPerLiter: meter.kmPerLiter,
    gasPricePerLiter: meter.gasPricePerLiter,
  );

  final trip = TripRecord(
    id: const Uuid().v4(),
    startedAt: meter.tripStartedAt!,
    endedAt: meter.tripEndedAt ?? DateTime.now(),
    distanceKm: meter.distanceKm,
    waitingMinutes: meter.waitingMinutes,
    totalFare: meter.totalFare,
    baseFare: breakdown?.flagdown ?? meter.baseFare,
    distanceFare: breakdown?.distanceFare ?? 0,
    waitingFare: breakdown?.waitingFare ?? 0,
    discountPercent: breakdown?.discountPercent ?? 0,
    discountAmount: breakdown?.discountAmount ?? 0,
    fuelLiters: fuelLiters,
    fuelCost: fuelCost,
    presetName: meter.activePreset.name,
    discountApplied: meter.discountEnabled,
    startLat: meter.tripStartPosition?.latitude,
    startLng: meter.tripStartPosition?.longitude,
    endLat: meter.currentPosition?.latitude,
    endLng: meter.currentPosition?.longitude,
  );

  // Copied now: the meter clears its route when the next trip starts.
  final route = meter.routePoints.toList();
  await context.read<HistoryProvider>().addTrip(trip);

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _TripSummarySheet(trip: trip, route: route),
  );
}

class _TripSummarySheet extends StatelessWidget {
  final TripRecord trip;

  final List<LatLng> route;
  final _cardKey = GlobalKey();

  _TripSummarySheet({required this.trip, required this.route});

  Future<void> _shareCard(ReceiptService receipt) async {
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      await receipt.shareImage(trip, png!.buffer.asUint8List());
    } catch (_) {
      // Image capture or file sharing unsupported here: text always works.
      await receipt.shareSummaryText(trip);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = AppTheme.mutedOf(context);
    final money = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    final receipt = context.read<ReceiptService>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: AppTheme.borderOf(context).withValues(alpha: 0.6),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: muted.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Text(
                  'Trip complete',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${trip.presetName} · ${DateFormat('MMM d, h:mm a').format(trip.endedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
                const SizedBox(height: 16),
                RepaintBoundary(
                  key: _cardKey,
                  child: TripCard(
                    trip: trip,
                    route: route,
                    fareStyle: AppTheme.fareStyle(
                      brightness: Brightness.dark,
                      fontSize: 38,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _line(
                  context,
                  'Distance',
                  '${trip.distanceKm.toStringAsFixed(2)} km',
                ),
                _line(
                  context,
                  'Duration',
                  '${trip.duration.inMinutes}m ${trip.duration.inSeconds % 60}s',
                ),
                _line(
                  context,
                  'Avg speed',
                  '${trip.averageSpeedKmh.toStringAsFixed(1)} km/h',
                ),
                _line(context, 'Flagdown', money.format(trip.baseFare)),
                _line(
                  context,
                  'Distance fare',
                  money.format(trip.distanceFare),
                ),
                _line(context, 'Waiting fare', money.format(trip.waitingFare)),
                if (trip.discountApplied)
                  _line(
                    context,
                    'Discount',
                    '- ${money.format(trip.discountAmount)}',
                  ),
                if (trip.startPoint != null)
                  _line(
                    context,
                    'Start GPS',
                    '${trip.startLat!.toStringAsFixed(4)}, ${trip.startLng!.toStringAsFixed(4)}',
                  ),
                if (trip.endPoint != null)
                  _line(
                    context,
                    'End GPS',
                    '${trip.endLat!.toStringAsFixed(4)}, ${trip.endLng!.toStringAsFixed(4)}',
                  ),
                const SizedBox(height: 18),
                PremiumConfirmButton(
                  label: 'Share trip card',
                  enabled: true,
                  icon: CupertinoIcons.share,
                  onPressed: () => _shareCard(receipt),
                ),
                const SizedBox(height: 8),
                PremiumSurfaceButton(
                  icon: CupertinoIcons.doc,
                  title: 'Share PDF receipt',
                  subtitle: 'For records and reimbursement',
                  onPressed: () => receipt.sharePdf(trip),
                ),
                const SizedBox(height: 8),
                PremiumSurfaceButton(
                  icon: CupertinoIcons.doc_richtext,
                  title: 'Preview PDF receipt',
                  subtitle: 'Open system print / PDF preview',
                  onPressed: () => receipt.previewPdf(trip),
                ),
                const SizedBox(height: 8),
                PremiumSurfaceButton(
                  icon: CupertinoIcons.chat_bubble_text,
                  title: 'Share as text',
                  subtitle: 'WhatsApp, Messenger, SMS',
                  onPressed: () => receipt.shareSummaryText(trip),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value) {
    final muted = AppTheme.mutedOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
