import 'package:postgres/postgres.dart';
import 'package:logger/logger.dart';
import 'package:bcrypt/bcrypt.dart';
import 'dart:math' as math;
import '../models/models.dart';

/// PostgreSQL service for local development
/// Connects directly to PostgreSQL instead of using Supabase
class PostgreSQLService {
  static final PostgreSQLService _instance = PostgreSQLService._internal();
  final Logger _logger = Logger();
  late Connection _connection;
  bool _isConnected = false;

  PostgreSQLService._internal();

  factory PostgreSQLService() {
    return _instance;
  }

  // Connection parameters
  static const String _host = 'localhost';
  static const int _port = 5432;
  static const String _database = 'rh_manager';
  static const String _username = 'postgres';
  static const String _password = 'postgres';

  bool get isConnected => _isConnected;
  Connection get connection => _connection;

  /// Initialize connection to PostgreSQL
  Future<void> initialize() async {
    try {
      _connection = await Connection.open(
        Endpoint(
          host: _host,
          port: _port,
          database: _database,
          username: _username,
          password: _password,
        ),
        settings: const ConnectionSettings(
          sslMode: SslMode.disable,
        ),
      );
      _isConnected = true;
      _logger.i('PostgreSQL connected: $_host:$_port/$_database');
    } catch (e) {
      _logger.e('Failed to connect to PostgreSQL: $e');
      _isConnected = false;
      rethrow;
    }
  }

  /// Close connection
  Future<void> close() async {
    try {
      await _connection.close();
      _isConnected = false;
      _logger.i('PostgreSQL connection closed');
    } catch (e) {
      _logger.e('Failed to close connection: $e');
    }
  }

  // Auth
  Future<void> signUp(String email, String password) async {
    try {
      final passwordHash = BCrypt.hashpw(password, BCrypt.gensalt());

      await _connection.execute(
        Sql.named('INSERT INTO users (email, password_hash) VALUES (@email, @hash)'),
        parameters: {
          'email': email,
          'hash': passwordHash,
        },
      );
      _logger.i('Sign up successful: $email');
    } catch (e) {
      _logger.e('Sign up failed: $e');
      rethrow;
    }
  }

  Future<({String id, Profile profile})> signIn(
      String email, String password) async {
    try {
      final result = await _connection.execute(
        Sql.named('SELECT id, password_hash FROM users WHERE email = @email'),
        parameters: {
          'email': email,
        },
      );

      if (result.isEmpty) {
        throw Exception('Invalid credentials');
      }

      final row = result.first.toColumnMap();
      final userId = row['id'].toString();
      final storedHash = row['password_hash'].toString();

      if (!BCrypt.checkpw(password, storedHash)) {
        throw Exception('Invalid credentials');
      }

      final profile = await getProfile(userId);

      _logger.i('Sign in successful: $email');
      return (id: userId, profile: profile);
    } catch (e) {
      _logger.e('Sign in failed: $e');
      rethrow;
    }
  }

  // Profile
  Future<Profile> getProfile(String userId) async {
    try {
      final result = await _connection.execute(
        Sql.named('SELECT id, email, first_name, last_name, phone, avatar_url, company_id, role, status, created_at, updated_at FROM profiles WHERE id = @id'),
        parameters: {'id': userId},
      );

      if (result.isEmpty) {
        throw Exception('Profile not found');
      }

      return _profileFromRow(result.first);
    } catch (e) {
      _logger.e('Failed to fetch profile: $e');
      rethrow;
    }
  }

  Future<void> updateProfile(Profile profile) async {
    try {
      await _connection.execute(
        Sql.named('UPDATE profiles SET first_name = @fn, last_name = @ln, phone = @phone, avatar_url = @avatar WHERE id = @id'),
        parameters: {
          'fn': profile.firstName,
          'ln': profile.lastName,
          'phone': profile.phone,
          'avatar': profile.avatarUrl,
          'id': profile.id,
        },
      );
      _logger.i('Profile updated: ${profile.id}');
    } catch (e) {
      _logger.e('Failed to update profile: $e');
      rethrow;
    }
  }

