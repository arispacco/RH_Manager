part of 'attendance_cubit.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {
  const AttendanceInitial();
}

class AttendanceLoading extends AttendanceState {
  const AttendanceLoading();
}

class AttendanceClockedIn extends AttendanceState {
  final AttendanceLog attendanceLog;

  const AttendanceClockedIn(this.attendanceLog);

  @override
  List<Object?> get props => [attendanceLog];
}

class AttendanceClockedOut extends AttendanceState {
  final AttendanceLog attendanceLog;

  const AttendanceClockedOut(this.attendanceLog);

  @override
  List<Object?> get props => [attendanceLog];
}

class AttendanceHistoryLoaded extends AttendanceState {
  final List<AttendanceLog> history;

  const AttendanceHistoryLoaded(this.history);

  @override
  List<Object?> get props => [history];
}

class CompanyAttendanceLoaded extends AttendanceState {
  final List<AttendanceLog> attendance;

  const CompanyAttendanceLoaded(this.attendance);

  @override
  List<Object?> get props => [attendance];
}

class AttendanceError extends AttendanceState {
  final String message;

  const AttendanceError(this.message);

  @override
  List<Object?> get props => [message];
}
