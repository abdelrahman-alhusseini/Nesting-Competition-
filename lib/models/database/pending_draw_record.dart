import '../booking_type.dart';

class PendingDrawRecord {
  const PendingDrawRecord({
    required this.id,
    required this.bookingType,
    required this.createdAt,
    required this.expiresAt,
  });

  final String id;
  final BookingType bookingType;
  final DateTime createdAt;
  final DateTime expiresAt;

  Duration get timeRemaining => expiresAt.difference(DateTime.now());

  String get expiryLabel {
    final Duration remaining = timeRemaining;
    if (remaining.isNegative || remaining == Duration.zero) return 'expired';
    final int hours = remaining.inHours;
    final int minutes = remaining.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${remaining.inMinutes.clamp(1, 59)}m';
  }

  factory PendingDrawRecord.fromJson(Map<String, dynamic> json) {
    final DateTime created = DateTime.parse(json['created_at'] as String).toLocal();
    final String? expiresRaw = json['expires_at'] as String?;
    return PendingDrawRecord(
      id: json['id'] as String,
      bookingType: BookingTypeX.fromDatabase(
        (json['booking_type'] as String?) ?? 'normal',
      ),
      createdAt: created,
      expiresAt: expiresRaw == null
          ? created.add(const Duration(hours: 24))
          : DateTime.parse(expiresRaw).toLocal(),
    );
  }
}
