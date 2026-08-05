enum CardTone { neutral, positive, negative, special }

class CardOutcome {
  const CardOutcome({
    required this.title,
    required this.description,
    required this.tone,
    this.points = 0,
    this.number,
    this.canGamble = false,
  });

  final String title;
  final String description;
  final CardTone tone;
  final int points;
  final int? number;
  final bool canGamble;

  bool get isSpecial => tone == CardTone.special;
  bool get isNegative => tone == CardTone.negative;
}
