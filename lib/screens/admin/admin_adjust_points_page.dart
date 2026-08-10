import 'package:flutter/material.dart';

import '../../models/app_role.dart';
import '../../models/database/leaderboard_entry.dart';
import '../../models/database/user_profile.dart';
import '../../state/app_controller.dart';
import 'admin_image_scaffold.dart';
import 'admin_live_scaffold.dart';

class AdminAdjustPointsPage extends StatefulWidget {
  const AdminAdjustPointsPage({required this.controller, super.key});

  final AppController controller;

  @override
  State<AdminAdjustPointsPage> createState() => _AdminAdjustPointsPageState();
}

class _AdminAdjustPointsPageState extends State<AdminAdjustPointsPage> {
  UserProfile? _selected;

  AppController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    final List<UserProfile> agents = controller.users.where((u) => u.role == AppRole.agent && u.isActive).toList();
    final List<LeaderboardEntry> leaderboard = controller.leaderboard.toList();
    final List<Map<String, dynamic>> history = controller.auditHistory
        .where((item) => (item['action'] as String?) == 'points_adjusted')
        .take(8)
        .toList();

    return AdminImageScaffold(
      controller: controller,
      assetPath: 'assets/images/v11/admin_adjust_points.png',
      children: <Widget>[
        Positioned(
          left: 310,
          top: 205,
          width: 295,
          height: 290,
          child: _selected == null
              ? adminEmptyMessage(icon: Icons.person_search_outlined, title: 'No user selected', message: 'Choose an agent to adjust their points.')
              : _SelectedAgentCard(user: _selected!),
        ),
        Positioned(
          left: 311,
          top: 507,
          width: 295,
          height: 49,
          child: FilledButton.icon(
            onPressed: controller.busy || agents.isEmpty ? null : () => _showAdjustmentDialog(context, agents),
            icon: const Icon(Icons.group_outlined),
            label: const Text('SELECT A USER'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEAF4FF).withValues(alpha: 0.94),
              foregroundColor: adminBlue,
              elevation: 0,
              side: const BorderSide(color: Color(0xFFB8D7F6)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
            ),
          ),
        ),
        Positioned(
          left: 650,
          top: 198,
          width: 930,
          height: 350,
          child: leaderboard.isEmpty
              ? adminEmptyMessage(icon: Icons.emoji_events_outlined, title: 'No leaderboard data yet', message: 'Scores will appear here as agents earn points.')
              : _LeaderboardTable(entries: leaderboard),
        ),
        Positioned(
          left: 315,
          top: 646,
          width: 1288,
          height: 185,
          child: history.isEmpty
              ? adminEmptyMessage(icon: Icons.history_rounded, title: 'No point adjustments yet', message: 'Point changes will appear here after an administrator makes an adjustment.')
              : _AdjustmentHistory(items: history, users: controller.users),
        ),
      ],
    );
  }

  Future<void> _showAdjustmentDialog(BuildContext context, List<UserProfile> agents) async {
    String? agentId = _selected?.id;
    bool deduct = false;
    final points = TextEditingController();
    final reason = TextEditingController();

    await showAdminDialog<void>(
      context: context,
      title: 'Adjust Agent Points',
      width: 600,
      child: StatefulBuilder(
        builder: (BuildContext dialogContext, StateSetter setDialogState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DropdownButtonFormField<String>(
                initialValue: agentId,
                dropdownColor: const Color(0xFFFCFEFF),
                decoration: const InputDecoration(labelText: 'Agent'),
                hint: const Text('Select an agent'),
                items: agents.map((UserProfile user) => DropdownMenuItem<String>(value: user.id, child: Text(user.displayName))).toList(),
                onChanged: (String? value) => setDialogState(() => agentId = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<bool>(
                initialValue: deduct,
                dropdownColor: const Color(0xFFFCFEFF),
                decoration: const InputDecoration(labelText: 'Adjustment type'),
                items: const <DropdownMenuItem<bool>>[
                  DropdownMenuItem(value: false, child: Text('Add points')),
                  DropdownMenuItem(value: true, child: Text('Deduct points')),
                ],
                onChanged: (bool? value) {
                  if (value != null) setDialogState(() => deduct = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(controller: points, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Points')),
              const SizedBox(height: 12),
              TextField(controller: reason, minLines: 3, maxLines: 4, decoration: const InputDecoration(labelText: 'Reason', alignLabelWithHint: true)),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: controller.busy
                      ? null
                      : () async {
                          final UserProfile? user = _findAgent(agents, agentId);
                          final int? parsed = int.tryParse(points.text.trim());
                          if (user == null) {
                            _snack(dialogContext, 'Select an agent.', true);
                            return;
                          }
                          if (parsed == null || parsed <= 0) {
                            _snack(dialogContext, 'Enter a positive whole number of points.', true);
                            return;
                          }
                          if (reason.text.trim().isEmpty) {
                            _snack(dialogContext, 'A reason is required.', true);
                            return;
                          }
                          final int amount = deduct ? -parsed : parsed;
                          final String? error = await controller.adjustAgentPoints(agentId: user.id, amount: amount, reason: reason.text.trim());
                          if (!dialogContext.mounted) return;
                          if (error != null) {
                            _snack(dialogContext, error, true);
                            return;
                          }
                          Navigator.of(dialogContext).pop();
                          setState(() => _selected = user);
                          _snack(this.context, 'Points updated successfully.', false);
                        },
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Apply Adjustment'),
                  style: adminPrimaryButtonStyle(),
                ),
              ),
            ],
          );
        },
      ),
    );
    points.dispose();
    reason.dispose();
  }

  UserProfile? _findAgent(List<UserProfile> agents, String? id) {
    if (id == null) return null;
    for (final UserProfile user in agents) {
      if (user.id == id) return user;
    }
    return null;
  }

  void _snack(BuildContext context, String message, bool error) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), backgroundColor: error ? adminRed : adminGreen));
  }
}

