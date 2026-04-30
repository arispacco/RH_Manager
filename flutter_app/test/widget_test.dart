import 'package:flutter_test/flutter_test.dart';

import 'package:attendance_os_mobile/app/app.dart';

void main() {
  testWidgets('renders login screen by default', (tester) async {
    await tester.pumpWidget(const AttendancePrototypeApp());

    expect(find.text('AttendanceOS'), findsOneWidget);
    expect(find.text('Sign in to your workspace'), findsOneWidget);
  });

  testWidgets('switches to register screen', (tester) async {
    await tester.pumpWidget(const AttendancePrototypeApp());
    await tester.ensureVisible(find.text('Request Access'));
    await tester.tap(find.text('Request Access'));
    await tester.pumpAndSettle();

    expect(find.text('Create an Account'), findsOneWidget);
  });
}
