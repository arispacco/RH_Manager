import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../models/models.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  final Logger _logger = Logger();
  late SupabaseClient _client;

  SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  static const String _supabaseUrl = 'http://localhost:8000';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRlc3QiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYyMzAzMDMzMywiZXhwIjoyMDAwMDAwMDAwfQ.your_test_key';

  SupabaseClient get client => _client;
  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: _supabaseUrl,
        anonKey: _supabaseAnonKey,
      );
      _client = Supabase.instance.client;
      _logger.i('Supabase initialized');
    } catch (e) {
      _logger.e('Failed to initialize Supabase: $e');
      rethrow;
    }
  }

  // Auth
  Future<void> signUp(String email, String password) async {
    try {
      await _client.auth.signUp(email: email, password: password);
      _logger.i('Sign up successful for $email');
    } catch (e) {
      _logger.e('Sign up failed: $e');
      rethrow;
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      _logger.i('Sign in successful for $email');
    } catch (e) {
      _logger.e('Sign in failed: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      _logger.i('Sign out successful');
    } catch (e) {
      _logger.e('Sign out failed: $e');
      rethrow;
    }
  }

  // Profile
  Future<Profile> getProfile(String userId) async {
    try {
      final response =
          await _client.from('profiles').select().eq('id', userId).single();
      return Profile.fromJson(response);
    } catch (e) {
      _logger.e('Failed to fetch profile: $e');
      rethrow;
    }
  }

  Future<void> updateProfile(Profile profile) async {
    try {
      await _client
          .from('profiles')
          .update(profile.toJson())
          .eq('id', profile.id);
      _logger.i('Profile updated for ${profile.id}');
    } catch (e) {
      _logger.e('Failed to update profile: $e');
      rethrow;
    }
  }

  // Company
  Future<Company> getCompany(String companyId) async {
    try {
      final response =
          await _client.from('companies').select().eq('id', companyId).single();
      return Company.fromJson(response);
    } catch (e) {
      _logger.e('Failed to fetch company: $e');
      rethrow;
    }
  }

  // QR Config
  Future<QRConfig?> getQRConfigByCode(String configCode) async {
    try {
      final response = await _client
          .from('qr_configs')
          .select()
          .eq('config_code', configCode)
          .eq('active', true);

      if (response.isEmpty) return null;
      return QRConfig.fromJson(response.first);
    } catch (e) {
      _logger.e('Failed to fetch QR config: $e');
      rethrow;
    }
  }

  // Attendance
  Future<AttendanceLog> clockIn({
    required String profileId,
    required String? qrConfigId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final now = DateTime.now();
      final response = await _client
          .from('attendance_logs')
          .insert({
            'profile_id': profileId,
            'qr_config_id': qrConfigId,
            'clock_in_time': now.toIso8601String(),
            'clock_in_lat': latitude,
            'clock_in_lng': longitude,
            'status': AttendanceStatus.clockedIn.name,
          })
          .select()
          .single();
      _logger.i('Clock in successful for $profileId');
      return AttendanceLog.fromJson(response);
    } catch (e) {
      _logger.e('Failed to clock in: $e');
      rethrow;
    }
  }

  Future<AttendanceLog> clockOut({
    required String attendanceLogId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final now = DateTime.now();
      final response = await _client
          .from('attendance_logs')
          .update({
            'clock_out_time': now.toIso8601String(),
            'clock_out_lat': latitude,
            'clock_out_lng': longitude,
            'status': AttendanceStatus.clockedOut.name,
          })
          .eq('id', attendanceLogId)
          .select()
          .single();
      _logger.i('Clock out successful for $attendanceLogId');
      return AttendanceLog.fromJson(response);
    } catch (e) {
      _logger.e('Failed to clock out: $e');
      rethrow;
    }
  }

  Future<List<AttendanceLog>> getAttendanceHistory({
    required String profileId,
    int? days = 30,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days ?? 30));
      final response = await _client
          .from('attendance_logs')
          .select()
          .eq('profile_id', profileId)
          .gte('clock_in_time', startDate.toIso8601String())
          .order('clock_in_time', ascending: false);

      return (response as List).map((e) => AttendanceLog.fromJson(e)).toList();
    } catch (e) {
      _logger.e('Failed to fetch attendance history: $e');
      rethrow;
    }
  }

  Future<List<AttendanceLog>> getCompanyAttendance({
    required String companyId,
    int? days = 30,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days ?? 30));
      final response = await _client
          .from('attendance_logs')
          .select('*, profiles(company_id)')
          .filter('profiles.company_id', 'eq', companyId)
          .gte('clock_in_time', startDate.toIso8601String())
          .order('clock_in_time', ascending: false);

      return (response as List).map((e) => AttendanceLog.fromJson(e)).toList();
    } catch (e) {
      _logger.e('Failed to fetch company attendance: $e');
      rethrow;
    }
  }

  // Geofencing helper
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lng2 - lng1) * p)) /
            2;
    return 12742 * (2 * math.asin(math.sqrt(a))); // 2 * R; R = 6371 km
  }

  bool isWithinGeofence({
    required double userLat,
    required double userLng,
    required double companylat,
    required double companyLng,
    required double radiusKm,
  }) {
    final distance =
        calculateDistance(userLat, userLng, companylat, companyLng);
    return distance <= radiusKm;
  }

  // Real-time subscriptions
  RealtimeChannel subscribeToAttendance(String profileId) {
    return _client
        .channel('attendance:$profileId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'attendance_logs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'profile_id',
            value: profileId,
          ),
          callback: (payload) {
            _logger.i('Attendance change for $profileId: ${payload.eventType}');
          },
        )
        .subscribe();
  }

  void unsubscribeFromAttendance(String profileId) {
    _client.removeChannel(_client.channel('attendance:$profileId'));
  }
}
