import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Registration screen — refactored to use BLoC + GoRouter.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedType = 'hr';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
          AuthRegisterRequested(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            accountType: _selectedType,
          ),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _selectedType == 'hr'
              ? 'Request sent. HR/Admin accounts require approval.'
              : 'Request sent. You can sign in once approved.',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    // Navigate back to login after a brief delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) context.go(RoutePaths.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create an Account',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your details to request access.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Type',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              children: [
                                ChoiceChip(
                                  label: const Text('Employee'),
                                  selected: _selectedType == 'employee',
                                  onSelected: (_) {
                                    setState(() => _selectedType = 'employee');
                                  },
                                ),
                                ChoiceChip(
                                  label: const Text('HR / Admin'),
                                  selected: _selectedType == 'hr',
                                  onSelected: (_) {
                                    setState(() => _selectedType = 'hr');
                                  },
                                ),
                              ],
                            ),
                            if (_selectedType == 'hr') ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: theme.colorScheme.primary
                                      .withAlpha(15),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 20,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Approval required before activation for HR/Admin accounts.',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Full name is required.';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                hintText: 'Alex Rivers',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Work email is required.';
                                }
                                if (!value.contains('@')) {
                                  return 'Use a valid email address.';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Work Email',
                                hintText: 'name@company.com',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              validator: (value) {
                                if (value == null || value.length < 6) {
                                  return 'Use at least 6 characters.';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'Create Password',
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // ── Submit ──
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                final isLoading =
                                    state.status == AuthStatus.loading;
                                return FilledButton(
                                  onPressed: isLoading ? null : _submit,
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text('REQUEST ACCOUNT'),
                                            SizedBox(width: 8),
                                            Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Already have an account?'),
                      TextButton(
                        onPressed: () => context.go(RoutePaths.login),
                        child: const Text('Log in'),
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
