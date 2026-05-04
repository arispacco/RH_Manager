import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

/// Navigation item definition.
class _NavItem {
  const _NavItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.roles,
  });

  final String path;
  final String label;
  final IconData icon;
  final Set<UserRole> roles;
}

/// Main application shell with bottom nav bar and drawer.
///
/// Used as a [ShellRoute] builder — receives a [child] widget
/// from GoRouter that represents the current route's content.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  static const _allItems = [
    _NavItem(
      path: '/${RoutePaths.dashboard}',
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      roles: {
        UserRole.employee,
        UserRole.hr,
        UserRole.admin,
        UserRole.super_admin,
        UserRole.owner
      },
    ),
    _NavItem(
      path: '/${RoutePaths.employees}',
      label: 'Employees',
      icon: Icons.groups_2_outlined,
      roles: {
        UserRole.hr,
        UserRole.admin,
        UserRole.super_admin,
        UserRole.owner
      },
    ),
    _NavItem(
      path: '/${RoutePaths.attendance}',
      label: 'Attendance',
      icon: Icons.history_toggle_off_rounded,
      roles: {UserRole.employee, UserRole.hr},
    ),
    _NavItem(
      path: '/${RoutePaths.reports}',
      label: 'Reports',
      icon: Icons.description_outlined,
      roles: {
        UserRole.hr,
        UserRole.admin,
        UserRole.super_admin,
        UserRole.owner
      },
    ),
    _NavItem(
      path: '/${RoutePaths.analytics}',
      label: 'Analytics',
      icon: Icons.trending_up_rounded,
      roles: {UserRole.admin, UserRole.super_admin, UserRole.owner},
    ),
    _NavItem(
      path: '/${RoutePaths.company}',
      label: 'Company',
      icon: Icons.apartment_rounded,
      roles: {
        UserRole.hr,
        UserRole.admin,
        UserRole.super_admin,
        UserRole.owner
      },
    ),
    _NavItem(
      path: '/${RoutePaths.settings}',
      label: 'Settings',
      icon: Icons.settings_outlined,
      roles: {
        UserRole.employee,
        UserRole.hr,
        UserRole.admin,
        UserRole.super_admin,
        UserRole.owner
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState.user;
        if (user == null) return const SizedBox.shrink();

        final visibleItems = _allItems
            .where((item) => item.roles.contains(user.role))
            .toList(growable: false);

        // Bottom bar shows first 4 items max
        final mobileItems = visibleItems.take(4).toList(growable: false);

        final currentPath = GoRouterState.of(context).matchedLocation;
        final currentMobileIndex =
            mobileItems.indexWhere((item) => currentPath.startsWith(item.path));
        final safeIndex = currentMobileIndex < 0 ? 0 : currentMobileIndex;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'AttendanceOS',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  // TODO: Navigate to notifications
                },
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ],
          ),
          drawer: _AppDrawer(
            user: user,
            items: visibleItems,
            currentPath: currentPath,
          ),
          body: child,
          bottomNavigationBar: mobileItems.isEmpty
              ? null
              : NavigationBar(
                  selectedIndex: safeIndex,
                  destinations: mobileItems
                      .map(
                        (item) => NavigationDestination(
                          icon: Icon(item.icon),
                          label: item.label,
                        ),
                      )
                      .toList(growable: false),
                  onDestinationSelected: (index) {
                    context.go(mobileItems[index].path);
                  },
                ),
        );
      },
    );
  }
}

/// Side drawer with user info, nav items, and sign-out button.
class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.user,
    required this.items,
    required this.currentPath,
  });

  final UserEntity user;
  final List<_NavItem> items;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // ── User Header ──
            ListTile(
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.primary,
                child: Text(
                  user.name.isNotEmpty ? user.name[0] : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: Text(
                user.name,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(user.role.label),
            ),
            const SizedBox(height: 4),

            // ── Nav Items ──
            Expanded(
              child: ListView(
                children: items.map((item) {
                  final selected = currentPath.startsWith(item.path);
                  return ListTile(
                    selected: selected,
                    selectedTileColor: AppTheme.primary.withAlpha(20),
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
                    onTap: () {
                      Navigator.of(context).pop(); // close drawer
                      context.go(item.path);
                    },
                  );
                }).toList(growable: false),
              ),
            ),

            // ── Sign Out ──
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton.tonalIcon(
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthLogoutRequested());
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
