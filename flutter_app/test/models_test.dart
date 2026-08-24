import 'package:flutter_test/flutter_test.dart';

import 'package:attendance_os_mobile/models/models.dart';

void main() {
  group('AttendanceLog.fromJson (dual-key parsing)', () {
    const createdAt = '2026-08-24T08:00:00Z';
    const clockIn = '2026-08-24T08:05:00Z';
    const base = {
      'id': 'log-1',
      'clock_in_lat': 4.05,
      'clock_in_lng': 9.7,
      'status': 'on_time',
    };

    test('parses the local schema keys', () {
      final log = AttendanceLog.fromJson(const {
        ...base,
        'profile_id': 'user-1',
        'clock_in_time': clockIn,
        'qr_config_id': 'cfg-1',
        'notes': 'ok',
        'created_at': createdAt,
        'updated_at': createdAt,
      });

      expect(log.profileId, 'user-1');
      expect(log.clockInTime, DateTime.parse(clockIn));
      expect(log.clockOutTime, isNull);
      expect(log.qrConfigId, 'cfg-1');
      expect(log.notes, 'ok');
    });

    test('parses the live Supabase schema keys', () {
      final log = AttendanceLog.fromJson(const {
        ...base,
        'user_id': 'auth-uid-1',
        'clock_in': clockIn,
      });

      expect(log.profileId, 'auth-uid-1');
      expect(log.clockInTime, DateTime.parse(clockIn));
      expect(log.clockOutTime, isNull);
      // Columns absent from the live schema stay null.
      expect(log.qrConfigId, isNull);
      expect(log.notes, isNull);
    });

    test('parses a closed log with cloud keys and local fallback', () {
      final closed = AttendanceLog.fromJson(const {
        ...base,
        'user_id': 'auth-uid-2',
        'clock_in': '2026-08-24T07:58:00Z',
        'clock_out_time': '2026-08-24T17:02:00Z',
      });
      expect(closed.clockOutTime, DateTime.parse('2026-08-24T17:02:00Z'));

      final closedLocal = AttendanceLog.fromJson(const {
        ...base,
        'profile_id': 'user-2',
        'clock_in_time': '2026-08-23T07:58:00Z',
        'clock_out_time': '2026-08-23T17:02:00Z',
      });
      expect(closedLocal.clockOutTime, DateTime.parse('2026-08-23T17:02:00Z'));
    });
  });

  group('Profile.fromJson (dual-key parsing)', () {
    const base = {
      'id': 'p-1',
      'role': 'employee',
      'created_at': '2026-08-24T06:00:00Z',
      'updated_at': '2026-08-24T06:00:00Z',
    };

    test('keeps the local schema behavior', () {
      final profile = Profile.fromJson(const {
        ...base,
        'email': 'john@acme.com',
        'first_name': 'John',
        'last_name': 'Doe',
        'company_id': 'c-1',
        'status': 'inactive',
      });

      expect(profile.email, 'john@acme.com');
      expect(profile.firstName, 'John');
      expect(profile.lastName, 'Doe');
      expect(profile.companyId, 'c-1');
      expect(profile.status, EmployeeStatus.inactive);
      expect(profile.fullName, 'John Doe');
    });

    test('splits the live `name` column into names', () {
      final profile = Profile.fromJson(const {
        ...base,
        'name': 'Jean-Paul Devereux',
        'company_id': 'c-2',
        'is_active': true,
      });

      expect(profile.email, isEmpty);
      expect(profile.firstName, 'Jean-Paul');
      expect(profile.lastName, 'Devereux');
      expect(profile.fullName, 'Jean-Paul Devereux');
      expect(profile.status, EmployeeStatus.active);
    });

    test('maps is_active=false to inactive status', () {
      final pending = Profile.fromJson(const {
        ...base,
        'name': 'New Hire',
        'is_active': false,
      });

      expect(pending.status, EmployeeStatus.inactive);
    });

    test('defaults to active when neither status nor is_active exist', () {
      final profile = Profile.fromJson(const {...base, 'name': 'Solo'});
      expect(profile.status, EmployeeStatus.active);
      expect(profile.lastName, isNull);
    });
  });
}
