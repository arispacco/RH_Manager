import 'package:equatable/equatable.dart';

import '../../domain/entities/attendance_entity.dart';

/// Possible states for today's attendance.
enum ClockStatus { idle, clockedIn, clockedOut, loading, error }

/// Represents a single employee's live presence for the HR view.
class PresenceEntry extends Equatable {
  const PresenceEntry({
    required this.name,
    required this.department,
    required this.timeIn,
    required this.status,
  });

  final String name;
  final String department;
  final String timeIn;
  final AttendanceStatus status;

  String get initials {
    final parts = name.split(' ');
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  List<Object?> get props => [name, department, status];
}

/// Weekly attendance data point.
class WeeklyData extends Equatable {
  const WeeklyData({required this.day, required this.rate});

  final String day;
  final double rate;

  @override
  List<Object?> get props => [day, rate];
}

class AttendanceState extends Equatable {
  const AttendanceState({
    this.clockStatus = ClockStatus.idle,
    this.clockInTime,
    this.clockOutTime,
    this.todayStatus = AttendanceStatus.absent,
    this.errorMessage,
    this.livePresence = const [],
    this.weeklyData = const [],
    this.totalEmployees = 0,
    this.presentCount = 0,
    this.lateCount = 0,
    this.absentCount = 0,
  });

  final ClockStatus clockStatus;
  final DateTime? clockInTime;
  final DateTime? clockOutTime;
  final AttendanceStatus todayStatus;
  final String? errorMessage;

  // HR-specific data
  final List<PresenceEntry> livePresence;
  final List<WeeklyData> weeklyData;
  final int totalEmployees;
  final int presentCount;
  final int lateCount;
  final int absentCount;

  AttendanceState copyWith({
    ClockStatus? clockStatus,
    DateTime? clockInTime,
    DateTime? clockOutTime,
    AttendanceStatus? todayStatus,
    String? errorMessage,
    List<PresenceEntry>? livePresence,
    List<WeeklyData>? weeklyData,
    int? totalEmployees,
    int? presentCount,
    int? lateCount,
    int? absentCount,
  }) {
    return AttendanceState(
      clockStatus: clockStatus ?? this.clockStatus,
      clockInTime: clockInTime ?? this.clockInTime,
      clockOutTime: clockOutTime ?? this.clockOutTime,
      todayStatus: todayStatus ?? this.todayStatus,
      errorMessage: errorMessage,
      livePresence: livePresence ?? this.livePresence,
      weeklyData: weeklyData ?? this.weeklyData,
      totalEmployees: totalEmployees ?? this.totalEmployees,
      presentCount: presentCount ?? this.presentCount,
      lateCount: lateCount ?? this.lateCount,
      absentCount: absentCount ?? this.absentCount,
    );
  }

  @override
  List<Object?> get props => [
        clockStatus,
        clockInTime,
        clockOutTime,
        todayStatus,
        errorMessage,
        livePresence,
        weeklyData,
      ];
}
