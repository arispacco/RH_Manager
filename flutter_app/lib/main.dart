import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import 'app/app.dart';
import 'app/di.dart';
import 'app/config.dart';
import 'services/postgresql_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation for consistency
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize dependency injection
  await initDependencies();

  // Initialize PostgreSQL connection if in local mode
  if (AppConfig.isLocal) {
    try {
      await sl<PostgreSQLService>().initialize();
    } catch (e) {
      // Log error
    }
  }

  runApp(const AttendanceApp());
}