class _SelectedAgentCard extends StatelessWidget {
  const _SelectedAgentCard({required this.user});
  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        CircleAvatar(
          radius: 44,
          backgroundColor: adminBabyBlue,
          child: Text(user.displayName.isEmpty ? '?' : user.displayName.substring(0, 1).toUpperCase(), style: const TextStyle(color: adminNavy, fontSize: 34, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 14),
        Text(user.displayName, textAlign: TextAlign.center, style: const TextStyle(color: adminNavy, fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 4),
        Text('@${user.username}', style: const TextStyle(color: adminMuted, fontSize: 12)),
      ],
    );
  }
}

class _LeaderboardTable extends StatelessWidget {
  const _LeaderboardTable({required this.entries});
  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: adminBabyBlue, borderRadius: BorderRadius.circular(10)),
          child: const Row(
            children: <Widget>[
              SizedBox(width: 75, child: Text('RANK', style: _adjustHead)),
              Expanded(flex: 3, child: Text('AGENT', style: _adjustHead)),
              Expanded(flex: 2, child: Text('TITLE', style: _adjustHead)),
              SizedBox(width: 110, child: Text('POINTS', style: _adjustHead)),
            ],
          ),
        ),
        Expanded(
          child: Scrollbar(
            thumbVisibility: entries.length > 6,
            child: ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: adminBorder),
              itemBuilder: (BuildContext context, int index) {
                final LeaderboardEntry entry = entries[index];
                return SizedBox(
                  height: 44,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: <Widget>[
                        SizedBox(width: 75, child: Text('#${entry.rank}', style: const TextStyle(color: adminNavy, fontWeight: FontWeight.w900, fontSize: 11))),
                        Expanded(flex: 3, child: Text(entry.displayName, overflow: TextOverflow.ellipsis, style: const TextStyle(color: adminNavy, fontWeight: FontWeight.w700, fontSize: 11))),
                        Expanded(flex: 2, child: Text(entry.title, style: const TextStyle(color: adminMuted, fontSize: 11))),
                        SizedBox(width: 110, child: Text('${entry.score}', style: const TextStyle(color: adminBlue, fontWeight: FontWeight.w900, fontSize: 12))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _AdjustmentHistory extends StatelessWidget {
  const _AdjustmentHistory({required this.items, required this.users});
  final List<Map<String, dynamic>> items;
  final List<UserProfile> users;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: adminBorder),
      itemBuilder: (BuildContext context, int index) {
        final Map<String, dynamic> item = items[index];
        final Map<String, dynamic> details = (item['details'] as Map<String, dynamic>?) ?? <String, dynamic>{};
        final String agentId = (details['agent_id'] as String?) ?? '';
        final int amount = (details['amount'] as num?)?.toInt() ?? 0;
        final String reason = (details['reason'] as String?) ?? 'No reason';
        final UserProfile? user = _find(users, agentId);
        return SizedBox(
          height: 38,
          child: Row(
            children: <Widget>[
              Expanded(flex: 2, child: Text(user?.displayName ?? 'Agent', style: const TextStyle(color: adminNavy, fontWeight: FontWeight.w800, fontSize: 11))),
              SizedBox(width: 90, child: Text(amount >= 0 ? 'ADD' : 'DEDUCT', style: TextStyle(color: amount >= 0 ? adminGreen : adminRed, fontWeight: FontWeight.w900, fontSize: 10))),
              SizedBox(width: 100, child: Text('${amount >= 0 ? '+' : ''}$amount', style: const TextStyle(color: adminNavy, fontWeight: FontWeight.w900, fontSize: 11))),
              Expanded(flex: 4, child: Text(reason, overflow: TextOverflow.ellipsis, style: const TextStyle(color: adminMuted, fontSize: 11))),
              SizedBox(width: 150, child: Text(_format(item['created_at']), style: const TextStyle(color: adminMuted, fontSize: 10))),
            ],
          ),
        );
      },
    );
  }

  static UserProfile? _find(List<UserProfile> users, String id) {
    for (final UserProfile user in users) {
      if (user.id == id) return user;
    }
    return null;
  }

  static String _format(dynamic value) {
    if (value is! String) return '—';
    final DateTime? date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return '—';
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    final String h = date.hour.toString().padLeft(2, '0');
    final String min = date.minute.toString().padLeft(2, '0');
    return '${date.year}-$m-$d $h:$min';
  }
}

const TextStyle _adjustHead = TextStyle(color: adminNavy, fontWeight: FontWeight.w900, fontSize: 10);
