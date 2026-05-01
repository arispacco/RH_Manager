import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../app/theme/app_theme.dart';

class EmployeeDashboard extends StatelessWidget {
  const EmployeeDashboard({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final firstName = user.name.split(' ').first;
    final today =
        MaterialLocalizations.of(context).formatFullDate(DateTime.now());
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Good morning, $firstName',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(today, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),
        Card(
          color: AppTheme.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              children: [
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 74,
                ),
                const SizedBox(height: 16),
                Text(
                  'Scan QR Code',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Launch Scanner'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.place_rounded,
                    color: AppTheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location Status',
                        style: theme.textTheme.labelMedium?.copyWith(
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Within 50m of Office',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle_rounded, color: Colors.green),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Attendance",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                const _InfoRow(
                  icon: Icons.schedule_rounded,
                  label: 'Clock-in Time',
                  value: '08:45 AM',
                ),
                const Divider(height: 22),
                const _InfoRow(
                  icon: Icons.history_rounded,
                  label: 'Status',
                  value: 'Present',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF4FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD8E5FF)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFF2857A6)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your location is verified automatically via GPS before scanning.',
                  style: TextStyle(
                    color: Color(0xFF1A325D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: AppTheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
