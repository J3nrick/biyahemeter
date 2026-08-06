import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:biyahe_meter/core/theme/app_theme.dart';
import 'package:biyahe_meter/features/history/history_provider.dart';
import 'package:biyahe_meter/features/meter/widgets/premium_buttons.dart';
import 'package:biyahe_meter/services/analytics_service.dart';
import 'package:biyahe_meter/services/receipt_service.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    final theme = Theme.of(context);
    final muted = AppTheme.mutedOf(context);
    final money = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    final snap = history.snapshot;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Driver Insights'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: history.trips.isEmpty ? null : history.exportCsv,
            icon: const Icon(CupertinoIcons.share),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              'Earnings & fuel analytics',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
            const SizedBox(height: 12),
            SegmentedButton<AnalyticsPeriod>(
              segments: const [
                ButtonSegment(
                  value: AnalyticsPeriod.today,
                  label: Text('Today'),
                ),
                ButtonSegment(
                  value: AnalyticsPeriod.week,
                  label: Text('Week'),
                ),
                ButtonSegment(
                  value: AnalyticsPeriod.month,
                  label: Text('Month'),
                ),
                ButtonSegment(
                  value: AnalyticsPeriod.all,
                  label: Text('All'),
                ),
              ],
              selected: {history.period},
              onSelectionChanged: (s) => history.setPeriod(s.first),
            ),
            const SizedBox(height: 16),
            _InsightCard(
              title: 'Gross earnings',
              value: money.format(snap.totalEarnings),
              subtitle: '${snap.tripCount} trips',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _InsightCard(
                    title: 'Fuel spent',
                    value: money.format(snap.totalFuelCost),
                    subtitle: 'Estimated',
                    compact: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InsightCard(
                    title: 'Net earnings',
                    value: money.format(snap.netEarnings),
                    subtitle: 'Fare − fuel',
                    compact: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _InsightCard(
                    title: 'Distance',
                    value: '${snap.totalDistanceKm.toStringAsFixed(1)} km',
                    subtitle: 'Covered',
                    compact: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InsightCard(
                    title: 'Waiting',
                    value: '${snap.totalWaitingMinutes.toStringAsFixed(0)} min',
                    subtitle: 'Traffic idle',
                    compact: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Recent trips',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            if (history.filteredTrips.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Text(
                  'No trips in this period yet.\nComplete a trip to see insights.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
              )
            else
              ...history.filteredTrips.take(30).map((trip) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: AppTheme.borderOf(context)),
                      ),
                      title: Text(
                        money.format(trip.totalFare),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        '${DateFormat('MMM d · h:mm a').format(trip.endedAt)} · '
                        '${trip.distanceKm.toStringAsFixed(2)} km · ${trip.presetName}',
                      ),
                      trailing: IconButton(
                        tooltip: 'Share receipt',
                        icon: const Icon(CupertinoIcons.doc_text),
                        onPressed: () =>
                            context.read<ReceiptService>().sharePdf(trip),
                      ),
                    ),
                  ),
                );
              }),
            if (history.trips.isNotEmpty) ...[
              const SizedBox(height: 12),
              PremiumSurfaceButton(
                icon: CupertinoIcons.trash,
                title: 'Clear history',
                subtitle: 'Remove all stored trips from this device',
                accent: AppTheme.dangerOf(context),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Clear trip history?'),
                      content: const Text(
                        'This permanently deletes local trip records.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) await history.clearAll();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final bool compact;

  const _InsightCard({
    required this.title,
    required this.value,
    required this.subtitle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = AppTheme.mutedOf(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderOf(context)),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.labelMedium?.copyWith(color: muted)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: theme.textTheme.labelSmall?.copyWith(color: muted)),
        ],
      ),
    );
  }
}
