class ActivityRecord {
  const ActivityRecord({
    required this.id,
    required this.message,
    required this.createdAt,
    required this.eventType,
    required this.actorName,
    required this.metadata,
  });

  final String id;
  final String message;
  final DateTime createdAt;
  final String eventType;
  final String actorName;
  final Map<String, dynamic> metadata;

  static const Set<String> agentGameEventTypes = <String>{
    'card_drawn',
    'special_card_drawn',
    'even_card_resolved',
    'special_card_saved',
    'special_card_expired',
    // Kept here so the Activity Feed automatically supports these event names
    // when the matching card-use RPCs are added/used.
    'card_used',
    'card_applied',
    'special_card_used',
    'special_card_applied',
    'shield_activated',
    'shield_triggered',
  };

  bool get isAgentGameActivity => agentGameEventTypes.contains(eventType);

  String get playerMessage {
    final String player = actorName.trim().isEmpty ? 'Player' : actorName.trim();

    switch (eventType) {
      case 'card_drawn':
        return _replaceGenericPlayer(message, player);
      case 'special_card_drawn':
        return _replaceGenericPlayer(message, player);
      case 'even_card_resolved':
        final bool gambled = metadata['gambled'] == true;
        final dynamic points = metadata['points'];
        if (points is num) {
          final int value = points.toInt();
          final String signed = value > 0 ? '+$value' : '$value';
          return gambled
              ? '$player gambled an even-number card and received $signed Points.'
              : '$player kept an even-number card and received $signed Points.';
        }
        return _replaceGenericPlayer(message, player);
      case 'special_card_saved':
        return '$player saved a special card for later use.';
      case 'special_card_expired':
        return "$player's saved special card expired.";
      case 'card_used':
      case 'card_applied':
        return _replaceGenericPlayer(message, player, fallback: '$player used a card.');
      case 'shield_activated':
        return '$player activated a Shield.';
      case 'shield_triggered':
        return "$player's Shield blocked a negative effect.";
      case 'special_card_used':
      case 'special_card_applied':
        return _replaceGenericPlayer(
          message,
          player,
          fallback: '$player used a special card.',
        );
      default:
        return _replaceGenericPlayer(message, player);
    }
  }

  factory ActivityRecord.fromJson(Map<String, dynamic> json) {
    final dynamic actorRaw = json['actor'];
    String actorName = '';
    if (actorRaw is Map<String, dynamic>) {
      actorName = ((actorRaw['display_name'] as String?) ??
              (actorRaw['username'] as String?) ??
              '')
          .trim();
    } else if (actorRaw is List && actorRaw.isNotEmpty) {
      final dynamic first = actorRaw.first;
      if (first is Map<String, dynamic>) {
        actorName = ((first['display_name'] as String?) ??
                (first['username'] as String?) ??
                '')
            .trim();
      }
    }

    final dynamic metadataRaw = json['metadata'];
    return ActivityRecord(
      id: json['id'] as String,
      message: (json['message'] as String?) ?? '',
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      eventType: (json['event_type'] as String?) ?? '',
      actorName: actorName,
      metadata: metadataRaw is Map<String, dynamic>
          ? Map<String, dynamic>.from(metadataRaw)
          : <String, dynamic>{},
    );
  }

  static String _replaceGenericPlayer(
    String source,
    String player, {
    String? fallback,
  }) {
    final String trimmed = source.trim();
    if (trimmed.isEmpty) return fallback ?? '$player performed a card action.';

    return trimmed
        .replaceFirst(RegExp(r'^A player\b', caseSensitive: false), player)
        .replaceFirst(RegExp(r"^A player'?s\b", caseSensitive: false), "$player's")
        .replaceFirst(RegExp(r'^An agent\b', caseSensitive: false), player);
  }
}
