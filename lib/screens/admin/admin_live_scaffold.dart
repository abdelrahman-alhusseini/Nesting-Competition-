import 'package:flutter/material.dart';

import '../../models/navigation.dart';
import '../../state/app_controller.dart';

const Color adminNavy = Color(0xFF17396C);
const Color adminBlue = Color(0xFF2E7BD8);
const Color adminBabyBlue = Color(0xFFEAF4FF);
const Color adminPageBg = Color(0xFFF5F8FC);
const Color adminNude = Color(0xFFEBC48F);
const Color adminMuted = Color(0xFF6F7E90);
const Color adminBorder = Color(0xFFDCE7F1);
const Color adminGreen = Color(0xFF42A675);
const Color adminRed = Color(0xFFC85D67);

class AdminLiveScaffold extends StatelessWidget {
  const AdminLiveScaffold({
    required this.controller,
    required this.title,
    required this.subtitle,
    required this.visualAsset,
    required this.child,
    super.key,
  });

  final AppController controller;
  final String title;
  final String subtitle;
  final String visualAsset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData lightTheme = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: adminPageBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: adminBlue,
        brightness: Brightness.light,
        primary: adminBlue,
        surface: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: adminBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: adminBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: adminBlue, width: 1.6),
        ),
        labelStyle: const TextStyle(color: adminMuted),
        hintStyle: const TextStyle(color: Color(0xFF9AA7B6)),
      ),
    );

    return Theme(
      data: lightTheme,
      child: Scaffold(
        backgroundColor: adminPageBg,
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxWidth < 1050;
            return Row(
              children: <Widget>[
                _AdminSidebar(controller: controller, compact: compact),
                Expanded(
                  child: SafeArea(
                    child: Column(
                      children: <Widget>[
                        _TopBar(
                          controller: controller,
                          title: title,
                          subtitle: subtitle,
                        ),
                        _AdminVisualBanner(assetPath: visualAsset),
                        Expanded(child: child),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AdminVisualBanner extends StatelessWidget {
  const _AdminVisualBanner({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double height = constraints.maxWidth < 850 ? 92 : 126;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: adminBorder),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                  return const ColoredBox(
                    color: adminBabyBlue,
                    child: Center(
                      child: Icon(Icons.image_outlined, color: adminBlue, size: 34),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({required this.controller, required this.compact});

  final AppController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double width = compact ? 88 : 238;
    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: adminBorder)),
      ),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(compact ? 12 : 18, 20, compact ? 12 : 18, 16),
              child: compact ? _compactBrand() : _brand(),
            ),
            const Divider(height: 1, color: adminBorder),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                children: <Widget>[
                  _nav(AdminPage.dashboard, Icons.dashboard_outlined, 'Dashboard'),
                  _nav(
                    AdminPage.approvals,
                    Icons.fact_check_outlined,
                    'Booking Approvals',
                    badge: controller.pendingBookings.length,
                  ),
                  _nav(AdminPage.users, Icons.person_outline_rounded, 'Users'),
                  _nav(AdminPage.testDraw, Icons.style_outlined, 'Manual Draw'),
                  _nav(AdminPage.adjustPoints, Icons.tune_rounded, 'Adjust Points'),
                  _nav(AdminPage.auditHistory, Icons.receipt_long_outlined, 'Audit History'),
                  _nav(AdminPage.settings, Icons.settings_outlined, 'Settings'),
                ],
              ),
            ),
            if (!compact)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Container(
                  height: 128,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[Color(0xFFF2F8FD), Color(0xFFE4F1FB)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: adminBorder),
                  ),
                  child: const Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Positioned(
                        top: 18,
                        child: Icon(Icons.home_work_outlined, color: Color(0xFF84A9C8), size: 54),
                      ),
                      Positioned(
                        bottom: 13,
                        left: 26,
                        child: Icon(Icons.local_shipping_outlined, color: adminNavy, size: 66),
                      ),
                      Positioned(
                        bottom: 18,
                        right: 28,
                        child: Icon(Icons.emoji_events_outlined, color: Color(0xFFC68B31), size: 34),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(compact ? 10 : 14, 0, compact ? 10 : 14, 16),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: controller.busy ? null : controller.logout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: compact ? const SizedBox.shrink() : const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: adminNavy,
                    side: const BorderSide(color: adminBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brand() {
    return const Row(
      children: <Widget>[
        CircleAvatar(
          radius: 20,
          backgroundColor: adminBabyBlue,
          child: Icon(Icons.local_shipping_outlined, color: adminNavy, size: 22),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Michael & Son',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: adminNavy, fontWeight: FontWeight.w900, fontSize: 16),
              ),
              SizedBox(height: 2),
              Text(
                'NESTING CHAMPIONS',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Color(0xFFC68B31), fontWeight: FontWeight.w800, fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _compactBrand() {
    return const CircleAvatar(
      radius: 24,
      backgroundColor: adminBabyBlue,
      child: Icon(Icons.local_shipping_outlined, color: adminNavy, size: 26),
    );
  }

  Widget _nav(AdminPage page, IconData icon, String label, {int badge = 0}) {
    final bool selected = controller.adminPage == page;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Tooltip(
        message: compact ? label : '',
        child: Material(
          color: selected ? adminNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => controller.openAdminPage(page),
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 46,
              child: Row(
                mainAxisAlignment: compact ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: <Widget>[
                  SizedBox(width: compact ? 0 : 13),
                  Icon(icon, size: 20, color: selected ? Colors.white : adminNavy),
                  if (!compact) ...<Widget>[
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? Colors.white : adminNavy,
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (badge > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: adminNude,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badge > 99 ? '99+' : '$badge',
                          style: const TextStyle(color: adminNavy, fontWeight: FontWeight.w900, fontSize: 10),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.controller,
    required this.title,
    required this.subtitle,
  });

  final AppController controller;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 20, 26, 18),
      decoration: const BoxDecoration(
        color: adminPageBg,
        border: Border(bottom: BorderSide(color: adminBorder)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(color: adminNavy, fontSize: 27, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: adminMuted, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              const Text('Welcome back,', style: TextStyle(color: adminMuted, fontSize: 11)),
              Text(
                controller.username.isEmpty ? 'Administrator' : controller.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: adminNavy, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(width: 10),
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFF8E8CC),
            child: Icon(Icons.admin_panel_settings_outlined, color: adminNavy),
          ),
          const SizedBox(width: 10),
          IconButton.filledTonal(
            tooltip: 'Refresh Supabase data',
            onPressed: controller.busy ? null : controller.refreshAll,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class AdminPanel extends StatelessWidget {
  const AdminPanel({required this.child, this.padding = const EdgeInsets.all(18), super.key});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: adminBorder),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x0B17396C), blurRadius: 22, offset: Offset(0, 9)),
        ],
      ),
      child: child,
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({required this.icon, required this.title, required this.message, super.key});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: const Color(0xFFA7BCD1), size: 44),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: adminNavy, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 5),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: adminMuted, fontSize: 12, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
