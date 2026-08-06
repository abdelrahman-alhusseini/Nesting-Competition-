import 'package:flutter/material.dart';

import 'models/app_role.dart';
import 'repositories/supabase_repository.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/agent/agent_shell.dart';
import 'screens/login_screen.dart';
import 'state/app_controller.dart';
import 'widgets/neon_widgets.dart';

class NestingChampionsApp extends StatefulWidget {
  const NestingChampionsApp({required this.repository, super.key});

  final SupabaseRepository? repository;

  @override
  State<NestingChampionsApp> createState() => _NestingChampionsAppState();
}

class _NestingChampionsAppState extends State<NestingChampionsApp> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppController(repository: widget.repository);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Michael & Son Nesting Champions',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: gold,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF010814),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: gold, width: 2),
          ),
        ),
      ),
      home: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          if (_controller.initializing) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: gold)),
            );
          }
          if (!_controller.loggedIn) {
            return LoginScreen(controller: _controller);
          }
          if (_controller.role == AppRole.admin) {
            return AdminShell(controller: _controller);
          }
          return AgentShell(controller: _controller);
        },
      ),
    );
  }
}
