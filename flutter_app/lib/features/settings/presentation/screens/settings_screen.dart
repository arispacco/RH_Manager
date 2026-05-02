import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';

/// Settings screen with profile info, preferences, and sign-out.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthBloc>().state.user;
    if (user == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Settings', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Manage your account and preferences.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),

        // ── Profile Card ──
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFFE7EEFF),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(user.email, style: theme.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withAlpha(20),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          user.role.label,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // TODO: Navigate to profile edit
                  },
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // ── Account Section ──
        const _SectionHeader(title: 'Account'),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                title: 'Edit Profile',
                subtitle: 'Name, photo, department',
                onTap: () {
                  // TODO: Profile editing
                },
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.lock_outline_rounded,
                title: 'Change Password',
                subtitle: 'Update your credentials',
                onTap: () {
                  // TODO: Password change
                },
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.security_rounded,
                title: 'Two-Factor Auth',
                subtitle: 'Extra layer of security',
                trailing: Switch(
                  value: false,
                  onChanged: (value) {
                    // TODO: Toggle 2FA
                  },
                ),
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Preferences Section ──
        const _SectionHeader(title: 'Preferences'),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Push alerts and reminders',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {
                    // TODO: Toggle notifications
                  },
                ),
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.language_rounded,
                title: 'Language',
                subtitle: 'English',
                onTap: () {
                  // TODO: Language picker
                },
              ),
              const Divider(height: 1, indent: 56),
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) {
                  final isDark = themeMode == ThemeMode.dark ||
                      (themeMode == ThemeMode.system &&
                          MediaQuery.of(context).platformBrightness ==
                              Brightness.dark);
                  return _SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    subtitle: 'Switch theme',
                    trailing: Switch(
                      value: isDark,
                      onChanged: (value) {
                        context.read<ThemeCubit>().toggleTheme();
                      },
                    ),
                    onTap: () {
                      context.read<ThemeCubit>().toggleTheme();
                    },
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── About Section ──
        const _SectionHeader(title: 'About'),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'App Version',
                subtitle: '1.0.0 (build 1)',
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                onTap: () {
                  // TODO: Open ToS
                },
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.shield_outlined,
                title: 'Privacy Policy',
                onTap: () {
                  // TODO: Open privacy policy
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Sign Out ──
        FilledButton.tonalIcon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Sign Out'),
                content:
                    const Text('Are you sure you want to sign out?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      context
                          .read<AuthBloc>()
                          .add(const AuthLogoutRequested());
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.logout_rounded, color: Colors.red),
          label: const Text(
            'Sign Out',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

// ── Section Header ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: AppTheme.onSurfaceVariant,
          ),
    );
  }
}

// ── Settings Tile ──────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primary.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: theme.textTheme.bodySmall)
          : null,
      trailing: trailing ??
          const Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
