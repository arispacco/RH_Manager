import 'package:flutter/material.dart';

import '../../models/app_role.dart';
import '../../models/app_user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onShowRegister,
  });

  final ValueChanged<AppUser> onLogin;
  final VoidCallback onShowRegister;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberWorkspace = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final role = roleFromEmail(email);
    widget.onLogin(AppUser.mock(email: email, role: role));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: theme.colorScheme.primaryContainer,
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'AttendanceOS',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to your workspace',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Work Email',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email is required.';
                                }
                                if (!value.contains('@')) {
                                  return 'Use a valid email address.';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                hintText: 'freddy@gmail.com',
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Password',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required.';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                hintText: '••••••••',
                              ),
                            ),
                            const SizedBox(height: 16),
                            CheckboxListTile(
                              value: _rememberWorkspace,
                              contentPadding: EdgeInsets.zero,
                              visualDensity: const VisualDensity(
                                horizontal: -4,
                                vertical: -4,
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (value) {
                                setState(() {
                                  _rememberWorkspace = value ?? true;
                                });
                              },
                              title: const Text('Remember my workspace'),
                            ),
                            const SizedBox(height: 8),
                            FilledButton(
                              onPressed: _submit,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('SIGN IN'),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: widget.onShowRegister,
                        child: const Text('Request Access'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
