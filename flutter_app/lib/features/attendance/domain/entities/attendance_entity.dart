import 'package:equatable/equatable.dart';

/// Status of a single attendance record.
enum AttendanceStatus { present, late, absent }

/// Domain entity for an attendance record.
class AttendanceEntity extends Equatable {
  const AttendanceEntity({
    required this.id,
    required this.userId,
    required this.date,
    this.clockIn,
    this.clockOut,
    required this.status,
    this.latitude,
    this.longitude,
    this.qrToken,
  });

  final String id;
  final String userId;
  final DateTime date;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final AttendanceStatus status;
  final double? latitude;
  final double? longitude;
  final String? qrToken;

  /// Duration of work for this record, or null if not clocked out.
  Duration? get workDuration {
    if (clockIn == null || clockOut == null) return null;
    return clockOut!.difference(clockIn!);
  }

  /// Formatted work duration string (e.g. "8h 15m").
  String get workDurationFormatted {
    final d = workDuration;
    if (d == null) return '--';
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  }

  @override
  List<Object?> get props => [id, userId, date, status];
}

/// Presentation helpers for [AttendanceStatus].
extension AttendanceStatusX on AttendanceStatus {
  String get label => switch (this) {
        AttendanceStatus.present => 'Present',
        AttendanceStatus.late => 'Late',
        AttendanceStatus.absent => 'Absent',
      };
}
