import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:biyahe_meter/core/theme/app_theme.dart';
import 'package:biyahe_meter/core/theme/theme_provider.dart';
import 'package:biyahe_meter/features/map/map_widget.dart';
import 'package:biyahe_meter/features/meter/meter_provider.dart';
import 'package:biyahe_meter/features/meter/widgets/glass_card.dart';
import 'package:biyahe_meter/features/meter/widgets/premium_buttons.dart';

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

  double _sheetExtent = _snapPeek;

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

  void _syncControllersFromMeter(MeterProvider meter) {
    if (!_editingKm) {
      _kmController.text = meter.kmPerLiter.toStringAsFixed(1);
    }
    if (!_editingGas) {
      _gasController.text = meter.gasPricePerLiter.toStringAsFixed(2);
    }
    if (!_editingBase) {
      _baseFareController.text = meter.baseFare.toStringAsFixed(2);
    }
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
      size.clamp(_snapMin, _snapMax),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPrimaryAction(MeterProvider meter) {
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
  }

  Future<void> _openSettingsSheet(MeterProvider meter) async {
    _syncControllersFromMeter(meter);
    await _expandSheet(_snapPeek);
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return _SettingsBottomSheet(
                meter: meter,
                kmController: _kmController,
                gasController: _gasController,
                baseFareController: _baseFareController,
                kmFocus: _kmFocus,
                gasFocus: _gasFocus,
                baseFareFocus: _baseFareFocus,
                editingKm: _editingKm,
                editingGas: _editingGas,
                editingBase: _editingBase,
                onEditKm: () {
                  if (_editingGas) _saveGas(meter);
                  if (_editingBase) _saveBase(meter);
                  setState(() => _editingKm = true);
                  setModalState(() {});
                  Future.delayed(
                    const Duration(milliseconds: 50),
                    _kmFocus.requestFocus,
                  );
                },
                onEditGas: () {
                  if (_editingKm) _saveKm(meter);
                  if (_editingBase) _saveBase(meter);
                  setState(() => _editingGas = true);
                  setModalState(() {});
                  Future.delayed(
                    const Duration(milliseconds: 50),
                    _gasFocus.requestFocus,
                  );
                },
                onEditBase: () {
                  if (_editingKm) _saveKm(meter);
                  if (_editingGas) _saveGas(meter);
                  setState(() => _editingBase = true);
                  setModalState(() {});
                  Future.delayed(
                    const Duration(milliseconds: 50),
                    _baseFareFocus.requestFocus,
                  );
                },
                onSaveKm: () {
                  _saveKm(meter);
                  setModalState(() {});
                },
                onSaveGas: () {
                  _saveGas(meter);
                  setModalState(() {});
                },
                onSaveBase: () {
                  _saveBase(meter);
                  setModalState(() {});
                },
              );
            },
          ),
        );
      },
    );

    if (_editingKm) _saveKm(meter);
    if (_editingGas) _saveGas(meter);
    if (_editingBase) _saveBase(meter);
  }

  @override
  Widget build(BuildContext context) {
    final meter = context.watch<MeterProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final mq = MediaQuery.of(context);
    final isNarrow = mq.size.width <= 393;
    final isWide = mq.size.width >= 700;
    final isCompactSheet = _sheetExtent < 0.42;
    final textScaler = mq.textScaler.clamp(
      minScaleFactor: 0.85,
      maxScaleFactor: 1.25,
    );

    return MediaQuery(
      data: mq.copyWith(textScaler: textScaler),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const MapWidget(),
            _TopStatusBar(meter: meter),
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                final next = notification.extent;
                if ((next - _sheetExtent).abs() > 0.01) {
                  setState(() => _sheetExtent = next);
                }
                return false;
              },
              child: DraggableScrollableSheet(
                controller: _sheetController,
                initialChildSize: _snapPeek,
                minChildSize: _snapMin,
                maxChildSize: _snapMax,
                snap: true,
                shouldCloseOnMinExtent: false,
                snapSizes: const [_snapPeek, _snapMid],
                builder: (context, scrollController) {
                  return _DashboardSheet(
                    scrollController: scrollController,
                    meter: meter,
                    themeProvider: themeProvider,
                    isNarrow: isNarrow,
                    isWide: isWide,
                    isCompact: isCompactSheet,
                    onExpand: _expandSheet,
                    onOpenSettings: () => _openSettingsSheet(meter),
                    onPrimaryAction: () => _onPrimaryAction(meter),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Floating top status strip ───────────────────────────────────

class _TopStatusBar extends StatelessWidget {
  final MeterProvider meter;

  const _TopStatusBar({required this.meter});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final width = MediaQuery.sizeOf(context).width;
    final success = AppTheme.successOf(context);
    final warning = AppTheme.warningOf(context);
    final danger = AppTheme.dangerOf(context);
    final muted = AppTheme.mutedOf(context);
    final primary = Theme.of(context).colorScheme.primary;

    final gpsLive = meter.lastUpdateTime != null &&
        DateTime.now().difference(meter.lastUpdateTime!).inSeconds < 30;
    final hasFix = meter.currentPosition != null;
    final hasSignal = meter.lastUpdateTime != null;

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

    final mapControlsReserve = width < 380 ? 64.0 : 72.0;

    return Positioned(
      top: top + 8,
      left: 12,
      right: mapControlsReserve,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      StatusChip(
                        icon: CupertinoIcons.circle_fill,
                        label: tripLabel,
                        color: tripColor,
                        active: meter.isRunning || meter.canResumeTrip,
                      ),
                      StatusChip(
                        icon: CupertinoIcons.location_solid,
                        label: hasFix
                            ? (gpsLive ? 'GPS Live' : 'GPS')
                            : 'No GPS',
                        color: gpsLive
                            ? success
                            : (hasFix ? warning : danger),
                        active: hasFix,
                      ),
                      StatusChip(
                        icon: CupertinoIcons.map_pin_ellipse,
                        label: hasFix ? 'Located' : 'Locating',
                        color: hasFix ? primary : muted,
                        active: hasFix,
                      ),
                      StatusChip(
                        icon: CupertinoIcons.wifi,
                        label: hasSignal
                            ? (gpsLive ? 'Signal' : 'Weak')
                            : 'Offline',
                        color: gpsLive
                            ? success
                            : (hasSignal ? warning : muted),
                        active: hasSignal,
                      ),
                    ],
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
  final bool isCompact;
  final Future<void> Function([double size]) onExpand;
  final VoidCallback onOpenSettings;
  final VoidCallback onPrimaryAction;

  const _DashboardSheet({
    required this.scrollController,
    required this.meter,
    required this.themeProvider,
    required this.isNarrow,
    required this.isWide,
    required this.isCompact,
    required this.onExpand,
    required this.onOpenSettings,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface
                  .withValues(alpha: isDark ? 0.88 : 0.94),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: AppTheme.borderOf(context).withValues(alpha: 0.75),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: ListView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(
                isWide ? 28 : 16,
                8,
                isWide ? 28 : 16,
                bottomPad + keyboard + 20,
              ),
              children: [
                Center(
                  child: Semantics(
                    label: 'Drag dashboard',
                    child: Container(
                      width: 42,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color:
                            AppTheme.mutedOf(context).withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
                _HeaderRow(
                  themeProvider: themeProvider,
                  onSettings: onOpenSettings,
                  onExpand: () => onExpand(0.60),
                ),
                const SizedBox(height: 12),
                _FareHeroCard(meter: meter, compact: isNarrow || isCompact),
                if (isCompact) ...[
                  const SizedBox(height: 12),
                  _CompactMetricsRow(meter: meter),
                  const SizedBox(height: 12),
                  TripActionButton(
                    kind: _tripActionKind(meter),
                    compact: true,
                    onPressed: onPrimaryAction,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Pull up for full trip controls',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.mutedOf(context),
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  _TripStatusBanner(meter: meter),
                  const SizedBox(height: 12),
                  _MetricsGrid(meter: meter),
                  const SizedBox(height: 16),
                  TripActionButton(
                    kind: _tripActionKind(meter),
                    compact: isNarrow,
                    onPressed: onPrimaryAction,
                  ),
                  const SizedBox(height: 12),
                  PremiumSurfaceButton(
                    icon: CupertinoIcons.slider_horizontal_3,
                    title: 'Trip settings',
                    subtitle: 'Fuel efficiency, gas price, base fare',
                    onPressed: onOpenSettings,
                  ),
                ],
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
  final VoidCallback onExpand;

  const _HeaderRow({
    required this.themeProvider,
    required this.onSettings,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = AppTheme.mutedOf(context);

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onExpand,
            behavior: HitTestBehavior.opaque,
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
        ),
        PremiumIconButton(
          tooltip: 'Trip settings',
          icon: CupertinoIcons.slider_horizontal_3,
          onPressed: onSettings,
        ),
        const SizedBox(width: 8),
        PremiumIconButton(
          tooltip: themeProvider.isDarkMode
              ? 'Switch to light mode'
              : 'Switch to dark mode',
          icon: themeProvider.isDarkMode
              ? CupertinoIcons.sun_max_fill
              : CupertinoIcons.moon_fill,
          iconColor: themeProvider.isDarkMode
              ? AppTheme.darkWarning
              : theme.colorScheme.primary,
          accent: themeProvider.isDarkMode
              ? AppTheme.darkWarning
              : theme.colorScheme.primary,
          active: true,
          onPressed: themeProvider.toggleTheme,
        ),
      ],
    );
  }
}

TripActionKind _tripActionKind(MeterProvider meter) {
  if (meter.isRunning) return TripActionKind.stop;
  if (meter.canResumeTrip) return TripActionKind.resume;
  return TripActionKind.start;
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
        padding: EdgeInsets.fromLTRB(
          16,
          compact ? 12 : 16,
          16,
          compact ? 12 : 16,
        ),
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
                          fontSize: compact ? 30 : 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
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
            if (!compact) ...[
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
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

class _CompactMetricsRow extends StatelessWidget {
  final MeterProvider meter;

  const _CompactMetricsRow({required this.meter});

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.mutedOf(context);
    final theme = Theme.of(context);

    Widget chip(String label, String value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderOf(context)),
          ),
          child: Column(
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(color: muted),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('km', meter.distanceKm.toStringAsFixed(2)),
        const SizedBox(width: 8),
        chip('min', meter.waitingMinutes.toStringAsFixed(1)),
        const SizedBox(width: 8),
        chip('km/h', meter.currentSpeed.toStringAsFixed(0)),
      ],
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
            label: 'Time',
            value: meter.waitingMinutes.toStringAsFixed(1),
            unit: 'waiting min',
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
            label: 'Fuel',
            value: fuelUsed.toStringAsFixed(2),
            unit: 'liters est.',
            accent: warning,
          ),
        ];

        if (wide) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: cards[i]),
              ],
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 10),
                Expanded(child: cards[1]),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: cards[2]),
                const SizedBox(width: 10),
                Expanded(child: cards[3]),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SettingsBottomSheet extends StatelessWidget {
  final MeterProvider meter;
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

  const _SettingsBottomSheet({
    required this.meter,
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
    final isNarrow = MediaQuery.sizeOf(context).width <= 393;
    final themeProvider = context.watch<ThemeProvider>();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: AppTheme.borderOf(context)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: muted.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Settings',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Grouped trip configuration',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: muted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close settings',
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        Navigator.pop(context);
                      },
                      icon: const Icon(CupertinoIcons.xmark_circle_fill),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsGroup(
                  title: 'Appearance',
                  description: 'Adaptive light and dark theme',
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(
                      themeProvider.isDarkMode
                          ? CupertinoIcons.moon_fill
                          : CupertinoIcons.sun_max_fill,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      'Dark mode',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      themeProvider.isDarkMode
                          ? 'Dark dashboard active'
                          : 'Light dashboard active',
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                    value: themeProvider.isDarkMode,
                    onChanged: (_) => themeProvider.toggleTheme(),
                  ),
                ),
                const SizedBox(height: 14),
                _SettingsGroup(
                  title: 'Fare inputs',
                  description: 'Fuel efficiency, gas price, and base fare',
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: FontAwesomeIcons.gasPump,
                        label: 'Fuel efficiency',
                        hint: 'km per liter',
                        controller: kmController,
                        focusNode: kmFocus,
                        isEditing: editingKm,
                        compact: isNarrow,
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
                        compact: isNarrow,
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
                        compact: isNarrow,
                        onTapEdit: onEditBase,
                        onSave: onSaveBase,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Rate ₱${(meter.kmPerLiter > 0 ? meter.gasPricePerLiter / meter.kmPerLiter : 0).toStringAsFixed(2)}/km · Current fare ₱${meter.totalFare.toStringAsFixed(2)}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;

  const _SettingsGroup({
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = AppTheme.mutedOf(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderOf(context)),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
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
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: compact ? 10 : 12,
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
              const SizedBox(width: 4),
              Pressable(
                onPressed: isEditing ? onSave : onTapEdit,
                semanticLabel: isEditing ? 'Save $label' : 'Edit $label',
                haptic: isEditing ? AppHaptic.medium : AppHaptic.selection,
                pressedScale: 0.92,
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isEditing
                        ? success.withValues(alpha: 0.14)
                        : primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isEditing
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.pencil,
                    size: 22,
                    color: isEditing ? success : muted,
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
