import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../attendance/domain/entities/attendance_entity.dart';
import '../../../attendance/presentation/bloc/attendance_bloc.dart';
import '../../../attendance/presentation/bloc/attendance_event.dart';
import '../../../attendance/presentation/bloc/attendance_state.dart';

/// HR Dashboard with live presence, weekly trends, and QR station launcher.
class HRDashboard extends StatefulWidget {
  const HRDashboard({super.key});

  @override
  State<HRDashboard> createState() => _HRDashboardState();
}

class _HRDashboardState extends State<HRDashboard> {
  @override
  void initState() {
    super.initState();
    context
        .read<AttendanceBloc>()
        .add(const AttendanceLivePresenceRequested());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, attendance) {
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

            // ── Stats Row ──
            Row(
              children: [
                _StatChip(
                  label: 'Present',
                  value: '${attendance.presentCount}',
                  color: const Color(0xFF1E7C4A),
                  bgColor: const Color(0xFFE9F9F0),
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Late',
                  value: '${attendance.lateCount}',
                  color: const Color(0xFFAF6711),
                  bgColor: const Color(0xFFFFF4E5),
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Absent',
                  value: '${attendance.absentCount}',
                  color: const Color(0xFF5E6270),
                  bgColor: const Color(0xFFEFF1F4),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Weekly Trends ──
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
                    for (final day in attendance.weeklyData) ...[
                      _AttendanceBarRow(day: day.day, ratio: day.rate),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Check-in Station Card ──
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
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.push('/scanner'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Launch Scanner'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Live Presence ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Real-time Presence',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          '${attendance.livePresence.length} / ${attendance.totalEmployees}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    for (final entry in attendance.livePresence) ...[
                      _PresenceTile(entry: entry),
                      const Divider(height: 18),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Stat Chip ──────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Attendance Bar ─────────────────────────────────────────────

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

// ── Presence Tile ──────────────────────────────────────────────

class _PresenceTile extends StatelessWidget {
  const _PresenceTile({required this.entry});

  final PresenceEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (label, bgColor, fgColor) = switch (entry.status) {
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
              Text(entry.department, style: theme.textTheme.bodySmall),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.2,
                  fontWeight: FontWeight.w700,
                  color: fgColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
