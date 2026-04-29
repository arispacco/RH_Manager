import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/attendance_entity.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

/// Manages attendance state: clock-in/out for employees,
/// live presence & weekly trends for HR.
class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  AttendanceBloc() : super(const AttendanceState()) {
    on<AttendanceLoadToday>(_onLoadToday);
    on<AttendanceClockIn>(_onClockIn);
    on<AttendanceClockOut>(_onClockOut);
    on<AttendanceLivePresenceRequested>(_onLivePresence);
  }

  Future<void> _onLoadToday(
    AttendanceLoadToday event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(clockStatus: ClockStatus.loading));
    await Future.delayed(const Duration(milliseconds: 400));

    // TODO: Fetch from BaaS
    // For now, simulate "not yet clocked in"
    emit(state.copyWith(clockStatus: ClockStatus.idle));
  }

  Future<void> _onClockIn(
    AttendanceClockIn event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(clockStatus: ClockStatus.loading));
    await Future.delayed(const Duration(milliseconds: 600));

    // TODO: Send clock-in to BaaS with QR token + GPS coords
    final now = DateTime.now();
    final isLate = now.hour >= 9;

    emit(state.copyWith(
      clockStatus: ClockStatus.clockedIn,
      clockInTime: now,
      todayStatus: isLate ? AttendanceStatus.late : AttendanceStatus.present,
    ));
  }

  Future<void> _onClockOut(
    AttendanceClockOut event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(clockStatus: ClockStatus.loading));
    await Future.delayed(const Duration(milliseconds: 400));

    // TODO: Send clock-out to BaaS
    emit(state.copyWith(
      clockStatus: ClockStatus.clockedOut,
      clockOutTime: DateTime.now(),
    ));
  }

  Future<void> _onLivePresence(
    AttendanceLivePresenceRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: Fetch from BaaS — mock data for prototype
    emit(state.copyWith(
      totalEmployees: 48,
      presentCount: 35,
      lateCount: 8,
      absentCount: 5,
      weeklyData: const [
        WeeklyData(day: 'Mon', rate: 0.85),
        WeeklyData(day: 'Tue', rate: 0.92),
        WeeklyData(day: 'Wed', rate: 0.88),
        WeeklyData(day: 'Thu', rate: 0.95),
        WeeklyData(day: 'Fri', rate: 0.0),
      ],
      livePresence: const [
        PresenceEntry(
          name: 'Sarah Mitchell',
          department: 'Engineering',
          timeIn: '08:45 AM',
          status: AttendanceStatus.present,
        ),
        PresenceEntry(
          name: 'James Davis',
          department: 'Marketing',
          timeIn: '09:12 AM',
          status: AttendanceStatus.late,
        ),
        PresenceEntry(
          name: 'Emily Wong',
          department: 'Sales',
          timeIn: '--:-- --',
          status: AttendanceStatus.absent,
        ),
        PresenceEntry(
          name: 'Michael Chang',
          department: 'Operations',
          timeIn: '08:55 AM',
          status: AttendanceStatus.present,
        ),
        PresenceEntry(
          name: 'Olivia Martin',
          department: 'Finance',
          timeIn: '08:30 AM',
          status: AttendanceStatus.present,
        ),
        PresenceEntry(
          name: 'Noah Brown',
          department: 'Engineering',
          timeIn: '09:05 AM',
          status: AttendanceStatus.late,
        ),
      ],
    ));
  }
}
