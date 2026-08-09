import 'package:flutter/material.dart';

import '../../models/booking_type.dart';
import '../../models/database/booking_record.dart';
import '../../state/app_controller.dart';
import 'admin_image_scaffold.dart';
import 'admin_live_scaffold.dart';

class AdminApprovalsPage extends StatefulWidget {
  const AdminApprovalsPage({required this.controller, super.key});

  final AppController controller;

  @override
  State<AdminApprovalsPage> createState() => _AdminApprovalsPageState();
}

class _AdminApprovalsPageState extends State<AdminApprovalsPage> {
  final TextEditingController _search = TextEditingController();
  String _type = 'all';
  BookingRecord? _selected;

  AppController get controller => widget.controller;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String q = _search.text.trim().toLowerCase();
    final List<BookingRecord> rows = controller.pendingBookings.where((BookingRecord booking) {
      final bool queryMatch = q.isEmpty ||
          booking.agentName.toLowerCase().contains(q) ||
          (booking.jobId ?? '').toLowerCase().contains(q) ||
          booking.jobUrl.toLowerCase().contains(q);
      final bool typeMatch = _type == 'all' || booking.bookingType.databaseValue == _type;
      return queryMatch && typeMatch;
    }).toList();

    if (_selected != null && !rows.any((b) => b.id == _selected!.id)) {
      _selected = null;
    }

    return AdminImageScaffold(
      controller: controller,
      assetPath: 'assets/images/v11/admin_approvals.png',
      children: <Widget>[
        Positioned(
          left: 325,
          top: 185,
          width: 745,
          height: 55,
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search bookings…',
                    prefixIcon: Icon(Icons.search_rounded, color: adminBlue),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: _type,
                  dropdownColor: const Color(0xFFFCFEFF),
                  decoration: const InputDecoration(
                    labelText: 'Booking type',
                    prefixIcon: Icon(Icons.filter_alt_outlined, color: adminBlue),
                  ),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(value: 'all', child: Text('All booking types')),
                    DropdownMenuItem(value: 'normal', child: Text('Normal Booking')),
                    DropdownMenuItem(value: 'cross_sell', child: Text('Cross-Sell Booking')),
                    DropdownMenuItem(value: 'remodeling_cross_sell', child: Text('Remodeling Cross-Sell')),
                    DropdownMenuItem(value: 'due_inspection', child: Text('Due Inspection')),
                    DropdownMenuItem(value: 'restoration', child: Text('Restoration')),
                  ],
                  onChanged: (String? value) {
                    if (value != null) setState(() => _type = value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: OutlinedButton.icon(
                  onPressed: controller.busy ? null : controller.refreshAll,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                  style: adminSecondaryButtonStyle(),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 322,
          top: 255,
          width: 760,
          height: 555,
          child: _BookingTable(
            rows: rows,
            selectedId: _selected?.id,
            onSelect: (BookingRecord booking) => setState(() => _selected = booking),
          ),
        ),
        Positioned(
          left: 1140,
          top: 235,
          width: 395,
          height: 560,
          child: _selected == null
              ? adminEmptyMessage(
                  icon: Icons.touch_app_outlined,
                  title: 'Select a booking',
                  message: 'Choose a pending booking on the left to review its details.',
                )
              : _BookingReviewPanel(
                  key: ValueKey<String>(_selected!.id),
                  controller: controller,
                  booking: _selected!,
                  onFinished: () => setState(() => _selected = null),
                ),
        ),
      ],
    );
  }
}

class _BookingTable extends StatelessWidget {
  const _BookingTable({required this.rows, required this.selectedId, required this.onSelect});

