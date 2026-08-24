import 'package:equatable/equatable.dart';

enum AppRole { superAdmin, owner, admin, hr, employee, kiosk }

enum AttendanceStatus { clockedIn, clockedOut, onBreak }

enum EmployeeStatus { active, inactive, onLeave }

class Company extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? geofenceRadius;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Company({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.latitude,
    this.longitude,
    this.geofenceRadius,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) => Company(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        address: json['address'],
        latitude: json['latitude'],
        longitude: json['longitude'],
        geofenceRadius: json['geofence_radius'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'geofence_radius': geofenceRadius,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        address,
        latitude,
        longitude,
        geofenceRadius,
        createdAt,
        updatedAt
      ];
}

class Profile extends Equatable {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? avatarUrl;

  /// Nullable: the live Supabase schema allows profiles without a company.
  final String? companyId;
  final AppRole role;
  final EmployeeStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.avatarUrl,
    this.companyId,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  /// Dual-key parsing: supports the legacy/local schema
  /// (first_name/last_name/status/email) and the live Supabase schema
  /// (`name`, `is_active`, no email column).
  factory Profile.fromJson(Map<String, dynamic> json) {
    final rawName = (json['name'] as String?)?.trim();
    final nameParts =
        rawName?.split(' ').where((p) => p.isNotEmpty).toList() ?? const [];
    return Profile(
        // The email column does not exist in the live schema: inject the
        // authenticated user's email at call site instead.
        id: json['id'],
        email: json['email'] ?? '',
        firstName: json['first_name'] ??
            (nameParts.isNotEmpty ? nameParts.first : null),
        lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : null,
        phone: json['phone'],
        avatarUrl: json['avatar_url'],
        companyId: json['company_id'],
        role: AppRole.values.firstWhere(
          (e) => e.name == json['role'],
          orElse: () => AppRole.employee,
        ),
        status: json['status'] != null
            ? EmployeeStatus.values.firstWhere(
                (e) => e.name == json['status'],
                orElse: () => EmployeeStatus.active,
              )
            : json['is_active'] == false
                ? EmployeeStatus.inactive
                : EmployeeStatus.active,
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'avatar_url': avatarUrl,
        'company_id': companyId,
        'role': role.name,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        email,
        firstName,
        lastName,
        phone,
        avatarUrl,
        companyId,
        role,
        status,
        createdAt,
        updatedAt,
      ];
}

class QRConfig extends Equatable {
  final String id;
  final String companyId;
  final String configCode;
  final String? name;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const QRConfig({
    required this.id,
    required this.companyId,
    required this.configCode,
    this.name,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QRConfig.fromJson(Map<String, dynamic> json) => QRConfig(
        id: json['id'],
        companyId: json['company_id'],
        configCode: json['config_code'],
        name: json['name'],
        active: json['active'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'config_code': configCode,
        'name': name,
        'active': active,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [id, companyId, configCode, name, active, createdAt, updatedAt];
}

class AttendanceLog extends Equatable {
  final String id;
  final String profileId;
  final String? qrConfigId;
  final DateTime clockInTime;
  final DateTime? clockOutTime;
  final double clockInLat;
  final double clockInLng;
  final double? clockOutLat;
  final double? clockOutLng;
  final AttendanceStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AttendanceLog({
    required this.id,
    required this.profileId,
    this.qrConfigId,
    required this.clockInTime,
    this.clockOutTime,
    required this.clockInLat,
    required this.clockInLng,
    this.clockOutLat,
    this.clockOutLng,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Dual-key parsing: supports the local schema
  /// (profile_id/clock_in_time/clock_out_time) and the live Supabase schema
  /// (user_id/clock_in/clock_out). The first non-null key wins.
  factory AttendanceLog.fromJson(Map<String, dynamic> json) => AttendanceLog(
        id: json['id'],
        profileId: json['profile_id'] ?? json['user_id'],
        qrConfigId: json['qr_config_id'],
        clockInTime:
            DateTime.parse(json['clock_in_time'] ?? json['clock_in']),
        clockOutTime: (json['clock_out_time'] ?? json['clock_out']) != null
            ? DateTime.parse(json['clock_out_time'] ?? json['clock_out'])
            : null,
        clockInLat: json['clock_in_lat'],
        clockInLng: json['clock_in_lng'],
        clockOutLat: json['clock_out_lat'],
        clockOutLng: json['clock_out_lng'],
        status: AttendanceStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => AttendanceStatus.clockedOut,
        ),
        notes: json['notes'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );

  /// Insert via RPC clock_in/clock_out in Supabase mode; kept for the
  /// local PostgreSQL mode.
  Map<String, dynamic> toJson() => {
        'id': id,
        'profile_id': profileId,
        'qr_config_id': qrConfigId,
        'clock_in_time': clockInTime.toIso8601String(),
        'clock_out_time': clockOutTime?.toIso8601String(),
        'clock_in_lat': clockInLat,
        'clock_in_lng': clockInLng,
        'clock_out_lat': clockOutLat,
        'clock_out_lng': clockOutLng,
        'status': status.name,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        profileId,
        qrConfigId,
        clockInTime,
        clockOutTime,
        clockInLat,
        clockInLng,
        clockOutLat,
        clockOutLng,
        status,
        notes,
        createdAt,
        updatedAt,
      ];
}
