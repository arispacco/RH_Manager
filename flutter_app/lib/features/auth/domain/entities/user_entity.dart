import 'package:equatable/equatable.dart';

/// Roles a user can have in the application.
enum UserRole { employee, hr, admin, superAdmin, owner, kiosk }

/// Domain entity representing an authenticated user.
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    this.avatarUrl,
    this.companyId,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String department;
  final String? avatarUrl;
  final String? companyId;

  /// Creates a mock user for prototype / offline mode.
  factory UserEntity.mock({required String email, required UserRole role}) {
    final name = switch (role) {
      UserRole.superAdmin => 'Super Admin',
      UserRole.owner => 'Company Owner',
      UserRole.admin => 'Alex Rivers',
      UserRole.hr => 'Sarah Jenkins',
      UserRole.employee => 'Sarah Mitchell',
      UserRole.kiosk => 'Reception Kiosk',
    };

    return UserEntity(
      id: '${role.name}-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      role: role,
      department: role.defaultDepartment,
    );
  }

  @override
  List<Object?> get props => [id, email, role];
}

/// Presentation helpers for [UserRole].
extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.employee => 'Employee',
        UserRole.hr => 'HR Manager',
        UserRole.admin => 'Admin',
        UserRole.superAdmin => 'Super Admin',
        UserRole.owner => 'Owner',
        UserRole.kiosk => 'Kiosk',
      };

  String get defaultDepartment => switch (this) {
        UserRole.employee => 'Engineering',
        UserRole.hr => 'Human Resources',
        UserRole.admin => 'Platform Operations',
        UserRole.superAdmin => 'Global Administration',
        UserRole.owner => 'Executive',
        UserRole.kiosk => 'Reception',
      };
}

/// Determine role from email (prototype fallback only).
UserRole roleFromEmail(String email) {
  final normalized = email.toLowerCase();
  if (normalized.contains('super_admin')) return UserRole.superAdmin;
  if (normalized.contains('owner')) return UserRole.owner;
  if (normalized.contains('admin')) return UserRole.admin;
  if (normalized.contains('hr')) return UserRole.hr;
  if (normalized.contains('kiosk')) return UserRole.kiosk;
  return UserRole.employee;
}
