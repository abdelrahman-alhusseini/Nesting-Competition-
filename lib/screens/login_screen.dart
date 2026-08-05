import 'package:flutter/material.dart';

import '../models/app_role.dart';
import '../state/app_controller.dart';
import '../widgets/design_canvas.dart';
import '../widgets/neon_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.controller, super.key});

  final AppController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (widget.controller.busy) return;
    final String? error = await widget.controller.login(
      username: _usernameController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    final bool admin = widget.controller.selectedLoginRole == AppRole.admin;

    return Scaffold(
      body: DesignCanvas(
        assetPath: 'assets/images/login.png',
        children: <Widget>[
          // Covers the generated form so all visible fields below are real widgets.
          Positioned(
            left: 855,
            top: 132,
            width: 660,
            height: 730,
            child: NeonPanel(
              padding: const EdgeInsets.fromLTRB(46, 42, 46, 34),
              color: const Color(0xFF030D20),
              borderColor: const Color(0xFF3158A4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Icon(Icons.account_circle, size: 76, color: Color(0xFF76A4FF)),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _RoleButton(
                          label: 'Agent Login',
                          icon: Icons.person,
                          selected: !admin,
                          onPressed: () => widget.controller.chooseLoginRole(AppRole.agent),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _RoleButton(
                          label: 'Admin Login',
                          icon: Icons.admin_panel_settings,
                          selected: admin,
                          onPressed: () => widget.controller.chooseLoginRole(AppRole.admin),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  const Text('Username', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(fontSize: 19),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_outline),
                      hintText: 'Enter your username',
                      filled: true,
                      fillColor: Color(0xFF020A18),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text('Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    onSubmitted: (_) { _login(); },
                    style: const TextStyle(fontSize: 19),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline),
                      hintText: 'Enter your password',
                      filled: true,
                      fillColor: const Color(0xFF020A18),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      ),
                    ),
                  ),
                  if (_error != null) ...<Widget>[
                    const SizedBox(height: 14),
                    Text(_error!, style: const TextStyle(color: Color(0xFFFF6060), fontSize: 16)),
                  ],
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: widget.controller.busy ? null : () { _login(); },
                    style: goldButtonStyle(),
                    icon: widget.controller.busy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.login),
                    label: Text(widget.controller.busy ? 'SIGNING IN...' : 'SIGN IN'),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.controller.databaseConfigured
                        ? 'Use the username and password created by an administrator.'
                        : 'Database setup required: start the app with SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: widget.controller.databaseConfigured
                          ? const Color(0xFF9FB1C8)
                          : const Color(0xFFFFB84D),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.shield_outlined, color: Color(0xFFA875FF)),
                      SizedBox(width: 8),
                      Text('Internal prototype — authorized access only.', style: TextStyle(color: Color(0xFFB7C4D5))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? gold : const Color(0xFF9CB6E5),
        side: BorderSide(color: selected ? gold : const Color(0xFF31527D), width: 2),
        backgroundColor: selected ? gold.withOpacity(0.06) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 22),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
