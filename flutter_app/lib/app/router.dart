import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/home_shell.dart';

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
}

/// Creates the [GoRouter] instance for the entire app.
///
/// The router redirects unauthenticated users to the login screen
/// and authenticated users away from auth screens.
GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: RoutePaths.login,
    debugLogDiagnostics: true,
    refreshListenable: _GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isAuthRoute = state.matchedLocation == RoutePaths.login ||
          state.matchedLocation == RoutePaths.register;

      // Not authenticated and not on an auth page → redirect to login
      if (!isAuthenticated && !isAuthRoute) {
        return RoutePaths.login;
      }

      // Authenticated but on an auth page → redirect to home
      if (isAuthenticated && isAuthRoute) {
        return RoutePaths.home;
      }

      return null; // no redirect
    },
    routes: [
      // Auth routes
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main app shell with nested navigation
      ShellRoute(
        builder: (context, state, child) {
          final user = authBloc.state.user;
          if (user == null) return const SizedBox.shrink();
          return HomeShell(child: child);
        },
        routes: [
          GoRoute(
            path: RoutePaths.home,
            redirect: (context, state) {
              // Redirect bare "/" to "/dashboard"
              if (state.matchedLocation == '/') {
                return '/${RoutePaths.dashboard}';
              }
              return null;
            },
          ),
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
              child: const _PlaceholderScreen(
                title: 'Reports',
                subtitle: 'Attendance reports and analytics.',
                icon: Icons.description_outlined,
              ),
            ),
          ),
          GoRoute(
            path: '/${RoutePaths.attendance}',
            pageBuilder: (context, state) => _fadeTransitionPage(
              key: state.pageKey,
              child: const _PlaceholderScreen(
                title: 'Attendance',
                subtitle: 'Attendance records and history.',
                icon: Icons.history_toggle_off_rounded,
              ),
            ),
          ),
          GoRoute(
            path: '/${RoutePaths.employees}',
            pageBuilder: (context, state) => _fadeTransitionPage(
              key: state.pageKey,
              child: const _PlaceholderScreen(
                title: 'Employee Directory',
                subtitle: 'Directory and profile management.',
                icon: Icons.groups_2_outlined,
              ),
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
              child: const _PlaceholderScreen(
                title: 'Settings',
                subtitle: 'Personalization and security settings.',
                icon: Icons.settings_outlined,
              ),
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
  // TODO: Import and return actual dashboard screens once refactored
  return _PlaceholderScreen(
    title: '${user.role.label} Dashboard',
    subtitle: 'Welcome back, ${user.name}',
    icon: Icons.dashboard_outlined,
  );
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

/// Adapts a [Stream] to a [Listenable] for GoRouter's refreshListenable.
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

/// Temporary placeholder screen for routes not yet implemented.
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
