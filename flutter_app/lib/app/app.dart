import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/attendance/presentation/bloc/attendance_bloc.dart';
import '../core/theme/theme_cubit.dart';
import 'di.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Root widget of the AttendanceOS application.
class AttendanceApp extends StatefulWidget {
  const AttendanceApp({super.key});

  @override
  State<AttendanceApp> createState() => _AttendanceAppState();
}

class _NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child; // Returns the child without wrapping it in a Scrollbar
  }
}

class _AttendanceAppState extends State<AttendanceApp> {
  late final AuthBloc _authBloc;
  late final AttendanceBloc _attendanceBloc;
  late final ThemeCubit _themeCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>();
    _attendanceBloc = sl<AttendanceBloc>();
    _themeCubit = sl<ThemeCubit>();
    _router = createRouter(_authBloc);

    // Check for an existing session on startup
    _authBloc.add(const AuthCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<AttendanceBloc>.value(value: _attendanceBloc),
        BlocProvider<ThemeCubit>.value(value: _themeCubit),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'AttendanceOS',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeMode,
            routerConfig: _router,
            scrollBehavior: _NoScrollbarBehavior(),
          );
        },
      ),
    );
  }
}
