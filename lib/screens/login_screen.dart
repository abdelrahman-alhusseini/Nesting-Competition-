import 'package:flutter/material.dart';

import '../models/app_role.dart';
import '../state/app_controller.dart';
import '../widgets/design_canvas.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.controller, super.key});

  final AppController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _heroAssetPath = 'assets/images/login_hero_light.png';

  static const Color _navy = Color(0xFF17396C);
  static const Color _blue = Color(0xFF2E7BD8);
  static const Color _muted = Color(0xFF748399);
  static const Color _nude = Color(0xFFEBC48F);
  static const Color _pageBlue = Color(0xFFEAF3FB);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (widget.controller.busy) return;

    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final String? error = await widget.controller.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _error = error);
  }

  void _selectRole(AppRole role) {
    if (widget.controller.selectedLoginRole == role) return;
    setState(() => _error = null);
    widget.controller.chooseLoginRole(role);
  }

  void _showResetInformation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Passwords are reset by an administrator from User Management.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          backgroundColor: _pageBlue,
          body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool desktop = constraints.maxWidth >= 1050;

              if (desktop) {
                return _buildDesktopCanvas();
              }

              return ColoredBox(
                color: _pageBlue,
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                    child: Column(
                      children: <Widget>[
                        const SizedBox(
                          height: 330,
                          child: ClipRRect(
                            borderRadius: BorderRadius.all(
                              Radius.circular(28),
                            ),
                            child: _HeroPane(assetPath: _heroAssetPath),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _buildLoginCard(maxWidth: 560),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDesktopCanvas() {
    final bool admin = widget.controller.selectedLoginRole == AppRole.admin;

    return DesignCanvas(
      assetPath: 'assets/images/login_full_light.png',
      lightBackground: true,
      children: <Widget>[
        Positioned(
          left: 876,
          top: 170,
          width: 648,
          height: 712,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFDFEFE).withValues(alpha: 0.985),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: const Color(0xFFD7E5F2),
                  width: 1.6,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: _navy.withValues(alpha: 0.10),
                    blurRadius: 40,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        height: 118,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: _DesktopRoleTab(
                                label: 'AGENT LOGIN',
                                icon: Icons.person_outline_rounded,
                                selected: !admin,
                                activeLineColor: _blue,
                                activeTextColor: _navy,
                                activeIconColor: _blue,
                                activeBackgroundColor:
                                    const Color(0xFFF8FBFF),
                                onTap: () => _selectRole(AppRole.agent),
                              ),
                            ),
                            Container(
                              width: 1,
                              margin: const EdgeInsets.symmetric(vertical: 14),
                              color: const Color(0xFFE4ECF4),
                            ),
                            Expanded(
                              child: _DesktopRoleTab(
                                label: 'ADMIN LOGIN',
                                icon: Icons.admin_panel_settings_outlined,
                                selected: admin,
                                activeLineColor: _nude,
                                activeTextColor: _navy,
                                activeIconColor: const Color(0xFFDBA443),
                                activeBackgroundColor:
                                    const Color(0xFFFFFBF4),
                                onTap: () => _selectRole(AppRole.admin),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(58, 44, 58, 34),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              _desktopField(
                                controller: _usernameController,
                                hint: 'Username',
                                icon: Icons.person_outline_rounded,
                                textInputAction: TextInputAction.next,
                                validator: (String? value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Enter your username.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              _desktopField(
                                controller: _passwordController,
                                hint: 'Password',
                                icon: Icons.lock_outline_rounded,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _login(),
                                suffix: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: _muted,
                                  ),
                                ),
                                validator: (String? value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter your password.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        setState(
                                          () => _rememberMe = !_rememberMe,
                                        );
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Checkbox(
                                            value: _rememberMe,
                                            onChanged: (bool? value) {
                                              setState(
                                                () =>
                                                    _rememberMe = value ?? false,
                                              );
                                            },
                                            activeColor: _blue,
                                            side: const BorderSide(
                                              color: Color(0xFFC4D1DF),
                                              width: 1.5,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          const Text(
                                            'Remember me',
                                            style: TextStyle(
                                              color: _muted,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _showResetInformation,
                                    style: TextButton.styleFrom(
                                      foregroundColor: _blue,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 8,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    child: const Text('Password help'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 64,
                                child: FilledButton(
                                  onPressed:
                                      widget.controller.busy ? null : _login,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _nude,
                                    foregroundColor: _navy,
                                    disabledBackgroundColor:
                                        _nude.withValues(alpha: 0.60),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  child: widget.controller.busy
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.6,
                                            color: _navy,
                                          ),
                                        )
                                      : const Text('SIGN IN'),
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: _error == null
                                    ? const SizedBox(height: 22)
                                    : Container(
                                        key: ValueKey<String>(_error!),
                                        margin: const EdgeInsets.only(top: 14),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 11,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF0F0),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFFF3C5C5),
                                          ),
                                        ),
                                        child: Text(
                                          _error!,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFFB84040),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                              ),
                              const Spacer(),
                              Row(
                                children: <Widget>[
                                  const Expanded(
                                    child: Divider(
                                      color: Color(0xFFD8E3EE),
                                      thickness: 1.2,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                    ),
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF2F7FD),
                                      borderRadius: BorderRadius.circular(21),
                                      border: Border.all(
                                        color: const Color(0xFFD8E6F5),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.shield_outlined,
                                      color: _blue,
                                      size: 23,
                                    ),
                                  ),
                                  const Expanded(
                                    child: Divider(
                                      color: Color(0xFFD8E3EE),
                                      thickness: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FBFD),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE1EAF3),
                                  ),
                                ),
                                child: const Text(
                                  'Secure sign-in • Authorized personnel only',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _blue,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _desktopField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required TextInputAction textInputAction,
    required String? Function(String?) validator,
    bool obscureText = false,
    ValueChanged<String>? onSubmitted,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      textAlignVertical: TextAlignVertical.center,
      style: const TextStyle(
        color: _navy,
        fontSize: 17,
        height: 1.2,
        fontWeight: FontWeight.w700,
      ),
      decoration: _desktopFieldDecoration(
        hint: hint,
        icon: icon,
        suffix: suffix,
      ),
    );
  }

  InputDecoration _desktopFieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    const OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: Color(0xFFD6E2EE), width: 1.5),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF90A1B6),
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: _muted, size: 25),
      prefixIconConstraints: const BoxConstraints(minWidth: 54),
      suffixIcon: suffix,
      suffixIconConstraints: const BoxConstraints(minWidth: 52),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 20,
      ),
      enabledBorder: border,
      border: border,
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: _blue, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Color(0xFFCF5A5A), width: 1.5),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Color(0xFFCF5A5A), width: 2),
      ),
      errorStyle: const TextStyle(height: 0, fontSize: 0),
    );
  }

  Widget _buildFormPane({required double horizontalPadding}) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFF8FBFE),
            Color(0xFFEAF3FB),
            Color(0xFFF6F0E8),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 28,
            ),
            child: _buildLoginCard(maxWidth: 560),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard({required double maxWidth}) {
    final bool admin = widget.controller.selectedLoginRole == AppRole.admin;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.fromLTRB(34, 34, 34, 30),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFDCE7F1)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: _navy.withValues(alpha: 0.10),
              blurRadius: 40,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Welcome back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _navy,
                    fontSize: 31,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Sign in to continue to Nesting Champions',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  height: 62,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F5FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _RoleTab(
                          label: 'Agent Login',
                          icon: Icons.person_outline_rounded,
                          selected: !admin,
                          onTap: () => _selectRole(AppRole.agent),
                        ),
                      ),
                      Expanded(
                        child: _RoleTab(
                          label: 'Admin Login',
                          icon: Icons.admin_panel_settings_outlined,
                          selected: admin,
                          onTap: () => _selectRole(AppRole.admin),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _usernameController,
                  autofocus: true,
                  autocorrect: false,
                  autofillHints: const <String>[AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _fieldDecoration(
                    hint: 'Username',
                    icon: Icons.person_outline_rounded,
                  ),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter your username.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 17),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autofillHints: const <String>[AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _fieldDecoration(
                    hint: 'Password',
                    icon: Icons.lock_outline_rounded,
                    suffix: IconButton(
                      tooltip:
                          _obscurePassword ? 'Show password' : 'Hide password',
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: _muted,
                      ),
                    ),
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your password.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 13),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 6,
                  children: <Widget>[
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() => _rememberMe = !_rememberMe);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (bool? value) {
                                setState(
                                  () => _rememberMe = value ?? false,
                                );
                              },
                              activeColor: _blue,
                              side: const BorderSide(
                                color: Color(0xFFC4D1DF),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const Text(
                              'Remember me',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _showResetInformation,
                      style: TextButton.styleFrom(
                        foregroundColor: _blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('Forgot password?'),
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _error == null
                      ? const SizedBox(height: 8)
                      : Container(
                          key: ValueKey<String>(_error!),
                          margin: const EdgeInsets.only(top: 6, bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFF3C5C5),
                            ),
                          ),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFB84040),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),
                SizedBox(
                  height: 58,
                  child: FilledButton(
                    onPressed: widget.controller.busy ? null : _login,
                    style: FilledButton.styleFrom(
                      backgroundColor: _nude,
                      foregroundColor: _navy,
                      disabledBackgroundColor: _nude.withValues(alpha: 0.60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    child: widget.controller.busy
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.6,
                              color: _navy,
                            ),
                          )
                        : const Text('SIGN IN'),
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF5FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD8E8FA)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.shield_outlined,
                        color: _blue,
                        size: 25,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Internal prototype — authorized access only. '
                          'Sign-in attempts are encrypted and secure.',
                          style: TextStyle(
                            color: Color(0xFF4F6680),
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    const OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: Color(0xFFD2DEE9), width: 1.4),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: _muted,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: _muted, size: 22),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFFBFDFE),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      enabledBorder: border,
      border: border,
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: _blue, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Color(0xFFCF5A5A), width: 1.5),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Color(0xFFCF5A5A), width: 2),
      ),
    );
  }
}

class _HeroPane extends StatelessWidget {
  const _HeroPane({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFEAF3FB),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            assetPath,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.high,
          ),
          const Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: 38,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: <Color>[
                    Color(0x00EAF3FB),
                    Color(0xFFEAF3FB),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleTab extends StatelessWidget {
  const _RoleTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFFBCD7F3) : Colors.transparent,
            ),
            boxShadow: selected
                ? const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x140F4F8D),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 21,
                color: selected
                    ? _LoginScreenState._blue
                    : const Color(0xFF65758A),
              ),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? _LoginScreenState._navy
                        : const Color(0xFF536174),
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopRoleTab extends StatelessWidget {
  const _DesktopRoleTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.activeLineColor,
    required this.activeTextColor,
    required this.activeIconColor,
    required this.activeBackgroundColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color activeLineColor;
  final Color activeTextColor;
  final Color activeIconColor;
  final Color activeBackgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? activeBackgroundColor : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 28,
              color: selected ? activeIconColor : const Color(0xFF95A3B5),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? activeTextColor : const Color(0xFF7E8C9E),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 18),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: double.infinity,
              height: 4,
              color: selected ? activeLineColor : const Color(0xFFE7EDF4),
            ),
          ],
        ),
      ),
    );
  }
}
