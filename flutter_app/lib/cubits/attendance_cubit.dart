import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/models.dart';
import '../services/postgresql_service.dart';

part 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  final PostgreSQLService _postgresService;

  AttendanceCubit(this._postgresService) : super(const AttendanceInitial());

  Future<void> clockIn({
    required String profileId,
    required String? qrConfigId,
    required double latitude,
    required double longitude,
    required double companyLat,
    required double companyLng,
    required double geofenceRadius,
  }) async {
    emit(const AttendanceLoading());
    try {
      // Check geofence
      final isWithinGeofence = _postgresService.isWithinGeofence(
        userLat: latitude,
        userLng: longitude,
        companylat: companyLat,
        companyLng: companyLng,
        radiusKm: geofenceRadius,
      );

      if (!isWithinGeofence) {
        emit(const AttendanceError('You are outside the geofence'));
        return;
      }

      final attendanceLog = await _postgresService.clockIn(
        profileId: profileId,
        qrConfigId: qrConfigId,
        latitude: latitude,
        longitude: longitude,
      );

      emit(AttendanceClockedIn(attendanceLog));
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }

  Future<void> clockOut({
    required String attendanceLogId,
    required double latitude,
    required double longitude,
  }) async {
    emit(const AttendanceLoading());
    try {
      final attendanceLog = await _postgresService.clockOut(
        attendanceLogId: attendanceLogId,
        latitude: latitude,
        longitude: longitude,
      );

      emit(AttendanceClockedOut(attendanceLog));
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }

  Future<void> loadAttendanceHistory({
    required String profileId,
    int? days = 30,
  }) async {
    emit(const AttendanceLoading());
    try {
      final history = await _postgresService.getAttendanceHistory(
        profileId: profileId,
        days: days,
      );

      emit(AttendanceHistoryLoaded(history));
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }

  Future<void> loadCompanyAttendance({
    required String companyId,
    int? days = 30,
  }) async {
    emit(const AttendanceLoading());
    try {
      final attendance = await _postgresService.getCompanyAttendance(
        companyId: companyId,
        days: days,
      );

      emit(CompanyAttendanceLoaded(attendance));
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }
}
