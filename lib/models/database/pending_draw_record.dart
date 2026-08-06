import '../booking_type.dart';

class PendingDrawRecord {
  const PendingDrawRecord({
    required this.id,
    required this.bookingType,
    required this.createdAt,
  });

  final String id;
  final BookingType bookingType;
  final DateTime createdAt;

  factory PendingDrawRecord.fromJson(Map<String, dynamic> json) {
    return PendingDrawRecord(
      id: json['id'] as String,
      bookingType: BookingTypeX.fromDatabase(
        (json['booking_type'] as String?) ?? 'normal',
      ),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}
