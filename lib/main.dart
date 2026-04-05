import 'dart:developer';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';
import 'app.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web 平台使用 WASM SQLite，移动端/桌面使用原生 sqflite
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 仅允许竖屏
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 全局未捕获异常处理
  FlutterError.onError = (FlutterErrorDetails details) {
    log('[ERROR] Flutter Error: ${details.exception}',
        name: 'main', error: details.exception, stackTrace: details.stack);
    FlutterError.presentError(details);
  };

  // 预初始化数据库（提前建立连接，避免首次操作延迟）
  try {
    await DatabaseService.database;
    log('[INIT] 数据库初始化成功', name: 'main');
  } catch (e, s) {
    log('[INIT] 数据库初始化失败: $e', name: 'main', error: e, stackTrace: s);
  }

  // 初始化通知服务（仅非 Web 平台，Web 跳过）
  try {
    await NotificationService.instance.init();
    log('[INIT] 通知服务初始化成功', name: 'main');
  } catch (e, s) {
    log('[INIT] 通知服务初始化失败: $e', name: 'main', error: e, stackTrace: s);
  }

  runApp(const MintDayApp());
}