  // Company
  Future<Company> getCompany(String companyId) async {
    try {
      final result = await _connection.execute(
        Sql.named('SELECT id, name, description, address, latitude, longitude, geofence_radius, created_at, updated_at FROM companies WHERE id = @id'),
        parameters: {'id': companyId},
      );

      if (result.isEmpty) {
        throw Exception('Company not found');
      }

      return _companyFromRow(result.first);
    } catch (e) {
      _logger.e('Failed to fetch company: $e');
      rethrow;
    }
  }

  // QR Config
  Future<QRConfig?> getQRConfigByCode(String configCode) async {
    try {
      final result = await _connection.execute(
        Sql.named('SELECT id, company_id, config_code, name, active, created_at, updated_at FROM qr_configs WHERE config_code = @code AND active = true'),
        parameters: {'code': configCode},
      );

      if (result.isEmpty) return null;
      return _qrConfigFromRow(result.first);
    } catch (e) {
      _logger.e('Failed to fetch QR config: $e');
      return null;
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
      final result = await _connection.execute(
        Sql.named('''INSERT INTO attendance_logs (profile_id, qr_config_id, clock_in_time, clock_in_lat, clock_in_lng, status)
           VALUES (@profileId, @qrId, CURRENT_TIMESTAMP, @lat, @lng, 'clocked_in'::attendance_status)
           RETURNING id, profile_id, qr_config_id, clock_in_time, clock_out_time, clock_in_lat, clock_in_lng, clock_out_lat, clock_out_lng, status, notes, created_at, updated_at'''),
        parameters: {
          'profileId': profileId,
          'qrId': qrConfigId,
          'lat': latitude,
          'lng': longitude,
        },
      );

      _logger.i('Clock in successful: $profileId');
      return _attendanceLogFromRow(result.first);
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
      final result = await _connection.execute(
        Sql.named('''UPDATE attendance_logs SET clock_out_time = CURRENT_TIMESTAMP, clock_out_lat = @lat, clock_out_lng = @lng, status = 'clocked_out'::attendance_status
           WHERE id = @id
           RETURNING id, profile_id, qr_config_id, clock_in_time, clock_out_time, clock_in_lat, clock_in_lng, clock_out_lat, clock_out_lng, status, notes, created_at, updated_at'''),
        parameters: {
          'lat': latitude,
          'lng': longitude,
          'id': attendanceLogId,
        },
      );

      _logger.i('Clock out successful: $attendanceLogId');
      return _attendanceLogFromRow(result.first);
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
      final result = await _connection.execute(
        Sql.named('''SELECT id, profile_id, qr_config_id, clock_in_time, clock_out_time, clock_in_lat, clock_in_lng, clock_out_lat, clock_out_lng, status, notes, created_at, updated_at
           FROM attendance_logs
           WHERE profile_id = @profileId AND clock_in_time >= (CURRENT_TIMESTAMP - INTERVAL '@days days')
           ORDER BY clock_in_time DESC'''),
        parameters: {
          'profileId': profileId,
          'days': days?.toString() ?? '30',
        },
      );

      return result.map((row) => _attendanceLogFromRow(row)).toList();
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
      final result = await _connection.execute(
        Sql.named('''SELECT a.id, a.profile_id, a.qr_config_id, a.clock_in_time, a.clock_out_time, 
                    a.clock_in_lat, a.clock_in_lng, a.clock_out_lat, a.clock_out_lng, a.status, a.notes, a.created_at, a.updated_at
            FROM attendance_logs a
            JOIN profiles p ON a.profile_id = p.id
            WHERE p.company_id = @companyId AND a.clock_in_time >= (CURRENT_TIMESTAMP - INTERVAL '@days days')
            ORDER BY a.clock_in_time DESC'''),
        parameters: {
          'companyId': companyId,
          'days': days?.toString() ?? '30',
        },
      );

      return result.map((row) => _attendanceLogFromRow(row)).toList();
    } catch (e) {
      _logger.e('Failed to fetch company attendance: $e');
      rethrow;
    }
  }

  // Geofencing helper
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double p = 0.017453292519943295;
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

