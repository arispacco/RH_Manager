import 'app_role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
  });

  factory AppUser.mock({required String email, required AppRole role}) {
    final name = switch (role) {
      AppRole.admin => 'Alex Rivers',
      AppRole.hr => 'Sarah Jenkins',
      AppRole.employee => 'Sarah Mitchell',
    };

    return AppUser(
      id: '${role.name}-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      role: role,
      department: role.department,
    );
  }

  final String id;
  final String name;
  final String email;
  final AppRole role;
  final String department;
}
