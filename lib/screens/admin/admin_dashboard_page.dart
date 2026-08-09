import 'package:flutter/material.dart';

import '../../models/app_role.dart';
import '../../models/booking_type.dart';
import '../../models/database/booking_record.dart';
import '../../models/navigation.dart';
import '../../state/app_controller.dart';
import 'admin_image_scaffold.dart';
import 'admin_live_scaffold.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final int agents = controller.users.where((user) => user.role == AppRole.agent).length;
    final List<BookingRecord> bookings = controller.pendingBookings.take(6).toList();

    return AdminImageScaffold(
      controller: controller,
      assetPath: 'assets/images/v11/admin_dashboard.png',
      children: <Widget>[
        _statValue(left: 936, top: 358, width: 122, value: controller.adminStats.pending),
        _statValue(left: 1104, top: 358, width: 122, value: agents),
        _statValue(left: 1273, top: 358, width: 122, value: controller.adminPendingDrawCount),
        _statValue(left: 1441, top: 358, width: 122, value: controller.activity.length),

        _quickAction(
          left: 307,
          top: 512,
          width: 158,
          height: 148,
          label: 'Review pending approvals',
          onTap: () => controller.openAdminPage(AdminPage.approvals),
        ),
        _quickAction(
          left: 477,
          top: 512,
          width: 158,
          height: 148,
          label: 'Manage draws',
          onTap: () => controller.openAdminPage(AdminPage.testDraw),
        ),
        _quickAction(
          left: 307,
          top: 670,
          width: 158,
          height: 148,
          label: 'Manage agents',
          onTap: () => controller.openAdminPage(AdminPage.users),
        ),
        _quickAction(
          left: 477,
          top: 670,
          width: 158,
          height: 148,
          label: 'System settings',
          onTap: () => controller.openAdminPage(AdminPage.settings),
        ),

        Positioned(
          left: 697,
          top: 551,
          width: 893,
          height: 290,
          child: bookings.isEmpty
              ? adminEmptyMessage(
                  icon: Icons.inbox_outlined,
                  title: 'No bookings awaiting approval',
                  message: 'New booking requests from agents will appear here automatically.',
                )
              : _DashboardBookingRows(
                  bookings: bookings,
                  onReview: () => controller.openAdminPage(AdminPage.approvals),
                ),
        ),
      ],
    );
  }

  Widget _statValue({required double left, required double top, required double width, required int value}) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: 58,
      child: Center(
        child: Text(
          '$value',
          style: const TextStyle(color: adminNavy, fontSize: 28, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _quickAction({
    required double left,
    required double top,
    required double width,
    required double height,
    required String label,
    required VoidCallback onTap,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            hoverColor: adminBabyBlue.withValues(alpha: 0.30),
            splashColor: adminBlue.withValues(alpha: 0.12),
          ),
        ),
      ),
    );
  }
}

class _DashboardBookingRows extends StatelessWidget {
  const _DashboardBookingRows({required this.bookings, required this.onReview});

  final List<BookingRecord> bookings;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (final BookingRecord booking in bookings)
          SizedBox(
            height: 42,
            child: Row(
              children: <Widget>[
                SizedBox(width: 126, child: _cell(booking.jobId ?? '—', bold: true)),
                SizedBox(width: 170, child: _cell(booking.bookingType.label)),
                SizedBox(width: 145, child: _cell(booking.agentName)),
                const SizedBox(width: 145),
                SizedBox(width: 140, child: _cell(_date(booking.submittedAt))),
                SizedBox(
                  width: 110,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: const Color(0xFFFFF4DC), borderRadius: BorderRadius.circular(10)),
                      child: const Text('PENDING', style: TextStyle(color: Color(0xFFB67618), fontSize: 10, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onReview,
                      style: TextButton.styleFrom(foregroundColor: adminBlue, visualDensity: VisualDensity.compact),
                      child: const Text('Review', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(String text, {bool bold = false}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: adminNavy, fontSize: 11, fontWeight: bold ? FontWeight.w800 : FontWeight.w600),
      ),
    );
  }

  static String _date(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
