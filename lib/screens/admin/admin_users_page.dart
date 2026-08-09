import 'package:flutter/material.dart';

import '../../models/app_role.dart';
import '../../models/database/user_profile.dart';
import '../../state/app_controller.dart';
import 'admin_image_scaffold.dart';
import 'admin_live_scaffold.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({required this.controller, super.key});

  final AppController controller;

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final TextEditingController _search = TextEditingController();
  String _role = 'all';
  String _status = 'all';
  UserProfile? _selected;

  AppController get controller => widget.controller;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String q = _search.text.trim().toLowerCase();
    final List<UserProfile> users = controller.users.where((UserProfile user) {
      final bool queryMatch = q.isEmpty || user.username.toLowerCase().contains(q) || user.displayName.toLowerCase().contains(q);
      final bool roleMatch = _role == 'all' || user.role.name == _role;
      final bool statusMatch = _status == 'all' || (_status == 'active' ? user.isActive : !user.isActive);
      return queryMatch && roleMatch && statusMatch;
    }).toList();

    if (_selected != null && !controller.users.any((u) => u.id == _selected!.id)) _selected = null;

    return AdminImageScaffold(
      controller: controller,
      assetPath: 'assets/images/v11/admin_users.png',
      children: <Widget>[
        Positioned(
          left: 336,
          top: 184,
          width: 875,
          height: 55,
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 5,
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(hintText: 'Search users…', prefixIcon: Icon(Icons.search_rounded, color: adminBlue)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: _role,
                  dropdownColor: const Color(0xFFFCFEFF),
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(value: 'all', child: Text('All roles')),
                    DropdownMenuItem(value: 'agent', child: Text('Agent')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (String? value) {
                    if (value != null) setState(() => _role = value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: _status,
                  dropdownColor: const Color(0xFFFCFEFF),
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(value: 'all', child: Text('All statuses')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  ],
                  onChanged: (String? value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: controller.busy ? null : () => _showAddUser(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add User'),
                style: adminPrimaryButtonStyle(),
              ),
            ],
          ),
        ),
        Positioned(
          left: 336,
          top: 255,
          width: 875,
          height: 545,
          child: _UsersTable(
            users: users,
            selectedId: _selected?.id,
            onSelect: (UserProfile user) => setState(() => _selected = user),
            onToggleActive: (UserProfile user) => _toggleActive(context, user),
          ),
        ),
        _actionHotspot(
          left: 1269,
          top: 236,
          width: 139,
          height: 134,
          enabled: _selected != null && !controller.busy,
          label: 'Edit username',
          onTap: () => _showEditUsername(context),
        ),
        _actionHotspot(
          left: 1418,
          top: 236,
          width: 139,
          height: 134,
          enabled: _selected != null && !controller.busy,
          label: 'Change password',
          onTap: () => _showChangePassword(context),
        ),
      ],
    );
  }

  Widget _actionHotspot({required double left, required double top, required double width, required double height, required bool enabled, required String label, required VoidCallback onTap}) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: Material(
          color: enabled ? Colors.transparent : Colors.white.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(14),
            hoverColor: adminBabyBlue.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddUser(BuildContext context) async {
    final username = TextEditingController();
    final displayName = TextEditingController();
    final password = TextEditingController();
    AppRole role = AppRole.agent;

    await showAdminDialog<void>(
      context: context,
      title: 'Add User',
      child: StatefulBuilder(
        builder: (BuildContext dialogContext, StateSetter setDialogState) {
          return Column(
            children: <Widget>[
              TextField(controller: username, decoration: const InputDecoration(labelText: 'Username')),
              const SizedBox(height: 12),
              TextField(controller: displayName, decoration: const InputDecoration(labelText: 'Display name')),
              const SizedBox(height: 12),
              TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Temporary password')),
              const SizedBox(height: 12),
              DropdownButtonFormField<AppRole>(
                initialValue: role,
                dropdownColor: const Color(0xFFFCFEFF),
                decoration: const InputDecoration(labelText: 'Role'),
                items: const <DropdownMenuItem<AppRole>>[
                  DropdownMenuItem(value: AppRole.agent, child: Text('Agent')),
                  DropdownMenuItem(value: AppRole.admin, child: Text('Administrator')),
                ],
                onChanged: (AppRole? value) {
                  if (value != null) setDialogState(() => role = value);
                },
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: controller.busy
                      ? null
                      : () async {
                          final String? error = await controller.createUser(
                            username: username.text,
                            displayName: displayName.text,
                            password: password.text,
                            role: role,
                          );
                          if (!dialogContext.mounted) return;
                          if (error != null) {
                            _snack(dialogContext, error, true);
                            return;
                          }
                          Navigator.of(dialogContext).pop();
                          _snack(context, 'User created successfully.', false);
                        },
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Create User'),
                  style: adminPrimaryButtonStyle(),
                ),
              ),
            ],
          );
        },
      ),
    );
    username.dispose();
    displayName.dispose();
    password.dispose();
  }

  Future<void> _showEditUsername(BuildContext context) async {
    final UserProfile? user = _selected;
    if (user == null) return;
    final input = TextEditingController(text: user.username);
    await showAdminDialog<void>(
      context: context,
      title: 'Edit Username',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Updating ${user.displayName}', style: const TextStyle(color: adminMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(controller: input, decoration: const InputDecoration(labelText: 'New username')),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: controller.busy
                  ? null
                  : () async {
                      final String? error = await controller.updateUsername(user, input.text);
                      if (!context.mounted) return;
                      if (error != null) {
                        _snack(context, error, true);
                        return;
                      }
                      Navigator.of(context).pop();
                      setState(() => _selected = null);
                      _snack(this.context, 'Username updated.', false);
                    },
              style: adminPrimaryButtonStyle(),
              child: const Text('Save Username'),
            ),
          ),
        ],
      ),
    );
    input.dispose();
  }

  Future<void> _showChangePassword(BuildContext context) async {
    final UserProfile? user = _selected;
    if (user == null) return;
    final password = TextEditingController();
    final confirm = TextEditingController();
    await showAdminDialog<void>(
      context: context,
      title: 'Change Password',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Set a new password for ${user.displayName}.', style: const TextStyle(color: adminMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
          const SizedBox(height: 12),
          TextField(controller: confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password')),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: controller.busy
                  ? null
                  : () async {
                      if (password.text != confirm.text) {
                        _snack(context, 'Passwords do not match.', true);
                        return;
                      }
                      final String? error = await controller.updateUserPassword(user, password.text);
                      if (!context.mounted) return;
                      if (error != null) {
                        _snack(context, error, true);
                        return;
                      }
                      Navigator.of(context).pop();
                      _snack(this.context, 'Password updated.', false);
                    },
              style: adminPrimaryButtonStyle(),
              child: const Text('Update Password'),
            ),
          ),
        ],
      ),
    );
    password.dispose();
    confirm.dispose();
  }

  Future<void> _toggleActive(BuildContext context, UserProfile user) async {
    final String? error = await controller.setUserActive(user, !user.isActive);
    if (!context.mounted) return;
    _snack(context, error ?? (user.isActive ? 'User deactivated.' : 'User activated.'), error != null);
  }

  void _snack(BuildContext context, String message, bool error) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), backgroundColor: error ? adminRed : adminGreen));
  }
}

