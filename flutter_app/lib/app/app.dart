import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import 'di.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Root widget of the AttendanceOS application.
class AttendanceApp extends StatefulWidget {
  const AttendanceApp({super.key});

  @override
  State<AttendanceApp> createState() => _AttendanceAppState();
}

class _AttendanceAppState extends State<AttendanceApp> {
  late final AuthBloc _authBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>();
    _router = createRouter(_authBloc);

    // Check for an existing session on startup
    _authBloc.add(const AuthCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
      ],
      child: MaterialApp.router(
        title: 'AttendanceOS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
      ),
    );
  }
}
