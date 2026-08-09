import 'package:flutter/material.dart';

import '../../models/card_outcome.dart';
import '../../state/app_controller.dart';
import 'admin_live_scaffold.dart';

class AdminCardRevealPage extends StatelessWidget {
  const AdminCardRevealPage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final CardOutcome? outcome = controller.currentOutcome;
    final Color accent = _accent(outcome);

    return AdminLiveScaffold(
      controller: controller,
      title: 'Test Card Reveal',
      subtitle: 'Preview the result of a non-destructive test draw.',
      visualAsset: 'assets/images/admin_manual_draw_visual.png',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: AdminPanel(
              child: outcome == null
                  ? const AdminEmptyState(
                      icon: Icons.style_outlined,
                      title: 'No test card is active',
                      message: 'Return to Manual Draw and start a test draw.',
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Center(
                            child: Text(
                              outcome.number?.toString() ?? _shortTitle(outcome.title),
                              style: TextStyle(color: accent, fontSize: 38, fontWeight: FontWeight.w900),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(outcome.title, textAlign: TextAlign.center, style: const TextStyle(color: adminNavy, fontSize: 24, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        Text(outcome.description, textAlign: TextAlign.center, style: const TextStyle(color: adminMuted, fontSize: 14, height: 1.45)),
                        if (outcome.points != 0) ...<Widget>[
                          const SizedBox(height: 12),
                          Text(
                            outcome.points > 0 ? '+${outcome.points} points' : '${outcome.points} points',
                            style: TextStyle(color: accent, fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: <Widget>[
                            OutlinedButton.icon(
                              onPressed: controller.returnToAdminTestDraw,
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('Back to Manual Draw'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: adminNavy,
                                side: const BorderSide(color: adminBorder),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: controller.drawUnlimitedAdminTestCard,
                              icon: const Icon(Icons.casino_outlined),
                              label: const Text('Draw Again'),
                              style: FilledButton.styleFrom(
                                backgroundColor: adminNavy,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            if (controller.gamblePending)
                              FilledButton.icon(
                                onPressed: () => controller.keepEvenCardPoint(adminTest: true),
                                icon: const Icon(Icons.lock_outline_rounded),
                                label: const Text('Keep +1'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: adminBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            if (controller.gamblePending)
                              OutlinedButton.icon(
                                onPressed: () => controller.gambleEvenCard(adminTest: true),
                                icon: const Icon(Icons.bolt_rounded),
                                label: const Text('Gamble 50/50'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: adminRed,
                                  side: const BorderSide(color: adminRed),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  static Color _accent(CardOutcome? outcome) {
    if (outcome == null) return adminBlue;
    if (outcome.isSpecial) return const Color(0xFFC68B31);
    if (outcome.isNegative) return adminRed;
    if (outcome.tone == CardTone.positive) return adminGreen;
    return adminBlue;
  }

  static String _shortTitle(String title) {
    if (title.contains('Skip')) return 'SKIP';
    if (title.contains('Reverse')) return 'REV';
    if (title.contains('+2')) return '+2';
    if (title.contains('+4')) return '+4';
    return 'CARD';
  }
}
