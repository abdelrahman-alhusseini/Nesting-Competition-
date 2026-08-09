import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/app_role.dart';
import '../../models/booking_type.dart';
import '../../models/card_outcome.dart';
import '../../models/database/user_profile.dart';
import '../../state/app_controller.dart';
import 'admin_image_scaffold.dart';
import 'admin_live_scaffold.dart';

class AdminManualDrawPage extends StatefulWidget {
  const AdminManualDrawPage({required this.controller, super.key});

  final AppController controller;

  @override
  State<AdminManualDrawPage> createState() => _AdminManualDrawPageState();
}

class _AdminManualDrawPageState extends State<AdminManualDrawPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _reasonController = TextEditingController();
  String? _agentId;
  BookingType _bookingType = BookingType.normal;
  late final AnimationController _flipController;

  AppController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _bookingType = controller.adminTestBookingType;
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
      value: controller.currentOutcome == null ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<UserProfile> agents = controller.users
        .where((UserProfile user) => user.role == AppRole.agent && user.isActive)
        .toList(growable: false);

    final List<Map<String, dynamic>> recentGrants = controller.auditHistory
        .where((Map<String, dynamic> event) => event['action'] == 'manual_draw_granted')
        .take(4)
        .toList(growable: false);

    return AdminImageScaffold(
      controller: controller,
      assetPath: 'assets/images/v12/admin_manual_draw.png',
      children: <Widget>[
        Positioned(
          left: 303,
          top: 457,
          width: 294,
          height: 52,
          child: DropdownButtonFormField<String>(
            initialValue: _agentId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Select Agent',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            hint: const Text('Choose an agent'),
            items: agents
                .map(
                  (UserProfile user) => DropdownMenuItem<String>(
                    value: user.id,
                    child: Text(
                      user.displayName.isEmpty ? user.username : user.displayName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: controller.busy ? null : (String? value) => setState(() => _agentId = value),
          ),
        ),
        Positioned(
          left: 616,
          top: 457,
          width: 329,
          height: 52,
          child: DropdownButtonFormField<BookingType>(
            initialValue: _bookingType,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Booking Type',
              prefixIcon: Icon(Icons.work_outline_rounded),
            ),
            items: BookingType.values
                .map(
                  (BookingType type) => DropdownMenuItem<BookingType>(
                    value: type,
                    child: Text(type.label, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: controller.busy
                ? null
                : (BookingType? value) {
                    if (value == null) return;
                    setState(() => _bookingType = value);
                    controller.setAdminTestBookingType(value);
                  },
          ),
        ),
        Positioned(
          left: 303,
          top: 521,
          width: 642,
          height: 108,
          child: TextField(
            controller: _reasonController,
            enabled: !controller.busy,
            maxLines: 4,
            style: const TextStyle(color: adminNavy, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'Why is this manual draw being granted?',
              alignLabelWithHint: true,
            ),
          ),
        ),
        Positioned(
          left: 760,
          top: 646,
          width: 184,
          height: 44,
          child: FilledButton.icon(
            onPressed: controller.busy ? null : () => _grantDraw(context),
            icon: controller.busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.add_card_rounded, size: 18),
            label: const Text('Grant Draw'),
            style: FilledButton.styleFrom(
              backgroundColor: adminNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),

        // Covers the static preview cards in the artwork so the card shown here
        // is a real Flutter widget that can animate and reveal live test results.
        Positioned(
          left: 1011,
          top: 446,
          width: 568,
          height: 205,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FCFF).withValues(alpha: 0.97),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD8E6F4)),
            ),
            child: Row(
              children: <Widget>[
                const SizedBox(width: 38),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Unlimited test draw',
                        style: TextStyle(color: adminNavy, fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Uses the selected booking type. Test draws never change scores, bookings, or Supabase data.',
                        style: TextStyle(color: adminMuted, fontSize: 11, height: 1.35),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: controller.busy ? null : _runTestDraw,
                        icon: const Icon(Icons.casino_outlined, size: 18),
                        label: const Text('Test Draw'),
                        style: FilledButton.styleFrom(
                          backgroundColor: adminBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 205,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _flipController,
                      builder: (BuildContext context, Widget? child) {
                        final double angle = _flipController.value * math.pi;
                        final bool showFront = angle > math.pi / 2;
                        final double visibleAngle = showFront ? angle - math.pi : angle;
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0015)
                            ..rotateY(visibleAngle),
                          child: showFront
                              ? _ThemeCardFront(outcome: controller.currentOutcome)
                              : const _ThemeCardBack(),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 28),
              ],
            ),
          ),
        ),

        Positioned(
          left: 304,
          top: 780,
          width: 639,
          height: 108,
          child: _CardResultPanel(controller: controller),
        ),
        Positioned(
          left: 1001,
          top: 780,
          width: 584,
          height: 108,
          child: _RecentGrantPanel(
            events: recentGrants,
            users: controller.users,
          ),
        ),
      ],
    );
  }

  Future<void> _grantDraw(BuildContext context) async {
    final String? agentId = _agentId;
    if (agentId == null || agentId.isEmpty) {
      _snack(context, 'Select an active agent first.', true);
      return;
    }
    final String reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      _snack(context, 'Enter a reason for the manual draw.', true);
      return;
    }

    final String? error = await controller.grantAgentDraw(
      agentId: agentId,
      bookingType: _bookingType,
      reason: reason,
    );
    if (!context.mounted) return;
    if (error != null) {
      _snack(context, error, true);
      return;
    }
    _reasonController.clear();
    _snack(context, 'Pending draw granted successfully.', false);
  }

  void _runTestDraw() {
    controller.setAdminTestBookingType(_bookingType);
    controller.drawUnlimitedAdminTestCardInline();
    _flipController.forward(from: 0);
  }

  void _snack(BuildContext context, String message, bool error) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? adminRed : adminGreen,
        ),
      );
  }
}

