import 'dart:developer';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/supabase_config.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      log('[INIT] Supabase initialized', name: 'main');
    } catch (error, stackTrace) {
      log(
        '[INIT] Supabase initialization failed: $error',
        name: 'main',
        error: error,
        stackTrace: stackTrace,
      );
    }
  } else {
    log(
      '[INIT] SupabaseConfig is using placeholder values; auth is disabled.',
      name: 'main',
    );
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  FlutterError.onError = (details) {
    log(
      '[ERROR] Flutter Error: ${details.exception}',
      name: 'main',
      error: details.exception,
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };

  try {
    await DatabaseService.database;
    log('[INIT] Database initialized', name: 'main');
  } catch (error, stackTrace) {
    log(
      '[INIT] Database initialization failed: $error',
      name: 'main',
      error: error,
      stackTrace: stackTrace,
    );
  }

  try {
    await NotificationService.instance.init();
    log('[INIT] Notification service initialized', name: 'main');
  } catch (error, stackTrace) {
    log(
      '[INIT] Notification service initialization failed: $error',
      name: 'main',
      error: error,
      stackTrace: stackTrace,
    );
  }

  runApp(const MintDayApp());
}
