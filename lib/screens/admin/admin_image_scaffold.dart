import 'package:flutter/material.dart';

import '../../models/navigation.dart';
import '../../state/app_controller.dart';
import '../../widgets/design_canvas.dart';
import 'admin_live_scaffold.dart';

/// Full-screen 1672×941 artwork shell used by the approved V11 admin pages.
///
/// The PNG provides only the decorative design. Navigation and all controls
/// are real Flutter widgets layered on top of the same coordinate system.
class AdminImageScaffold extends StatelessWidget {
  const AdminImageScaffold({
    required this.controller,
    required this.assetPath,
    required this.children,
    super.key,
  });

  final AppController controller;
  final String assetPath;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final TextTheme readableText = ThemeData.light().textTheme.apply(
      bodyColor: adminNavy,
      displayColor: adminNavy,
    );

    final ThemeData base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF4F8FC),
      canvasColor: Colors.white,
      hoverColor: adminBabyBlue,
      focusColor: const Color(0xFFDCEEFF),
      splashColor: adminBlue.withValues(alpha: 0.10),
      textTheme: readableText,
      colorScheme: ColorScheme.fromSeed(
        seedColor: adminBlue,
        brightness: Brightness.light,
        primary: adminBlue,
        secondary: adminNude,
        surface: Colors.white,
        onSurface: adminNavy,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFFFCFEFF),
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: Color(0xFFFCFEFF),
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: adminNavy, fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FBFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBFD5EA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBFD5EA), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: adminBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: adminRed, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: adminRed, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF4F6482), fontWeight: FontWeight.w700),
        floatingLabelStyle: const TextStyle(color: adminBlue, fontWeight: FontWeight.w800),
        hintStyle: const TextStyle(color: Color(0xFF7D8EA5), fontWeight: FontWeight.w500),
        suffixStyle: const TextStyle(color: adminNavy, fontWeight: FontWeight.w800),
        prefixIconColor: adminBlue,
        suffixIconColor: adminNavy,
      ),
    );

    return Theme(
      data: base,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F8FC),
        body: DesignCanvas(
          assetPath: assetPath,
          lightBackground: true,
          children: <Widget>[
            _AdminCanvasSidebar(controller: controller),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _AdminCanvasSidebar extends StatelessWidget {
  const _AdminCanvasSidebar({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final List<({AdminPage page, IconData icon, String label})> rows = <({AdminPage page, IconData icon, String label})>[
      (page: AdminPage.dashboard, icon: Icons.dashboard_outlined, label: 'DASHBOARD'),
      (page: AdminPage.approvals, icon: Icons.fact_check_outlined, label: 'BOOKING APPROVALS'),
      (page: AdminPage.users, icon: Icons.group_outlined, label: 'USERS'),
      (page: AdminPage.testDraw, icon: Icons.style_outlined, label: 'MANUAL DRAW'),
      (page: AdminPage.adjustPoints, icon: Icons.tune_rounded, label: 'ADJUST POINTS'),
      (page: AdminPage.auditHistory, icon: Icons.history_rounded, label: 'AUDIT HISTORY'),
      (page: AdminPage.settings, icon: Icons.settings_outlined, label: 'SETTINGS'),
    ];

    const double left = 24;
    const double width = 238;
    const double top = 326;
    const double rowHeight = 44;
    const double gap = 8;

    return Stack(
      children: <Widget>[
        for (int i = 0; i < rows.length; i++)
          Positioned(
            left: left,
            top: top + i * (rowHeight + gap),
            width: width,
            height: rowHeight,
            child: _SidebarButton(
              selected: controller.adminPage == rows[i].page,
              icon: rows[i].icon,
              label: rows[i].label,
              badge: rows[i].page == AdminPage.approvals ? controller.pendingBookings.length : 0,
              onTap: () => controller.openAdminPage(rows[i].page),
            ),
          ),
        Positioned(
          left: left,
          top: top + rows.length * (rowHeight + gap) + 4,
          width: width,
          height: rowHeight,
          child: _SidebarButton(
            selected: false,
            icon: Icons.logout_rounded,
            label: 'SIGN OUT',
            onTap: controller.busy ? null : controller.logout,
          ),
        ),
      ],
    );
  }
}

class _SidebarButton extends StatefulWidget {
  const _SidebarButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final int badge;

  @override
  State<_SidebarButton> createState() => _SidebarButtonState();
}

class _SidebarButtonState extends State<_SidebarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool highlighted = widget.selected || _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: highlighted ? const Color(0xFFDCEEFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Row(
              children: <Widget>[
                Icon(widget.icon, color: widget.selected ? adminBlue : adminNavy, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.selected ? adminBlue : adminNavy,
                      fontWeight: widget.selected ? FontWeight.w800 : FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (widget.badge > 0)
                  Container(
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    decoration: BoxDecoration(
                      color: adminNude,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${widget.badge}',
                      style: const TextStyle(color: adminNavy, fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Standard dialog surface for every admin popup/dropdown workflow.
Future<T?> showAdminDialog<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  List<Widget>? actions,
  double width = 560,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: adminNavy.withValues(alpha: 0.20),
    builder: (BuildContext dialogContext) {
      final ThemeData dialogTheme = ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFCFEFF),
        canvasColor: const Color(0xFFFCFEFF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: adminBlue,
          brightness: Brightness.light,
          primary: adminBlue,
          secondary: adminNude,
          surface: const Color(0xFFFCFEFF),
          onSurface: adminNavy,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: adminNavy,
          displayColor: adminNavy,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFFFCFEFF),
          surfaceTintColor: Colors.transparent,
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: Color(0xFFFCFEFF),
          surfaceTintColor: Colors.transparent,
          textStyle: TextStyle(color: adminNavy, fontWeight: FontWeight.w700),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FBFF),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Color(0xFFB8CEE4), width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Color(0xFFB8CEE4), width: 1.25),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: adminBlue, width: 2.1),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: adminRed, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: adminRed, width: 2.1),
          ),
          labelStyle: const TextStyle(
            color: adminNavy,
            fontWeight: FontWeight.w700,
          ),
          floatingLabelStyle: const TextStyle(
            color: adminBlue,
            fontWeight: FontWeight.w900,
          ),
          hintStyle: const TextStyle(
            color: Color(0xFF71839C),
            fontWeight: FontWeight.w500,
          ),
          suffixStyle: const TextStyle(
            color: adminNavy,
            fontWeight: FontWeight.w900,
          ),
          prefixIconColor: adminBlue,
          suffixIconColor: adminNavy,
        ),
      );

      return Theme(
        data: dialogTheme,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width, maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.85),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFFCFEFF),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: adminBorder),
                boxShadow: const <BoxShadow>[
                  BoxShadow(color: Color(0x1A17396C), blurRadius: 30, offset: Offset(0, 12)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(color: adminBabyBlue, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.bolt_rounded, color: adminBlue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(title, style: const TextStyle(color: adminNavy, fontSize: 20, fontWeight: FontWeight.w900)),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded, color: adminMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Flexible(child: SingleChildScrollView(child: child)),
                  if (actions != null && actions.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

ButtonStyle adminPrimaryButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: adminBlue,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

ButtonStyle adminSecondaryButtonStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: adminNavy,
    side: const BorderSide(color: adminBorder),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

Widget adminEmptyMessage({required IconData icon, required String title, required String message}) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(color: adminBabyBlue, borderRadius: BorderRadius.circular(18)),
          child: Icon(icon, color: adminBlue, size: 28),
        ),
        const SizedBox(height: 13),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(color: adminNavy, fontWeight: FontWeight.w900, fontSize: 15)),
        const SizedBox(height: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: adminMuted, fontSize: 12, height: 1.35)),
        ),
      ],
    ),
  );
}
