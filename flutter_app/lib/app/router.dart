import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/attendance/presentation/screens/reports_screen.dart';
import '../../features/attendance/presentation/screens/scanner_screen.dart';
import '../../features/dashboard/presentation/screens/admin_dashboard.dart';
import '../../features/dashboard/presentation/screens/employee_dashboard.dart';
import '../../features/dashboard/presentation/screens/home_shell.dart';
import '../../features/dashboard/presentation/screens/hr_dashboard.dart';
import '../../features/dashboard/presentation/screens/kiosk_dashboard.dart';
import '../../features/employees/presentation/screens/employee_directory_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

/// Application route paths.
class RoutePaths {
  RoutePaths._();

  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/';
  static const String dashboard = 'dashboard';
  static const String employees = 'employees';
  static const String attendance = 'attendance';
  static const String reports = 'reports';
  static const String analytics = 'analytics';
  static const String company = 'company';
  static const String settings = 'settings';
  static const String scanner = '/scanner';
  static const String kiosk = '/kiosk';
}

/// Creates the [GoRouter] instance for the entire app.
GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: RoutePaths.login,
    debugLogDiagnostics: false,
    refreshListenable: _GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final user = authState.user;
      final isAuthRoute = state.matchedLocation == RoutePaths.login ||
          state.matchedLocation == RoutePaths.register;

      if (!isAuthenticated && !isAuthRoute) return RoutePaths.login;

      if (isAuthenticated && isAuthRoute) {
        if (user?.role == UserRole.kiosk) {
          return RoutePaths.kiosk;
        }
        return '/${RoutePaths.dashboard}';
      }

      // Block non-kiosk routes for kiosk users
      if (isAuthenticated &&
          user?.role == UserRole.kiosk &&
          state.matchedLocation != RoutePaths.kiosk) {
        return RoutePaths.kiosk;
      }

      return null;
    },
    routes: [
      // ── Auth Routes ──
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return RegisterScreen(initialType: extra?['type'] as String?);
        },
      ),

      // ── Kiosk Route (outside shell) ──
      GoRoute(
        path: RoutePaths.kiosk,
        builder: (context, state) => const KioskDashboard(),
      ),

      // ── Scanner (full-screen, outside shell) ──
      GoRoute(
        path: RoutePaths.scanner,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ScannerScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),

      // ── Main App Shell ──
      ShellRoute(
        builder: (context, state, child) {
          final user = authBloc.state.user;
          if (user == null) return const SizedBox.shrink();
          return HomeShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/${RoutePaths.dashboard}',
            pageBuilder: (context, state) => _fadeTransitionPage(
              key: state.pageKey,
              child: _buildDashboardForRole(authBloc.state.user),
            ),
          ),
          GoRoute(
            path: '/${RoutePaths.reports}',
            pageBuilder: (context, state) => _fadeTransitionPage(
              key: state.pageKey,
              child: const ReportsScreen(),
            ),
          ),
          GoRoute(
            path: '/${RoutePaths.attendance}',
            pageBuilder: (context, state) => _fadeTransitionPage(
              key: state.pageKey,
              child: const ReportsScreen(),
            ),
          ),
          GoRoute(
            path: '/${RoutePaths.employees}',
            pageBuilder: (context, state) => _fadeTransitionPage(
              key: state.pageKey,
              child: const EmployeeDirectoryScreen(),
            ),
          ),
          GoRoute(
            path: '/${RoutePaths.analytics}',
            pageBuilder: (context, state) => _fadeTransitionPage(
              key: state.pageKey,
              child: const _PlaceholderScreen(
                title: 'Analytics',
                subtitle: 'Cross-company KPIs and trends.',
                icon: Icons.insights_outlined,
              ),
            ),
          ),
          GoRoute(
            path: '/${RoutePaths.company}',
            pageBuilder: (context, state) => _fadeTransitionPage(
              key: state.pageKey,
              child: const _PlaceholderScreen(
                title: 'Company',
                subtitle: 'Workspace and company settings.',
                icon: Icons.apartment_rounded,
              ),
            ),
          ),
          GoRoute(
            path: '/${RoutePaths.settings}',
            pageBuilder: (context, state) => _fadeTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}

// ── Helpers ──────────────────────────────────────────────────

Widget _buildDashboardForRole(UserEntity? user) {
  if (user == null) return const SizedBox.shrink();
  return switch (user.role) {
    UserRole.admin ||
    UserRole.super_admin ||
    UserRole.owner =>
      const AdminDashboard(),
    UserRole.hr => const HRDashboard(),
    UserRole.employee => const EmployeeDashboard(),
    UserRole.kiosk => const SizedBox
        .shrink(), // Kiosk is not in the shell, this won't be reached
  };
}

CustomTransitionPage<void> _fadeTransitionPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({
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
                    color: theme.colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, size: 34, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
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