  // Row mappings
  Profile _profileFromRow(ResultRow row) => _profileFromMap(row.toColumnMap());
  Company _companyFromRow(ResultRow row) => _companyFromMap(row.toColumnMap());
  QRConfig _qrConfigFromRow(ResultRow row) =>
      _qrConfigFromMap(row.toColumnMap());
  AttendanceLog _attendanceLogFromRow(ResultRow row) =>
      _attendanceLogFromMap(row.toColumnMap());

  // Helpers
  Profile _profileFromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'].toString(),
      email: map['email'].toString(),
      firstName: map['first_name']?.toString(),
      lastName: map['last_name']?.toString(),
      phone: map['phone']?.toString(),
      avatarUrl: map['avatar_url']?.toString(),
      companyId: map['company_id'].toString(),
      role: _parseAppRole(map['role'].toString()),
      status: _parseEmployeeStatus(map['status'].toString()),
      createdAt: DateTime.parse(map['created_at'].toString()),
      updatedAt: DateTime.parse(map['updated_at'].toString()),
    );
  }

  Company _companyFromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'].toString(),
      name: map['name'].toString(),
      description: map['description']?.toString(),
      address: map['address']?.toString(),
      latitude:
          map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null
          ? (map['longitude'] as num).toDouble()
          : null,
      geofenceRadius: map['geofence_radius'] != null
          ? (map['geofence_radius'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(map['created_at'].toString()),
      updatedAt: DateTime.parse(map['updated_at'].toString()),
    );
  }

  QRConfig _qrConfigFromMap(Map<String, dynamic> map) {
    return QRConfig(
      id: map['id'].toString(),
      companyId: map['company_id'].toString(),
      configCode: map['config_code'].toString(),
      name: map['name']?.toString(),
      active: map['active'] as bool,
      createdAt: DateTime.parse(map['created_at'].toString()),
      updatedAt: DateTime.parse(map['updated_at'].toString()),
    );
  }

  AttendanceLog _attendanceLogFromMap(Map<String, dynamic> map) {
    return AttendanceLog(
      id: map['id'].toString(),
      profileId: map['profile_id'].toString(),
      qrConfigId: map['qr_config_id']?.toString(),
      clockInTime: DateTime.parse(map['clock_in_time'].toString()),
      clockOutTime: map['clock_out_time'] != null
          ? DateTime.parse(map['clock_out_time'].toString())
          : null,
      clockInLat: (map['clock_in_lat'] as num).toDouble(),
      clockInLng: (map['clock_in_lng'] as num).toDouble(),
      clockOutLat: map['clock_out_lat'] != null
          ? (map['clock_out_lat'] as num).toDouble()
          : null,
      clockOutLng: map['clock_out_lng'] != null
          ? (map['clock_out_lng'] as num).toDouble()
          : null,
      status: _parseAttendanceStatus(map['status'].toString()),
      notes: map['notes']?.toString(),
      createdAt: DateTime.parse(map['created_at'].toString()),
      updatedAt: DateTime.parse(map['updated_at'].toString()),
    );
  }

  AppRole _parseAppRole(String role) {
    switch (role) {
      case 'super_admin':
        return AppRole.superAdmin;
      case 'owner':
        return AppRole.owner;
      case 'admin':
        return AppRole.admin;
      case 'hr':
        return AppRole.hr;
      case 'employee':
        return AppRole.employee;
      case 'kiosk':
        return AppRole.kiosk;
      default:
        return AppRole.employee;
    }
  }

  EmployeeStatus _parseEmployeeStatus(String status) {
    switch (status) {
      case 'active':
        return EmployeeStatus.active;
      case 'inactive':
        return EmployeeStatus.inactive;
      case 'on_leave':
        return EmployeeStatus.onLeave;
      default:
        return EmployeeStatus.active;
    }
  }

  AttendanceStatus _parseAttendanceStatus(String status) {
    switch (status) {
      case 'clocked_in':
        return AttendanceStatus.clockedIn;
      case 'clocked_out':
        return AttendanceStatus.clockedOut;
      case 'on_break':
        return AttendanceStatus.onBreak;
      default:
        return AttendanceStatus.clockedOut;
    }
  }
}