class _ThemeCardBack extends StatelessWidget {
  const _ThemeCardBack();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 162,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF17396C), Color(0xFF0F294F)],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: adminNude, width: 2),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x2217396C), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: const Color(0x88EBC48F)),
                ),
              ),
            ),
          ),
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.local_shipping_outlined, color: Colors.white, size: 28),
                SizedBox(height: 8),
                Text('M&S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                SizedBox(height: 3),
                Text('NESTING\nCHAMPIONS', textAlign: TextAlign.center, style: TextStyle(color: adminNude, fontSize: 8, fontWeight: FontWeight.w900, height: 1.1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeCardFront extends StatelessWidget {
  const _ThemeCardFront({required this.outcome});

  final CardOutcome? outcome;

  @override
  Widget build(BuildContext context) {
    final CardOutcome? value = outcome;
    final Color accent = _cardAccent(value);
    final String center = value == null
        ? '★'
        : value.number?.toString() ?? _shortCard(value.title);

    return Container(
      width: 112,
      height: 162,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: adminNude, width: 2),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x2217396C), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0x99EBC48F)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                center,
                textAlign: TextAlign.center,
                style: TextStyle(color: accent, fontSize: center.length > 2 ? 20 : 34, fontWeight: FontWeight.w900),
              ),
              if (value != null) ...<Widget>[
                const SizedBox(height: 7),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    value.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: adminNavy, fontSize: 9, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CardResultPanel extends StatelessWidget {
  const _CardResultPanel({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final CardOutcome? outcome = controller.currentOutcome;
    if (outcome == null) {
      return const Center(
        child: Text(
          'Run a test draw to preview the card result here.',
          style: TextStyle(color: adminMuted, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }

    final Color accent = _cardAccent(outcome);
    return Row(
      children: <Widget>[
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.emoji_events_outlined, color: accent, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(outcome.title, style: const TextStyle(color: adminNavy, fontSize: 15, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              Text(outcome.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: adminMuted, fontSize: 11, height: 1.3)),
            ],
          ),
        ),
        if (controller.gamblePending) ...<Widget>[
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () => controller.keepEvenCardPoint(adminTest: true),
            style: OutlinedButton.styleFrom(foregroundColor: adminBlue, side: const BorderSide(color: adminBlue)),
            child: const Text('Keep +1'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => controller.gambleEvenCard(adminTest: true),
            style: FilledButton.styleFrom(backgroundColor: adminNavy, foregroundColor: Colors.white),
            child: const Text('Gamble'),
          ),
        ],
      ],
    );
  }
}

class _RecentGrantPanel extends StatelessWidget {
  const _RecentGrantPanel({required this.events, required this.users});

  final List<Map<String, dynamic>> events;
  final List<UserProfile> users;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(
        child: Text(
          'No manual grants recorded yet.',
          style: TextStyle(color: adminMuted, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: events.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: adminBorder),
      itemBuilder: (BuildContext context, int index) {
        final Map<String, dynamic> event = events[index];
        final Map<String, dynamic> details = (event['details'] as Map<String, dynamic>?) ?? <String, dynamic>{};
        final String agentId = (details['agent_id'] as String?) ?? '';
        UserProfile? agent;
        for (final UserProfile candidate in users) {
          if (candidate.id == agentId) {
            agent = candidate;
            break;
          }
        }
        final String name = agent?.displayName.isNotEmpty == true
            ? agent!.displayName
            : agent?.username ?? 'Agent';
        final String bookingType = ((details['booking_type'] as String?) ?? 'normal').replaceAll('_', ' ');
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: <Widget>[
              const Icon(Icons.style_outlined, color: adminBlue, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$name • $bookingType',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: adminNavy, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              Text(_formatDate(event['created_at']), style: const TextStyle(color: adminMuted, fontSize: 9)),
            ],
          ),
        );
      },
    );
  }

  static String _formatDate(dynamic value) {
    if (value is! String) return '';
    final DateTime? date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return '';
    final String h = date.hour.toString().padLeft(2, '0');
    final String m = date.minute.toString().padLeft(2, '0');
    return '${date.month}/${date.day} $h:$m';
  }
}

Color _cardAccent(CardOutcome? outcome) {
  if (outcome == null) return const Color(0xFFC99645);
  if (outcome.isSpecial) return const Color(0xFFC99645);
  if (outcome.isNegative) return adminRed;
  if (outcome.tone == CardTone.positive) return adminGreen;
  return adminBlue;
}

String _shortCard(String title) {
  if (title.contains('Skip')) return 'SKIP';
  if (title.contains('Reverse')) return 'REV';
  if (title.contains('+2')) return '+2';
  if (title.contains('+4')) return '+4';
  return '★';
}
