import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/location_service.dart';
import '../../../../services/postgresql_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/attendance_entity.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

/// Manages attendance state using PostgreSQL backend (Local Dev).
class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final LocationService _locationService;
  final PostgreSQLService? _postgres;
  final AuthBloc _authBloc;

  AttendanceBloc({
    required LocationService locationService,
    PostgreSQLService? postgres,
    required AuthBloc authBloc,
  })  : _locationService = locationService,
        _postgres = postgres,
        _authBloc = authBloc,
        super(const AttendanceState()) {
    on<AttendanceLoadToday>(_onLoadToday);
    on<AttendanceClockIn>(_onClockIn);
    on<AttendanceClockOut>(_onClockOut);
    on<AttendanceLivePresenceRequested>(_onLivePresence);
    on<LocationCheckRequested>(_onLocationCheck);
  }

  Future<void> _onLoadToday(
    AttendanceLoadToday event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(clockStatus: ClockStatus.loading));
    
    final user = _authBloc.state.user;
    if (user == null) {
      emit(state.copyWith(clockStatus: ClockStatus.idle));
      return;
    }

    try {
      if (!_postgres.isConnected) await _postgres.initialize();
      final history = await _postgres.getAttendanceHistory(profileId: user.id, days: 1);
      
      if (history.isNotEmpty) {
        final last = history.first;
        emit(state.copyWith(
          clockStatus: last.clockOutTime == null ? ClockStatus.clockedIn : ClockStatus.clockedOut,
          clockInTime: last.clockInTime,
          clockOutTime: last.clockOutTime,
        ));
      } else {
        emit(state.copyWith(clockStatus: ClockStatus.idle));
      }
    } catch (e) {
      emit(state.copyWith(clockStatus: ClockStatus.idle));
    }
  }

  Future<void> _onClockIn(
    AttendanceClockIn event,
    Emitter<AttendanceState> emit,
  ) async {
    final user = _authBloc.state.user;
    if (user == null) return;

    emit(state.copyWith(clockStatus: ClockStatus.loading));

    try {
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        emit(state.copyWith(clockStatus: ClockStatus.error, errorMessage: 'Location required'));
        return;
      }

      if (!_postgres.isConnected) await _postgres.initialize();
      
      // Optional: Fetch QR config if a code was provided
      String? qrId;
      if (event.qrToken.isNotEmpty) {
        final qrConfig = await _postgres.getQRConfigByCode(event.qrToken);
        qrId = qrConfig?.id;
      }

      await _postgres.clockIn(
        profileId: user.id,
        qrConfigId: qrId,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      emit(state.copyWith(
        clockStatus: ClockStatus.clockedIn,
        clockInTime: DateTime.now(),
      ));
    } catch (e) {
      emit(state.copyWith(clockStatus: ClockStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onClockOut(
    AttendanceClockOut event,
    Emitter<AttendanceState> emit,
  ) async {
    final user = _authBloc.state.user;
    if (user == null) return;

    emit(state.copyWith(clockStatus: ClockStatus.loading));

    try {
      if (!_postgres.isConnected) await _postgres.initialize();
      
      // Find active log
      final history = await _postgres.getAttendanceHistory(profileId: user.id, days: 1);
      final activeLog = history.where((l) => l.clockOutTime == null).firstOrNull;
      
      if (activeLog == null) {
        emit(state.copyWith(clockStatus: ClockStatus.error, errorMessage: 'No active session found'));
        return;
      }

      final position = await _locationService.getCurrentPosition();
      final lat = position?.latitude ?? 0.0;
      final lng = position?.longitude ?? 0.0;

      await _postgres.clockOut(
        attendanceLogId: activeLog.id,
        latitude: lat,
        longitude: lng,
      );

      emit(state.copyWith(
        clockStatus: ClockStatus.clockedOut,
        clockOutTime: DateTime.now(),
      ));
    } catch (e) {
      emit(state.copyWith(clockStatus: ClockStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onLocationCheck(
    LocationCheckRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    final user = _authBloc.state.user;
    if (user == null) return;

    emit(state.copyWith(locationStatus: LocationStatus.checking));

    try {
      if (!_postgres.isConnected) await _postgres.initialize();
      
      final profile = await _postgres.getProfile(user.id);
      final company = await _postgres.getCompany(profile.companyId);

      if (company.latitude == null || company.longitude == null) {
        emit(state.copyWith(locationStatus: LocationStatus.withinRange, locationMessage: 'No geofence enforced'));
        return;
      }

      final result = await _locationService.checkLocation(
        officeLat: company.latitude!,
        officeLng: company.longitude!,
        radiusMeters: company.geofenceRadius ?? 200,
      );

      if (result.isWithinGeofence) {
        emit(state.copyWith(
          locationStatus: LocationStatus.withinRange,
          locationMessage: 'Within range',
        ));
      } else {
        emit(state.copyWith(
          locationStatus: LocationStatus.outOfRange,
          locationMessage: 'Too far from office',
        ));
      }
    } catch (e) {
      emit(state.copyWith(locationStatus: LocationStatus.error, locationMessage: e.toString()));
    }
  }

  Future<void> _onLivePresence(
    AttendanceLivePresenceRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    final user = _authBloc.state.user;
    if (user == null || user.companyId == null) return;

    try {
      if (!_postgres.isConnected) await _postgres.initialize();
      final logs = await _postgres.getCompanyAttendance(companyId: user.companyId!);
      
      final presence = logs.map((log) => PresenceEntry(
        name: 'Employee ${log.profileId.substring(0, 5)}',
        department: 'General',
        timeIn: log.clockInTime.toLocal().toString(),
        status: AttendanceStatus.present,
      )).toList();

      emit(state.copyWith(
        livePresence: presence,
        totalEmployees: presence.length,
        presentCount: presence.length,
      ));
    } catch (e) {
      // Ignore errors in live presence for now
    }
  }
}
