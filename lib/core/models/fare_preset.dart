enum FarePresetId {
  regularTaxi,
  tnvs,
  tricycle,
  jeepney,
  fuelBased,
}

/// Immutable LTFRB / custom fare matrix preset.
class FarePreset {
  final FarePresetId id;
  final String name;
  final String description;
  final double flagdown;
  final double ratePerKm;
  final double waitingPerMinute;
  final bool isFuelBased;

  const FarePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.flagdown,
    required this.ratePerKm,
    required this.waitingPerMinute,
    this.isFuelBased = false,
  });

  static const List<FarePreset> presets = [
    FarePreset(
      id: FarePresetId.regularTaxi,
      name: 'Regular Taxi',
      description: 'LTFRB flagdown + ₱/km + waiting',
      flagdown: 45.0,
      ratePerKm: 13.50,
      waitingPerMinute: 2.0,
    ),
    FarePreset(
      id: FarePresetId.tnvs,
      name: 'TNVS / Ride-Hailing',
      description: 'App-style flagdown with variable km rate',
      flagdown: 50.0,
      ratePerKm: 15.0,
      waitingPerMinute: 2.0,
    ),
    FarePreset(
      id: FarePresetId.tricycle,
      name: 'Tricycle',
      description: 'Custom tricycle negotiated rates',
      flagdown: 20.0,
      ratePerKm: 10.0,
      waitingPerMinute: 1.0,
    ),
    FarePreset(
      id: FarePresetId.jeepney,
      name: 'Jeepney Custom',
      description: 'Custom jeepney / shared rates',
      flagdown: 13.0,
      ratePerKm: 2.0,
      waitingPerMinute: 0.0,
    ),
    FarePreset(
      id: FarePresetId.fuelBased,
      name: 'Fuel-Based Meter',
      description: 'Original BiyaheMeter fuel cost formula',
      flagdown: 45.0,
      ratePerKm: 0.0,
      waitingPerMinute: 2.0,
      isFuelBased: true,
    ),
  ];

  static FarePreset byId(FarePresetId id) =>
      presets.firstWhere((p) => p.id == id, orElse: () => presets.first);
}
