import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/booking_type.dart';
import '../../models/card_outcome.dart';
import '../../models/database/booking_record.dart';
import '../../models/database/leaderboard_entry.dart';
import '../../models/navigation.dart';
import '../../state/app_controller.dart';
import '../../widgets/design_canvas.dart';
import '../../widgets/image_hotspot.dart';

class AgentShell extends StatefulWidget {
  const AgentShell({required this.controller, super.key});

  final AppController controller;

  @override
  State<AgentShell> createState() => _AgentShellState();
}

class _AgentShellState extends State<AgentShell> {
  AppController get controller => widget.controller;

  final TextEditingController _bookingLinkController = TextEditingController();
  final TextEditingController _bookingSearchController = TextEditingController();
  BookingType _bookingType = BookingType.normal;

  @override
  void dispose() {
    _bookingLinkController.dispose();
    _bookingSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool lightPage = controller.agentPage != AgentPage.useSpecialCard;
    return Scaffold(
      body: DesignCanvas(
        assetPath: _assetFor(controller.agentPage),
        lightBackground: lightPage,
        children: <Widget>[
          if (lightPage) ..._lightNavigationOverlay() else ..._navigationHotspots(),
          ..._pageOverlay(context),
          if (!lightPage)
            ImageHotspot(
              rect: const Rect.fromLTWH(20, 720, 230, 70),
              label: 'Sign out',
              onTap: controller.logout,
            ),
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
        return 'assets/images/agent_draw_cards.png';
      case AgentPage.myCards:
        return 'assets/images/agent_my_cards.png';
      case AgentPage.useSpecialCard:
        return 'assets/images/agent_use_special.png';
      case AgentPage.leaderboard:
        return 'assets/images/agent_leaderboard.png';
      case AgentPage.activityFeed:
        return 'assets/images/agent_activity.png';
      case AgentPage.howToPlay:
        return 'assets/images/agent_how_to_play.png';
    }
  }

  List<Widget> _lightNavigationOverlay() {
    const Color navy = Color(0xFF17396C);
    const Color blue = Color(0xFF2E7BD8);
    const double left = 25;
    final double top = switch (controller.agentPage) {
      AgentPage.myCards => 372,
      AgentPage.activityFeed => 365,
      AgentPage.howToPlay => 310,
      _ => 325,
    };
    const double width = 230;
    const double rowHeight = 40;
    const double gap = 5;
    final List<({AgentPage page, IconData icon, String label})> rows = <({AgentPage page, IconData icon, String label})>[
      (page: AgentPage.dashboard, icon: Icons.dashboard_outlined, label: 'DASHBOARD'),
      (page: AgentPage.bookings, icon: Icons.calendar_month_outlined, label: 'MY BOOKINGS'),
      (page: AgentPage.drawCards, icon: Icons.style_outlined, label: 'DRAW CARDS'),
      (page: AgentPage.myCards, icon: Icons.wallet_outlined, label: 'MY CARDS'),
      (page: AgentPage.leaderboard, icon: Icons.emoji_events_outlined, label: 'LEADERBOARD'),
      (page: AgentPage.activityFeed, icon: Icons.monitor_heart_outlined, label: 'ACTIVITY FEED'),
      (page: AgentPage.howToPlay, icon: Icons.menu_book_outlined, label: 'HOW TO PLAY'),
    ];
    final List<Widget> result = <Widget>[
      Positioned(
        left: left - 4,
        top: top - 8,
        width: width + 8,
        height: rows.length * (rowHeight + gap) + 62,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    ];
    for (int i = 0; i < rows.length; i++) {
      final item = rows[i];
      final bool selected = controller.agentPage == item.page;
      result.add(
        Positioned(
          left: left,
          top: top + i * (rowHeight + gap),
          width: width,
          height: rowHeight,
          child: Material(
            color: selected ? const Color(0xFFDDEEFF) : Colors.white,
            borderRadius: BorderRadius.circular(11),
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: () => controller.openAgentPage(item.page),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 11),
                child: Row(
                  children: <Widget>[
                    Icon(item.icon, size: 19, color: selected ? blue : navy),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: selected ? blue : navy, fontSize: 12.5, fontWeight: selected ? FontWeight.w900 : FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    result.add(
      Positioned(
        left: left,
        top: top + rows.length * (rowHeight + gap) + 4,
        width: width,
        height: rowHeight,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            onTap: controller.logout,
            borderRadius: BorderRadius.circular(11),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 11),
              child: Row(children: <Widget>[Icon(Icons.logout_rounded, size: 19, color: navy), SizedBox(width: 10), Text('SIGN OUT', style: TextStyle(color: navy, fontSize: 12.5, fontWeight: FontWeight.w800))]),
            ),
          ),
        ),
      ),
    );
    return result;
  }

  List<Widget> _navigationHotspots() {
    const double x = 14;
    const double width = 252;
    const double firstY = 335;
    const double step = 45.5;
    Rect row(int index) => Rect.fromLTWH(x, firstY + (index * step), width, 43);

    return <Widget>[
      ImageHotspot(rect: row(0), label: 'Dashboard', onTap: () => controller.openAgentPage(AgentPage.dashboard)),
      ImageHotspot(rect: row(1), label: 'My Bookings', onTap: () => controller.openAgentPage(AgentPage.bookings)),
      ImageHotspot(rect: row(2), label: 'Draw Cards', onTap: () => controller.openAgentPage(AgentPage.drawCards)),
      ImageHotspot(rect: row(3), label: 'My Cards', onTap: () => controller.openAgentPage(AgentPage.myCards)),
      ImageHotspot(rect: row(4), label: 'Leaderboard', onTap: () => controller.openAgentPage(AgentPage.leaderboard)),
      ImageHotspot(rect: row(5), label: 'Activity Feed', onTap: () => controller.openAgentPage(AgentPage.activityFeed)),
      ImageHotspot(rect: row(6), label: 'How to Play', onTap: () => controller.openAgentPage(AgentPage.howToPlay)),
    ];
  }

  List<Widget> _pageOverlay(BuildContext context) {
    switch (controller.agentPage) {
      case AgentPage.dashboard:
        return _dashboardOverlay();
      case AgentPage.bookings:
        return _bookingsOverlay(context);
      case AgentPage.drawCards:
        return _drawCardsOverlay(context);
      case AgentPage.cardReveal:
        return _cardRevealOverlay(context);
      case AgentPage.myCards:
        return _myCardsOverlay(context);
      case AgentPage.useSpecialCard:
        return _useSpecialOverlay(context);
      case AgentPage.leaderboard:
        return _leaderboardOverlay();
      case AgentPage.activityFeed:
        return _activityOverlay();
      case AgentPage.howToPlay:
        return const <Widget>[];
    }
  }

  List<Widget> _dashboardOverlay() {
    final List<LeaderboardEntry> leaders = controller.leaderboard.take(5).toList();
    final List<String> activity = controller.agentGameActivity.take(5).toList();
    final String rewardTitle = controller.profile?.title ?? 'Rookie';

    return <Widget>[
      _valueText(956, 342, 280, 72, '${controller.bookingCount}', fontSize: 30),
      _valueText(1260, 342, 280, 72, '${controller.agentGameActivity.length}', fontSize: 30),

      Positioned(
        left: 318,
        top: 548,
        width: 345,
        height: 282,
        child: _lightContentCard(
          child: Column(
            children: <Widget>[
              if (leaders.isEmpty)
                const Expanded(
                  child: Center(child: Text('No leaderboard data yet', style: TextStyle(color: Color(0xFF748399), fontWeight: FontWeight.w700))),
                )
              else
                ...leaders.map((LeaderboardEntry entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: <Widget>[
                          SizedBox(width: 34, child: Text('#${entry.rank}', style: const TextStyle(color: Color(0xFF2E7BD8), fontWeight: FontWeight.w900))),
                          Expanded(child: Text(entry.displayName, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF17396C), fontWeight: FontWeight.w800))),
                          Text('${entry.score}', style: const TextStyle(color: Color(0xFFB7791F), fontWeight: FontWeight.w900)),
                        ],
                      ),
                    )),
              const Spacer(),
              _lightActionButton('View Full Leaderboard', Icons.emoji_events_outlined, () => controller.openAgentPage(AgentPage.leaderboard)),
            ],
          ),
        ),
      ),
      Positioned(
        left: 735,
        top: 548,
        width: 335,
        height: 282,
        child: _lightContentCard(
          child: Column(
            children: <Widget>[
              if (activity.isEmpty)
                const Expanded(
                  child: Center(child: Text('No recent activity yet', style: TextStyle(color: Color(0xFF748399), fontWeight: FontWeight.w700))),
                )
              else
                ...activity.map((String item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Icon(Icons.bolt_rounded, color: Color(0xFF2E7BD8), size: 17),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF17396C), fontSize: 12.5, height: 1.25, fontWeight: FontWeight.w700))),
                        ],
                      ),
                    )),
              const Spacer(),
              _lightActionButton('View All Activity', Icons.monitor_heart_outlined, () => controller.openAgentPage(AgentPage.activityFeed)),
            ],
          ),
        ),
      ),
      Positioned(
        left: 1135,
        top: 548,
        width: 415,
        height: 282,
        child: _lightContentCard(
          child: Column(
            children: <Widget>[
              const SizedBox(height: 8),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: const Color(0xFFF0F6FF), borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.workspace_premium_outlined, color: Color(0xFF2E7BD8), size: 34),
              ),
              const SizedBox(height: 12),
              Text(rewardTitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF17396C), fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              Text('${controller.agentScore} total points', style: const TextStyle(color: Color(0xFF2E7BD8), fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(controller.savedSpecialCard == null ? 'No saved special card' : 'Special card ready to use', style: const TextStyle(color: Color(0xFF748399), fontSize: 12.5, fontWeight: FontWeight.w600)),
              const Spacer(),
              _lightActionButton('View My Cards', Icons.style_outlined, () => controller.openAgentPage(AgentPage.myCards)),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _bookingsOverlay(BuildContext context) {
    final String query = _bookingSearchController.text.trim().toLowerCase();
    final List<BookingRecord> rows = controller.myBookings.where((BookingRecord booking) {
      if (query.isEmpty) return true;
      return (booking.jobId ?? '').toLowerCase().contains(query) ||
          booking.bookingType.label.toLowerCase().contains(query) ||
          booking.status.toLowerCase().contains(query);
    }).take(3).toList();

    return <Widget>[
      Positioned(
        left: 345,
        top: 268,
        width: 625,
        height: 255,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _bookingLinkController,
                    style: const TextStyle(color: Color(0xFF17396C), fontWeight: FontWeight.w700),
                    decoration: _agentFieldDecoration('ServiceTitan link', Icons.link_rounded),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<BookingType>(
                    initialValue: _bookingType,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Color(0xFF17396C), fontWeight: FontWeight.w700),
                    decoration: _agentFieldDecoration('Booking type', Icons.calendar_month_outlined),
                    items: BookingType.values.map((BookingType type) => DropdownMenuItem<BookingType>(value: type, child: Text(type.label))).toList(),
                    onChanged: (BookingType? value) {
                      if (value != null) setState(() => _bookingType = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(color: const Color(0xFFF2F7FD), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFD9E7F4))),
              child: const Row(
                children: <Widget>[
                  Icon(Icons.info_outline_rounded, color: Color(0xFF2E7BD8)),
                  SizedBox(width: 10),
                  Expanded(child: Text('Paste the ServiceTitan booking link, choose its type, then submit it for admin review.', style: TextStyle(color: Color(0xFF4F6680), fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 220,
                height: 48,
                child: FilledButton.icon(
                  onPressed: controller.busy ? null : () => _submitBookingFromPage(context),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Submit Booking'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7BD8), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ),
          ],
        ),
      ),
      Positioned(
        left: 1048,
        top: 618,
        width: 430,
        height: 48,
        child: TextField(
          controller: _bookingSearchController,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: Color(0xFF17396C), fontWeight: FontWeight.w700),
          decoration: _agentFieldDecoration('Search bookings', Icons.search_rounded),
        ),
      ),
      Positioned(
        left: 340,
        top: 688,
        width: 1190,
        height: 150,
        child: Column(
          children: <Widget>[
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: const Color(0xFFF3F7FC), borderRadius: BorderRadius.circular(10)),
              child: const Row(
                children: <Widget>[
                  Expanded(flex: 2, child: Text('BOOKING ID', style: TextStyle(color: Color(0xFF5E7390), fontSize: 11, fontWeight: FontWeight.w900))),
                  Expanded(flex: 3, child: Text('BOOKING TYPE', style: TextStyle(color: Color(0xFF5E7390), fontSize: 11, fontWeight: FontWeight.w900))),
                  Expanded(flex: 2, child: Text('STATUS', style: TextStyle(color: Color(0xFF5E7390), fontSize: 11, fontWeight: FontWeight.w900))),
                  Expanded(flex: 2, child: Text('SUBMITTED', style: TextStyle(color: Color(0xFF5E7390), fontSize: 11, fontWeight: FontWeight.w900))),
                ],
              ),
            ),
            if (rows.isEmpty)
              const Expanded(child: Center(child: Text('No bookings found', style: TextStyle(color: Color(0xFF748399), fontWeight: FontWeight.w700))))
            else
              ...rows.map((BookingRecord booking) => Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5EDF5)))),
                    child: Row(
                      children: <Widget>[
                        Expanded(flex: 2, child: Text(booking.jobId ?? '—', overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF17396C), fontSize: 12, fontWeight: FontWeight.w800))),
                        Expanded(flex: 3, child: Text(booking.bookingType.label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF17396C), fontSize: 12, fontWeight: FontWeight.w700))),
                        Expanded(flex: 2, child: Text(booking.status.toUpperCase(), style: TextStyle(color: _statusColor(booking.status), fontSize: 11, fontWeight: FontWeight.w900))),
                        Expanded(flex: 2, child: Text(_date(booking.submittedAt), style: const TextStyle(color: Color(0xFF536A84), fontSize: 11.5, fontWeight: FontWeight.w700))),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    ];
  }

  List<Widget> _drawCardsOverlay(BuildContext context) {
    final bool canDraw = controller.pendingDraws > 0 && !controller.busy;
    return <Widget>[
      Positioned(
        left: 455,
        top: 220,
        width: 250,
        height: 390,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: canDraw ? () => controller.drawAgentCard() : () => _message(context, 'No approved draws are available yet.'),
            child: Tooltip(
              message: canDraw ? 'Click the card to reveal your draw' : 'No draws available',
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
      Positioned(
        left: 465,
        top: 610,
        width: 230,
        height: 42,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xF7FFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC9DDF1)),
          ),
          child: Text(
            controller.pendingDraws == 1 ? '1 draw available' : '${controller.pendingDraws} draws available',
            style: const TextStyle(color: Color(0xFF17396C), fontSize: 13, fontWeight: FontWeight.w900),
          ),
        ),
      ),
      Positioned(
        left: 965,
        top: 270,
        width: 455,
        height: 210,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          child: Text(
            canDraw
                ? 'Click the card on the left to start the reveal.'
                : 'Complete an approved booking or receive a manual draw to unlock your next card.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6D8097), fontSize: 16, height: 1.45, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      Positioned(
        left: 842,
        top: 548,
        width: 720,
        height: 96,
        child: Row(
          children: <Widget>[
            Expanded(child: _drawActionPlaceholder(Icons.check_circle_outline_rounded, 'USE / KEEP', enabled: false)),
            const SizedBox(width: 14),
            Expanded(child: _drawActionPlaceholder(Icons.save_outlined, 'SAVE CARD', enabled: false)),
            const SizedBox(width: 14),
            Expanded(child: _drawActionPlaceholder(Icons.casino_outlined, 'GAMBLE', enabled: false)),
          ],
        ),
      ),
    ];
  }

  List<Widget> _cardRevealOverlay(BuildContext context) {
    final CardOutcome? outcome = controller.currentOutcome;
    if (outcome == null) {
      return <Widget>[
        Positioned(
          left: 980,
          top: 300,
          width: 430,
          height: 150,
          child: const Center(
            child: Text('No card result is available.', style: TextStyle(color: Color(0xFF748399), fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ];
    }

    final bool gamble = controller.gamblePending;
    final bool special = outcome.isSpecial;
    return <Widget>[
      Positioned(
        left: 965,
        top: 245,
        width: 455,
        height: 245,
        child: _AgentRevealFlipCard(outcome: outcome),
      ),
      Positioned(
        left: 842,
        top: 548,
        width: 720,
        height: 96,
        child: Row(
          children: <Widget>[
            Expanded(
              child: _drawActionButton(
                icon: gamble ? Icons.verified_outlined : Icons.check_circle_outline_rounded,
                label: gamble ? 'KEEP +1' : (special ? 'USE CARD' : 'CONTINUE'),
                onPressed: controller.busy
                    ? null
                    : () async {
                        if (gamble) {
                          await controller.keepEvenCardPoint(adminTest: false);
                          return;
                        }
                        if (special) {
                          final String? error = await controller.saveCurrentSpecialCard(replaceExisting: true);
                          if (!context.mounted) return;
                          if (error != null) {
                            _message(context, error);
                          } else {
                            controller.openAgentPage(AgentPage.myCards);
                          }
                          return;
                        }
                        controller.continueAfterAgentReveal();
                      },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _drawActionButton(
                icon: Icons.save_outlined,
                label: 'SAVE CARD',
                onPressed: special && !controller.busy
                    ? () async {
                        final String? error = await controller.saveCurrentSpecialCard(replaceExisting: true);
                        if (!context.mounted) return;
                        if (error != null) {
                          _message(context, error);
                        } else {
                          _message(context, 'Special card saved to My Cards.');
                          controller.openAgentPage(AgentPage.myCards);
                        }
                      }
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _drawActionButton(
                icon: Icons.casino_outlined,
                label: 'GAMBLE / RISK IT',
                onPressed: gamble && !controller.busy
                    ? () async => controller.gambleEvenCard(adminTest: false)
                    : null,
              ),
            ),
          ],
        ),
      ),
      if (!gamble && !special)
        Positioned(
          left: 990,
          top: 650,
          width: 400,
          height: 40,
          child: TextButton(
            onPressed: controller.continueAfterAgentReveal,
            child: const Text('Continue to the next draw', style: TextStyle(color: Color(0xFF2E7BD8), fontWeight: FontWeight.w900)),
          ),
        ),
    ];
  }

  List<Widget> _myCardsOverlay(BuildContext context) {
    final card = controller.savedSpecialCard;
    final List<Rect> slots = <Rect>[
      const Rect.fromLTWH(985, 246, 125, 174),
      const Rect.fromLTWH(1132, 246, 125, 174),
      const Rect.fromLTWH(1280, 246, 125, 174),
      const Rect.fromLTWH(1427, 246, 125, 174),
      const Rect.fromLTWH(985, 440, 125, 174),
      const Rect.fromLTWH(1132, 440, 125, 174),
      const Rect.fromLTWH(1280, 440, 125, 174),
      const Rect.fromLTWH(1427, 440, 125, 174),
    ];

    return <Widget>[
      Positioned(
        left: 585,
        top: 245,
        width: 305,
        height: 370,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.96), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFD7E5F2), width: 1.4)),
          child: card == null
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.style_outlined, size: 58, color: Color(0xFF8FB6E8)),
                    SizedBox(height: 16),
                    Text('No active special card', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF17396C), fontSize: 20, fontWeight: FontWeight.w900)),
                    SizedBox(height: 8),
                    Text('Special cards you save after a draw will appear here.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF748399), fontSize: 13, height: 1.4, fontWeight: FontWeight.w600)),
                  ],
                )
              : Column(
                  children: <Widget>[
                    Container(width: 72, height: 72, decoration: BoxDecoration(color: const Color(0xFFF1F6FE), borderRadius: BorderRadius.circular(22)), child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF7E57C2), size: 38)),
                    const SizedBox(height: 14),
                    Text(card.title, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF17396C), fontSize: 21, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(card.description, maxLines: 4, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF61748A), fontSize: 13, height: 1.4, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('${card.bookingsRemaining} booking(s) remaining', style: const TextStyle(color: Color(0xFF2E7BD8), fontSize: 12.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: FilledButton.icon(
                        onPressed: () => controller.openAgentPage(AgentPage.useSpecialCard),
                        icon: const Icon(Icons.bolt_rounded, size: 18),
                        label: const Text('Use Card'),
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7BD8), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                  ],
                ),
        ),
      ),
      for (int i = 0; i < slots.length; i++)
        Positioned(
          left: slots[i].left,
          top: slots[i].top,
          width: slots[i].width,
          height: slots[i].height,
          child: Material(
            color: Colors.white.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: i == 0 && card != null ? () => controller.openAgentPage(AgentPage.useSpecialCard) : null,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: i == 0 && card != null ? const Color(0xFF8BB9EC) : const Color(0xFFD4E1EE), width: 1.4)),
                child: Center(
                  child: i == 0 && card != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF7E57C2), size: 30),
                            const SizedBox(height: 9),
                            Text(card.title, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF17396C), fontSize: 11.5, fontWeight: FontWeight.w900)),
                          ],
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(Icons.add_circle_outline_rounded, color: Color(0xFFB8CBE0), size: 28),
                            SizedBox(height: 8),
                            Text('Empty', style: TextStyle(color: Color(0xFF9AABBD), fontSize: 11, fontWeight: FontWeight.w700)),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      Positioned(
        left: 575,
        top: 731,
        width: 390,
        height: 108,
        child: const Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _AgentInfoLine(icon: Icons.looks_one_outlined, text: 'Earn a special card from an eligible approved booking.'),
              SizedBox(height: 8),
              _AgentInfoLine(icon: Icons.looks_two_outlined, text: 'Save it, then choose Use Card when you are ready.'),
              SizedBox(height: 8),
              _AgentInfoLine(icon: Icons.looks_3_outlined, text: 'Apply the card to the next supported action.'),
            ],
          ),
        ),
      ),
      Positioned(
        left: 1025,
        top: 731,
        width: 520,
        height: 108,
        child: const Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _AgentInfoLine(icon: Icons.info_outline_rounded, text: 'Saved-card availability and remaining uses come from Supabase.'),
              SizedBox(height: 8),
              _AgentInfoLine(icon: Icons.security_outlined, text: 'A special card is only consumed when the supported action succeeds.'),
              SizedBox(height: 8),
              _AgentInfoLine(icon: Icons.refresh_rounded, text: 'Refresh the page after another approved draw to see the latest card state.'),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _useSpecialOverlay(BuildContext context) {
    final card = controller.savedSpecialCard;
    final List<LeaderboardEntry> targets = controller.leaderboard.take(5).toList();
    return <Widget>[
      if (card != null) ...<Widget>[
        _text(385, 612, 310, 38, card.title, fontSize: 23, color: const Color(0xFFFFC62B), align: TextAlign.center, weight: FontWeight.w900),
        _text(385, 660, 310, 65, card.description, fontSize: 16, align: TextAlign.center),
      ],
      for (int i = 0; i < targets.length; i++)
        _text(835, 210 + i * 54, 320, 36, targets[i].displayName, fontSize: 17),
      ImageHotspot(
        rect: const Rect.fromLTWH(650, 785, 380, 75),
        label: 'Use special card',
        onTap: () => _message(
          context,
          card == null
              ? 'No saved special card is available.'
              : 'The special-card action screen is ready visually. The selected action RPC is the next database feature to connect.',
        ),
      ),
    ];
  }

  List<Widget> _leaderboardOverlay() {
    final List<LeaderboardEntry> rows = controller.leaderboard.take(8).toList();
    LeaderboardEntry? me;
    final String? userId = controller.profile?.id;
    if (userId != null) {
      for (final LeaderboardEntry entry in controller.leaderboard) {
        if (entry.userId == userId) {
          me = entry;
          break;
        }
      }
    }
    final int total = controller.leaderboard.length;
    final int percentile = me == null || total == 0
        ? 0
        : (((total - me.rank + 1) / total) * 100).round().clamp(0, 100).toInt();

    return <Widget>[
      _valueText(381, 235, 240, 72, me == null ? '—' : '#${me.rank}', fontSize: 28),
      _valueText(682, 235, 240, 72, '${controller.agentScore}', fontSize: 28),
      _valueText(985, 235, 240, 72, me?.title ?? 'Rookie', fontSize: 20),
      _valueText(1290, 235, 240, 72, '$percentile%', fontSize: 28),
      Positioned(
        left: 374,
        top: 480,
        width: 850,
        height: 290,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          color: Colors.white.withValues(alpha: 0.94),
          child: Column(
            children: <Widget>[
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: const Color(0xFFF1F6FC), borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: <Widget>[
                    SizedBox(width: 58, child: Text('RANK', style: TextStyle(color: Color(0xFF647A94), fontSize: 11, fontWeight: FontWeight.w900))),
                    Expanded(child: Text('AGENT', style: TextStyle(color: Color(0xFF647A94), fontSize: 11, fontWeight: FontWeight.w900))),
                    SizedBox(width: 150, child: Text('TITLE', style: TextStyle(color: Color(0xFF647A94), fontSize: 11, fontWeight: FontWeight.w900))),
                    SizedBox(width: 90, child: Text('POINTS', textAlign: TextAlign.right, style: TextStyle(color: Color(0xFF647A94), fontSize: 11, fontWeight: FontWeight.w900))),
                  ],
                ),
              ),
              if (rows.isEmpty)
                const Expanded(child: Center(child: Text('No leaderboard data yet', style: TextStyle(color: Color(0xFF748399), fontWeight: FontWeight.w700))))
              else
                ...rows.map((LeaderboardEntry entry) => Container(
                      height: 29,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: entry.userId == userId ? const Color(0xFFEAF4FF) : Colors.transparent,
                        border: const Border(bottom: BorderSide(color: Color(0xFFE7EEF5))),
                      ),
                      child: Row(
                        children: <Widget>[
                          SizedBox(width: 58, child: Text('#${entry.rank}', style: const TextStyle(color: Color(0xFF2E7BD8), fontSize: 12, fontWeight: FontWeight.w900))),
                          Expanded(child: Text(entry.displayName, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF17396C), fontSize: 12, fontWeight: FontWeight.w800))),
                          SizedBox(width: 150, child: Text(entry.title, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF647A94), fontSize: 11.5, fontWeight: FontWeight.w700))),
                          SizedBox(width: 90, child: Text('${entry.score}', textAlign: TextAlign.right, style: const TextStyle(color: Color(0xFFB7791F), fontSize: 12, fontWeight: FontWeight.w900))),
                        ],
                      ),
                    )),
            ],
          ),
        ),
      ),
      Positioned(
        left: 1282,
        top: 455,
        width: 285,
        height: 300,
        child: Container(
          padding: const EdgeInsets.all(18),
          color: Colors.white.withValues(alpha: 0.92),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _rankTier(Icons.emoji_events_outlined, 'Champion', 'Top of the leaderboard'),
              const SizedBox(height: 12),
              _rankTier(Icons.star_outline_rounded, 'Elite', 'High-performing agents'),
              const SizedBox(height: 12),
              _rankTier(Icons.workspace_premium_outlined, 'Rising', 'Keep collecting points'),
              const SizedBox(height: 12),
              _rankTier(Icons.flag_outlined, 'Starter', 'Every booking counts'),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _activityOverlay() {
    final List<String> rows = controller.agentGameActivity.take(9).toList();
    return <Widget>[
      Positioned(
        left: 395,
        top: 322,
        width: 1210,
        height: 82,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.96), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFD7E4F0))),
                child: const Row(children: <Widget>[Icon(Icons.filter_alt_outlined, color: Color(0xFF2E7BD8)), SizedBox(width: 10), Text('All activity types', style: TextStyle(color: Color(0xFF17396C), fontWeight: FontWeight.w800))]),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.96), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFD7E4F0))),
                child: const Row(children: <Widget>[Icon(Icons.schedule_outlined, color: Color(0xFF2E7BD8)), SizedBox(width: 10), Text('Newest first', style: TextStyle(color: Color(0xFF17396C), fontWeight: FontWeight.w800))]),
              ),
            ),
          ],
        ),
      ),
      Positioned(
        left: 395,
        top: 448,
        width: 700,
        height: 420,
        child: Container(
          padding: const EdgeInsets.all(18),
          color: Colors.white.withValues(alpha: 0.94),
          child: rows.isEmpty
              ? const Center(child: Text('No activity yet', style: TextStyle(color: Color(0xFF748399), fontWeight: FontWeight.w700)))
              : ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(color: Color(0xFFE6EDF5), height: 14),
                  itemBuilder: (BuildContext context, int index) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(width: 34, height: 34, decoration: BoxDecoration(color: const Color(0xFFEAF4FF), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.bolt_rounded, color: Color(0xFF2E7BD8), size: 18)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(rows[index], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF17396C), fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w700))),
                    ],
                  ),
                ),
        ),
      ),
      Positioned(
        left: 1142,
        top: 448,
        width: 455,
        height: 190,
        child: Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white.withValues(alpha: 0.94),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _activityMetric(Icons.calendar_month_outlined, '${controller.bookingCount}', 'Bookings'),
              _activityMetric(Icons.style_outlined, '${controller.pendingDraws}', 'Pending draws'),
              _activityMetric(Icons.emoji_events_outlined, '${controller.agentScore}', 'Points'),
            ],
          ),
        ),
      ),
      Positioned(
        left: 1142,
        top: 665,
        width: 455,
        height: 200,
        child: Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white.withValues(alpha: 0.94),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Your latest competition activity is pulled directly from Supabase.', style: TextStyle(color: Color(0xFF17396C), fontSize: 13, height: 1.45, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              Text(controller.pendingDraws > 0 ? 'You have a card draw ready to reveal.' : 'No card draws are waiting right now.', style: const TextStyle(color: Color(0xFF667B94), fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w600)),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: controller.pendingDraws > 0 ? () => controller.openAgentPage(AgentPage.drawCards) : null,
                  icon: const Icon(Icons.style_outlined, size: 17),
                  label: const Text('Go to Draw Cards'),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF2E7BD8), side: const BorderSide(color: Color(0xFFB9D5F0))),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _lightContentCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _lightActionButton(String label, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2E7BD8),
          side: const BorderSide(color: Color(0xFFBCD6F0)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _drawActionPlaceholder(IconData icon, String label, {required bool enabled}) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xF8FFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD5E2EF)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: const Color(0xFF9AAFC4), size: 19),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Color(0xFF9AAFC4), fontSize: 11.5, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _drawActionButton({required IconData icon, required String label, required VoidCallback? onPressed}) {
    return SizedBox(
      height: 64,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, textAlign: TextAlign.center),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFF8FBFF),
          foregroundColor: const Color(0xFF17396C),
          disabledBackgroundColor: const Color(0xFFF4F7FA),
          disabledForegroundColor: const Color(0xFF9AAFC4),
          side: BorderSide(color: onPressed == null ? const Color(0xFFDDE6EF) : const Color(0xFFB7D4F1), width: 1.4),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _rankTier(IconData icon, String title, String subtitle) {
    return Row(
      children: <Widget>[
        Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFF0F6FD), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: const Color(0xFF2E7BD8), size: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: const TextStyle(color: Color(0xFF17396C), fontSize: 12.5, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF748399), fontSize: 10.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _activityMetric(IconData icon, String value, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFF0F6FD), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: const Color(0xFF2E7BD8), size: 24)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Color(0xFF17396C), fontSize: 20, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: Color(0xFF748399), fontSize: 10.5, fontWeight: FontWeight.w700)),
      ],
    );
  }

  InputDecoration _agentFieldDecoration(String hint, IconData icon) {
    const OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFCDDBE9), width: 1.3),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF8A9BAE), fontWeight: FontWeight.w600),
      prefixIcon: Icon(icon, color: const Color(0xFF2E7BD8), size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      enabledBorder: border,
      border: border,
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF2E7BD8), width: 2),
      ),
    );
  }

  Future<void> _submitBookingFromPage(BuildContext context) async {
    final String link = _bookingLinkController.text.trim();
    if (link.isEmpty) {
      _message(context, 'Enter the ServiceTitan booking link first.');
      return;
    }
    final String? error = await controller.submitBooking(link, _bookingType);
    if (!mounted) return;
    if (error == null) {
      _bookingLinkController.clear();
      _message(context, 'Booking submitted for admin review.');
      setState(() {});
    } else {
      _message(context, error);
    }
  }

  Future<void> _showSubmitBookingDialog(BuildContext context) async {
    final TextEditingController link = TextEditingController();
    BookingType selected = BookingType.normal;
    String? error;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF07152B),
              title: const Text('Submit a booking'),
              content: SizedBox(
                width: 560,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: link,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'ServiceTitan job link',
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<BookingType>(
                      initialValue: selected,
                      decoration: const InputDecoration(labelText: 'Booking type'),
                      items: BookingType.values
                          .map((BookingType type) => DropdownMenuItem<BookingType>(value: type, child: Text(type.label)))
                          .toList(),
                      onChanged: (BookingType? value) {
                        if (value != null) setDialogState(() => selected = value);
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
                          final String? result = await controller.submitBooking(link.text, selected);
                          if (!dialogContext.mounted) return;
                          if (result == null) {
                            Navigator.pop(dialogContext);
                            _message(context, 'Booking submitted for admin review.');
                          } else {
                            setDialogState(() => error = result);
                          }
                        },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
    link.dispose();
  }

  bool get _usesLightArtwork => controller.agentPage != AgentPage.useSpecialCard;

  Widget _valueText(double left, double top, double width, double height, String value, {double fontSize = 26}) {
    return _text(left, top, width, height, value, fontSize: fontSize, color: _usesLightArtwork ? const Color(0xFF17396C) : Colors.white, align: TextAlign.center, weight: FontWeight.w900);
  }

  Widget _text(
    double left,
    double top,
    double width,
    double height,
    String value, {
    double fontSize = 16,
    Color? color,
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
            color: color ?? (_usesLightArtwork ? const Color(0xFF17396C) : Colors.white),
            fontSize: fontSize,
            fontWeight: weight,
            shadows: _usesLightArtwork ? const <Shadow>[] : const <Shadow>[Shadow(color: Colors.black, blurRadius: 5)],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF62E78B);
      case 'rejected':
        return const Color(0xFFFF6B72);
      default:
        return const Color(0xFFFFC62B);
    }
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


class _AgentInfoLine extends StatelessWidget {
  const _AgentInfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 17, color: const Color(0xFF2E7BD8)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF536A84),
              fontSize: 11.5,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _AgentRevealFlipCard extends StatelessWidget {
  const _AgentRevealFlipCard({required this.outcome});

  final CardOutcome outcome;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<String>('${outcome.title}-${outcome.number}-${outcome.points}'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOutCubic,
      builder: (BuildContext context, double value, Widget? child) {
        final double angle = math.pi * value;
        final bool showFront = value >= 0.5;
        final Matrix4 transform = Matrix4.identity()
          ..setEntry(3, 2, 0.0016)
          ..rotateY(angle);
        return Transform(
          alignment: Alignment.center,
          transform: transform,
          child: showFront
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: _front(),
                )
              : _back(),
        );
      },
    );
  }

  Widget _back() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF163E73),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8B968), width: 3),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x332E7BD8), blurRadius: 24, spreadRadius: 3),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF88B9E9), width: 1.3),
              ),
            ),
          ),
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.bolt_rounded, color: Color(0xFFEBC48F), size: 54),
                SizedBox(height: 6),
                Text('M&S', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                SizedBox(height: 4),
                Text('NESTING CHAMPIONS', style: TextStyle(color: Color(0xFFBFDDF7), fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _front() {
    final Color accent = switch (outcome.tone) {
      CardTone.positive => const Color(0xFF2E9F69),
      CardTone.negative => const Color(0xFFC9565C),
      CardTone.special => const Color(0xFF7E57C2),
      CardTone.neutral => const Color(0xFF2E7BD8),
    };
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.fromLTRB(26, 20, 26, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEBC48F), width: 2.5),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x242E7BD8), blurRadius: 24, spreadRadius: 2),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(18)),
            child: Icon(outcome.isSpecial ? Icons.auto_awesome_rounded : Icons.bolt_rounded, color: accent, size: 30),
          ),
          const SizedBox(height: 10),
          Text(outcome.title, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF17396C), fontSize: 24, fontWeight: FontWeight.w900)),
          if (outcome.number != null) ...<Widget>[
            const SizedBox(height: 4),
            Text('${outcome.number}', style: TextStyle(color: accent, fontSize: 36, height: 1, fontWeight: FontWeight.w900)),
          ],
          const SizedBox(height: 7),
          Text(outcome.description, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF667B94), fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
