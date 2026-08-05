import 'package:flutter/material.dart';

import '../../models/booking_type.dart';
import '../../models/navigation.dart';
import '../../models/database/booking_record.dart';
import '../../models/database/leaderboard_entry.dart';
import '../../state/app_controller.dart';
import '../../widgets/design_canvas.dart';
import '../../widgets/image_hotspot.dart';
import '../../widgets/neon_widgets.dart';
import '../shared/card_reveal_content.dart';

class AgentShell extends StatelessWidget {
  const AgentShell({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        assetPath: _assetFor(controller.agentPage),
        children: <Widget>[
          ..._sidebarHotspots(context),
          Positioned(
            left: 271,
            top: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(30, 28, 34, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[Color(0xFA020C1C), Color(0xF506142B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: _pageContent(context),
            ),
          ),
          _userCard(),
        ],
      ),
    );
  }

  String _assetFor(AgentPage page) {
    switch (page) {
      case AgentPage.dashboard:
        return 'assets/images/agent_dashboard.png';
      case AgentPage.bookings:
        return 'assets/images/agent_bookings.png';
      case AgentPage.drawCards:
        return 'assets/images/agent_draw_cards.png';
      case AgentPage.cardReveal:
        return 'assets/images/card_reveal.png';
      case AgentPage.myCards:
        return 'assets/images/agent_my_cards.png';
      case AgentPage.useSpecialCard:
        return 'assets/images/agent_use_special.png';
      case AgentPage.leaderboard:
        return 'assets/images/agent_leaderboard.png';
      case AgentPage.activityFeed:
        return 'assets/images/agent_activity.png';
    }
  }

  List<Widget> _sidebarHotspots(BuildContext context) {
    const double firstY = 194;
    const double step = 55;
    const double width = 252;
    const double height = 50;
    Rect row(int index) => Rect.fromLTWH(14, firstY + index * step, width, height);

    return <Widget>[
      ImageHotspot(rect: row(0), label: 'Dashboard', onTap: () => controller.openAgentPage(AgentPage.dashboard)),
      ImageHotspot(rect: row(1), label: 'My Bookings', onTap: () => controller.openAgentPage(AgentPage.bookings)),
      ImageHotspot(rect: row(2), label: 'Draw Cards', onTap: () => controller.openAgentPage(AgentPage.drawCards)),
      ImageHotspot(rect: row(3), label: 'My Cards', onTap: () => controller.openAgentPage(AgentPage.myCards)),
      ImageHotspot(rect: row(4), label: 'Leaderboard', onTap: () => controller.openAgentPage(AgentPage.leaderboard)),
      ImageHotspot(rect: row(5), label: 'Activity Feed', onTap: () => controller.openAgentPage(AgentPage.activityFeed)),
      ImageHotspot(rect: row(6), label: 'Rewards', onTap: () => _showMessage(context, 'Rewards will be configured by the admin.')),
      ImageHotspot(rect: row(7), label: 'How to Play', onTap: () => _showHowToPlay(context)),
    ];
  }

  Widget _userCard() {
    return Positioned(
      left: 20,
      bottom: 28,
      width: 230,
      height: 103,
      child: NeonPanel(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: <Widget>[
            const CircleAvatar(
              radius: 27,
              backgroundColor: Color(0xFF284A7C),
              child: Icon(Icons.person, size: 34),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(controller.username, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const Text('Rookie', style: TextStyle(color: gold, fontSize: 16)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Log out',
              onPressed: controller.logout,
              icon: const Icon(Icons.logout, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageContent(BuildContext context) {
    switch (controller.agentPage) {
      case AgentPage.dashboard:
        return _dashboard(context);
      case AgentPage.bookings:
        return _bookings(context);
      case AgentPage.drawCards:
        return _drawCards(context);
      case AgentPage.cardReveal:
        return CardRevealContent(controller: controller, adminTest: false);
      case AgentPage.myCards:
        return _myCards(context);
      case AgentPage.useSpecialCard:
        return _noSpecialCard(context);
      case AgentPage.leaderboard:
        return _leaderboard();
      case AgentPage.activityFeed:
        return _activityFeed();
    }
  }

  Widget _dashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Welcome back, ${controller.username}!', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Submit bookings, earn draws, and climb the leaderboard.', style: TextStyle(fontSize: 18, color: Color(0xFFB9C7DA))),
        const SizedBox(height: 26),
        Row(
          children: <Widget>[
            Expanded(
              child: NeonPanel(
                child: _Metric(
                  icon: Icons.style,
                  label: 'Pending draws',
                  value: '${controller.pendingDraws}',
                  actionLabel: controller.pendingDraws > 0 ? 'DRAW NOW' : null,
                  onAction: controller.pendingDraws > 0 ? () => controller.openAgentPage(AgentPage.drawCards) : null,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: NeonPanel(
                borderColor: const Color(0xFF6932A7),
                child: _Metric(
                  icon: Icons.workspace_premium,
                  label: 'My score',
                  value: '${controller.agentScore}',
                  subtext: 'No demo points are preloaded',
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: NeonPanel(
                child: _Metric(
                  icon: Icons.receipt_long,
                  label: 'Submitted bookings',
                  value: '${controller.bookingCount}',
                  subtext: 'Waiting for real submissions',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        NeonPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('QUICK ACTIONS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(child: _QuickAction(icon: Icons.playlist_add_check, label: 'Submit booking', onTap: () => controller.openAgentPage(AgentPage.bookings))),
                  const SizedBox(width: 14),
                  Expanded(child: _QuickAction(icon: Icons.style, label: 'Draw cards', onTap: () => controller.openAgentPage(AgentPage.drawCards))),
                  const SizedBox(width: 14),
                  Expanded(child: _QuickAction(icon: Icons.auto_awesome, label: 'My cards', onTap: () => controller.openAgentPage(AgentPage.myCards))),
                  const SizedBox(width: 14),
                  Expanded(child: _QuickAction(icon: Icons.emoji_events, label: 'Leaderboard', onTap: () => controller.openAgentPage(AgentPage.leaderboard))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Expanded(
          child: NeonPanel(
            child: controller.activity.isEmpty
                ? const EmptyState(
                    icon: Icons.dynamic_feed,
                    title: 'No activity yet',
                    message: 'Real bookings, approvals, card draws, and admin changes will appear here.',
                  )
                : ListView.separated(
                    itemCount: controller.activity.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (BuildContext context, int index) => ListTile(
                      leading: const Icon(Icons.bolt, color: gold),
                      title: Text(controller.activity[index]),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _bookings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text('MY BOOKINGS', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
        const Text('Submit a ServiceTitan job link and track its approval status.', style: TextStyle(fontSize: 18, color: Color(0xFFB9C7DA))),
        const SizedBox(height: 24),
        NeonPanel(
          child: _BookingForm(controller: controller, onMessage: (String value) => _showMessage(context, value)),
        ),
        const SizedBox(height: 22),
        Expanded(
          child: NeonPanel(
            child: controller.myBookings.isEmpty
                ? const EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'No booking history yet',
                    message: 'Your submitted ServiceTitan jobs will appear here.',
                  )
                : ListView.separated(
                    itemCount: controller.myBookings.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (BuildContext context, int index) {
                      final BookingRecord booking = controller.myBookings[index];
                      final Color statusColor = switch (booking.status) {
                        'approved' => const Color(0xFF58D26B),
                        'rejected' => const Color(0xFFFF5656),
                        'reversed' => const Color(0xFFFF8B3E),
                        _ => gold,
                      };
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withOpacity(0.18),
                          child: Icon(Icons.receipt_long, color: statusColor),
                        ),
                        title: Text(booking.jobId == null ? 'ServiceTitan booking' : 'Job ${booking.jobId}'),
                        subtitle: Text('${booking.bookingType.label} • ${booking.status.toUpperCase()}'),
                        trailing: Text(
                          booking.submittedAt.toString().substring(0, 16),
                          style: const TextStyle(color: Color(0xFF9DB0C8)),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _drawCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text('DRAW CARDS', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(
          '${controller.pendingDraws} pending draw(s)',
          style: const TextStyle(fontSize: 20, color: gold),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: NeonPanel(
            child: controller.pendingDraws == 0
                ? const EmptyState(
                    icon: Icons.style_outlined,
                    title: 'No cards ready to draw',
                    message: 'A draw appears here after an admin validates one of your bookings.',
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Icons.style, size: 140, color: Color(0xFF6DA9FF)),
                        const SizedBox(height: 24),
                        Text('${controller.pendingDraws} card(s) ready', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: controller.busy ? null : controller.drawAgentCard,
                          style: goldButtonStyle(),
                          icon: const Icon(Icons.casino),
                          label: const Text('DRAW ONE CARD'),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _myCards(BuildContext context) {
    final card = controller.savedSpecialCard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text('MY CARDS', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
        const Text('You may hold one special card at a time.', style: TextStyle(fontSize: 18, color: Color(0xFFB9C7DA))),
        const SizedBox(height: 24),
        Expanded(
          child: NeonPanel(
            borderColor: card == null ? const Color(0xFF1C4D7F) : const Color(0xFF8737D8),
            child: card == null
                ? const EmptyState(
                    icon: Icons.auto_awesome_outlined,
                    title: 'No saved special card',
                    message: 'A special card will appear here after you draw and save one.',
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Icons.auto_awesome, size: 100, color: gold),
                        const SizedBox(height: 18),
                        Text(card.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        Text(card.description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Color(0xFFB9C7DA))),
                        const SizedBox(height: 20),
                        Chip(
                          avatar: const Icon(Icons.event_busy, color: gold),
                          label: Text('Expires after ${card.bookingsRemaining} more approved booking(s)'),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _noSpecialCard(BuildContext context) {
    return const NeonPanel(
      child: EmptyState(
        icon: Icons.block,
        title: 'No special card available',
        message: 'Return to My Cards after you receive and save a special card.',
      ),
    );
  }

  Widget _leaderboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text('LEADERBOARD', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
        const Text('Live rankings from the active competition.', style: TextStyle(fontSize: 18, color: Color(0xFFB9C7DA))),
        const SizedBox(height: 24),
        Expanded(
          child: NeonPanel(
            child: controller.leaderboard.isEmpty
                ? const EmptyState(
                    icon: Icons.emoji_events_outlined,
                    title: 'No ranked players yet',
                    message: 'Players will appear after agent accounts are created.',
                  )
                : ListView.separated(
                    itemCount: controller.leaderboard.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (BuildContext context, int index) {
                      final LeaderboardEntry entry = controller.leaderboard[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: entry.rank <= 3 ? gold.withOpacity(0.20) : const Color(0xFF17355D),
                          child: Text('${entry.rank}', style: TextStyle(color: entry.rank <= 3 ? gold : Colors.white, fontWeight: FontWeight.w800)),
                        ),
                        title: Text(entry.displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(entry.title),
                        trailing: Text('${entry.score} pts', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: gold)),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _activityFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text('ACTIVITY FEED', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
        const Text('Public game events will appear here.', style: TextStyle(fontSize: 18, color: Color(0xFFB9C7DA))),
        const SizedBox(height: 24),
        Expanded(
          child: NeonPanel(
            child: controller.activity.isEmpty
                ? const EmptyState(
                    icon: Icons.rss_feed,
                    title: 'No activity yet',
                    message: 'The feed contains only real actions. No demo events are preloaded.',
                  )
                : ListView.separated(
                    itemCount: controller.activity.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (BuildContext context, int index) => ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.bolt)),
                      title: Text(controller.activity[index]),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showHowToPlay(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: navy,
        title: const Text('How to play'),
        content: const SizedBox(
          width: 560,
          child: Text(
            '1. Submit one unique ServiceTitan job link.\n'
            '2. The admin validates the booking type and approves or rejects it.\n'
            '3. Each approved booking grants one draw, up to three pending draws.\n'
            '4. Draw cards, collect points, and use special cards strategically.',
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    this.subtext,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subtext;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 58, color: gold),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFB8C6D9))),
              Text(value, style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900)),
              if (subtext != null) Text(subtext!, style: const TextStyle(color: Color(0xFF90A3BA))),
            ],
          ),
        ),
        if (actionLabel != null)
          FilledButton(onPressed: onAction, style: goldButtonStyle(), child: Text(actionLabel!)),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF071A34),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1C4D7F)),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 44, color: gold),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
            const Icon(Icons.arrow_forward),
          ],
        ),
      ),
    );
  }
}

class _BookingForm extends StatefulWidget {
  const _BookingForm({required this.controller, required this.onMessage});

  final AppController controller;
  final ValueChanged<String> onMessage;

  @override
  State<_BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<_BookingForm> {
  final TextEditingController _linkController = TextEditingController();
  BookingType _type = BookingType.normal;

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String link = _linkController.text.trim();
    final String lower = link.toLowerCase();
    if (!lower.contains('go.servicetitan.com') ||
        (!lower.contains('/job/index/') && !lower.contains('/job/node/'))) {
      widget.onMessage('Enter a valid ServiceTitan job link.');
      return;
    }
    final String? error = await widget.controller.submitBooking(link, _type);
    if (!mounted) return;
    if (error != null) {
      widget.onMessage(error);
      return;
    }
    _linkController.clear();
    widget.onMessage('Booking submitted for admin approval.');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text('SUBMIT A BOOKING', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              flex: 2,
              child: TextField(
                controller: _linkController,
                style: const TextStyle(fontSize: 17),
                decoration: const InputDecoration(
                  labelText: 'ServiceTitan Job Link',
                  hintText: 'https://go.servicetitan.com/#/Job/Index/...',
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFF020B19),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<BookingType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Booking Type', border: OutlineInputBorder()),
                items: BookingType.values.map((BookingType type) => DropdownMenuItem<BookingType>(value: type, child: Text(type.label))).toList(),
                onChanged: (BookingType? value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(onPressed: widget.controller.busy ? null : () { _submit(); }, style: goldButtonStyle(), icon: const Icon(Icons.send), label: const Text('SUBMIT')),
          ],
        ),
      ],
    );
  }
}
