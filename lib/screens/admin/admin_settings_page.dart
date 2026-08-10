import 'package:flutter/material.dart';

import '../../models/database/game_settings.dart';
import '../../state/app_controller.dart';
import 'admin_image_scaffold.dart';
import 'admin_live_scaffold.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AdminImageScaffold(
      controller: controller,
      assetPath: 'assets/images/v11/admin_settings.png',
      children: <Widget>[
        _configureButton(context, left: 388, top: 588, label: 'Configure', onTap: () => _showDrawEngine(context)),
        _configureButton(context, left: 806, top: 588, label: 'Configure', onTap: () => _showInfo(context, 'Notifications', 'Notification preferences are not part of the current Supabase game_settings schema yet. No fake values will be saved here.')),
        _configureButton(context, left: 1223, top: 588, label: 'Configure', onTap: () => _showInfo(context, 'Integrations', 'The live integration used by this app is Supabase. Additional integration settings can be added when the backend schema supports them.')),
        _configureButton(context, left: 388, top: 792, label: 'Configure', onTap: () => _showStorageRules(context)),
        _configureButton(context, left: 806, top: 792, label: 'Configure', onTap: () => _showInfo(context, 'Backup & Recovery', 'Backup and recovery controls are deployment-level settings and are not stored in the current game_settings table.')),
        _configureButton(context, left: 1223, top: 792, label: 'Configure', onTap: () => _showPendingDrawLimit(context)),
      ],
    );
  }

  Widget _configureButton(BuildContext context, {required double left, required double top, required String label, required VoidCallback onTap}) {
    return Positioned(
      left: left,
      top: top,
      width: 132,
      height: 42,
      child: OutlinedButton.icon(
        onPressed: controller.busy ? null : onTap,
        icon: const Icon(Icons.tune_rounded, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: adminBlue,
          backgroundColor: const Color(0xF7FFFFFF),
          side: const BorderSide(color: Color(0xFFB8D7F6)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Future<void> _showDrawEngine(BuildContext context) async {
    final GameSettings? base = controller.gameSettings;
    if (base == null) {
      _snack(context, 'No game_settings record is available in Supabase.', true);
      return;
    }

    final normal = TextEditingController(text: _percent(base.normalSpecialChance));
    final crossSell = TextEditingController(text: _percent(base.crossSellSpecialChance));
    final remodeling = TextEditingController(text: _percent(base.remodelingSpecialChance));
    final due = TextEditingController(text: _percent(base.dueInspectionSpecialChance));
    final restoration = TextEditingController(text: _percent(base.restorationSpecialChance));
    final number = TextEditingController(text: _percent(base.numberPoolChance));
    final plusTwo = TextEditingController(text: _percent(base.plusTwoChance));
    final plusFour = TextEditingController(text: _percent(base.plusFourChance));
    final reverse = TextEditingController(text: _percent(base.reverseChance));
    final skip = TextEditingController(text: _percent(base.skipChance));
    final gamblePlusFour = TextEditingController(text: _percent(base.gamblePlusFourChance));
    final gambleMinusSix = TextEditingController(text: _percent(base.gambleMinusSixChance));

    await showAdminDialog<void>(
      context: context,
      title: 'Draw Engine Settings',
      width: 760,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text('SPECIAL-CARD CHANCE BY BOOKING TYPE', style: TextStyle(color: adminNavy, fontWeight: FontWeight.w900, fontSize: 11)),
          const SizedBox(height: 12),
          _pair(_percentField(normal, 'Normal Booking'), _percentField(crossSell, 'Cross-Sell')),
          const SizedBox(height: 10),
          _pair(_percentField(remodeling, 'Remodeling Cross-Sell'), _percentField(due, 'Due Inspection')),
          const SizedBox(height: 10),
          _pair(_percentField(restoration, 'Restoration'), const SizedBox.shrink()),
          const SizedBox(height: 20),
          const Text('REGULAR DRAW DISTRIBUTION', style: TextStyle(color: adminNavy, fontWeight: FontWeight.w900, fontSize: 11)),
          const SizedBox(height: 12),
          _pair(_percentField(number, 'Number Cards'), _percentField(plusTwo, '+2 Cards')),
          const SizedBox(height: 10),
          _pair(_percentField(plusFour, '+4 Cards'), _percentField(reverse, 'Reverse Cards')),
          const SizedBox(height: 10),
          _pair(_percentField(skip, 'Skip Cards'), const SizedBox.shrink()),
          const SizedBox(height: 20),
          const Text('EVEN-NUMBER GAMBLE OUTCOME', style: TextStyle(color: adminNavy, fontWeight: FontWeight.w900, fontSize: 11)),
          const SizedBox(height: 12),
          _pair(_percentField(gamblePlusFour, '+4 Win Chance'), _percentField(gambleMinusSix, '-6 Loss Chance')),
          const SizedBox(height: 8),
          const Text('These two percentages must total 100%. They control the gamble after an even number is drawn.', style: TextStyle(color: adminNavy, fontSize: 11, height: 1.35)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: adminBabyBlue, borderRadius: BorderRadius.circular(12), border: Border.all(color: adminBorder)),
            child: const Text('Percentages are stored as decimals in Supabase. Enter values from 0 to 100 here.', style: TextStyle(color: adminNavy, fontSize: 11)),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: controller.busy
                  ? null
                  : () async {
                      final List<double?> values = <double?>[
                        _readPercent(normal),
                        _readPercent(crossSell),
                        _readPercent(remodeling),
                        _readPercent(due),
                        _readPercent(restoration),
                        _readPercent(number),
                        _readPercent(plusTwo),
                        _readPercent(plusFour),
                        _readPercent(reverse),
                        _readPercent(skip),
                        _readPercent(gamblePlusFour),
                        _readPercent(gambleMinusSix),
                      ];
                      if (values.any((value) => value == null || value! < 0 || value > 1)) {
                        _snack(context, 'Every percentage must be between 0 and 100.', true);
                        return;
                      }
                      final double gambleTotal = values[10]! + values[11]!;
                      if ((gambleTotal - 1.0).abs() > 0.0001) {
                        _snack(context, 'The +4 and -6 gamble percentages must total 100%.', true);
                        return;
                      }
                      final GameSettings updated = base.copyWith(
                        normalSpecialChance: values[0],
                        crossSellSpecialChance: values[1],
                        remodelingSpecialChance: values[2],
                        dueInspectionSpecialChance: values[3],
                        restorationSpecialChance: values[4],
                        numberPoolChance: values[5],
                        plusTwoChance: values[6],
                        plusFourChance: values[7],
                        reverseChance: values[8],
                        skipChance: values[9],
                        gamblePlusFourChance: values[10],
                        gambleMinusSixChance: values[11],
                      );
                      final String? error = await controller.saveGameSettings(updated);
                      if (!context.mounted) return;
                      if (error != null) {
                        _snack(context, error, true);
                        return;
                      }
                      Navigator.of(context).pop();
                      _snack(context, 'Draw percentages updated.', false);
                    },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Percentages'),
              style: adminPrimaryButtonStyle(),
            ),
          ),
        ],
      ),
    );

    for (final TextEditingController c in <TextEditingController>[normal, crossSell, remodeling, due, restoration, number, plusTwo, plusFour, reverse, skip, gamblePlusFour, gambleMinusSix]) {
      c.dispose();
    }
  }

  Future<void> _showStorageRules(BuildContext context) async {
    final GameSettings? base = controller.gameSettings;
    if (base == null) {
      _snack(context, 'No game_settings record is available in Supabase.', true);
      return;
    }
    final saved = TextEditingController(text: '${base.maxSavedSpecialCards}');
    final expiry = TextEditingController(text: '${base.specialExpiryBookings}');
    await showAdminDialog<void>(
      context: context,
      title: 'Data & Security Rules',
      child: Column(
        children: <Widget>[
          TextField(controller: saved, keyboardType: TextInputType.number, style: const TextStyle(color: adminNavy, fontWeight: FontWeight.w800), decoration: const InputDecoration(labelText: 'Max saved special cards (1–3)')),
          const SizedBox(height: 12),
          TextField(controller: expiry, keyboardType: TextInputType.number, style: const TextStyle(color: adminNavy, fontWeight: FontWeight.w800), decoration: const InputDecoration(labelText: 'Special card expiry (bookings)')),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: controller.busy
                  ? null
                  : () async {
                      final int? savedValue = int.tryParse(saved.text.trim());
                      final int? expiryValue = int.tryParse(expiry.text.trim());
                      if (savedValue == null || savedValue < 1 || savedValue > 3 || expiryValue == null || expiryValue < 1) {
                        _snack(context, 'Enter valid whole numbers.', true);
                        return;
                      }
                      final String? error = await controller.saveGameSettings(base.copyWith(maxSavedSpecialCards: savedValue, specialExpiryBookings: expiryValue));
                      if (!context.mounted) return;
                      if (error != null) {
                        _snack(context, error, true);
                        return;
                      }
                      Navigator.of(context).pop();
                      _snack(context, 'Storage rules updated.', false);
                    },
              style: adminPrimaryButtonStyle(),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
    saved.dispose();
    expiry.dispose();
  }

  Future<void> _showPendingDrawLimit(BuildContext context) async {
    await showAdminDialog<void>(
      context: context,
      title: 'System & Maintenance',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: adminBabyBlue,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: adminBorder),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Pending Draw Policy', style: TextStyle(color: adminNavy, fontWeight: FontWeight.w900, fontSize: 16)),
            SizedBox(height: 10),
            Text(
              'Agents can hold any number of approved pending draws. Each draw expires exactly 24 hours after it is granted. Approving several bookings at once will no longer discard older draws.',
              style: TextStyle(color: adminNavy, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showInfo(BuildContext context, String title, String message) {
    return showAdminDialog<void>(
      context: context,
      title: title,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: adminBabyBlue, borderRadius: BorderRadius.circular(14), border: Border.all(color: adminBorder)),
        child: Text(message, style: const TextStyle(color: adminNavy, height: 1.5)),
      ),
    );
  }

  Widget _pair(Widget left, Widget right) => Row(children: <Widget>[Expanded(child: left), const SizedBox(width: 12), Expanded(child: right)]);

  Widget _percentField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: adminNavy, fontWeight: FontWeight.w800),
      cursorColor: adminBlue,
      decoration: InputDecoration(
        labelText: label,
        suffixText: '%',
        labelStyle: const TextStyle(color: adminNavy, fontWeight: FontWeight.w700),
        floatingLabelStyle: const TextStyle(color: adminBlue, fontWeight: FontWeight.w900),
        suffixStyle: const TextStyle(color: adminNavy, fontWeight: FontWeight.w900),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(11)),
          borderSide: BorderSide(color: Color(0xFFB8CEE4), width: 1.25),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(11)),
          borderSide: BorderSide(color: adminBlue, width: 2.1),
        ),
      ),
    );
  }

  String _percent(double value) => (value * 100).toStringAsFixed(0);
  double? _readPercent(TextEditingController controller) {
    final double? value = double.tryParse(controller.text.trim());
    return value == null ? null : value / 100;
  }

  void _snack(BuildContext context, String message, bool error) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), backgroundColor: error ? adminRed : adminGreen));
  }
}
