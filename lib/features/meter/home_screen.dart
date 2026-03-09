import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:biyahe_meter/features/map/map_widget.dart';
import 'package:biyahe_meter/features/meter/meter_provider.dart';

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

  static const _bg = Color(0xFFF2F2F7);        // iOS system grouped bg
  static const _surface = Colors.white;
  static const _label = Color(0xFF1C1C1E);      // iOS label
  static const _secondaryLabel = Color(0xFF8E8E93); // iOS secondary label
  static const _accent = Color(0xFFFFB800);     // gold
  static const _navy = Color(0xFF1A237E);
  static const _separator = Color(0xFFE5E5EA);

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

  @override
  Widget build(BuildContext context) {
    final meter = context.watch<MeterProvider>();
    final mq = MediaQuery.of(context);
    final isLandscape = mq.orientation == Orientation.landscape;
    final bottomPad = mq.padding.bottom;

    final double sheetMin = isLandscape ? 0.28 : 0.22;
    final double sheetInitial = isLandscape ? 0.62 : 0.52;
    final double sheetMax = isLandscape ? 0.96 : 0.92;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full-screen map ──
          const MapWidget(),

          // ── Draggable bottom sheet ──
          DraggableScrollableSheet(
            key: ValueKey(isLandscape),
            initialChildSize: sheetInitial,
            minChildSize: sheetMin,
            maxChildSize: sheetMax,
            snap: true,
            snapSizes: [sheetInitial],
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: _bg,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(22)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding:
                      EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomPad),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Drag handle ──
                      const SizedBox(height: 8),
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1D1D6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Logo header — always above fare card ──
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/images/logo.png',
                              height: 56,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),

                      if (isLandscape) ..._buildLandscapeContent(meter)
                      else ..._buildPortraitContent(meter),
                    ],
                  ),
                ),
              );
            },
          ),

        ],
      ),
    );
  }

  // ── Portrait layout ──
  List<Widget> _buildPortraitContent(MeterProvider meter) => [
        _buildFareRow(meter),
        const SizedBox(height: 10),
        _buildStatsRow(meter),
        const SizedBox(height: 10),
        _buildSettingsRow(meter),
        const SizedBox(height: 12),
        _buildStartButton(meter),
      ];

  // ── Landscape layout: fare + stats side-by-side, settings + button in a row ──
  List<Widget> _buildLandscapeContent(MeterProvider meter) => [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: _buildFareRow(meter)),
            const SizedBox(width: 10),
            Expanded(flex: 4, child: _buildStatsColumn(meter)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _buildSettingsRow(meter)),
            const SizedBox(width: 10),
            SizedBox(width: 150, child: _buildStartButton(meter)),
          ],
        ),
      ];

  // ── Fare Row ──
  Widget _buildFareRow(MeterProvider meter) {
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(16),
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
                        color: Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '₱ ${meter.totalFare.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(updateText,
                    style: const TextStyle(
                        color: Colors.white38,
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
            unit: 'min wait'),
        const SizedBox(width: 8),
        _statChip(
            icon: CupertinoIcons.location_north_line,
            value: meter.distanceKm.toStringAsFixed(2),
            unit: 'km'),
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
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
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
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _label,
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

  // ── Stats chips (landscape: vertical column) ──
  Widget _buildStatsColumn(MeterProvider meter) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _statChipWide(
            icon: CupertinoIcons.speedometer,
            label: 'Speed',
            value: '${meter.currentSpeed.toStringAsFixed(0)} km/h'),
        const SizedBox(height: 6),
        _statChipWide(
            icon: CupertinoIcons.clock,
            label: 'Waiting',
            value: '${meter.waitingMinutes.toStringAsFixed(1)} min'),
        const SizedBox(height: 6),
        _statChipWide(
            icon: CupertinoIcons.location_north_line,
            label: 'Distance',
            value: '${meter.distanceKm.toStringAsFixed(2)} km'),
      ],
    );
  }

  Widget _statChipWide(
      {required IconData icon,
      required String label,
      required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: _accent),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: _secondaryLabel,
                  letterSpacing: 0.2)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _label,
                  height: 1)),
        ],
      ),
    );
  }

  // ── Inline Settings Row ──
  Widget _buildSettingsRow(MeterProvider meter) {
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
    required VoidCallback onTapEdit,
    required VoidCallback onSave,
  }) {
    return GestureDetector(
      onTap: isEditing ? null : onTapEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
  Widget _buildStartButton(MeterProvider meter) {
    final isRunning = meter.isRunning;
    return GestureDetector(
      onTap: () => isRunning ? meter.stopTrip() : meter.startTrip(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(14),
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
              isRunning ? 'Stop Trip' : 'Start New Trip',
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