  final List<BookingRecord> rows;
  final String? selectedId;
  final ValueChanged<BookingRecord> onSelect;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return adminEmptyMessage(
        icon: Icons.fact_check_outlined,
        title: 'No bookings awaiting approval',
        message: 'Pending booking requests from Supabase will appear here automatically.',
      );
    }
    return Column(
      children: <Widget>[
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: adminBabyBlue, borderRadius: BorderRadius.circular(10)),
          child: const Row(
            children: <Widget>[
              Expanded(flex: 2, child: Text('JOB ID', style: _headStyle)),
              Expanded(flex: 2, child: Text('AGENT', style: _headStyle)),
              Expanded(flex: 3, child: Text('BOOKING TYPE', style: _headStyle)),
              Expanded(flex: 2, child: Text('SUBMITTED', style: _headStyle)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: adminBorder),
            itemBuilder: (BuildContext context, int index) {
              final BookingRecord booking = rows[index];
              final bool selected = booking.id == selectedId;
              return Material(
                color: selected ? adminBabyBlue.withValues(alpha: 0.60) : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                child: InkWell(
                  onTap: () => onSelect(booking),
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: <Widget>[
                        Expanded(flex: 2, child: _cell(booking.jobId ?? '—', bold: true)),
                        Expanded(flex: 2, child: _cell(booking.agentName)),
                        Expanded(flex: 3, child: _cell(booking.bookingType.label)),
                        Expanded(flex: 2, child: _cell(_date(booking.submittedAt))),
                      ],
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

  static Widget _cell(String value, {bool bold = false}) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: adminNavy, fontSize: 11, fontWeight: bold ? FontWeight.w800 : FontWeight.w600),
    );
  }

  static String _date(DateTime value) {
    final String m = value.month.toString().padLeft(2, '0');
    final String d = value.day.toString().padLeft(2, '0');
    return '${value.year}-$m-$d';
  }
}

class _BookingReviewPanel extends StatefulWidget {
  const _BookingReviewPanel({required this.controller, required this.booking, required this.onFinished, super.key});

  final AppController controller;
  final BookingRecord booking;
  final VoidCallback onFinished;

  @override
  State<_BookingReviewPanel> createState() => _BookingReviewPanelState();
}

class _BookingReviewPanelState extends State<_BookingReviewPanel> {
  late BookingType _type;
  final TextEditingController _reason = TextEditingController();

  @override
  void initState() {
    super.initState();
    _type = widget.booking.bookingType;
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _line('Agent', widget.booking.agentName),
        _line('Job ID', widget.booking.jobId ?? '—'),
        _line('Submitted', _format(widget.booking.submittedAt)),
        const SizedBox(height: 8),
        SelectableText(
          widget.booking.jobUrl,
          maxLines: 3,
          style: const TextStyle(color: adminBlue, fontSize: 11, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<BookingType>(
          initialValue: _type,
          dropdownColor: const Color(0xFFFCFEFF),
          decoration: const InputDecoration(labelText: 'Confirmed booking type'),
          items: BookingType.values
              .map((type) => DropdownMenuItem<BookingType>(value: type, child: Text(type.label)))
              .toList(),
          onChanged: (BookingType? value) {
            if (value != null) setState(() => _type = value);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _reason,
          minLines: 2,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Rejection reason (only if rejecting)', alignLabelWithHint: true),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: widget.controller.busy ? null : () => _submit(context, true),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Approve Booking'),
          style: FilledButton.styleFrom(
            backgroundColor: adminGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: widget.controller.busy ? null : () => _submit(context, false),
          icon: const Icon(Icons.close_rounded),
          label: const Text('Reject Booking'),
          style: OutlinedButton.styleFrom(
            foregroundColor: adminRed,
            side: const BorderSide(color: adminRed),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          SizedBox(width: 90, child: Text(label, style: const TextStyle(color: adminMuted, fontSize: 11, fontWeight: FontWeight.w700))),
          Expanded(child: Text(value, style: const TextStyle(color: adminNavy, fontSize: 12, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context, bool approve) async {
    final String reason = _reason.text.trim();
    if (!approve && reason.isEmpty) {
      _snack(context, 'Enter a rejection reason first.', true);
      return;
    }
    final String? error = await widget.controller.reviewBooking(
      booking: widget.booking,
      approve: approve,
      correctedType: _type,
      rejectionReason: approve ? null : reason,
    );
    if (!context.mounted) return;
    if (error != null) {
      _snack(context, error, true);
      return;
    }
    _snack(context, approve ? 'Booking approved.' : 'Booking rejected.', false);
    widget.onFinished();
  }

  void _snack(BuildContext context, String text, bool error) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), backgroundColor: error ? adminRed : adminGreen));
  }

  String _format(DateTime value) {
    final String m = value.month.toString().padLeft(2, '0');
    final String d = value.day.toString().padLeft(2, '0');
    final String h = value.hour.toString().padLeft(2, '0');
    final String min = value.minute.toString().padLeft(2, '0');
    return '${value.year}-$m-$d $h:$min';
  }
}

const TextStyle _headStyle = TextStyle(color: adminNavy, fontWeight: FontWeight.w900, fontSize: 10);
