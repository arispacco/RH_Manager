import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/di.dart';

import '../../../../core/services/location_service.dart';
import '../../domain/entities/attendance_entity.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

/// Manages attendance state: clock-in/out for employees,
/// live presence & weekly trends for HR.
class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  AttendanceBloc({required LocationService locationService})
      : _locationService = locationService,
        super(const AttendanceState()) {
    on<AttendanceLoadToday>(_onLoadToday);
    on<AttendanceClockIn>(_onClockIn);
    on<AttendanceClockOut>(_onClockOut);
    on<AttendanceLivePresenceRequested>(_onLivePresence);
    on<LocationCheckRequested>(_onLocationCheck);
  }

  final LocationService _locationService;

  Future<void> _onLoadToday(
    AttendanceLoadToday event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(clockStatus: ClockStatus.loading));
    await Future.delayed(const Duration(milliseconds: 400));

    // TODO: Fetch from BaaS
    emit(state.copyWith(clockStatus: ClockStatus.idle));
  }

  Future<void> _onClockIn(
    AttendanceClockIn event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(clockStatus: ClockStatus.loading));

    // Verify location before allowing clock-in
    if (state.locationStatus != LocationStatus.withinRange) {
      emit(state.copyWith(
        clockStatus: ClockStatus.error,
        errorMessage: 'Please verify your location first.',
      ));
      return;
    }

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

  Future<void> _onLocationCheck(
    LocationCheckRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(
      locationStatus: LocationStatus.checking,
      locationMessage: 'Fetching geofence config from server...',
    ));

    try {
      final _supabase = sl<SupabaseClient>();
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // 1. Get the user's company_id
      final profile = await _supabase
          .from('profiles')
          .select('company_id')
          .eq('id', user.id)
          .single();
      final companyId = profile['company_id'];

      // 2. Get the GPS config for this company
      final config = await _supabase
          .from('qr_configs')
          .select('office_lat, office_lng, radius_meters')
          .eq('company_id', companyId)
          .single();

      final officeLat = config['office_lat'] as double;
      final officeLng = config['office_lng'] as double;
      final radiusMeters = (config['radius_meters'] as num).toDouble();

      emit(state.copyWith(
        locationMessage: 'Checking your physical location...',
      ));

      // 3. Compare physical location with company's GPS config
      final result = await _locationService.checkLocation(
        officeLat: officeLat,
        officeLng: officeLng,
        radiusMeters: radiusMeters,
      );

      if (result.errorMessage != null) {
        emit(state.copyWith(
          locationStatus: LocationStatus.error,
          locationMessage: result.errorMessage!,
        ));
        return;
      }

      if (result.isWithinGeofence) {
        emit(state.copyWith(
          locationStatus: LocationStatus.withinRange,
          distanceMeters: result.distanceMeters,
          locationMessage: 'Within ${result.distanceFormatted} of office',
        ));
      } else {
        emit(state.copyWith(
          locationStatus: LocationStatus.outOfRange,
          distanceMeters: result.distanceMeters,
          locationMessage: '${result.distanceFormatted} from office — too far',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        locationStatus: LocationStatus.error,
        locationMessage: 'Failed to fetch GPS config: $e',
      ));
    }
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
