import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class HRDashboard extends StatelessWidget {
  const HRDashboard({super.key});

  static const _weeklyAttendance = [
    _WeeklyAttendance(day: 'Mon', presentRate: 0.85),
    _WeeklyAttendance(day: 'Tue', presentRate: 0.92),
    _WeeklyAttendance(day: 'Wed', presentRate: 0.88),
    _WeeklyAttendance(day: 'Thu', presentRate: 0.95),
    _WeeklyAttendance(day: 'Fri', presentRate: 0.0),
  ];

  static const _presence = [
    _PresenceEntry(
      name: 'Sarah Mitchell',
      department: 'Engineering',
      timeIn: '08:45 AM',
      status: 'present',
    ),
    _PresenceEntry(
      name: 'James Davis',
      department: 'Marketing',
      timeIn: '09:12 AM',
      status: 'late',
    ),
    _PresenceEntry(
      name: 'Emily Wong',
      department: 'Sales',
      timeIn: '--:-- --',
      status: 'absent',
    ),
    _PresenceEntry(
      name: 'Michael Chang',
      department: 'Operations',
      timeIn: '08:55 AM',
      status: 'present',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Overview', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Real-time workforce insights for today',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Attendance Trends',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                for (final day in _weeklyAttendance) ...[
                  _AttendanceBarRow(day: day.day, ratio: day.presentRate),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          color: AppTheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.qr_code_2_rounded,
                  size: 34,
                  color: AppTheme.secondaryContainer,
                ),
                const SizedBox(height: 14),
                Text(
                  'Check-in Station',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Deploy a QR scanner for immediate employee check-ins.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.82),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Launch Scanner UI'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Real-time Presence',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                for (final employee in _presence) ...[
                  _PresenceTile(entry: employee),
                  const Divider(height: 18),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AttendanceBarRow extends StatelessWidget {
  const _AttendanceBarRow({required this.day, required this.ratio});

  final String day;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final percentage = (ratio * 100).round();
    return Row(
      children: [
        SizedBox(
          width: 34,
          child: Text(
            day,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: LinearProgressIndicator(
            minHeight: 10,
            borderRadius: BorderRadius.circular(20),
            value: ratio,
            color: AppTheme.secondary,
            backgroundColor: const Color(0xFFE2ECFF),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            '$percentage%',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _PresenceTile extends StatelessWidget {
  const _PresenceTile({required this.entry});

  final _PresenceEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusStyle = switch (entry.status) {
      'present' => const _StatusStyle(
          label: 'Present',
          background: Color(0xFFE9F9F0),
          foreground: Color(0xFF1E7C4A),
        ),
      'late' => const _StatusStyle(
          label: 'Late',
          background: Color(0xFFFFF4E5),
          foreground: Color(0xFFAF6711),
        ),
      _ => const _StatusStyle(
          label: 'Absent',
          background: Color(0xFFEFF1F4),
          foreground: Color(0xFF5E6270),
        ),
    };

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFE8EEFF),
          child: Text(
            entry.initials,
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                entry.department,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              entry.timeIn,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusStyle.background,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusStyle.label,
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.2,
                  fontWeight: FontWeight.w700,
                  color: statusStyle.foreground,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WeeklyAttendance {
  const _WeeklyAttendance({required this.day, required this.presentRate});

  final String day;
  final double presentRate;
}

class _PresenceEntry {
  const _PresenceEntry({
    required this.name,
    required this.department,
    required this.timeIn,
    required this.status,
  });

  final String name;
  final String department;
  final String timeIn;
  final String status;

  String get initials {
    final split = name.split(' ');
    if (split.length == 1) {
      return split.first.substring(0, 1).toUpperCase();
    }
    return '${split.first[0]}${split.last[0]}'.toUpperCase();
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
}
