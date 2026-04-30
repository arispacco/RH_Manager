import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../attendance/domain/entities/attendance_entity.dart';
import '../../../attendance/presentation/bloc/attendance_bloc.dart';
import '../../../attendance/presentation/bloc/attendance_event.dart';
import '../../../attendance/presentation/bloc/attendance_state.dart';

/// Employee dashboard with clock-in/out status, QR scan button,
/// and location verification.
class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<AttendanceBloc>();
    bloc.add(const AttendanceLoadToday());
    bloc.add(const LocationCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthBloc>().state.user;
    if (user == null) return const SizedBox.shrink();

    final firstName = user.name.split(' ').first;
    final today = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, attendance) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Greeting ──
            Text(
              'Good morning, $firstName',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(today, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),

            // ── QR Scan Card ──
            _ScanCard(clockStatus: attendance.clockStatus),
            const SizedBox(height: 16),

            // ── Location Status ──
            _LocationCard(attendance: attendance),
            const SizedBox(height: 16),

            // ── Today's Attendance ──
            _AttendanceCard(
              theme: theme,
              clockStatus: attendance.clockStatus,
              clockInTime: attendance.clockInTime,
              clockOutTime: attendance.clockOutTime,
              todayStatus: attendance.todayStatus,
            ),
            const SizedBox(height: 16),

            // ── Info Box ──
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
      },
    );
  }
}

// ── Scan Card ──────────────────────────────────────────────────

class _ScanCard extends StatelessWidget {
  const _ScanCard({required this.clockStatus});

  final ClockStatus clockStatus;

  @override
  Widget build(BuildContext context) {
    final isClockedIn = clockStatus == ClockStatus.clockedIn;
    final isClockedOut = clockStatus == ClockStatus.clockedOut;
    final theme = Theme.of(context);

    return Card(
      color: isClockedOut
          ? Colors.grey.shade400
          : isClockedIn
              ? const Color(0xFF1E7C4A)
              : AppTheme.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          children: [
            Icon(
              isClockedOut
                  ? Icons.check_circle_outline_rounded
                  : isClockedIn
                      ? Icons.logout_rounded
                      : Icons.qr_code_scanner_rounded,
              color: Colors.white,
              size: 74,
            ),
            const SizedBox(height: 16),
            Text(
              isClockedOut
                  ? 'Day Complete'
                  : isClockedIn
                      ? 'Clock Out'
                      : 'Scan QR Code',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isClockedOut
                  ? 'You have clocked out for today.'
                  : isClockedIn
                      ? 'Tap to register your departure.'
                      : 'Scan the office QR to clock in.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: isClockedOut
                  ? null
                  : () {
                      if (isClockedIn) {
                        context
                            .read<AttendanceBloc>()
                            .add(const AttendanceClockOut());
                      } else {
                        context.push('/scanner');
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withAlpha(46),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white.withAlpha(20),
                disabledForegroundColor: Colors.white60,
              ),
              child: Text(isClockedOut
                  ? 'See you tomorrow!'
                  : isClockedIn
                      ? 'Clock Out Now'
                      : 'Launch Scanner'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Location Card ──────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.attendance});

  final AttendanceState attendance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locStatus = attendance.locationStatus;

    // Determine visual state
    final (icon, iconColor, bgColor, label, trailing) = switch (locStatus) {
      LocationStatus.unknown => (
          Icons.place_outlined,
          AppTheme.onSurfaceVariant,
          AppTheme.onSurfaceVariant.withAlpha(30),
          'Tap to verify location',
          const Icon(Icons.gps_fixed_rounded, color: AppTheme.secondary),
        ),
      LocationStatus.checking => (
          Icons.my_location_rounded,
          AppTheme.secondary,
          AppTheme.secondary.withAlpha(30),
          'Checking your location...',
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ) as Widget,
        ),
      LocationStatus.withinRange => (
          Icons.place_rounded,
          const Color(0xFF1E7C4A),
          const Color(0xFFE9F9F0),
          attendance.locationMessage,
          const Icon(Icons.check_circle_rounded, color: Color(0xFF1E7C4A)),
        ),
      LocationStatus.outOfRange => (
          Icons.wrong_location_rounded,
          const Color(0xFFAF6711),
          const Color(0xFFFFF4E5),
          attendance.locationMessage,
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFAF6711)),
        ),
      LocationStatus.error => (
          Icons.location_disabled_rounded,
          Colors.red,
          Colors.red.withAlpha(20),
          attendance.locationMessage,
          const Icon(Icons.error_outline_rounded, color: Colors.red),
        ),
    };

    return GestureDetector(
      onTap: locStatus != LocationStatus.checking
          ? () {
              context
                  .read<AttendanceBloc>()
                  .add(const LocationCheckRequested());
            }
          : null,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor),
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
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: iconColor,
                      ),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Attendance Card ────────────────────────────────────────────

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({
    required this.theme,
    required this.clockStatus,
    required this.clockInTime,
    required this.clockOutTime,
    required this.todayStatus,
  });

  final ThemeData theme;
  final ClockStatus clockStatus;
  final DateTime? clockInTime;
  final DateTime? clockOutTime;
  final AttendanceStatus todayStatus;

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('hh:mm a');
    final clockInStr =
        clockInTime != null ? timeFormat.format(clockInTime!) : '--:-- --';
    final clockOutStr =
        clockOutTime != null ? timeFormat.format(clockOutTime!) : '--:-- --';

    final statusLabel = todayStatus.label;
    final statusColor = switch (todayStatus) {
      AttendanceStatus.present => const Color(0xFF1E7C4A),
      AttendanceStatus.late => const Color(0xFFAF6711),
      AttendanceStatus.absent => const Color(0xFF5E6270),
    };
    final statusBg = switch (todayStatus) {
      AttendanceStatus.present => const Color(0xFFE9F9F0),
      AttendanceStatus.late => const Color(0xFFFFF4E5),
      AttendanceStatus.absent => const Color(0xFFEFF1F4),
    };

    return Card(
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
            _InfoRow(
              icon: Icons.schedule_rounded,
              label: 'Clock-in',
              value: clockInStr,
            ),
            const Divider(height: 22),
            _InfoRow(
              icon: Icons.schedule_rounded,
              label: 'Clock-out',
              value: clockOutStr,
            ),
            const Divider(height: 22),
            Row(
              children: [
                const Icon(Icons.history_rounded, color: AppTheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Status', style: theme.textTheme.bodyMedium),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
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