class _UsersTable extends StatelessWidget {
  const _UsersTable({required this.users, required this.selectedId, required this.onSelect, required this.onToggleActive});

  final List<UserProfile> users;
  final String? selectedId;
  final ValueChanged<UserProfile> onSelect;
  final ValueChanged<UserProfile> onToggleActive;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return adminEmptyMessage(icon: Icons.group_off_outlined, title: 'No users found', message: 'Try changing your search or filters.');
    }
    return Column(
      children: <Widget>[
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: adminBabyBlue, borderRadius: BorderRadius.circular(10)),
          child: const Row(
            children: <Widget>[
              Expanded(flex: 2, child: Text('USERNAME', style: _usersHead)),
              Expanded(flex: 3, child: Text('DISPLAY NAME', style: _usersHead)),
              Expanded(flex: 2, child: Text('ROLE', style: _usersHead)),
              Expanded(flex: 2, child: Text('STATUS', style: _usersHead)),
              SizedBox(width: 90, child: Text('ACTION', style: _usersHead)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: adminBorder),
            itemBuilder: (BuildContext context, int index) {
              final UserProfile user = users[index];
              final bool selected = user.id == selectedId;
              return Material(
                color: selected ? adminBabyBlue.withValues(alpha: 0.6) : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                child: InkWell(
                  onTap: () => onSelect(user),
                  borderRadius: BorderRadius.circular(9),
                  child: SizedBox(
                    height: 56,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: <Widget>[
                          Expanded(flex: 2, child: Text(user.username, style: const TextStyle(color: adminNavy, fontSize: 11, fontWeight: FontWeight.w800))),
                          Expanded(flex: 3, child: Text(user.displayName, overflow: TextOverflow.ellipsis, style: const TextStyle(color: adminNavy, fontSize: 11))),
                          Expanded(flex: 2, child: Text(user.role == AppRole.admin ? 'ADMIN' : 'AGENT', style: const TextStyle(color: adminBlue, fontSize: 10, fontWeight: FontWeight.w900))),
                          Expanded(
                            flex: 2,
                            child: Text(user.isActive ? 'ACTIVE' : 'INACTIVE', style: TextStyle(color: user.isActive ? adminGreen : adminRed, fontSize: 10, fontWeight: FontWeight.w900)),
                          ),
                          SizedBox(
                            width: 90,
                            child: TextButton(
                              onPressed: () => onToggleActive(user),
                              child: Text(user.isActive ? 'Disable' : 'Enable', style: TextStyle(color: user.isActive ? adminRed : adminGreen, fontWeight: FontWeight.w800, fontSize: 10)),
                            ),
                          ),
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
}

const TextStyle _usersHead = TextStyle(color: adminNavy, fontWeight: FontWeight.w900, fontSize: 10);
