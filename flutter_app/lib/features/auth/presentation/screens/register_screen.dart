import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../domain/entities/user_entity.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.initialType});

  final String? initialType;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyController = TextEditingController();
  UserRole _selectedType = UserRole.owner;

  @override
  void initState() {
    super.initState();
    if (widget.initialType == 'company') {
      _selectedType = UserRole.owner;
    } else {
      _selectedType = UserRole.employee;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String message = 'Request sent. You can sign in once approved.';
    if (_selectedType == UserRole.owner) {
      message = 'Company registered successfully. You can now sign in.';
    } else if (_selectedType == UserRole.hr) {
      message = 'Request sent. HR/Admin accounts require approval.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    context.go(RoutePaths.login);
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
                    _selectedType == UserRole.owner
                        ? 'Register Company'
                        : 'Create an Account',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _selectedType == UserRole.owner
                        ? 'Create a new organization workspace.'
                        : 'Enter your details to request access.',
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
                                  selected: _selectedType == UserRole.employee,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedType = UserRole.employee;
                                    });
                                  },
                                ),
                                ChoiceChip(
                                  label: const Text('HR / Admin'),
                                  selected: _selectedType == UserRole.hr,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedType = UserRole.hr;
                                    });
                                  },
                                ),
                                ChoiceChip(
                                  label: const Text('Company'),
                                  selected: _selectedType == UserRole.owner,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedType = UserRole.owner;
                                    });
                                  },
                                ),
                              ],
                            ),
                            if (_selectedType == UserRole.hr ||
                                _selectedType == UserRole.owner) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.06),
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
                                        _selectedType == UserRole.hr
                                            ? 'Approval required before activation for HR/Admin accounts.'
                                            : 'Registering a company creates a new organization and assigns you the Owner role.',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            if (_selectedType == UserRole.owner) ...[
                              TextFormField(
                                controller: _companyController,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Company name is required.';
                                  }
                                  return null;
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Company Name',
                                  hintText: 'e.g. Acme Corp',
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextFormField(
                              controller: _nameController,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Full name is required.';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                hintText: 'Alex Rivers',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
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
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.length < 6) {
                                  return 'Use at least 6 characters.';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Create Password',
                                hintText: '••••••••',
                              ),
                            ),
                            const SizedBox(height: 18),
                            FilledButton(
                              onPressed: _submit,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(_selectedType == UserRole.owner
                                      ? 'REGISTER COMPANY'
                                      : 'REQUEST ACCOUNT'),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded,
                                      size: 18),
                                ],
                              ),
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
