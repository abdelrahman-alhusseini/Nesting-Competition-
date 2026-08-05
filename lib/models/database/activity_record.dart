class ActivityRecord {
  const ActivityRecord({
    required this.id,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String message;
  final DateTime createdAt;

  factory ActivityRecord.fromJson(Map<String, dynamic> json) {
    return ActivityRecord(
      id: json['id'] as String,
      message: (json['message'] as String?) ?? '',
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}
