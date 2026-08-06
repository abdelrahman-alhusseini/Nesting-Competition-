import '../booking_type.dart';

class BookingRecord {
  const BookingRecord({
    required this.id,
    required this.agentId,
    required this.agentName,
    required this.jobUrl,
    required this.jobId,
    required this.bookingType,
    required this.status,
    required this.submittedAt,
    this.rejectionReason,
  });

  final String id;
  final String agentId;
  final String agentName;
  final String jobUrl;
  final String? jobId;
  final BookingType bookingType;
  final String status;
  final DateTime submittedAt;
  final String? rejectionReason;

  factory BookingRecord.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? profile = json['profiles'] as Map<String, dynamic>?;
    return BookingRecord(
      id: json['id'] as String,
      agentId: json['agent_id'] as String,
      agentName: (profile?['display_name'] as String?) ??
          (profile?['username'] as String?) ??
          'Agent',
      jobUrl: json['job_url'] as String,
      jobId: json['job_id'] as String?,
      bookingType: BookingTypeX.fromDatabase((json['booking_type'] as String?) ?? 'normal'),
      status: (json['status'] as String?) ?? 'pending',
      submittedAt: DateTime.parse(json['submitted_at'] as String).toLocal(),
      rejectionReason: json['rejection_reason'] as String?,
    );
  }
}
