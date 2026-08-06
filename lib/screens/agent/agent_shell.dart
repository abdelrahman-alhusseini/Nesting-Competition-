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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        assetPath: _assetFor(controller.agentPage),
        children: <Widget>[
          ..._navigationHotspots(),
          ..._pageOverlay(context),
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
        return 'assets/images/agent_card_reveal.png';
      case AgentPage.myCards:
        return 'assets/images/agent_my_cards.png';
      case AgentPage.useSpecialCard:
        return 'assets/images/agent_use_special.png';
      case AgentPage.leaderboard:
        return 'assets/images/agent_leaderboard.png';
      case AgentPage.activityFeed:
        return 'assets/images/agent_activity.png';
      case AgentPage.rewards:
        return 'assets/images/agent_rewards.png';
      case AgentPage.howToPlay:
        return 'assets/images/agent_how_to_play.png';
    }
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
      ImageHotspot(rect: row(6), label: 'Rewards', onTap: () => controller.openAgentPage(AgentPage.rewards)),
      ImageHotspot(rect: row(7), label: 'How to Play', onTap: () => controller.openAgentPage(AgentPage.howToPlay)),
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
      case AgentPage.rewards:
      case AgentPage.howToPlay:
        return const <Widget>[];
    }
  }

  List<Widget> _dashboardOverlay() {
    final List<LeaderboardEntry> leaders = controller.leaderboard.take(5).toList();
    return <Widget>[
      _valueText(635, 744, 118, 50, '${controller.agentScore}'),
      _valueText(770, 744, 118, 50, '${controller.pendingDraws}'),
      _valueText(905, 744, 118, 50, controller.savedSpecialCard == null ? '—' : 'SAVED', fontSize: 21),
      _valueText(1084, 744, 110, 50, controller.profile?.title ?? 'Rookie', fontSize: 18),
      for (int i = 0; i < leaders.length; i++) ...<Widget>[
        _text(1110, 264 + i * 46, 280, 32, leaders[i].displayName, fontSize: 18),
        _text(1450, 264 + i * 46, 105, 32, '${leaders[i].score}', fontSize: 18, color: const Color(0xFFFFC62B), align: TextAlign.right),
      ],
      for (int i = 0; i < controller.activity.take(5).length; i++)
        _text(370, 584 + i * 47, 200, 32, controller.activity[i], fontSize: 14),
    ];
  }

  List<Widget> _bookingsOverlay(BuildContext context) {
    final List<BookingRecord> rows = controller.myBookings.take(3).toList();
    final int approved = controller.myBookings.where((BookingRecord item) => item.status == 'approved').length;
    return <Widget>[
      ImageHotspot(
        rect: const Rect.fromLTWH(454, 500, 552, 60),
        label: 'Submit booking',
        onTap: () => _showSubmitBookingDialog(context),
      ),
      _valueText(456, 850, 190, 52, '${controller.bookingCount}'),
      _valueText(786, 850, 190, 52, '$approved'),
      _valueText(1125, 850, 190, 52, '${controller.pendingDraws}'),
      for (int i = 0; i < rows.length; i++) ...<Widget>[
        _text(354, 678 + i * 43, 145, 28, rows[i].jobId ?? '—', fontSize: 15),
        _text(516, 678 + i * 43, 225, 28, rows[i].bookingType.label, fontSize: 15),
        _text(760, 678 + i * 43, 180, 28, rows[i].status.toUpperCase(), fontSize: 15, color: _statusColor(rows[i].status)),
        _text(1010, 678 + i * 43, 190, 28, _date(rows[i].submittedAt), fontSize: 14),
      ],
    ];
  }

  List<Widget> _drawCardsOverlay(BuildContext context) {
    return <Widget>[
      _valueText(540, 590, 170, 50, '${controller.pendingDraws}', fontSize: 28),
      ImageHotspot(
        rect: const Rect.fromLTWH(440, 480, 310, 78),
        label: 'Draw one card',
        onTap: () async {
          if (controller.pendingDraws == 0) {
            _message(context, 'No approved draws are available yet.');
            return;
          }
          await controller.drawAgentCard();
        },
      ),
      ImageHotspot(
        rect: const Rect.fromLTWH(780, 480, 275, 78),
        label: 'Draw card',
        onTap: () async {
          if (controller.pendingDraws == 0) {
            _message(context, 'No approved draws are available yet.');
            return;
          }
          await controller.drawAgentCard();
        },
      ),
    ];
  }

  List<Widget> _cardRevealOverlay(BuildContext context) {
    final CardOutcome? outcome = controller.currentOutcome;
    if (outcome == null) {
      return <Widget>[
        ImageHotspot(
          rect: const Rect.fromLTWH(680, 780, 300, 90),
          label: 'Return to draw cards',
          onTap: () => controller.openAgentPage(AgentPage.drawCards),
        ),
      ];
    }

    return <Widget>[
      _text(725, 455, 470, 60, outcome.title, fontSize: 30, color: const Color(0xFFFFC62B), align: TextAlign.center, weight: FontWeight.w900),
      _text(725, 530, 470, 95, outcome.description, fontSize: 18, align: TextAlign.center),
      if (outcome.number != null)
        _text(830, 275, 250, 110, '${outcome.number}', fontSize: 78, color: const Color(0xFFFFD35A), align: TextAlign.center, weight: FontWeight.w900),
      ImageHotspot(
        rect: const Rect.fromLTWH(408, 790, 250, 90),
        label: 'Keep card',
        onTap: () async {
          if (outcome.isSpecial) {
            final String? error = await controller.saveCurrentSpecialCard(replaceExisting: true);
            if (context.mounted && error != null) _message(context, error);
          } else if (controller.gamblePending) {
            await controller.keepEvenCardPoint(adminTest: false);
          } else {
            controller.continueAfterAgentReveal();
          }
        },
      ),
      ImageHotspot(
        rect: const Rect.fromLTWH(680, 790, 300, 90),
        label: 'Use or gamble',
        onTap: () async {
          if (controller.gamblePending) {
            await controller.gambleEvenCard(adminTest: false);
          } else if (outcome.isSpecial) {
            final String? error = await controller.saveCurrentSpecialCard(replaceExisting: true);
            if (context.mounted && error == null) {
              controller.openAgentPage(AgentPage.myCards);
            } else if (context.mounted && error != null) {
              _message(context, error);
            }
          } else {
            controller.continueAfterAgentReveal();
          }
        },
      ),
      ImageHotspot(
        rect: const Rect.fromLTWH(1000, 790, 250, 90),
        label: 'Continue',
        onTap: controller.continueAfterAgentReveal,
      ),
    ];
  }

  List<Widget> _myCardsOverlay(BuildContext context) {
    final card = controller.savedSpecialCard;
    return <Widget>[
      if (card != null) ...<Widget>[
        _text(620, 225, 310, 42, card.title, fontSize: 25, color: const Color(0xFFFFC62B), weight: FontWeight.w900),
        _text(620, 285, 340, 100, card.description, fontSize: 17),
        _text(620, 415, 300, 36, '${card.bookingsRemaining} booking(s) remaining', fontSize: 16, color: const Color(0xFF8DEBFF)),
      ],
      ImageHotspot(
        rect: const Rect.fromLTWH(605, 500, 205, 60),
        label: 'Select special card',
        onTap: () {
          if (card == null) {
            _message(context, 'You do not have a saved special card yet.');
          } else {
            controller.openAgentPage(AgentPage.useSpecialCard);
          }
        },
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
    final List<LeaderboardEntry> rows = controller.leaderboard.take(6).toList();
    return <Widget>[
      for (int i = 0; i < rows.length; i++) ...<Widget>[
        _text(390, 575 + i * 54, 90, 34, '${rows[i].rank}', fontSize: 19, align: TextAlign.center, weight: FontWeight.w800),
        _text(520, 575 + i * 54, 270, 34, rows[i].displayName, fontSize: 18),
        _text(815, 575 + i * 54, 250, 34, rows[i].title, fontSize: 17),
        _text(1100, 575 + i * 54, 140, 34, '${rows[i].score}', fontSize: 19, color: const Color(0xFFFFC62B), align: TextAlign.right, weight: FontWeight.w900),
      ],
    ];
  }

  List<Widget> _activityOverlay() {
    final List<String> rows = controller.activity.take(7).toList();
    return <Widget>[
      for (int i = 0; i < rows.length; i++)
        _text(360, 424 + i * 58, 820, 40, rows[i], fontSize: 16),
    ];
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
