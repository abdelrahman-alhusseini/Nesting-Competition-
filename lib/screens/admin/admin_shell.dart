import 'package:flutter/material.dart';

import '../../models/app_role.dart';
import '../../models/booking_type.dart';
import '../../models/database/booking_record.dart';
import '../../models/database/user_profile.dart';
import '../../models/navigation.dart';
import '../../state/app_controller.dart';
import '../../widgets/design_canvas.dart';
import '../../widgets/image_hotspot.dart';
import '../../widgets/neon_widgets.dart';
import '../shared/card_reveal_content.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        assetPath: controller.adminPage == AdminPage.cardReveal
            ? 'assets/images/card_reveal.png'
            : 'assets/images/admin_dashboard.png',
        children: <Widget>[
          ..._sidebarHotspots(),
          Positioned(
            left: 235,
            top: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(28, 24, 30, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[Color(0xFB020B1A), Color(0xF8071830)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: _content(context),
            ),
          ),
          _adminCard(),
        ],
      ),
    );
  }

  List<Widget> _sidebarHotspots() {
    const double firstY = 210;
    const double step = 55;
    const double width = 215;
    const double height = 48;
    Rect row(int index) => Rect.fromLTWH(10, firstY + index * step, width, height);

    return <Widget>[
      ImageHotspot(rect: row(0), label: 'Admin Dashboard', onTap: () => controller.openAdminPage(AdminPage.dashboard)),
      ImageHotspot(rect: row(1), label: 'Booking Approvals', onTap: () => controller.openAdminPage(AdminPage.approvals)),
      ImageHotspot(rect: row(2), label: 'Users', onTap: () => controller.openAdminPage(AdminPage.users)),
      ImageHotspot(rect: row(3), label: 'Unlimited Test Draw', onTap: () => controller.openAdminPage(AdminPage.testDraw)),
      ImageHotspot(rect: row(4), label: 'Adjust Points', onTap: () => controller.openAdminPage(AdminPage.adjustPoints)),
      ImageHotspot(rect: row(5), label: 'Audit History', onTap: () => controller.openAdminPage(AdminPage.auditHistory)),
      ImageHotspot(rect: row(6), label: 'Settings', onTap: () => controller.openAdminPage(AdminPage.settings)),
    ];
  }

  Widget _adminCard() {
    return Positioned(
      left: 19,
      bottom: 24,
      width: 198,
      height: 124,
      child: NeonPanel(
        padding: const EdgeInsets.all(12),
        borderColor: const Color(0xFF7132BB),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const CircleAvatar(
                  radius: 23,
                  backgroundColor: Color(0xFF5B2D99),
                  child: Icon(Icons.admin_panel_settings),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(controller.username, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const Text('Administrator', style: TextStyle(color: Color(0xFFB269FF))),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: controller.logout,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('LOG OUT'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    switch (controller.adminPage) {
      case AdminPage.dashboard:
        return _dashboard(context);
      case AdminPage.approvals:
        return _approvals(context);
      case AdminPage.users:
        return _users(context);
      case AdminPage.testDraw:
        return _testDraw();
      case AdminPage.cardReveal:
        return CardRevealContent(controller: controller, adminTest: true);
      case AdminPage.adjustPoints:
        return _adjustPoints(context);
      case AdminPage.auditHistory:
        return _auditHistory();
      case AdminPage.settings:
        return _settings();
    }
  }

  Widget _dashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(Icons.shield, size: 46, color: Color(0xFF4B8FFF)),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('ADMIN DASHBOARD', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
                  Text('Manage bookings, users, points, and card testing.', style: TextStyle(fontSize: 17, color: Color(0xFFB7C4D4))),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => controller.openAdminPage(AdminPage.testDraw),
              style: purpleButtonStyle(),
              icon: const Icon(Icons.casino),
              label: const Text('OPEN TEST DRAW'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: <Widget>[
            Expanded(child: _AdminMetric(icon: Icons.receipt_long, label: 'Total bookings', value: '${controller.adminStats.totalBookings}')),
            const SizedBox(width: 14),
            Expanded(child: _AdminMetric(icon: Icons.check_circle, label: 'Approved', value: '${controller.adminStats.approved}', color: const Color(0xFF5BD35B))),
            const SizedBox(width: 14),
            Expanded(child: _AdminMetric(icon: Icons.schedule, label: 'Pending', value: '${controller.adminStats.pending}', color: gold)),
            const SizedBox(width: 14),
            Expanded(child: _AdminMetric(icon: Icons.cancel, label: 'Rejected', value: '${controller.adminStats.rejected}', color: const Color(0xFFFF5151))),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: NeonPanel(
                  child: controller.pendingBookings.isEmpty
                      ? const EmptyState(
                          icon: Icons.fact_check_outlined,
                          title: 'No pending bookings',
                          message: 'New agent submissions will appear here for approval.',
                        )
                      : ListView.separated(
                          itemCount: controller.pendingBookings.take(6).length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (BuildContext context, int index) {
                            final BookingRecord booking = controller.pendingBookings[index];
                            return ListTile(
                              leading: const Icon(Icons.link, color: gold),
                              title: Text(booking.jobId == null ? booking.agentName : 'Job ${booking.jobId}'),
                              subtitle: Text('${booking.agentName} • ${booking.bookingType.label}'),
                              trailing: TextButton(
                                onPressed: () => _showReviewDialog(context, booking),
                                child: const Text('REVIEW'),
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: NeonPanel(
                        borderColor: const Color(0xFF6F2EC0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            const Text('QUICK ACTIONS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              onPressed: () => controller.openAdminPage(AdminPage.testDraw),
                              style: purpleButtonStyle(),
                              icon: const Icon(Icons.style),
                              label: const Text('UNLIMITED CARD TEST'),
                            ),
                            const SizedBox(height: 14),
                            FilledButton.icon(
                              onPressed: () => _showManualDrawDialog(context),
                              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1C58C8), padding: const EdgeInsets.symmetric(vertical: 18)),
                              icon: const Icon(Icons.add_card),
                              label: const Text('GRANT AGENT TEST DRAW'),
                            ),
                            const Spacer(),
                            const Text(
                              'Admin card tests do not change player points, bookings, or activity.',
                              style: TextStyle(color: Color(0xFFAFC0D5)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Expanded(
                      child: NeonPanel(
                        child: EmptyState(
                          icon: Icons.history,
                          title: 'No admin activity',
                          message: 'Approvals and manual changes will be audited here.',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _approvals(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text('BOOKING APPROVALS', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
        const Text('Open each submitted ServiceTitan link and validate its booking type.', style: TextStyle(fontSize: 17, color: Color(0xFFB7C4D4))),
        const SizedBox(height: 24),
        Expanded(
          child: NeonPanel(
            child: controller.pendingBookings.isEmpty
                ? const EmptyState(
                    icon: Icons.approval_outlined,
                    title: 'No bookings awaiting approval',
                    message: 'New unique booking links submitted by agents will appear on this page.',
                  )
                : ListView.separated(
                    itemCount: controller.pendingBookings.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (BuildContext context, int index) {
                      final BookingRecord booking = controller.pendingBookings[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
                        title: Text(booking.jobId == null ? 'ServiceTitan booking' : 'Job ${booking.jobId}'),
                        subtitle: Text(
                          '${booking.agentName} • ${booking.bookingType.label}\n${booking.jobUrl}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: FilledButton(
                          onPressed: () => _showReviewDialog(context, booking),
                          style: goldButtonStyle(),
                          child: const Text('REVIEW'),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _users(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(child: Text('USERS', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900))),
            FilledButton.icon(
              onPressed: () => _showCreateUserDialog(context),
              style: goldButtonStyle(),
              icon: const Icon(Icons.person_add),
              label: const Text('ADD USER'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: NeonPanel(
            child: controller.users.isEmpty
                ? const EmptyState(
                    icon: Icons.group_outlined,
                    title: 'No accounts found',
                    message: 'Create the first agent account using Add User.',
                  )
                : ListView.separated(
                    itemCount: controller.users.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (BuildContext context, int index) {
                      final UserProfile user = controller.users[index];
                      return SwitchListTile(
                        value: user.isActive,
                        onChanged: user.id == controller.profile?.id
                            ? null
                            : (bool value) async {
                                final String? error = await controller.setUserActive(user, value);
                                if (context.mounted && error != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                                }
                              },
                        secondary: CircleAvatar(
                          backgroundColor: user.role == AppRole.admin
                              ? const Color(0xFF6328A0)
                              : const Color(0xFF214B7A),
                          child: Icon(user.role == AppRole.admin ? Icons.admin_panel_settings : Icons.person),
                        ),
                        title: Text(user.displayName),
                        subtitle: Text('@${user.username} • ${user.role.name.toUpperCase()}'),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _testDraw() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Row(
          children: <Widget>[
            Icon(Icons.science, size: 48, color: Color(0xFFB266FF)),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('UNLIMITED CARD TEST', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
                  Text('Choose the booking type first, then test card animations, sounds, chances, and the even-number gamble.', style: TextStyle(fontSize: 17, color: Color(0xFFB7C4D4))),
                ],
              ),
            ),
            Chip(avatar: Icon(Icons.all_inclusive, color: gold), label: Text('UNLIMITED')),
          ],
        ),
        const SizedBox(height: 28),
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(
                child: NeonPanel(
                  borderColor: const Color(0xFF6E30B8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text('1. SELECT BOOKING TYPE', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<BookingType>(
                        value: controller.adminTestBookingType,
                        decoration: const InputDecoration(
                          labelText: 'Booking type used for this draw',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color(0xFF020B19),
                        ),
                        items: BookingType.values
                            .map((BookingType type) => DropdownMenuItem<BookingType>(value: type, child: Text(type.label)))
                            .toList(),
                        onChanged: (BookingType? value) {
                          if (value != null) controller.setAdminTestBookingType(value);
                        },
                      ),
                      const SizedBox(height: 22),
                      _ChanceRow(label: 'Special-card chance', value: '${(controller.adminTestBookingType.specialChance * 100).round()}%'),
                      const Divider(height: 34),
                      const Text('Regular pool', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      const Text('60% number • 12% +2 • 7% +4 • 10% reverse • 11% skip', style: TextStyle(fontSize: 17, color: Color(0xFFB8C7DA))),
                      const SizedBox(height: 16),
                      const Text('Even numbers let you keep +1 or gamble with a 50% chance of +4 and a 50% chance of -6.', style: TextStyle(fontSize: 17, color: Color(0xFFB8C7DA))),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: controller.drawUnlimitedAdminTestCard,
                        style: goldButtonStyle(),
                        icon: const Icon(Icons.casino),
                        label: const Text('DRAW TEST CARD'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 22),
              const Expanded(
                child: NeonPanel(
                  child: EmptyState(
                    icon: Icons.animation,
                    title: 'Ready to test',
                    message: 'Every press creates a fresh independent draw. Test draws are unlimited and never alter real game data.',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _adjustPoints(BuildContext context) {
    final List<UserProfile> agents = controller.users
        .where((UserProfile user) => user.role == AppRole.agent && user.isActive)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text('ADJUST POINTS', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
        const Text('Every manual score change requires a reason and is written to the audit history.', style: TextStyle(fontSize: 17, color: Color(0xFFB7C4D4))),
        const SizedBox(height: 24),
        Expanded(
          child: NeonPanel(
            child: agents.isEmpty
                ? const EmptyState(
                    icon: Icons.tune,
                    title: 'No active agents',
                    message: 'Create an agent account before adjusting points.',
                  )
                : Center(
                    child: FilledButton.icon(
                      onPressed: () => _showAdjustPointsDialog(context),
                      style: goldButtonStyle(),
                      icon: const Icon(Icons.tune),
                      label: const Text('OPEN POINT ADJUSTMENT'),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _auditHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text('AUDIT HISTORY', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
        const Text('Approvals, rejections, draw grants, reversals, and point changes are recorded here.', style: TextStyle(fontSize: 17, color: Color(0xFFB7C4D4))),
        const SizedBox(height: 24),
        Expanded(
          child: NeonPanel(
            child: controller.auditHistory.isEmpty
                ? const EmptyState(
                    icon: Icons.history_toggle_off,
                    title: 'No audit entries',
                    message: 'Admin actions will appear here.',
                  )
                : ListView.separated(
                    itemCount: controller.auditHistory.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (BuildContext context, int index) {
                      final Map<String, dynamic> item = controller.auditHistory[index];
                      final Map<String, dynamic>? actor = item['profiles'] as Map<String, dynamic>?;
                      return ListTile(
                        leading: const Icon(Icons.history, color: gold),
                        title: Text((item['action'] as String? ?? 'action').replaceAll('_', ' ').toUpperCase()),
                        subtitle: Text('By ${actor?['display_name'] ?? actor?['username'] ?? 'System'} • ${item['entity_type'] ?? ''}'),
                        trailing: Text((item['created_at'] as String? ?? '').replaceFirst('T', ' ').split('.').first),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _showReviewDialog(BuildContext context, BookingRecord booking) async {
    BookingType selectedType = booking.bookingType;
    final TextEditingController reasonController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => AlertDialog(
          backgroundColor: navy,
          title: Text(booking.jobId == null ? 'Review booking' : 'Review Job ${booking.jobId}'),
          content: SizedBox(
            width: 650,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SelectableText(booking.jobUrl, style: const TextStyle(color: Color(0xFF8BB7FF))),
                const SizedBox(height: 18),
                Text('Submitted by: ${booking.agentName}'),
                const SizedBox(height: 18),
                DropdownButtonFormField<BookingType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Validated booking type'),
                  items: BookingType.values
                      .map((BookingType type) => DropdownMenuItem<BookingType>(
                            value: type,
                            child: Text(type.label),
                          ))
                      .toList(),
                  onChanged: (BookingType? value) {
                    if (value != null) setState(() => selectedType = value);
                  },
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Rejection reason (only needed when rejecting)',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB32632)),
              onPressed: controller.busy
                  ? null
                  : () async {
                      final String? error = await controller.reviewBooking(
                        booking: booking,
                        approve: false,
                        correctedType: selectedType,
                        rejectionReason: reasonController.text,
                      );
                      if (!dialogContext.mounted) return;
                      if (error != null) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(error)));
                        return;
                      }
                      Navigator.pop(dialogContext);
                    },
              child: const Text('REJECT'),
            ),
            FilledButton(
              style: goldButtonStyle(),
              onPressed: controller.busy
                  ? null
                  : () async {
                      final String? error = await controller.reviewBooking(
                        booking: booking,
                        approve: true,
                        correctedType: selectedType,
                      );
                      if (!dialogContext.mounted) return;
                      if (error != null) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(error)));
                        return;
                      }
                      Navigator.pop(dialogContext);
                    },
              child: const Text('APPROVE'),
            ),
          ],
        ),
      ),
    );
    reasonController.dispose();
  }

  Future<void> _showCreateUserDialog(BuildContext context) async {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController displayNameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    AppRole role = AppRole.agent;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => AlertDialog(
          backgroundColor: navy,
          title: const Text('Create user account'),
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: displayNameController,
                  decoration: const InputDecoration(labelText: 'Display name'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    helperText: 'At least 6 characters',
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<AppRole>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: AppRole.values
                      .map((AppRole value) => DropdownMenuItem<AppRole>(
                            value: value,
                            child: Text(value.name.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (AppRole? value) {
                    if (value != null) setState(() => role = value);
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL')),
            FilledButton(
              style: goldButtonStyle(),
              onPressed: controller.busy
                  ? null
                  : () async {
                      final String? error = await controller.createUser(
                        username: usernameController.text,
                        displayName: displayNameController.text,
                        password: passwordController.text,
                        role: role,
                      );
                      if (!dialogContext.mounted) return;
                      if (error != null) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(error)));
                        return;
                      }
                      Navigator.pop(dialogContext);
                    },
              child: const Text('CREATE USER'),
            ),
          ],
        ),
      ),
    );

    usernameController.dispose();
    displayNameController.dispose();
    passwordController.dispose();
  }

  Future<void> _showManualDrawDialog(BuildContext context) async {
    final List<UserProfile> agents = controller.users
        .where((UserProfile user) => user.role == AppRole.agent && user.isActive)
        .toList();
    if (agents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create an active agent first.')));
      return;
    }

    UserProfile selectedAgent = agents.first;
    BookingType selectedType = BookingType.normal;
    final TextEditingController reasonController = TextEditingController(text: 'Manual admin draw');

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => AlertDialog(
          backgroundColor: navy,
          title: const Text('Grant manual draw'),
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DropdownButtonFormField<UserProfile>(
                  value: selectedAgent,
                  decoration: const InputDecoration(labelText: 'Agent'),
                  items: agents
                      .map((UserProfile user) => DropdownMenuItem<UserProfile>(
                            value: user,
                            child: Text(user.displayName),
                          ))
                      .toList(),
                  onChanged: (UserProfile? value) {
                    if (value != null) setState(() => selectedAgent = value);
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<BookingType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Booking type used for the draw'),
                  items: BookingType.values
                      .map((BookingType type) => DropdownMenuItem<BookingType>(
                            value: type,
                            child: Text(type.label),
                          ))
                      .toList(),
                  onChanged: (BookingType? value) {
                    if (value != null) setState(() => selectedType = value);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(labelText: 'Reason'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL')),
            FilledButton(
              style: goldButtonStyle(),
              onPressed: controller.busy
                  ? null
                  : () async {
                      final String? error = await controller.grantAgentDraw(
                        agentId: selectedAgent.id,
                        bookingType: selectedType,
                        reason: reasonController.text,
                      );
                      if (!dialogContext.mounted) return;
                      if (error != null) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(error)));
                        return;
                      }
                      Navigator.pop(dialogContext);
                    },
              child: const Text('GRANT DRAW'),
            ),
          ],
        ),
      ),
    );
    reasonController.dispose();
  }

  Future<void> _showAdjustPointsDialog(BuildContext context) async {
    final List<UserProfile> agents = controller.users
        .where((UserProfile user) => user.role == AppRole.agent && user.isActive)
        .toList();
    if (agents.isEmpty) return;

    UserProfile selectedAgent = agents.first;
    final TextEditingController amountController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => AlertDialog(
          backgroundColor: navy,
          title: const Text('Adjust agent points'),
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DropdownButtonFormField<UserProfile>(
                  value: selectedAgent,
                  decoration: const InputDecoration(labelText: 'Agent'),
                  items: agents
                      .map((UserProfile user) => DropdownMenuItem<UserProfile>(
                            value: user,
                            child: Text(user.displayName),
                          ))
                      .toList(),
                  onChanged: (UserProfile? value) {
                    if (value != null) setState(() => selectedAgent = value);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Point change',
                    hintText: 'Use a negative number to subtract',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(labelText: 'Required reason'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL')),
            FilledButton(
              style: goldButtonStyle(),
              onPressed: controller.busy
                  ? null
                  : () async {
                      final int? amount = int.tryParse(amountController.text.trim());
                      if (amount == null || amount == 0) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('Enter a non-zero whole number.')),
                        );
                        return;
                      }
                      final String? error = await controller.adjustAgentPoints(
                        agentId: selectedAgent.id,
                        amount: amount,
                        reason: reasonController.text,
                      );
                      if (!dialogContext.mounted) return;
                      if (error != null) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(error)));
                        return;
                      }
                      Navigator.pop(dialogContext);
                    },
              child: const Text('APPLY'),
            ),
          ],
        ),
      ),
    );

    amountController.dispose();
    reasonController.dispose();
  }

  Widget _settings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text('GAME SETTINGS', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
        const SizedBox(height: 24),
        Expanded(
          child: NeonPanel(
            child: ListView(
              children: <Widget>[
                const ListTile(leading: Icon(Icons.filter_3, color: gold), title: Text('Maximum pending agent draws'), trailing: Text('3')),
                const Divider(),
                const ListTile(leading: Icon(Icons.auto_awesome, color: Color(0xFFB266FF)), title: Text('Maximum saved special cards'), trailing: Text('1')),
                const Divider(),
                const ListTile(leading: Icon(Icons.event_busy, color: Color(0xFFFF8B3E)), title: Text('Special-card expiry'), trailing: Text('5 bookings')),
                const Divider(),
                ...BookingType.values.map((BookingType type) => ListTile(
                  leading: const Icon(Icons.casino_outlined),
                  title: Text(type.label),
                  trailing: Text('${(type.specialChance * 100).round()}% special chance'),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminMetric extends StatelessWidget {
  const _AdminMetric({required this.icon, required this.label, required this.value, this.color = gold});

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return NeonPanel(
      child: Row(
        children: <Widget>[
          Icon(icon, size: 48, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label.toUpperCase(), style: const TextStyle(color: Color(0xFFB8C7DA), fontWeight: FontWeight.w700)),
                Text(value, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChanceRow extends StatelessWidget {
  const _ChanceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: const TextStyle(fontSize: 19))),
        Text(value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: gold)),
      ],
    );
  }
}
