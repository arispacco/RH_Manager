import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/entities/attendance_entity.dart';

/// Reports screen with attendance history, stats, and filter chips.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedFilter = 'Last 7 days';

  // TODO: Replace with BaaS data
  static const _stats = [
    _Stat(label: 'Total Days', value: '7'),
    _Stat(label: 'Present', value: '5'),
    _Stat(label: 'Late', value: '2'),
    _Stat(label: 'Absent', value: '0'),
  ];

  static const _logs = [
    _Log(
      date: 'Monday, Oct 23',
      timeRange: '08:55 AM - 05:05 PM',
      status: AttendanceStatus.present,
      hours: '8h 10m',
    ),
    _Log(
      date: 'Tuesday, Oct 24',
      timeRange: '09:15 AM - 05:30 PM',
      status: AttendanceStatus.late,
      hours: '8h 15m',
    ),
    _Log(
      date: 'Wednesday, Oct 25',
      timeRange: '08:58 AM - 05:02 PM',
      status: AttendanceStatus.present,
      hours: '8h 04m',
    ),
    _Log(
      date: 'Thursday, Oct 26',
      timeRange: '08:30 AM - 05:10 PM',
      status: AttendanceStatus.present,
      hours: '8h 40m',
    ),
    _Log(
      date: 'Friday, Oct 27',
      timeRange: '09:08 AM - 05:15 PM',
      status: AttendanceStatus.late,
      hours: '8h 07m',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Attendance Reports', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Detailed historical logs and trend analysis.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),

        // ── Filter Chips ──
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final filter in ['Last 7 days', 'October', 'Present', 'Late'])
              FilterChip(
                label: Text(filter),
                selected: _selectedFilter == filter,
                onSelected: (_) => setState(() => _selectedFilter = filter),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Stats Grid ──
        GridView.builder(
          itemCount: _stats.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          itemBuilder: (context, index) {
            final stat = _stats[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stat.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stat.value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),

        // ── Log Details ──
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Log Details',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                for (int i = 0; i < _logs.length; i++) ...[
                  _LogTile(log: _logs[i]),
                  if (i < _logs.length - 1) const Divider(height: 18),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Log Tile ───────────────────────────────────────────────────

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});

  final _Log log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (label, bgColor, fgColor) = switch (log.status) {
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFE9EEFF),
          ),
          child: const Icon(
            Icons.calendar_month_rounded,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                log.date,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${log.timeRange} • ${log.hours}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: bgColor,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fgColor,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Data Classes ───────────────────────────────────────────────

class _Log {
  const _Log({
    required this.date,
    required this.timeRange,
    required this.status,
    required this.hours,
  });

  final String date;
  final String timeRange;
  final AttendanceStatus status;
  final String hours;
}

class _Stat {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;
}
