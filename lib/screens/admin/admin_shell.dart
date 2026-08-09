import 'package:flutter/material.dart';

import '../../models/navigation.dart';
import '../../state/app_controller.dart';
import 'admin_adjust_points_page.dart';
import 'admin_approvals_page.dart';
import 'admin_audit_history_page.dart';
import 'admin_card_reveal_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_manual_draw_page.dart';
import 'admin_settings_page.dart';
import 'admin_users_page.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    switch (controller.adminPage) {
      case AdminPage.dashboard:
        return AdminDashboardPage(controller: controller);
      case AdminPage.approvals:
        return AdminApprovalsPage(controller: controller);
      case AdminPage.users:
        return AdminUsersPage(controller: controller);
      case AdminPage.testDraw:
        return AdminManualDrawPage(controller: controller);
      case AdminPage.cardReveal:
        return AdminCardRevealPage(controller: controller);
      case AdminPage.adjustPoints:
        return AdminAdjustPointsPage(controller: controller);
      case AdminPage.auditHistory:
        return AdminAuditHistoryPage(controller: controller);
      case AdminPage.settings:
        return AdminSettingsPage(controller: controller);
    }
  }
}
