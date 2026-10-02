import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:biyahe_meter/core/models/trip_record.dart';
import 'package:biyahe_meter/core/theme/app_theme.dart';
import 'package:biyahe_meter/core/utils/trip_calculator.dart';
import 'package:biyahe_meter/features/history/history_provider.dart';
import 'package:biyahe_meter/features/meter/meter_provider.dart';
import 'package:biyahe_meter/features/meter/widgets/premium_buttons.dart';
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

  await context.read<HistoryProvider>().addTrip(trip);

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _TripSummarySheet(trip: trip),
  );
}

class _TripSummarySheet extends StatelessWidget {
  final TripRecord trip;

  const _TripSummarySheet({required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = AppTheme.mutedOf(context);
    final money = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    final receipt = context.read<ReceiptService>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.82,
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: AppTheme.borderOf(context).withValues(alpha: 0.6),
                  width: 0.8,
                ),
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
                Text(
                  money.format(trip.totalFare),
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                _line(context, 'Distance',
                    '${trip.distanceKm.toStringAsFixed(2)} km'),
                _line(context, 'Duration',
                    '${trip.duration.inMinutes}m ${trip.duration.inSeconds % 60}s'),
                _line(context, 'Avg speed',
                    '${trip.averageSpeedKmh.toStringAsFixed(1)} km/h'),
                _line(context, 'Flagdown', money.format(trip.baseFare)),
                _line(context, 'Distance fare', money.format(trip.distanceFare)),
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
                  label: 'Share Trip Summary',
                  enabled: true,
                  icon: CupertinoIcons.share,
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
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: muted),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
