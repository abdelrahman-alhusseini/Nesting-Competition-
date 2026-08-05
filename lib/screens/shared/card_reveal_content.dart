import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/booking_type.dart';
import '../../models/card_outcome.dart';
import '../../models/navigation.dart';
import '../../state/app_controller.dart';
import '../../widgets/neon_widgets.dart';

class CardRevealContent extends StatefulWidget {
  const CardRevealContent({
    required this.controller,
    required this.adminTest,
    super.key,
  });

  final AppController controller;
  final bool adminTest;

  @override
  State<CardRevealContent> createState() => _CardRevealContentState();
}

class _CardRevealContentState extends State<CardRevealContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..forward().whenComplete(widget.controller.finishRevealSound);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CardOutcome outcome = widget.controller.currentOutcome ??
        const CardOutcome(
          title: 'No card',
          description: 'Return and draw a card.',
          tone: CardTone.neutral,
        );

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.adminTest ? 'ADMIN CARD TEST' : 'CARD REVEAL',
                    style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.adminTest
                        ? '${widget.controller.adminTestBookingType.label} • unlimited test mode'
                        : 'Your card has been revealed.',
                    style: const TextStyle(fontSize: 18, color: Color(0xFFB7C8DD)),
                  ),
                ],
              ),
            ),
            if (widget.adminTest)
              const Chip(
                avatar: Icon(Icons.science, color: gold),
                label: Text('NO POINTS OR DATA ARE SAVED'),
              ),
          ],
        ),
        const SizedBox(height: 28),
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (BuildContext context, Widget? child) {
                      final double value = Curves.easeInOut.transform(_animationController.value);
                      final double angle = value * math.pi;
                      final bool front = value >= 0.5;
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0013)
                          ..rotateY(angle),
                        child: front
                            ? Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateY(math.pi),
                                child: _CardFace(outcome: outcome),
                              )
                            : const _CardBack(),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 30),
              Expanded(
                flex: 2,
                child: NeonPanel(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Icon(_iconFor(outcome), size: 70, color: _colorFor(outcome)),
                      const SizedBox(height: 20),
                      Text(
                        outcome.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: _colorFor(outcome),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        outcome.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 19, color: Color(0xFFC1CDDC)),
                      ),
                      if (widget.controller.gamblePending) ...<Widget>[
                        const SizedBox(height: 30),
                        FilledButton(
                          onPressed: () => widget.controller.keepEvenCardPoint(
                            adminTest: widget.adminTest,
                          ),
                          style: goldButtonStyle(),
                          child: const Text('KEEP +1'),
                        ),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: () => widget.controller.gambleEvenCard(
                            adminTest: widget.adminTest,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFB11F36),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          child: const Text('GAMBLE: +4 OR -6'),
                        ),
                      ] else ...<Widget>[
                        const SizedBox(height: 30),
                        if (widget.adminTest) ...<Widget>[
                          FilledButton.icon(
                            onPressed: widget.controller.returnToAdminTestDraw,
                            style: goldButtonStyle(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('DRAW ANOTHER'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () => widget.controller.openAdminPage(AdminPage.dashboard),
                            child: const Text('BACK TO ADMIN DASHBOARD'),
                          ),
                        ] else if (widget.controller.specialStoragePending) ...<Widget>[
                          if (widget.controller.savedSpecialCard == null)
                            FilledButton.icon(
                              onPressed: widget.controller.busy
                                  ? null
                                  : () => _saveSpecialCard(replaceExisting: false),
                              style: goldButtonStyle(),
                              icon: const Icon(Icons.save),
                              label: const Text('SAVE SPECIAL CARD'),
                            )
                          else ...<Widget>[
                            FilledButton.icon(
                              onPressed: widget.controller.busy
                                  ? null
                                  : () => _saveSpecialCard(replaceExisting: true),
                              style: goldButtonStyle(),
                              icon: const Icon(Icons.swap_horiz),
                              label: const Text('REPLACE SAVED CARD'),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: widget.controller.busy
                                  ? null
                                  : () => _saveSpecialCard(replaceExisting: false),
                              child: const Text('KEEP CURRENT CARD'),
                            ),
                          ],
                        ] else
                          FilledButton(
                            onPressed: widget.controller.continueAfterAgentReveal,
                            style: goldButtonStyle(),
                            child: const Text('CONTINUE'),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Future<void> _saveSpecialCard({required bool replaceExisting}) async {
    final String? error = await widget.controller.saveCurrentSpecialCard(
      replaceExisting: replaceExisting,
    );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    widget.controller.continueAfterAgentReveal();
  }

  Color _colorFor(CardOutcome outcome) {
    switch (outcome.tone) {
      case CardTone.positive:
        return const Color(0xFFBD6BFF);
      case CardTone.negative:
        return const Color(0xFFFF4E4E);
      case CardTone.special:
        return gold;
      case CardTone.neutral:
        return const Color(0xFF68A9FF);
    }
  }

  IconData _iconFor(CardOutcome outcome) {
    if (outcome.isSpecial) {
      return Icons.auto_awesome;
    }
    if (outcome.points > 0) {
      return Icons.add_circle_outline;
    }
    if (outcome.points < 0) {
      return Icons.remove_circle_outline;
    }
    return Icons.block;
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 330,
      height: 480,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF082C62), Color(0xFF020C1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFD7EAFF), width: 7),
        boxShadow: <BoxShadow>[
          BoxShadow(color: const Color(0xFF368CFF).withOpacity(0.8), blurRadius: 35),
        ],
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.workspace_premium, size: 92, color: gold),
          SizedBox(height: 18),
          Text('MICHAEL & SON', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          Text('NESTING', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900)),
          Text('CHAMPIONS', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: gold)),
        ],
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({required this.outcome});

  final CardOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final Color color = outcome.isSpecial
        ? gold
        : outcome.isNegative
            ? const Color(0xFFFF3E4D)
            : outcome.points > 0
                ? const Color(0xFF9F42FF)
                : const Color(0xFF3E8FFF);

    return Container(
      width: 330,
      height: 480,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[color.withOpacity(0.72), const Color(0xFF16062E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: color.withOpacity(0.95), width: 6),
        boxShadow: <BoxShadow>[
          BoxShadow(color: color.withOpacity(0.8), blurRadius: 38),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(outcome.isSpecial ? Icons.auto_awesome : Icons.handyman, size: 94, color: Colors.white),
          const SizedBox(height: 28),
          Text(
            outcome.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),
          Text(
            outcome.isSpecial ? 'SPECIAL CARD' : 'CARD RESULT',
            style: TextStyle(fontSize: 20, letterSpacing: 2, color: color),
          ),
        ],
      ),
    );
  }
}
