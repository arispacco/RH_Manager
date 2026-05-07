import 'package:bcrypt/bcrypt.dart';

void main() {
  final password = 'password';
  final newHash = BCrypt.hashpw(password, BCrypt.gensalt());
  print('New hash for "password": $newHash');
}
