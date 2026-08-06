import 'package:flutter/material.dart';

import '../../models/app_role.dart';
import '../../models/booking_type.dart';
import '../../models/card_outcome.dart';
import '../../models/database/booking_record.dart';
import '../../models/database/user_profile.dart';
import '../../models/navigation.dart';
import '../../state/app_controller.dart';
import '../../widgets/design_canvas.dart';
import '../../widgets/image_hotspot.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({required this.controller, super.key});

  final AppController controller;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  AppController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        assetPath: _assetFor(controller.adminPage),
        children: <Widget>[
          ..._navigationHotspots(),
          ..._pageOverlay(context),
          ImageHotspot(
            rect: const Rect.fromLTWH(18, 650, 245, 75),
            label: 'Sign out',
            onTap: controller.logout,
          ),
        ],
      ),
    );
  }

  String _assetFor(AdminPage page) {
    switch (page) {
      case AdminPage.dashboard:
        return 'assets/images/admin_dashboard.png';
      case AdminPage.approvals:
        return 'assets/images/admin_approvals.png';
      case AdminPage.users:
        return 'assets/images/admin_users.png';
      case AdminPage.testDraw:
        return 'assets/images/admin_test_draw.png';
      case AdminPage.cardReveal:
        return 'assets/images/admin_card_reveal.png';
      case AdminPage.adjustPoints:
        return 'assets/images/admin_adjust_points.png';
      case AdminPage.auditHistory:
        return 'assets/images/admin_audit_history.png';
      case AdminPage.settings:
        return 'assets/images/admin_settings.png';
    }
  }

  List<Widget> _navigationHotspots() {
    const double firstY = 330;
    const double step = 48;
    Rect row(int index) => Rect.fromLTWH(14, firstY + index * step, 250, 44);

    return <Widget>[
      ImageHotspot(rect: row(0), label: 'Dashboard', onTap: () => controller.openAdminPage(AdminPage.dashboard)),
      ImageHotspot(rect: row(1), label: 'Booking Approvals', onTap: () => controller.openAdminPage(AdminPage.approvals)),
      ImageHotspot(rect: row(2), label: 'Users', onTap: () => controller.openAdminPage(AdminPage.users)),
      ImageHotspot(rect: row(3), label: 'Manual Draw', onTap: () => controller.openAdminPage(AdminPage.testDraw)),
      ImageHotspot(rect: row(4), label: 'Adjust Points', onTap: () => controller.openAdminPage(AdminPage.adjustPoints)),
      ImageHotspot(rect: row(5), label: 'Audit History', onTap: () => controller.openAdminPage(AdminPage.auditHistory)),
      ImageHotspot(rect: row(6), label: 'Settings', onTap: () => controller.openAdminPage(AdminPage.settings)),
    ];
  }

  List<Widget> _pageOverlay(BuildContext context) {
    switch (controller.adminPage) {
      case AdminPage.dashboard:
        return _dashboardOverlay(context);
      case AdminPage.approvals:
        return _approvalsOverlay(context);
      case AdminPage.users:
        return _usersOverlay(context);
      case AdminPage.testDraw:
        return _testDrawOverlay(context);
      case AdminPage.cardReveal:
        return _cardRevealOverlay(context);
      case AdminPage.adjustPoints:
        return _adjustPointsOverlay(context);
      case AdminPage.auditHistory:
        return _auditOverlay();
      case AdminPage.settings:
        return _settingsOverlay(context);
    }
  }

  List<Widget> _dashboardOverlay(BuildContext context) {
    final List<BookingRecord> pending = controller.pendingBookings.take(5).toList();
    return <Widget>[
      _valueText(946, 318, 124, 48, '${controller.adminStats.pending}'),
      _valueText(1125, 318, 124, 48, '${controller.adminStats.totalUsers}'),
      _valueText(1302, 318, 124, 48, '${controller.pendingDraws}'),
      _valueText(1470, 318, 124, 48, '${controller.activity.length}'),
      for (int i = 0; i < pending.length; i++) ...<Widget>[
        _text(335, 551 + i * 47, 145, 30, pending[i].jobId ?? '—', fontSize: 15),
        _text(505, 551 + i * 47, 175, 30, pending[i].agentName, fontSize: 15),
        _text(700, 551 + i * 47, 180, 30, pending[i].bookingType.label, fontSize: 14),
      ],
      for (int i = 0; i < controller.activity.take(5).length; i++)
        _text(1065, 510 + i * 55, 230, 38, controller.activity[i], fontSize: 14),
      ImageHotspot(
        rect: const Rect.fromLTWH(360, 802, 300, 55),
        label: 'Review all approvals',
        onTap: () => controller.openAdminPage(AdminPage.approvals),
      ),
      ImageHotspot(
        rect: const Rect.fromLTWH(760, 802, 270, 60),
        label: 'Admin tools',
        onTap: () => controller.openAdminPage(AdminPage.testDraw),
      ),
    ];
  }

  List<Widget> _approvalsOverlay(BuildContext context) {
    final List<BookingRecord> rows = controller.pendingBookings.take(8).toList();
    return <Widget>[
      _valueText(430, 230, 190, 55, '${controller.pendingBookings.length}'),
      _valueText(785, 230, 190, 55, '${controller.adminStats.approved}'),
      _valueText(1125, 230, 190, 55, '${controller.adminStats.rejected}'),
      for (int i = 0; i < rows.length; i++) ...<Widget>[
        _text(350, 385 + i * 49, 125, 28, rows[i].jobId ?? '—', fontSize: 14),
        _text(495, 385 + i * 49, 150, 28, rows[i].agentName, fontSize: 14),
        _text(665, 385 + i * 49, 170, 28, rows[i].bookingType.label, fontSize: 13),
        _text(865, 385 + i * 49, 150, 28, _date(rows[i].submittedAt), fontSize: 13),
        ImageHotspot(
          rect: Rect.fromLTWH(1175, 372 + i * 49, 185, 42),
          label: 'Review booking',
          onTap: () => _showReviewDialog(context, rows[i]),
        ),
      ],
    ];
  }

  List<Widget> _usersOverlay(BuildContext context) {
    final List<UserProfile> rows = controller.users.take(5).toList();
    final int agents = controller.users.where((UserProfile item) => item.role == AppRole.agent && item.isActive).length;
    final int admins = controller.users.where((UserProfile item) => item.role == AppRole.admin).length;
    return <Widget>[
      _valueText(450, 223, 170, 54, '${controller.users.length}'),
      _valueText(800, 223, 170, 54, '$agents'),
      _valueText(1150, 223, 170, 54, '$admins'),
      ImageHotspot(
        rect: const Rect.fromLTWH(1145, 405, 165, 65),
        label: 'Create user',
        onTap: () => _showCreateUserDialog(context),
      ),
      for (int i = 0; i < rows.length; i++) ...<Widget>[
        _text(350, 645 + i * 47, 180, 28, rows[i].username, fontSize: 14),
        _text(540, 645 + i * 47, 210, 28, rows[i].displayName, fontSize: 14),
        _text(785, 645 + i * 47, 120, 28, rows[i].role.name.toUpperCase(), fontSize: 14, color: rows[i].role == AppRole.admin ? const Color(0xFFC98AFF) : const Color(0xFF65C9FF)),
        _text(945, 645 + i * 47, 115, 28, rows[i].isActive ? 'ACTIVE' : 'INACTIVE', fontSize: 13, color: rows[i].isActive ? const Color(0xFF62E78B) : const Color(0xFFFF6B72)),
        ImageHotspot(
          rect: Rect.fromLTWH(1115, 635 + i * 47, 160, 40),
          label: 'Toggle user status',
          onTap: () async {
            if (rows[i].id == controller.profile?.id) {
              _message(context, 'You cannot deactivate your own admin account.');
              return;
            }
            final String? error = await controller.setUserActive(rows[i], !rows[i].isActive);
            if (context.mounted && error != null) _message(context, error);
          },
        ),
      ],
    ];
  }

  List<Widget> _testDrawOverlay(BuildContext context) {
    final List<BookingType> types = BookingType.values;
    return <Widget>[
      for (int i = 0; i < types.length; i++)
        ImageHotspot(
          rect: Rect.fromLTWH(285 + i * 120, 245, 112, 175),
          label: types[i].label,
          onTap: () => controller.setAdminTestBookingType(types[i]),
        ),
      _text(340, 430, 510, 38, 'Selected: ${controller.adminTestBookingType.label} • ${(controller.adminTestBookingType.specialChance * 100).round()}% special chance', fontSize: 17, color: const Color(0xFF8DEBFF)),
      ImageHotspot(
        rect: const Rect.fromLTWH(315, 785, 550, 75),
        label: 'Draw test card',
        onTap: controller.drawUnlimitedAdminTestCard,
      ),
    ];
  }

  List<Widget> _cardRevealOverlay(BuildContext context) {
    final CardOutcome? outcome = controller.currentOutcome;
    if (outcome == null) {
      return <Widget>[
        ImageHotspot(
          rect: const Rect.fromLTWH(325, 785, 285, 78),
          label: 'Return to manual draw',
          onTap: controller.returnToAdminTestDraw,
        ),
      ];
    }

    return <Widget>[
      _text(1160, 365, 360, 42, outcome.title, fontSize: 23, color: const Color(0xFFFFC62B), weight: FontWeight.w900),
      _text(1160, 465, 360, 90, outcome.description, fontSize: 16),
      if (outcome.number != null)
        _text(680, 300, 280, 160, '${outcome.number}', fontSize: 92, color: const Color(0xFFFFD35A), align: TextAlign.center, weight: FontWeight.w900),
      ImageHotspot(
        rect: const Rect.fromLTWH(325, 785, 285, 78),
        label: 'Draw again',
        onTap: controller.drawUnlimitedAdminTestCard,
      ),
      ImageHotspot(
        rect: const Rect.fromLTWH(635, 785, 300, 78),
        label: 'Resolve test card',
        onTap: () async {
          if (controller.gamblePending) {
            await controller.gambleEvenCard(adminTest: true);
          } else {
            controller.drawUnlimitedAdminTestCard();
          }
        },
      ),
      ImageHotspot(
        rect: const Rect.fromLTWH(960, 785, 285, 78),
        label: 'Keep one',
        onTap: () async {
          if (controller.gamblePending) {
            await controller.keepEvenCardPoint(adminTest: true);
          } else {
            controller.returnToAdminTestDraw();
          }
        },
      ),
      ImageHotspot(
        rect: const Rect.fromLTWH(1280, 785, 300, 78),
        label: 'Gamble 50/50',
        onTap: () async {
          if (controller.gamblePending) {
            await controller.gambleEvenCard(adminTest: true);
          } else {
            controller.drawUnlimitedAdminTestCard();
          }
        },
      ),
    ];
  }

  List<Widget> _adjustPointsOverlay(BuildContext context) {
    return <Widget>[
      ImageHotspot(
        rect: const Rect.fromLTWH(555, 515, 355, 70),
        label: 'Apply point adjustment',
        onTap: () => _showAdjustPointsDialog(context),
      ),
    ];
  }

  List<Widget> _auditOverlay() {
    final List<Map<String, dynamic>> rows = controller.auditHistory.take(8).toList();
    return <Widget>[
      for (int i = 0; i < rows.length; i++) ...<Widget>[
        _text(350, 410 + i * 46, 160, 28, ((rows[i]['action'] as String?) ?? 'action').replaceAll('_', ' '), fontSize: 13),
        _text(520, 410 + i * 46, 140, 28, (rows[i]['entity_type'] as String?) ?? '—', fontSize: 13),
        _text(675, 410 + i * 46, 170, 28, _actorName(rows[i]), fontSize: 13),
        _text(860, 410 + i * 46, 165, 28, _rawDate(rows[i]['created_at']), fontSize: 12),
      ],
    ];
  }

  List<Widget> _settingsOverlay(BuildContext context) {
    return <Widget>[
      ImageHotspot(
        rect: const Rect.fromLTWH(780, 860, 330, 58),
        label: 'Save changes',
        onTap: () => _message(
          context,
          'The settings artwork is ready. Connect the game_settings update RPC before changing production probabilities.',
        ),
      ),
    ];
  }

  Future<void> _showReviewDialog(BuildContext context, BookingRecord booking) async {
    BookingType corrected = booking.bookingType;
    final TextEditingController rejectionReason = TextEditingController();
    String? error;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF07152B),
              title: Text('Review ${booking.jobId == null ? 'booking' : 'job ${booking.jobId}'}'),
              content: SizedBox(
                width: 620,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SelectableText(booking.jobUrl),
                    const SizedBox(height: 14),
                    Text('Submitted by ${booking.agentName}'),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<BookingType>(
                      initialValue: corrected,
                      decoration: const InputDecoration(labelText: 'Confirmed booking type'),
                      items: BookingType.values
                          .map((BookingType type) => DropdownMenuItem<BookingType>(value: type, child: Text(type.label)))
                          .toList(),
                      onChanged: (BookingType? value) {
                        if (value != null) setDialogState(() => corrected = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: rejectionReason,
                      decoration: const InputDecoration(labelText: 'Rejection reason (only required when rejecting)'),
                    ),
                    if (error != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(error!, style: const TextStyle(color: Color(0xFFFF6B72))),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC93645)),
                  onPressed: controller.busy
                      ? null
                      : () async {
                          final String? result = await controller.reviewBooking(
                            booking: booking,
                            approve: false,
                            correctedType: corrected,
                            rejectionReason: rejectionReason.text,
                          );
                          if (!dialogContext.mounted) return;
                          if (result == null) {
                            Navigator.pop(dialogContext);
                          } else {
                            setDialogState(() => error = result);
                          }
                        },
                  child: const Text('Reject'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2C9A58)),
                  onPressed: controller.busy
                      ? null
                      : () async {
                          final String? result = await controller.reviewBooking(
                            booking: booking,
                            approve: true,
                            correctedType: corrected,
                          );
                          if (!dialogContext.mounted) return;
                          if (result == null) {
                            Navigator.pop(dialogContext);
                          } else {
                            setDialogState(() => error = result);
                          }
                        },
                  child: const Text('Approve'),
                ),
              ],
            );
          },
        );
      },
    );
    rejectionReason.dispose();
  }

  Future<void> _showCreateUserDialog(BuildContext context) async {
    final TextEditingController username = TextEditingController();
    final TextEditingController displayName = TextEditingController();
    final TextEditingController password = TextEditingController();
    AppRole role = AppRole.agent;
    String? error;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF07152B),
              title: const Text('Create user'),
              content: SizedBox(
                width: 560,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(controller: username, decoration: const InputDecoration(labelText: 'Username')),
                    const SizedBox(height: 12),
                    TextField(controller: displayName, decoration: const InputDecoration(labelText: 'Display name')),
                    const SizedBox(height: 12),
                    TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password (6+ characters)')),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AppRole>(
                      initialValue: role,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: AppRole.values
                          .map((AppRole item) => DropdownMenuItem<AppRole>(value: item, child: Text(item.name.toUpperCase())))
                          .toList(),
                      onChanged: (AppRole? value) {
                        if (value != null) setDialogState(() => role = value);
                      },
                    ),
                    if (error != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(error!, style: const TextStyle(color: Color(0xFFFF6B72))),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                FilledButton(
                  onPressed: controller.busy
                      ? null
                      : () async {
                          final String? result = await controller.createUser(
                            username: username.text,
                            displayName: displayName.text,
                            password: password.text,
                            role: role,
                          );
                          if (!dialogContext.mounted) return;
                          if (result == null) {
                            Navigator.pop(dialogContext);
                          } else {
                            setDialogState(() => error = result);
                          }
                        },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
    username.dispose();
    displayName.dispose();
    password.dispose();
  }

  Future<void> _showAdjustPointsDialog(BuildContext context) async {
    final List<UserProfile> agents = controller.users
        .where((UserProfile item) => item.role == AppRole.agent && item.isActive)
        .toList();
    if (agents.isEmpty) {
      _message(context, 'Create an active agent first.');
      return;
    }

    UserProfile selected = agents.first;
    final TextEditingController amount = TextEditingController();
    final TextEditingController reason = TextEditingController();
    bool deduct = false;
    String? error;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF07152B),
              title: const Text('Adjust points'),
              content: SizedBox(
                width: 560,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DropdownButtonFormField<UserProfile>(
                      initialValue: selected,
                      decoration: const InputDecoration(labelText: 'Agent'),
                      items: agents
                          .map((UserProfile item) => DropdownMenuItem<UserProfile>(value: item, child: Text(item.displayName)))
                          .toList(),
                      onChanged: (UserProfile? value) {
                        if (value != null) setDialogState(() => selected = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<bool>(
                      segments: const <ButtonSegment<bool>>[
                        ButtonSegment<bool>(value: false, label: Text('Add'), icon: Icon(Icons.add)),
                        ButtonSegment<bool>(value: true, label: Text('Deduct'), icon: Icon(Icons.remove)),
                      ],
                      selected: <bool>{deduct},
                      onSelectionChanged: (Set<bool> value) => setDialogState(() => deduct = value.first),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Point amount')),
                    const SizedBox(height: 12),
                    TextField(controller: reason, decoration: const InputDecoration(labelText: 'Reason')),
                    if (error != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(error!, style: const TextStyle(color: Color(0xFFFF6B72))),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                FilledButton(
                  onPressed: controller.busy
                      ? null
                      : () async {
                          final int? parsed = int.tryParse(amount.text.trim());
                          if (parsed == null || parsed <= 0) {
                            setDialogState(() => error = 'Enter a positive whole number.');
                            return;
                          }
                          final String? result = await controller.adjustAgentPoints(
                            agentId: selected.id,
                            amount: deduct ? -parsed : parsed,
                            reason: reason.text,
                          );
                          if (!dialogContext.mounted) return;
                          if (result == null) {
                            Navigator.pop(dialogContext);
                          } else {
                            setDialogState(() => error = result);
                          }
                        },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
    amount.dispose();
    reason.dispose();
  }

  Widget _valueText(double left, double top, double width, double height, String value, {double fontSize = 26}) {
    return _text(left, top, width, height, value, fontSize: fontSize, color: Colors.white, align: TextAlign.center, weight: FontWeight.w900);
  }

  Widget _text(
    double left,
    double top,
    double width,
    double height,
    String value, {
    double fontSize = 16,
    Color color = Colors.white,
    TextAlign align = TextAlign.left,
    FontWeight weight = FontWeight.w600,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Align(
        alignment: align == TextAlign.center
            ? Alignment.center
            : align == TextAlign.right
                ? Alignment.centerRight
                : Alignment.centerLeft,
        child: Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: weight,
            shadows: const <Shadow>[Shadow(color: Colors.black, blurRadius: 5)],
          ),
        ),
      ),
    );
  }

  String _actorName(Map<String, dynamic> item) {
    final Map<String, dynamic>? profile = item['profiles'] as Map<String, dynamic>?;
    return (profile?['display_name'] as String?) ??
        (profile?['username'] as String?) ??
        'System';
  }

  String _rawDate(dynamic value) {
    if (value is! String || value.isEmpty) return '—';
    return value.replaceFirst('T', ' ').split('.').first;
  }

  String _date(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
