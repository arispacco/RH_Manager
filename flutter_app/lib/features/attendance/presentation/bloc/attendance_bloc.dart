import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../app/di.dart';
import '../../../../app/config.dart';
import '../../../../core/services/location_service.dart';
import '../../../../services/postgresql_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final LocationService _locationService;
  final PostgreSQLService? _postgres;
  final sb.SupabaseClient? _supabase;
  final AuthBloc _authBloc;

  AttendanceBloc({
    required LocationService locationService,
    PostgreSQLService? postgres,
    AuthBloc? authBloc,
  })  : _locationService = locationService,
        _postgres = AppConfig.isLocal
            ? (postgres ?? sl<PostgreSQLService>())
            : null,
        _supabase = AppConfig.isSupabase ? sl<sb.SupabaseClient>() : null,
        _authBloc = authBloc ?? sl<AuthBloc>(),
        super(const AttendanceState()) {
    on<AttendanceLoadToday>(_onLoadToday);
    on<AttendanceClockIn>(_onClockIn);
    on<AttendanceClockOut>(_onClockOut);
    on<AttendanceLivePresenceRequested>(_onLivePresence);
    on<LocationCheckRequested>(_onLocationCheck);
  }

  PostgreSQLService get _localPostgres {
    final service = _postgres;
    if (service == null) {
      throw StateError('PostgreSQL backend unavailable in Supabase mode');
    }
    return service;
  }

  sb.SupabaseClient get _remoteSupabase {
    final client = _supabase;
    if (client == null) {
      throw StateError('Supabase backend unavailable in local mode');
    }
    return client;
  }

  Future<void> _onLoadToday(AttendanceLoadToday event, Emitter<AttendanceState> emit) async {
    emit(state.copyWith(clockStatus: ClockStatus.loading));
    final user = _authBloc.state.user;
    if (user == null) {
      emit(state.copyWith(clockStatus: ClockStatus.idle));
      return;
    }

    try {
      if (AppConfig.isLocal) {
        if (!_localPostgres.isConnected) await _localPostgres.initialize();
        final history = await _localPostgres.getAttendanceHistory(profileId: user.id, days: 1);
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
      } else {
        // Supabase Mode
        final response = await _remoteSupabase.from('attendance_logs')
            .select()
            .eq('profile_id', user.id)
            .order('clock_in_time', ascending: false)
            .limit(1)
            .maybeSingle();
        
        if (response != null) {
          final lastClockOut = response['clock_out_time'];
          emit(state.copyWith(
            clockStatus: lastClockOut == null ? ClockStatus.clockedIn : ClockStatus.clockedOut,
            clockInTime: DateTime.parse(response['clock_in_time']),
            clockOutTime: lastClockOut != null ? DateTime.parse(lastClockOut) : null,
          ));
        } else {
          emit(state.copyWith(clockStatus: ClockStatus.idle));
        }
      }
    } catch (e) {
      emit(state.copyWith(clockStatus: ClockStatus.idle));
    }
  }

  Future<void> _onClockIn(AttendanceClockIn event, Emitter<AttendanceState> emit) async {
    final user = _authBloc.state.user;
    if (user == null) return;
    emit(state.copyWith(clockStatus: ClockStatus.loading));

    try {
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        emit(state.copyWith(clockStatus: ClockStatus.error, errorMessage: 'Location required'));
        return;
      }

      if (AppConfig.isLocal) {
        if (!_localPostgres.isConnected) await _localPostgres.initialize();
        await _localPostgres.clockIn(profileId: user.id, qrConfigId: null, latitude: position.latitude, longitude: position.longitude);
      } else {
        // Supabase Mode
        await _remoteSupabase.from('attendance_logs').insert({
          'profile_id': user.id,
          'clock_in_time': DateTime.now().toIso8601String(),
          'clock_in_lat': position.latitude,
          'clock_in_lng': position.longitude,
          'status': 'present',
        });
      }

      emit(state.copyWith(clockStatus: ClockStatus.clockedIn, clockInTime: DateTime.now()));
    } catch (e) {
      emit(state.copyWith(clockStatus: ClockStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onClockOut(AttendanceClockOut event, Emitter<AttendanceState> emit) async {
    final user = _authBloc.state.user;
    if (user == null) return;
    emit(state.copyWith(clockStatus: ClockStatus.loading));

    try {
      final position = await _locationService.getCurrentPosition();
      final lat = position?.latitude ?? 0.0;
      final lng = position?.longitude ?? 0.0;

      if (AppConfig.isLocal) {
        if (!_localPostgres.isConnected) await _localPostgres.initialize();
        final history = await _localPostgres.getAttendanceHistory(profileId: user.id, days: 1);
        final activeLog = history.where((l) => l.clockOutTime == null).firstOrNull;
        if (activeLog != null) {
          await _localPostgres.clockOut(attendanceLogId: activeLog.id, latitude: lat, longitude: lng);
        }
      } else {
        // Supabase Mode
        final response = await _remoteSupabase.from('attendance_logs')
            .select('id')
            .eq('profile_id', user.id)
            .isFilter('clock_out_time', null)
            .order('clock_in_time', ascending: false)
            .limit(1)
            .maybeSingle();
        
        if (response != null) {
          await _remoteSupabase.from('attendance_logs').update({
            'clock_out_time': DateTime.now().toIso8601String(),
            'clock_out_lat': lat,
            'clock_out_lng': lng,
          }).eq('id', response['id']);
        }
      }

      emit(state.copyWith(clockStatus: ClockStatus.clockedOut, clockOutTime: DateTime.now()));
    } catch (e) {
      emit(state.copyWith(clockStatus: ClockStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onLocationCheck(LocationCheckRequested event, Emitter<AttendanceState> emit) async {
     // Location check is mostly local logic (comparing current vs office coords)
     // but we need office coords from the DB.
     final user = _authBloc.state.user;
     if (user == null) return;
     emit(state.copyWith(locationStatus: LocationStatus.checking));

     try {
       double? officeLat;
       double? officeLng;
       double radius = 200;

       if (AppConfig.isLocal) {
         if (!_localPostgres.isConnected) await _localPostgres.initialize();
         final profile = await _localPostgres.getProfile(user.id);
         final company = await _localPostgres.getCompany(profile.companyId);
         officeLat = company.latitude;
         officeLng = company.longitude;
         radius = company.geofenceRadius ?? 200;
       } else {
         final company = await _remoteSupabase.from('companies').select().eq('id', user.companyId!).single();
         officeLat = company['latitude'];
         officeLng = company['longitude'];
         radius = company['geofence_radius']?.toDouble() ?? 200;
       }

       if (officeLat == null || officeLng == null) {
         emit(state.copyWith(locationStatus: LocationStatus.withinRange, locationMessage: 'No geofence enforced'));
         return;
       }

       final result = await _locationService.checkLocation(officeLat: officeLat, officeLng: officeLng, radiusMeters: radius);
       if (result.isWithinGeofence) {
         emit(state.copyWith(locationStatus: LocationStatus.withinRange, locationMessage: 'Within range'));
       } else {
         emit(state.copyWith(locationStatus: LocationStatus.outOfRange, locationMessage: 'Too far from office'));
       }
     } catch (e) {
       emit(state.copyWith(locationStatus: LocationStatus.error, locationMessage: e.toString()));
     }
  }

  Future<void> _onLivePresence(AttendanceLivePresenceRequested event, Emitter<AttendanceState> emit) async {
    // Simplified live presence for both modes
  }
}
