import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_shell.dart';
import 'theme/app_theme.dart';

enum _AuthScreen { login, register }

class AttendancePrototypeApp extends StatefulWidget {
  const AttendancePrototypeApp({super.key});

  @override
  State<AttendancePrototypeApp> createState() => _AttendancePrototypeAppState();
}

class _AttendancePrototypeAppState extends State<AttendancePrototypeApp> {
  AppUser? _user;
  _AuthScreen _authScreen = _AuthScreen.login;

  void _handleLogin(AppUser user) {
    setState(() {
      _user = user;
    });
  }

  void _showRegister() {
    setState(() {
      _authScreen = _AuthScreen.register;
    });
  }

  void _showLogin() {
    setState(() {
      _authScreen = _AuthScreen.login;
    });
  }

  void _logout() {
    setState(() {
      _user = null;
      _authScreen = _AuthScreen.login;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AttendanceOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _user == null
            ? _AuthFlow(
                key: ValueKey(_authScreen),
                authScreen: _authScreen,
                onLogin: _handleLogin,
                onShowLogin: _showLogin,
                onShowRegister: _showRegister,
              )
            : HomeShell(
                key: ValueKey(_user?.id),
                user: _user!,
                onLogout: _logout,
              ),
      ),
    );
  }
}

class _AuthFlow extends StatelessWidget {
  const _AuthFlow({
    super.key,
    required this.authScreen,
    required this.onLogin,
    required this.onShowRegister,
    required this.onShowLogin,
  });

  final _AuthScreen authScreen;
  final ValueChanged<AppUser> onLogin;
  final VoidCallback onShowRegister;
  final VoidCallback onShowLogin;

  @override
  Widget build(BuildContext context) {
    switch (authScreen) {
      case _AuthScreen.login:
        return LoginScreen(
          onLogin: onLogin,
          onShowRegister: onShowRegister,
        );
      case _AuthScreen.register:
        return RegisterScreen(
          onRegistered: onShowLogin,
          onShowLogin: onShowLogin,
        );
    }
  }
}
