class AdminStats {
  const AdminStats({
    this.totalBookings = 0,
    this.approved = 0,
    this.pending = 0,
    this.rejected = 0,
    this.totalUsers = 0,
  });

  final int totalBookings;
  final int approved;
  final int pending;
  final int rejected;
  final int totalUsers;

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalBookings: (json['total_bookings'] as num?)?.toInt() ?? 0,
      approved: (json['approved'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      rejected: (json['rejected'] as num?)?.toInt() ?? 0,
      totalUsers: (json['total_users'] as num?)?.toInt() ?? 0,
    );
  }
}
