import 'package:equatable/equatable.dart';

/// Events for the Attendance BLoC.
abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

/// Load today's attendance status for the current user.
class AttendanceLoadToday extends AttendanceEvent {
  const AttendanceLoadToday();
}

/// User performed a clock-in (via QR scan).
class AttendanceClockIn extends AttendanceEvent {
  const AttendanceClockIn({
    required this.qrToken,
    this.latitude,
    this.longitude,
  });

  final String qrToken;
  final double? latitude;
  final double? longitude;

  @override
  List<Object?> get props => [qrToken, latitude, longitude];
}

/// User performed a clock-out.
class AttendanceClockOut extends AttendanceEvent {
  const AttendanceClockOut();
}

/// HR requests the live presence list.
class AttendanceLivePresenceRequested extends AttendanceEvent {
  const AttendanceLivePresenceRequested();
}

/// Employee requests a location check (GPS verification).
class LocationCheckRequested extends AttendanceEvent {
  const LocationCheckRequested();
}
