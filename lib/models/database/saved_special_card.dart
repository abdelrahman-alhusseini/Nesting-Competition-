class SavedSpecialCard {
  const SavedSpecialCard({
    required this.id,
    required this.cardDrawId,
    required this.cardCode,
    required this.title,
    required this.description,
    required this.bookingsRemaining,
    required this.createdAt,
  });

  final String id;
  final String cardDrawId;
  final String cardCode;
  final String title;
  final String description;
  final int bookingsRemaining;
  final DateTime createdAt;

  factory SavedSpecialCard.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> metadata =
        (json['metadata'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return SavedSpecialCard(
      id: json['id'] as String,
      cardDrawId: (json['card_draw_id'] as String?) ?? '',
      cardCode: (json['card_code'] as String?) ?? '',
      title: (metadata['title'] as String?) ?? 'Special Card',
      description: (metadata['description'] as String?) ?? '',
      bookingsRemaining: (json['bookings_remaining'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse((json['created_at'] as String?) ?? '')?.toLocal() ?? DateTime.now(),
    );
  }
}
