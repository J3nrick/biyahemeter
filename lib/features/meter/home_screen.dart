import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:biyahe_meter/core/theme/theme_provider.dart';
import 'package:biyahe_meter/features/map/map_widget.dart';
import 'package:biyahe_meter/features/meter/meter_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
  with SingleTickerProviderStateMixin {
  late TextEditingController _kmController;
  late TextEditingController _gasController;
  late TextEditingController _baseFareController;
  bool _editingKm = false;
  bool _editingGas = false;
  bool _editingBase = false;
  late final AnimationController _dashboardSlideController;
  double _maxDashboardDrag = 280;
  final FocusNode _kmFocus = FocusNode();
  final FocusNode _gasFocus = FocusNode();
  final FocusNode _baseFareFocus = FocusNode();

  static const _surface = Colors.white;
  static const _label = Color(0xFF1C1C1E);      // iOS label
  static const _secondaryLabel = Color(0xFF8E8E93); // iOS secondary label
  static const _accent = Color(0xFFFFB800);     // gold
  static const _separator = Color(0xFFE5E5EA);

  @override
  void initState() {
    super.initState();
    _dashboardSlideController = AnimationController(
      vsync: this,
      value: 0,
      lowerBound: 0,
      upperBound: 1,
      duration: const Duration(milliseconds: 320),
    )..addListener(() {
        if (mounted) setState(() {});
      });

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
    _dashboardSlideController.dispose();
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

  void _onDashboardDragUpdate(DragUpdateDetails details) {
    final deltaProgress = details.delta.dy / _maxDashboardDrag;
    _dashboardSlideController.value =
        (_dashboardSlideController.value + deltaProgress).clamp(0.0, 1.0);
  }

  void _onDashboardDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final current = _dashboardSlideController.value;
    final shouldHide = velocity > 420 || current > 0.5;

    _dashboardSlideController.animateTo(
      shouldHide ? 1.0 : 0.0,
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
    final bottomPad = mq.padding.bottom;
    _maxDashboardDrag = (mq.size.height * 0.36).clamp(220.0, 360.0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen map layer.
          const MapWidget(),
          Positioned(
            left: 12,
            right: 12,
            bottom: bottomPad + 10,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: _onDashboardDragUpdate,
              onVerticalDragEnd: _onDashboardDragEnd,
              child: Transform.translate(
                offset: Offset(0, _dashboardSlideController.value * _maxDashboardDrag),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 360),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.98, end: 1.0)
                          .animate(animation),
                      child: child,
                    ),
                  ),
                  child: _buildMainDashboard(
                    meter,
                    isNarrow,
                    themeProvider,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainDashboard(
    MeterProvider meter,
    bool compact,
    ThemeProvider themeProvider,
  ) {
    return Container(
      key: ValueKey(themeProvider.isDarkMode),
      padding: EdgeInsets.fromLTRB(12, compact ? 10 : 12, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: themeProvider.isDarkMode ? 0.18 : 0.7),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: themeProvider.isDarkMode ? 0.22 : 0.1),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'BiyaheMeter',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  _themeToggle(themeProvider),
                ],
              ),
              const SizedBox(height: 10),
              _buildFareRow(meter, compact: compact),
              const SizedBox(height: 10),
              _buildStatsRow(meter),
              const SizedBox(height: 10),
              _buildSettingsRow(meter, compact: compact),
              const SizedBox(height: 12),
              _buildStartButton(meter, compact: compact),
            ],
          ),
        ),
      ),
    );
  }

  Widget _themeToggle(ThemeProvider themeProvider) {
    return GestureDetector(
      onTap: themeProvider.toggleTheme,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(
          themeProvider.isDarkMode
              ? CupertinoIcons.sun_max_fill
              : CupertinoIcons.moon_fill,
          size: 18,
          color: themeProvider.isDarkMode ? Colors.amberAccent : Colors.blueAccent,
        ),
      ),
    );
  }

  // ── Fare Row ──
  Widget _buildFareRow(MeterProvider meter, {bool compact = false}) {
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

    final fareColor = Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFF1F4FA)
      : Colors.black;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 10 : 14),
          decoration: BoxDecoration(
            color: const Color(0xFF111111).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Estimated Fare',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3)),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '₱ ${meter.totalFare.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: fareColor,
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                          letterSpacing: -0.6,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(updateText,
                        style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _fareDetail(
                      'Base', '₱${meter.baseFare.toStringAsFixed(0)}'),
                  const SizedBox(height: 4),
                  _fareDetail('Rate',
                      '₱${(meter.gasPricePerLiter / meter.kmPerLiter).toStringAsFixed(2)}/km'),
                  const SizedBox(height: 4),
                  _fareDetail('Dist.',
                      '${meter.distanceKm.toStringAsFixed(2)} km'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fareDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white38, fontSize: 9, letterSpacing: 0.5)),
        Text(value,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ── Stats Chips Row ──
  Widget _buildStatsRow(MeterProvider meter) {
    return Row(
      children: [
        _statChip(
            icon: CupertinoIcons.speedometer,
            value: meter.currentSpeed.toStringAsFixed(0),
            unit: 'km/h'),
        const SizedBox(width: 8),
        _statChip(
            icon: CupertinoIcons.clock,
            value: meter.waitingMinutes.toStringAsFixed(1),
            unit: 'Time'),
        const SizedBox(width: 8),
        _statChip(
            icon: CupertinoIcons.location_north_line,
            value: meter.distanceKm.toStringAsFixed(2),
            unit: 'Distance'),
      ],
    );
  }

  Widget _statChip(
      {required IconData icon,
      required String value,
      required String unit}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: _accent),
            const SizedBox(width: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                  style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                        height: 1)),
                Text(unit,
                    style: const TextStyle(
                        fontSize: 9,
                    color: _secondaryLabel,
                        letterSpacing: 0.2)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Inline Settings Row ──
  Widget _buildSettingsRow(MeterProvider meter, {bool compact = false}) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          // km/L field
          Expanded(
            child: _settingsTile(
              icon: FontAwesomeIcons.gasPump,
              label: 'km/L',
              controller: _kmController,
              focusNode: _kmFocus,
              isEditing: _editingKm,
              compact: compact,
              onTapEdit: () {
                if (_editingGas) _saveGas(meter);
                if (_editingBase) _saveBase(meter);
                setState(() => _editingKm = true);
                Future.delayed(
                    const Duration(milliseconds: 50), _kmFocus.requestFocus);
              },
              onSave: () => _saveKm(meter),
            ),
          ),
          Container(
              width: 1, height: 40, color: _separator),
          // Gas price field
          Expanded(
            child: _settingsTile(
              icon: FontAwesomeIcons.pesoSign,
              label: '₱/L',
              controller: _gasController,
              focusNode: _gasFocus,
              isEditing: _editingGas,
              compact: compact,
              onTapEdit: () {
                if (_editingKm) _saveKm(meter);
                if (_editingBase) _saveBase(meter);
                setState(() => _editingGas = true);
                Future.delayed(
                    const Duration(milliseconds: 50), _gasFocus.requestFocus);
              },
              onSave: () => _saveGas(meter),
            ),
          ),
          Container(width: 1, height: 40, color: _separator),
          // Base fare field
          Expanded(
            child: _settingsTile(
              icon: FontAwesomeIcons.coins,
              label: 'Base ₱',
              controller: _baseFareController,
              focusNode: _baseFareFocus,
              isEditing: _editingBase,
              compact: compact,
              onTapEdit: () {
                if (_editingKm) _saveKm(meter);
                if (_editingGas) _saveGas(meter);
                setState(() => _editingBase = true);
                Future.delayed(
                    const Duration(milliseconds: 50), _baseFareFocus.requestFocus);
              },
              onSave: () => _saveBase(meter),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isEditing,
    bool compact = false,
    required VoidCallback onTapEdit,
    required VoidCallback onSave,
  }) {
    return GestureDetector(
      onTap: isEditing ? null : onTapEdit,
      child: Padding(
        padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 14, vertical: compact ? 8 : 10),
        child: Row(
          children: [
            FaIcon(icon, size: 12, color: _accent),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 10,
                          color: _secondaryLabel,
                          letterSpacing: 0.2)),
                  isEditing
                      ? TextField(
                          controller: controller,
                          focusNode: focusNode,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _label,
                              height: 1.2),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => onSave(),
                        )
                      : Text(
                          controller.text,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _label,
                              height: 1.2),
                        ),
                ],
              ),
            ),
            GestureDetector(
              onTap: isEditing ? onSave : onTapEdit,
              child: Icon(
                isEditing
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.pencil,
                size: 18,
                color: isEditing ? const Color(0xFF34C759) : _secondaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Start / Stop pill button ──
  Widget _buildStartButton(MeterProvider meter, {bool compact = false}) {
    final isRunning = meter.isRunning;
    final isResume = meter.canResumeTrip;
    return GestureDetector(
      onTap: () {
        if (isRunning) {
          meter.stopTrip();
          return;
        }
        if (isResume) {
          meter.resumeTrip();
        } else {
          meter.startTrip();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: compact ? 44 : 52,
        decoration: BoxDecoration(
          color: isRunning
              ? const Color(0xFFD32F2F)
              : const Color(0xFF1E7A43),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isRunning
                  ? CupertinoIcons.stop_fill
                  : CupertinoIcons.play_arrow_solid,
              color: Colors.white,
              size: 17,
            ),
            const SizedBox(width: 8),
            Text(
              isRunning
                  ? 'Stop Trip'
                  : (isResume ? 'Resume Trip' : 'Start Trip'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
