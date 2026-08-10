class GameSettings {
  const GameSettings({
    required this.competitionId,
    this.maxPendingDraws = 3,
    this.maxSavedSpecialCards = 1,
    this.specialExpiryBookings = 5,
    this.normalSpecialChance = 0.05,
    this.crossSellSpecialChance = 0.50,
    this.remodelingSpecialChance = 1.00,
    this.dueInspectionSpecialChance = 0.25,
    this.restorationSpecialChance = 0.15,
    this.numberPoolChance = 0.60,
    this.plusTwoChance = 0.12,
    this.plusFourChance = 0.07,
    this.reverseChance = 0.10,
    this.skipChance = 0.11,
    this.gamblePlusFourChance = 0.50,
    this.gambleMinusSixChance = 0.50,
    this.updatedAt,
  });

  final String competitionId;
  final int maxPendingDraws;
  final int maxSavedSpecialCards;
  final int specialExpiryBookings;
  final double normalSpecialChance;
  final double crossSellSpecialChance;
  final double remodelingSpecialChance;
  final double dueInspectionSpecialChance;
  final double restorationSpecialChance;
  final double numberPoolChance;
  final double plusTwoChance;
  final double plusFourChance;
  final double reverseChance;
  final double skipChance;
  final double gamblePlusFourChance;
  final double gambleMinusSixChance;
  final DateTime? updatedAt;

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic value, double fallback) => (value as num?)?.toDouble() ?? fallback;

    return GameSettings(
      competitionId: (json['competition_id'] as String?) ?? '',
      maxPendingDraws: (json['max_pending_draws'] as num?)?.toInt() ?? 3,
      maxSavedSpecialCards: (json['max_saved_special_cards'] as num?)?.toInt() ?? 3,
      specialExpiryBookings: (json['special_expiry_bookings'] as num?)?.toInt() ?? 5,
      normalSpecialChance: asDouble(json['normal_special_chance'], 0.05),
      crossSellSpecialChance: asDouble(json['cross_sell_special_chance'], 0.50),
      remodelingSpecialChance: asDouble(json['remodeling_special_chance'], 1.00),
      dueInspectionSpecialChance: asDouble(json['due_inspection_special_chance'], 0.25),
      restorationSpecialChance: asDouble(json['restoration_special_chance'], 0.15),
      numberPoolChance: asDouble(json['number_pool_chance'], 0.60),
      plusTwoChance: asDouble(json['plus_two_chance'], 0.12),
      plusFourChance: asDouble(json['plus_four_chance'], 0.07),
      reverseChance: asDouble(json['reverse_chance'], 0.10),
      skipChance: asDouble(json['skip_chance'], 0.11),
      gamblePlusFourChance: asDouble(json['gamble_plus_four_chance'], 0.50),
      gambleMinusSixChance: asDouble(json['gamble_minus_six_chance'], 0.50),
      updatedAt: json['updated_at'] == null ? null : DateTime.tryParse(json['updated_at'] as String)?.toLocal(),
    );
  }

  GameSettings copyWith({
    String? competitionId,
    int? maxPendingDraws,
    int? maxSavedSpecialCards,
    int? specialExpiryBookings,
    double? normalSpecialChance,
    double? crossSellSpecialChance,
    double? remodelingSpecialChance,
    double? dueInspectionSpecialChance,
    double? restorationSpecialChance,
    double? numberPoolChance,
    double? plusTwoChance,
    double? plusFourChance,
    double? reverseChance,
    double? skipChance,
    double? gamblePlusFourChance,
    double? gambleMinusSixChance,
    DateTime? updatedAt,
  }) {
    return GameSettings(
      competitionId: competitionId ?? this.competitionId,
      maxPendingDraws: maxPendingDraws ?? this.maxPendingDraws,
      maxSavedSpecialCards: maxSavedSpecialCards ?? this.maxSavedSpecialCards,
      specialExpiryBookings: specialExpiryBookings ?? this.specialExpiryBookings,
      normalSpecialChance: normalSpecialChance ?? this.normalSpecialChance,
      crossSellSpecialChance: crossSellSpecialChance ?? this.crossSellSpecialChance,
      remodelingSpecialChance: remodelingSpecialChance ?? this.remodelingSpecialChance,
      dueInspectionSpecialChance: dueInspectionSpecialChance ?? this.dueInspectionSpecialChance,
      restorationSpecialChance: restorationSpecialChance ?? this.restorationSpecialChance,
      numberPoolChance: numberPoolChance ?? this.numberPoolChance,
      plusTwoChance: plusTwoChance ?? this.plusTwoChance,
      plusFourChance: plusFourChance ?? this.plusFourChance,
      reverseChance: reverseChance ?? this.reverseChance,
      skipChance: skipChance ?? this.skipChance,
      gamblePlusFourChance: gamblePlusFourChance ?? this.gamblePlusFourChance,
      gambleMinusSixChance: gambleMinusSixChance ?? this.gambleMinusSixChance,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'max_pending_draws': maxPendingDraws,
      'max_saved_special_cards': maxSavedSpecialCards,
      'special_expiry_bookings': specialExpiryBookings,
      'normal_special_chance': normalSpecialChance,
      'cross_sell_special_chance': crossSellSpecialChance,
      'remodeling_special_chance': remodelingSpecialChance,
      'due_inspection_special_chance': dueInspectionSpecialChance,
      'restoration_special_chance': restorationSpecialChance,
      'number_pool_chance': numberPoolChance,
      'plus_two_chance': plusTwoChance,
      'plus_four_chance': plusFourChance,
      'reverse_chance': reverseChance,
      'skip_chance': skipChance,
      'gamble_plus_four_chance': gamblePlusFourChance,
      'gamble_minus_six_chance': gambleMinusSixChance,
    };
  }
}
