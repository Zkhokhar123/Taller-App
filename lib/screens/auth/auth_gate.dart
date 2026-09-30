import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../repositories/auth_repository.dart';
import '../home_shell.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// Decides Login / Register / Home based on local account + session.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _auth = AuthRepository();
  bool _loading = true;
  Widget? _destination;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    try {
      final hasAccount = await _auth.hasRegisteredAccount();
      final loggedIn = await _auth.isLoggedIn();

      Widget next;
      if (!hasAccount) {
        next = const RegisterScreen(isFirstLaunch: true);
      } else if (!loggedIn) {
        next = const LoginScreen();
      } else {
        next = const HomeShell();
      }

      if (!mounted) return;
      setState(() {
        _destination = next;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _destination = const RegisterScreen(isFirstLaunch: true);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.navy,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'ٹیلر ماسٹر',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return _destination ?? const RegisterScreen(isFirstLaunch: true);
  }
}
