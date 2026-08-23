import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:attendance_os_mobile/app/app.dart';
import 'package:attendance_os_mobile/app/di.dart';

void main() {
  setUpAll(() async {
    // Provide an in-memory implementation: no plugin is available on the
    // Dart test VM.
    SharedPreferences.setMockInitialValues({});
    await initDependencies();
  });

  testWidgets('renders login screen by default', (tester) async {
    await tester.pumpWidget(const AttendanceApp());
    await tester.pumpAndSettle();

    expect(find.text('AttendanceOS'), findsOneWidget);
    expect(find.text('Sign in to your workspace'), findsOneWidget);
  });
}
