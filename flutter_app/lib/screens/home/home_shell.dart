import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../models/app_role.dart';
import '../../models/app_user.dart';
import '../dashboard/admin_dashboard.dart';
import '../dashboard/employee_dashboard.dart';
import '../dashboard/hr_dashboard.dart';
import '../reports/reports_screen.dart';

enum AppSection {
  dashboard,
  employees,
  attendance,
  reports,
  analytics,
  company,
  settings,
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.user,
    required this.onLogout,
  });

  final AppUser user;
  final VoidCallback onLogout;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _allItems = [
    _NavItem(
      section: AppSection.dashboard,
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      roles: {AppRole.employee, AppRole.hr, AppRole.admin},
    ),
    _NavItem(
      section: AppSection.employees,
      label: 'Employees',
      icon: Icons.groups_2_outlined,
      roles: {AppRole.hr, AppRole.admin},
    ),
    _NavItem(
      section: AppSection.attendance,
      label: 'Attendance',
      icon: Icons.history_toggle_off_rounded,
      roles: {AppRole.employee, AppRole.hr},
    ),
    _NavItem(
      section: AppSection.reports,
      label: 'Reports',
      icon: Icons.description_outlined,
      roles: {AppRole.hr, AppRole.admin},
    ),
    _NavItem(
      section: AppSection.analytics,
      label: 'Analytics',
      icon: Icons.trending_up_rounded,
      roles: {AppRole.admin},
    ),
    _NavItem(
      section: AppSection.company,
      label: 'Company',
      icon: Icons.apartment_rounded,
      roles: {AppRole.hr, AppRole.admin},
    ),
    _NavItem(
      section: AppSection.settings,
      label: 'Settings',
      icon: Icons.settings_outlined,
      roles: {AppRole.employee, AppRole.hr, AppRole.admin},
    ),
  ];

  AppSection _currentSection = AppSection.dashboard;

  List<_NavItem> get _visibleItems => _allItems
      .where((item) => item.roles.contains(widget.user.role))
      .toList(growable: false);

  List<_NavItem> get _mobileItems =>
      _visibleItems.take(4).toList(growable: false);

  int get _currentMobileIndex {
    final index =
        _mobileItems.indexWhere((item) => item.section == _currentSection);
    return index < 0 ? 0 : index;
  }

  void _navigate(AppSection section) {
    setState(() {
      _currentSection = section;
    });
    Navigator.of(context).pop();
  }

  Widget _buildCurrentScreen() {
    switch (_currentSection) {
      case AppSection.dashboard:
        return switch (widget.user.role) {
          AppRole.admin => const AdminDashboard(),
          AppRole.hr => const HRDashboard(),
          AppRole.employee => EmployeeDashboard(user: widget.user),
        };
      case AppSection.reports:
      case AppSection.attendance:
        return const ReportsScreen();
      case AppSection.employees:
        return const _ComingSoonScreen(
          title: 'Employee Directory',
          subtitle: 'Directory and profile management screens come next.',
          icon: Icons.groups_2_outlined,
        );
      case AppSection.analytics:
        return const _ComingSoonScreen(
          title: 'Analytics',
          subtitle: 'Cross-company KPIs and trend dashboards are coming soon.',
          icon: Icons.insights_outlined,
        );
      case AppSection.company:
        return const _ComingSoonScreen(
          title: 'Company',
          subtitle: 'Workspace and company setup views are coming soon.',
          icon: Icons.apartment_rounded,
        );
      case AppSection.settings:
        return const _ComingSoonScreen(
          title: 'Settings',
          subtitle:
              'Personalization, security, and workspace settings coming soon.',
          icon: Icons.settings_outlined,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AttendanceOS',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    widget.user.name[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(
                  widget.user.name,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(widget.user.role.label),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: ListView(
                  children: _visibleItems.map((item) {
                    final selected = item.section == _currentSection;
                    return ListTile(
                      selected: selected,
                      selectedTileColor: AppTheme.primary.withOpacity(0.08),
                      leading: Icon(
                        item.icon,
                        color: selected ? AppTheme.primary : null,
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      onTap: () => _navigate(item.section),
                    );
                  }).toList(growable: false),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.tonalIcon(
                  onPressed: widget.onLogout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _buildCurrentScreen(),
      ),
      bottomNavigationBar: _mobileItems.isEmpty
          ? null
          : NavigationBar(
              selectedIndex: _currentMobileIndex,
              destinations: _mobileItems
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      label: item.label,
                    ),
                  )
                  .toList(growable: false),
              onDestinationSelected: (index) {
                setState(() {
                  _currentSection = _mobileItems[index].section;
                });
              },
            ),
      floatingActionButton: _currentSection == AppSection.dashboard &&
              widget.user.role == AppRole.hr
          ? FloatingActionButton.extended(
              onPressed: () {},
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Scan'),
            )
          : null,
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.section,
    required this.label,
    required this.icon,
    required this.roles,
  });

  final AppSection section;
  final String label;
  final IconData icon;
  final Set<AppRole> roles;
}

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, size: 34, color: AppTheme.primary),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
