import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:biyahe_meter/core/theme/app_theme.dart';
import 'package:biyahe_meter/core/theme/theme_provider.dart';
import 'package:biyahe_meter/features/map/map_widget.dart';
import 'package:biyahe_meter/features/meter/meter_provider.dart';
import 'package:biyahe_meter/features/meter/widgets/glass_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TextEditingController _kmController;
  late TextEditingController _gasController;
  late TextEditingController _baseFareController;
  bool _editingKm = false;
  bool _editingGas = false;
  bool _editingBase = false;
  final FocusNode _kmFocus = FocusNode();
  final FocusNode _gasFocus = FocusNode();
  final FocusNode _baseFareFocus = FocusNode();

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  static const double _snapMin = 0.12;
  static const double _snapPeek = 0.35;
  static const double _snapMid = 0.60;
  static const double _snapMax = 0.90;

  @override
  void initState() {
    super.initState();
    final meter = context.read<MeterProvider>();
    _kmController =
        TextEditingController(text: meter.kmPerLiter.toStringAsFixed(1));
    _gasController =
        TextEditingController(text: meter.gasPricePerLiter.toStringAsFixed(2));
    _baseFareController =
        TextEditingController(text: meter.baseFare.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _kmController.dispose();
    _gasController.dispose();
    _baseFareController.dispose();
    _kmFocus.dispose();
    _gasFocus.dispose();
    _baseFareFocus.dispose();
    super.dispose();
  }

  void _saveKm(MeterProvider meter) {
    final val = double.tryParse(_kmController.text);
    if (val != null && val > 0) meter.kmPerLiter = val;
    _kmFocus.unfocus();
    setState(() => _editingKm = false);
  }

  void _saveGas(MeterProvider meter) {
    final val = double.tryParse(_gasController.text);
    if (val != null && val > 0) meter.gasPricePerLiter = val;
    _gasFocus.unfocus();
    setState(() => _editingGas = false);
  }

  void _saveBase(MeterProvider meter) {
    final val = double.tryParse(_baseFareController.text);
    if (val != null && val >= 0) meter.baseFare = val;
    _baseFareFocus.unfocus();
    setState(() => _editingBase = false);
  }

  Future<void> _expandSheet([double size = _snapMid]) async {
    if (!_sheetController.isAttached) return;
    await _sheetController.animateTo(
      size,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final meter = context.watch<MeterProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final mq = MediaQuery.of(context);
    final isNarrow = mq.size.width <= 393;
    final isWide = mq.size.width >= 700;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const MapWidget(),
          _TopStatusBar(meter: meter, themeProvider: themeProvider),
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: _snapPeek,
            minChildSize: _snapMin,
            maxChildSize: _snapMax,
            snap: true,
            // Intermediate snaps only — min/max are snap points when snap: true.
            snapSizes: const [_snapPeek, _snapMid],
            builder: (context, scrollController) {
              return _DashboardSheet(
                scrollController: scrollController,
                meter: meter,
                themeProvider: themeProvider,
                isNarrow: isNarrow,
                isWide: isWide,
                kmController: _kmController,
                gasController: _gasController,
                baseFareController: _baseFareController,
                kmFocus: _kmFocus,
                gasFocus: _gasFocus,
                baseFareFocus: _baseFareFocus,
                editingKm: _editingKm,
                editingGas: _editingGas,
                editingBase: _editingBase,
                onExpand: _expandSheet,
                onEditKm: () {
                  if (_editingGas) _saveGas(meter);
                  if (_editingBase) _saveBase(meter);
                  setState(() => _editingKm = true);
                  _expandSheet(_snapMax);
                  Future.delayed(
                      const Duration(milliseconds: 50), _kmFocus.requestFocus);
                },
                onEditGas: () {
                  if (_editingKm) _saveKm(meter);
                  if (_editingBase) _saveBase(meter);
                  setState(() => _editingGas = true);
                  _expandSheet(_snapMax);
                  Future.delayed(
                      const Duration(milliseconds: 50), _gasFocus.requestFocus);
                },
                onEditBase: () {
                  if (_editingKm) _saveKm(meter);
                  if (_editingGas) _saveGas(meter);
                  setState(() => _editingBase = true);
                  _expandSheet(_snapMax);
                  Future.delayed(const Duration(milliseconds: 50),
                      _baseFareFocus.requestFocus);
                },
                onSaveKm: () => _saveKm(meter),
                onSaveGas: () => _saveGas(meter),
                onSaveBase: () => _saveBase(meter),
                onPrimaryAction: () {
                  _expandSheet(_snapPeek);
                  if (meter.isRunning) {
                    meter.stopTrip();
                    return;
                  }
                  if (meter.canResumeTrip) {
                    meter.resumeTrip();
                  } else {
                    meter.startTrip();
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Floating top status strip (map stays visible) ───────────────

class _TopStatusBar extends StatelessWidget {
  final MeterProvider meter;
  final ThemeProvider themeProvider;

  const _TopStatusBar({
    required this.meter,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final success = AppTheme.successOf(context);
    final warning = AppTheme.warningOf(context);
    final danger = AppTheme.dangerOf(context);
    final muted = AppTheme.mutedOf(context);

    final gpsLive = meter.lastUpdateTime != null &&
        DateTime.now().difference(meter.lastUpdateTime!).inSeconds < 30;
    final hasFix = meter.currentPosition != null || meter.lastUpdateTime != null;

    String tripLabel;
    Color tripColor;
    if (meter.isRunning) {
      tripLabel = 'Live';
      tripColor = success;
    } else if (meter.canResumeTrip) {
      tripLabel = 'Paused';
      tripColor = warning;
    } else {
      tripLabel = 'Idle';
      tripColor = muted;
    }

    return Positioned(
      top: top + 10,
      left: 14,
      right: 72,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surface
                  .withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.borderOf(context).withValues(alpha: 0.7),
              ),
              boxShadow: AppTheme.softShadow(context),
            ),
            child: Row(
              children: [
                Flexible(
                  child: StatusChip(
                    icon: CupertinoIcons.circle_fill,
                    label: tripLabel,
                    color: tripColor,
                    active: meter.isRunning || meter.canResumeTrip,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: StatusChip(
                    icon: CupertinoIcons.location_solid,
                    label: gpsLive ? 'GPS Live' : (hasFix ? 'GPS' : 'No GPS'),
                    color: gpsLive ? success : (hasFix ? warning : danger),
                    active: hasFix,
                  ),
                ),
                const SizedBox(width: 8),
                const _LiveClock(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveClock extends StatefulWidget {
  const _LiveClock();

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = AppTheme.mutedOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat('HH:mm').format(_now),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        Text(
          DateFormat('MMM d').format(_now),
          style: theme.textTheme.labelSmall?.copyWith(color: muted),
        ),
      ],
    );
  }
}

// ── Draggable premium dashboard ─────────────────────────────────

class _DashboardSheet extends StatelessWidget {
  final ScrollController scrollController;
  final MeterProvider meter;
  final ThemeProvider themeProvider;
  final bool isNarrow;
  final bool isWide;
  final TextEditingController kmController;
  final TextEditingController gasController;
  final TextEditingController baseFareController;
  final FocusNode kmFocus;
  final FocusNode gasFocus;
  final FocusNode baseFareFocus;
  final bool editingKm;
  final bool editingGas;
  final bool editingBase;
  final Future<void> Function([double size]) onExpand;
  final VoidCallback onEditKm;
  final VoidCallback onEditGas;
  final VoidCallback onEditBase;
  final VoidCallback onSaveKm;
  final VoidCallback onSaveGas;
  final VoidCallback onSaveBase;
  final VoidCallback onPrimaryAction;

  const _DashboardSheet({
    required this.scrollController,
    required this.meter,
    required this.themeProvider,
    required this.isNarrow,
    required this.isWide,
    required this.kmController,
    required this.gasController,
    required this.baseFareController,
    required this.kmFocus,
    required this.gasFocus,
    required this.baseFareFocus,
    required this.editingKm,
    required this.editingGas,
    required this.editingBase,
    required this.onExpand,
    required this.onEditKm,
    required this.onEditGas,
    required this.onEditBase,
    required this.onSaveKm,
    required this.onSaveGas,
    required this.onSaveBase,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: isDark ? 0.88 : 0.92),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: AppTheme.borderOf(context).withValues(alpha: 0.75),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(
                isWide ? 28 : 16,
                8,
                isWide ? 28 : 16,
                bottomPad + 20,
              ),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.mutedOf(context).withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                _HeaderRow(
                  themeProvider: themeProvider,
                  onSettings: () => onExpand(0.90),
                ),
                const SizedBox(height: 14),
                _FareHeroCard(meter: meter, compact: isNarrow),
                const SizedBox(height: 12),
                _TripStatusBanner(meter: meter),
                const SizedBox(height: 12),
                _MetricsGrid(meter: meter),
                const SizedBox(height: 14),
                _SettingsSection(
                  meter: meter,
                  compact: isNarrow,
                  kmController: kmController,
                  gasController: gasController,
                  baseFareController: baseFareController,
                  kmFocus: kmFocus,
                  gasFocus: gasFocus,
                  baseFareFocus: baseFareFocus,
                  editingKm: editingKm,
                  editingGas: editingGas,
                  editingBase: editingBase,
                  onEditKm: onEditKm,
                  onEditGas: onEditGas,
                  onEditBase: onEditBase,
                  onSaveKm: onSaveKm,
                  onSaveGas: onSaveGas,
                  onSaveBase: onSaveBase,
                ),
                const SizedBox(height: 16),
                _PrimaryTripButton(
                  meter: meter,
                  compact: isNarrow,
                  onTap: onPrimaryAction,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final ThemeProvider themeProvider;
  final VoidCallback onSettings;

  const _HeaderRow({
    required this.themeProvider,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = AppTheme.mutedOf(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BiyaheMeter',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                'Premium trip control',
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
          ),
        ),
        _IconAction(
          semanticLabel: 'Open settings',
          icon: CupertinoIcons.slider_horizontal_3,
          onTap: onSettings,
        ),
        const SizedBox(width: 8),
        _IconAction(
          semanticLabel: 'Toggle theme',
          icon: themeProvider.isDarkMode
              ? CupertinoIcons.sun_max_fill
              : CupertinoIcons.moon_fill,
          iconColor: themeProvider.isDarkMode
              ? AppTheme.darkWarning
              : theme.colorScheme.primary,
          onTap: themeProvider.toggleTheme,
        ),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;
  final Color? iconColor;

  const _IconAction({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.borderOf(context).withValues(alpha: 0.8),
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _FareHeroCard extends StatelessWidget {
  final MeterProvider meter;
  final bool compact;

  const _FareHeroCard({required this.meter, required this.compact});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String updateText;
    final lastUpdate = meter.lastUpdateTime;
    if (lastUpdate == null) {
      updateText = 'GPS not started';
    } else {
      final diff = DateTime.now().difference(lastUpdate);
      updateText = diff.inSeconds < 60
          ? 'Updated ${diff.inSeconds}s ago'
          : 'Updated ${diff.inMinutes}m ago';
    }

    final rate = meter.kmPerLiter > 0
        ? meter.gasPricePerLiter / meter.kmPerLiter
        : 0.0;

    return Semantics(
      label: 'Estimated fare ${meter.totalFare.toStringAsFixed(2)} pesos',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.fromLTRB(18, compact ? 14 : 18, 18, compact ? 14 : 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF151A24), Color(0xFF1E2636)]
                : const [Color(0xFF0F172A), Color(0xFF1E3A5F)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.14),
          ),
          boxShadow: AppTheme.softShadow(context),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT FARE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.12),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: Text(
                        '₱ ${meter.totalFare.toStringAsFixed(2)}',
                        key: ValueKey(meter.totalFare.toStringAsFixed(2)),
                        style: AppTheme.fareStyle(
                          brightness: Brightness.dark,
                          fontSize: compact ? 34 : 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    updateText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _FareDetail(
                  label: 'Base',
                  value: '₱${meter.baseFare.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 8),
                _FareDetail(
                  label: 'Rate',
                  value: '₱${rate.toStringAsFixed(2)}/km',
                ),
                const SizedBox(height: 8),
                _FareDetail(
                  label: 'Dist.',
                  value: '${meter.distanceKm.toStringAsFixed(2)} km',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FareDetail extends StatelessWidget {
  final String label;
  final String value;

  const _FareDetail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white38,
                letterSpacing: 0.5,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _TripStatusBanner extends StatelessWidget {
  final MeterProvider meter;

  const _TripStatusBanner({required this.meter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final success = AppTheme.successOf(context);
    final warning = AppTheme.warningOf(context);
    final muted = AppTheme.mutedOf(context);

    late final String title;
    late final String subtitle;
    late final Color color;
    late final IconData icon;

    if (meter.isRunning) {
      title = 'Trip in progress';
      subtitle = 'Meter is tracking distance and waiting time';
      color = success;
      icon = CupertinoIcons.checkmark_seal_fill;
    } else if (meter.canResumeTrip) {
      title = 'Trip paused';
      subtitle = 'Resume to continue from current totals';
      color = warning;
      icon = CupertinoIcons.pause_circle_fill;
    } else {
      title = 'Ready to start';
      subtitle = 'Map stays visible — pull up for full controls';
      color = muted;
      icon = CupertinoIcons.car_detailed;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final MeterProvider meter;

  const _MetricsGrid({required this.meter});

  @override
  Widget build(BuildContext context) {
    final fuelUsed =
        meter.kmPerLiter > 0 ? meter.distanceKm / meter.kmPerLiter : 0.0;
    final primary = Theme.of(context).colorScheme.primary;
    final success = AppTheme.successOf(context);
    final warning = AppTheme.warningOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 520;
        final cards = [
          MetricCard(
            icon: CupertinoIcons.location_north_line_fill,
            label: 'Distance',
            value: meter.distanceKm.toStringAsFixed(2),
            unit: 'kilometers',
            accent: primary,
          ),
          MetricCard(
            icon: CupertinoIcons.clock_fill,
            label: 'Waiting',
            value: meter.waitingMinutes.toStringAsFixed(1),
            unit: 'minutes',
            accent: warning,
          ),
          MetricCard(
            icon: CupertinoIcons.speedometer,
            label: 'Speed',
            value: meter.currentSpeed.toStringAsFixed(0),
            unit: 'km/h',
            accent: success,
          ),
          MetricCard(
            icon: FontAwesomeIcons.gasPump,
            label: 'Fuel used',
            value: fuelUsed.toStringAsFixed(2),
            unit: 'liters est.',
            accent: warning,
          ),
        ];

        if (wide) {
          return SizedBox(
            height: 118,
            child: Row(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: cards[i]),
                ],
              ],
            ),
          );
        }

        return Column(
          children: [
            SizedBox(
              height: 114,
              child: Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[1]),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 114,
              child: Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[3]),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final MeterProvider meter;
  final bool compact;
  final TextEditingController kmController;
  final TextEditingController gasController;
  final TextEditingController baseFareController;
  final FocusNode kmFocus;
  final FocusNode gasFocus;
  final FocusNode baseFareFocus;
  final bool editingKm;
  final bool editingGas;
  final bool editingBase;
  final VoidCallback onEditKm;
  final VoidCallback onEditGas;
  final VoidCallback onEditBase;
  final VoidCallback onSaveKm;
  final VoidCallback onSaveGas;
  final VoidCallback onSaveBase;

  const _SettingsSection({
    required this.meter,
    required this.compact,
    required this.kmController,
    required this.gasController,
    required this.baseFareController,
    required this.kmFocus,
    required this.gasFocus,
    required this.baseFareFocus,
    required this.editingKm,
    required this.editingGas,
    required this.editingBase,
    required this.onEditKm,
    required this.onEditGas,
    required this.onEditBase,
    required this.onSaveKm,
    required this.onSaveGas,
    required this.onSaveBase,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = AppTheme.mutedOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trip settings',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Fuel efficiency, gas price, and base fare',
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.borderOf(context).withValues(alpha: 0.9),
            ),
            boxShadow: AppTheme.softShadow(context),
          ),
          child: Column(
            children: [
              _SettingsTile(
                icon: FontAwesomeIcons.gasPump,
                label: 'Fuel efficiency',
                hint: 'km per liter',
                controller: kmController,
                focusNode: kmFocus,
                isEditing: editingKm,
                compact: compact,
                onTapEdit: onEditKm,
                onSave: onSaveKm,
              ),
              Divider(height: 1, color: AppTheme.borderOf(context)),
              _SettingsTile(
                icon: FontAwesomeIcons.pesoSign,
                label: 'Gas price',
                hint: 'pesos per liter',
                controller: gasController,
                focusNode: gasFocus,
                isEditing: editingGas,
                compact: compact,
                onTapEdit: onEditGas,
                onSave: onSaveGas,
              ),
              Divider(height: 1, color: AppTheme.borderOf(context)),
              _SettingsTile(
                icon: FontAwesomeIcons.coins,
                label: 'Base fare',
                hint: 'starting amount',
                controller: baseFareController,
                focusNode: baseFareFocus,
                isEditing: editingBase,
                compact: compact,
                onTapEdit: onEditBase,
                onSave: onSaveBase,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isEditing;
  final bool compact;
  final VoidCallback onTapEdit;
  final VoidCallback onSave;
  final bool isLast;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.hint,
    required this.controller,
    required this.focusNode,
    required this.isEditing,
    required this.compact,
    required this.onTapEdit,
    required this.onSave,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = AppTheme.mutedOf(context);
    final success = AppTheme.successOf(context);
    final primary = theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEditing ? null : onTapEdit,
        borderRadius: BorderRadius.vertical(
          top: label == 'Fuel efficiency' ? const Radius.circular(18) : Radius.zero,
          bottom: isLast ? const Radius.circular(18) : Radius.zero,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 12 : 14,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: FaIcon(icon, size: 14, color: primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      hint,
                      style: theme.textTheme.labelSmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 88,
                child: isEditing
                    ? TextField(
                        controller: controller,
                        focusNode: focusNode,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.end,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => onSave(),
                      )
                    : Text(
                        controller.text,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: isEditing ? 'Save $label' : 'Edit $label',
                child: InkWell(
                  onTap: isEditing ? onSave : onTapEdit,
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      isEditing
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.pencil,
                      size: 22,
                      color: isEditing ? success : muted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryTripButton extends StatelessWidget {
  final MeterProvider meter;
  final bool compact;
  final VoidCallback onTap;

  const _PrimaryTripButton({
    required this.meter,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = meter.isRunning;
    final isResume = meter.canResumeTrip;
    final success = AppTheme.successOf(context);
    final danger = AppTheme.dangerOf(context);

    final label = isRunning
        ? 'Stop Trip'
        : (isResume ? 'Resume Trip' : 'Start Trip');
    final icon = isRunning
        ? CupertinoIcons.stop_fill
        : CupertinoIcons.play_arrow_solid;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            height: compact ? 52 : 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isRunning
                    ? [danger, danger.withValues(alpha: 0.85)]
                    : [
                        success,
                        Color.lerp(success, Colors.black, 0.12)!,
                      ],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: (isRunning ? danger : success)
                      .withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
