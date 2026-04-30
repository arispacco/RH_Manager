enum AppRole { employee, hr, admin }

extension AppRolePresentation on AppRole {
  String get label => switch (this) {
        AppRole.employee => 'Employee',
        AppRole.hr => 'HR Manager',
        AppRole.admin => 'Super Admin',
      };

  String get department => switch (this) {
        AppRole.employee => 'Engineering',
        AppRole.hr => 'Human Resources',
        AppRole.admin => 'Platform Operations',
      };
}

AppRole roleFromEmail(String email) {
  final normalized = email.toLowerCase();
  if (normalized.contains('admin')) {
    return AppRole.admin;
  }
  if (normalized.contains('hr')) {
    return AppRole.hr;
  }
  return AppRole.employee;
}
