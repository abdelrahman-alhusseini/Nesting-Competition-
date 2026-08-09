import 'package:flutter/material.dart';

import '../../state/app_controller.dart';
import 'admin_image_scaffold.dart';
import 'admin_live_scaffold.dart';

class AdminAuditHistoryPage extends StatefulWidget {
  const AdminAuditHistoryPage({required this.controller, super.key});

  final AppController controller;

  @override
  State<AdminAuditHistoryPage> createState() => _AdminAuditHistoryPageState();
}

class _AdminAuditHistoryPageState extends State<AdminAuditHistoryPage> {
  final TextEditingController _search = TextEditingController();
  String _action = 'all';
  Map<String, dynamic>? _selected;

  AppController get controller => widget.controller;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String q = _search.text.trim().toLowerCase();
    final List<String> actionValues = <String>{
      'all',
      ...controller.auditHistory.map((item) => (item['action'] as String?) ?? 'unknown'),
    }.toList();

    final List<Map<String, dynamic>> rows = controller.auditHistory.where((Map<String, dynamic> item) {
      final String action = ((item['action'] as String?) ?? '').toLowerCase();
      final String entity = ((item['entity_type'] as String?) ?? '').toLowerCase();
      final Map<String, dynamic>? actor = item['profiles'] as Map<String, dynamic>?;
      final String actorName = ((actor?['display_name'] as String?) ?? (actor?['username'] as String?) ?? 'system').toLowerCase();
      final bool queryMatch = q.isEmpty || action.contains(q) || entity.contains(q) || actorName.contains(q);
      final bool actionMatch = _action == 'all' || action == _action;
      return queryMatch && actionMatch;
    }).toList();

    if (_selected != null && !rows.any((item) => item['id'] == _selected!['id'])) _selected = null;

    return AdminImageScaffold(
      controller: controller,
      assetPath: 'assets/images/v11/admin_audit_history.png',
      children: <Widget>[
        Positioned(
          left: 322,
          top: 183,
          width: 830,
          height: 54,
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 5,
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(hintText: 'Search actor, action, or entity…', prefixIcon: Icon(Icons.search_rounded, color: adminBlue)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: _action,
                  dropdownColor: const Color(0xFFFCFEFF),
                  decoration: const InputDecoration(labelText: 'Action', prefixIcon: Icon(Icons.filter_alt_outlined, color: adminBlue)),
                  items: actionValues
                      .map((value) => DropdownMenuItem<String>(value: value, child: Text(value == 'all' ? 'All actions' : value.replaceAll('_', ' '))))
                      .toList(),
                  onChanged: (String? value) {
                    if (value != null) setState(() => _action = value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: controller.busy ? null : controller.refreshAll,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
                style: adminSecondaryButtonStyle(),
              ),
            ],
          ),
        ),
        Positioned(
          left: 320,
          top: 253,
          width: 850,
          height: 560,
          child: rows.isEmpty
              ? adminEmptyMessage(icon: Icons.history_toggle_off_outlined, title: 'No audit events found', message: 'Try changing the filters or search query.')
              : _AuditTable(rows: rows, selectedId: _selected?['id'] as String?, onSelect: (item) => setState(() => _selected = item)),
        ),
        Positioned(
          left: 1220,
          top: 190,
          width: 330,
          height: 610,
          child: _selected == null
              ? adminEmptyMessage(icon: Icons.article_outlined, title: 'Select an event', message: 'Choose an audit row to inspect the stored details.')
              : _AuditDetails(item: _selected!),
        ),
      ],
    );
  }
}

class _AuditTable extends StatelessWidget {
  const _AuditTable({required this.rows, required this.selectedId, required this.onSelect});

  final List<Map<String, dynamic>> rows;
  final String? selectedId;
  final ValueChanged<Map<String, dynamic>> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: adminBabyBlue, borderRadius: BorderRadius.circular(10)),
          child: const Row(
            children: <Widget>[
              Expanded(flex: 3, child: Text('WHEN', style: _auditHead)),
              Expanded(flex: 2, child: Text('ACTOR', style: _auditHead)),
              Expanded(flex: 3, child: Text('ACTION', style: _auditHead)),
              Expanded(flex: 2, child: Text('ENTITY', style: _auditHead)),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Expanded(
          child: ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: adminBorder),
            itemBuilder: (BuildContext context, int index) {
              final Map<String, dynamic> item = rows[index];
              final Map<String, dynamic>? actor = item['profiles'] as Map<String, dynamic>?;
              final bool selected = item['id'] == selectedId;
              return Material(
                color: selected ? adminBabyBlue.withValues(alpha: 0.60) : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                child: InkWell(
                  onTap: () => onSelect(item),
                  borderRadius: BorderRadius.circular(9),
                  child: SizedBox(
                    height: 50,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: <Widget>[
                          Expanded(flex: 3, child: _text(_format(item['created_at']))),
                          Expanded(flex: 2, child: _text((actor?['display_name'] as String?) ?? (actor?['username'] as String?) ?? 'System', bold: true)),
                          Expanded(flex: 3, child: _text(((item['action'] as String?) ?? '—').replaceAll('_', ' '))),
                          Expanded(flex: 2, child: _text((item['entity_type'] as String?) ?? '—')),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static Widget _text(String value, {bool bold = false}) => Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: adminNavy, fontSize: 10.5, fontWeight: bold ? FontWeight.w800 : FontWeight.w600));

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

class _AuditDetails extends StatelessWidget {
  const _AuditDetails({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? actor = item['profiles'] as Map<String, dynamic>?;
    final Map<String, dynamic> details = (item['details'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 12),
        _row('Actor', (actor?['display_name'] as String?) ?? (actor?['username'] as String?) ?? 'System'),
        _row('Action', ((item['action'] as String?) ?? '—').replaceAll('_', ' ')),
        _row('Entity', (item['entity_type'] as String?) ?? '—'),
        _row('Entity ID', (item['entity_id'] as String?) ?? '—'),
        const SizedBox(height: 14),
        const Text('DETAILS', style: TextStyle(color: adminNavy, fontSize: 11, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(color: adminBabyBlue.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(13), border: Border.all(color: adminBorder)),
            child: SelectableText(
              details.isEmpty ? 'No additional details were stored.' : details.entries.map((entry) => '${entry.key}: ${entry.value}').join('\n'),
              style: const TextStyle(color: adminNavy, fontSize: 10.5, height: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 78, child: Text(label, style: const TextStyle(color: adminMuted, fontSize: 10, fontWeight: FontWeight.w700))),
          Expanded(child: Text(value, style: const TextStyle(color: adminNavy, fontSize: 10.5, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

const TextStyle _auditHead = TextStyle(color: adminNavy, fontWeight: FontWeight.w900, fontSize: 10);
