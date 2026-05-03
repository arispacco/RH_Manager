import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../attendance/domain/entities/attendance_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_event.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';

/// Employee directory with search, department filters, and status badges.
class EmployeeDirectoryScreen extends StatefulWidget {
  const EmployeeDirectoryScreen({super.key});

  @override
  State<EmployeeDirectoryScreen> createState() =>
      _EmployeeDirectoryScreenState();
}

class _EmployeeDirectoryScreenState extends State<EmployeeDirectoryScreen> {
  String _searchQuery = '';
  String _selectedDepartment = 'All';

  // TODO: Replace with BaaS data
  static const _departments = [
    'All',
    'Engineering',
    'Marketing',
    'Sales',
    'Finance',
    'Operations',
    'Human Resources',
  ];

  static const _employees = [
    _Employee(
      name: 'Sarah Mitchell',
      email: 'sarah.m@company.com',
      department: 'Engineering',
      role: 'Frontend Developer',
      status: AttendanceStatus.present,
      phone: '+237 6XX XXX XXX',
    ),
    _Employee(
      name: 'James Davis',
      email: 'james.d@company.com',
      department: 'Marketing',
      role: 'Marketing Lead',
      status: AttendanceStatus.late,
      phone: '+237 6XX XXX XXX',
    ),
    _Employee(
      name: 'Emily Wong',
      email: 'emily.w@company.com',
      department: 'Sales',
      role: 'Sales Executive',
      status: AttendanceStatus.absent,
      phone: '+237 6XX XXX XXX',
    ),
    _Employee(
      name: 'Michael Chang',
      email: 'michael.c@company.com',
      department: 'Operations',
      role: 'Operations Manager',
      status: AttendanceStatus.present,
      phone: '+237 6XX XXX XXX',
    ),
    _Employee(
      name: 'Olivia Martin',
      email: 'olivia.m@company.com',
      department: 'Finance',
      role: 'Financial Analyst',
      status: AttendanceStatus.present,
      phone: '+237 6XX XXX XXX',
    ),
    _Employee(
      name: 'Noah Brown',
      email: 'noah.b@company.com',
      department: 'Engineering',
      role: 'Backend Developer',
      status: AttendanceStatus.late,
      phone: '+237 6XX XXX XXX',
    ),
    _Employee(
      name: 'Sophia Leclerc',
      email: 'sophia.l@company.com',
      department: 'Human Resources',
      role: 'HR Coordinator',
      status: AttendanceStatus.present,
      phone: '+237 6XX XXX XXX',
    ),
    _Employee(
      name: 'Liam Nguyen',
      email: 'liam.n@company.com',
      department: 'Engineering',
      role: 'DevOps Engineer',
      status: AttendanceStatus.present,
      phone: '+237 6XX XXX XXX',
    ),
  ];

  List<_Employee> get _filtered {
    return _employees.where((e) {
      final matchesDept =
          _selectedDepartment == 'All' || e.department == _selectedDepartment;
      final matchesSearch = _searchQuery.isEmpty ||
          e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.role.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesDept && matchesSearch;
    }).toList();
  }

  void _showCreateUserSheet(BuildContext context) {
    final theme = Theme.of(context);
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'employee';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New User',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Temporary Password'),
                      obscureText: true,
                      validator: (v) => (v == null || v.length < 6) ? 'Min 6 chars' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [
                        DropdownMenuItem(value: 'employee', child: Text('Employee')),
                        DropdownMenuItem(value: 'hr', child: Text('Human Resources')),
                        DropdownMenuItem(value: 'kiosk', child: Text('Kiosk Device')),
                      ],
                      onChanged: (val) {
                        if (val != null) setSheetState(() => selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 24),
                    BlocConsumer<AuthBloc, AuthState>(
                      listener: (context, state) {
                         if (state.errorMessage != null) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red));
                         } else if (state.status == AuthStatus.unauthenticated && state.errorMessage == null) {
                            // Success
                            Navigator.pop(sheetContext);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User created successfully!'), backgroundColor: Colors.green));
                         }
                      },
                      builder: (context, state) {
                        final isLoading = state.status == AuthStatus.loading;
                        return FilledButton(
                          onPressed: isLoading ? null : () {
                            if (formKey.currentState!.validate()) {
                              context.read<AuthBloc>().add(AuthRegisterRequested(
                                name: nameController.text,
                                email: emailController.text,
                                password: passwordController.text,
                                accountType: selectedRole,
                              ));
                            }
                          },
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                          child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Create User'),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
                ),
              );
            }
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = _filtered;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateUserSheet(context),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add User'),
      ),
      body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Employee Directory', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          '${_employees.length} team members across ${_departments.length - 1} departments',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),

        // ── Search ──
        TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Search by name, email, or role...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () => setState(() => _searchQuery = ''),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),

        // ── Department Filters ──
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _departments.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final dept = _departments[index];
              final selected = dept == _selectedDepartment;
              return FilterChip(
                label: Text(dept),
                selected: selected,
                onSelected: (_) =>
                    setState(() => _selectedDepartment = dept),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // ── Results Count ──
        Text(
          '${results.length} result${results.length != 1 ? 's' : ''}',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),

        // ── Employee Cards ──
        for (final employee in results) ...[
          _EmployeeCard(employee: employee),
          const SizedBox(height: 10),
        ],

        if (results.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 12),
                Text(
                  'No employees match your search.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
      ],
    ),
    );
  }
}

// ── Employee Card ──────────────────────────────────────────────

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({required this.employee});

  final _Employee employee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _getInitials(employee.name);

    final (statusLabel, statusBg, statusFg) = switch (employee.status) {
      AttendanceStatus.present => (
          'Present',
          const Color(0xFFE9F9F0),
          const Color(0xFF1E7C4A),
        ),
      AttendanceStatus.late => (
          'Late',
          const Color(0xFFFFF4E5),
          const Color(0xFFAF6711),
        ),
      AttendanceStatus.absent => (
          'Absent',
          const Color(0xFFEFF1F4),
          const Color(0xFF5E6270),
        ),
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _showProfileSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE7EEFF),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${employee.role} • ${employee.department}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusFg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: const Color(0xFFE7EEFF),
                child: Text(
                  _getInitials(employee.name),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                employee.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                employee.role,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              _ProfileRow(
                icon: Icons.email_outlined,
                label: employee.email,
              ),
              const SizedBox(height: 10),
              _ProfileRow(
                icon: Icons.phone_outlined,
                label: employee.phone,
              ),
              const SizedBox(height: 10),
              _ProfileRow(
                icon: Icons.business_outlined,
                label: employee.department,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
          ),
        );
      },
    );
  }

  static String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}

// ── Data Class ─────────────────────────────────────────────────

class _Employee {
  const _Employee({
    required this.name,
    required this.email,
    required this.department,
    required this.role,
    required this.status,
    required this.phone,
  });

  final String name;
  final String email;
  final String department;
  final String role;
  final AttendanceStatus status;
  final String phone;
}
