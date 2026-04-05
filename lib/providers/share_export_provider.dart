import 'dart:developer';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../core/utils.dart';
import '../services/database_service.dart';
import '../services/share_export_service.dart';

/// 分享 / 导出过程中的简单加载状态（供按钮禁用等）。
class ShareExportProvider extends ChangeNotifier {
  static const _name = 'ShareExportProvider';

  bool _busy = false;
  bool get isBusy => _busy;

  Future<void> shareWidgetAsPng(
    BuildContext context,
    Widget widget, {
    required String fileStem,
    Size targetSize = const Size(360, 720),
    String? shareText,
    Duration captureDelay = const Duration(milliseconds: 600),
  }) async {
    if (kIsWeb) {
      AppUtils.showSnackBar(
        context,
        'Web 端暂不支持导出图片，请使用 Android / iOS / 桌面客户端。',
        isError: true,
      );
      return;
    }
    if (_busy) return;

    _busy = true;
    notifyListeners();
    try {
      final bytes = await ShareExportService.captureWidgetToPng(
        context,
        widget,
        targetSize: targetSize,
        delay: captureDelay,
      );
      await ShareExportService.sharePngBytes(
        bytes,
        fileStem,
        text: shareText,
      );
    } catch (e, s) {
      log('[$_name] shareWidgetAsPng 失败: $e',
          name: _name, error: e, stackTrace: s);
      if (context.mounted) {
        AppUtils.showSnackBar(context, '分享失败，请稍后重试', isError: true);
      }
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// 导出自然年打卡 CSV 并分享。
  Future<void> shareYearCheckInsCsv(BuildContext context, int year) async {
    if (kIsWeb) {
      AppUtils.showSnackBar(
        context,
        'Web 端暂不支持导出文件，请使用 Android / iOS / 桌面客户端。',
        isError: true,
      );
      return;
    }
    if (_busy) return;

    _busy = true;
    notifyListeners();
    try {
      final csv = await DatabaseService.buildCheckInsCsvForYear(year);
      await ShareExportService.shareTextFile(
        csv,
        'mintday_checkins_$year',
        subject: 'MintDay $year 打卡导出',
      );
    } catch (e, s) {
      log('[$_name] shareYearCheckInsCsv 失败: $e',
          name: _name, error: e, stackTrace: s);
      if (context.mounted) {
        AppUtils.showSnackBar(context, '导出失败，请稍后重试', isError: true);
      }
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// 导出全部打卡 CSV 并分享。
  Future<void> shareAllCheckInsCsv(BuildContext context) async {
    if (kIsWeb) {
      AppUtils.showSnackBar(
        context,
        'Web 端暂不支持导出文件，请使用 Android / iOS / 桌面客户端。',
        isError: true,
      );
      return;
    }
    if (_busy) return;

    _busy = true;
    notifyListeners();
    try {
      final csv = await DatabaseService.buildCheckInsCsvAll();
      await ShareExportService.shareTextFile(
        csv,
        'mintday_checkins_all',
        subject: 'MintDay 打卡全量导出',
      );
    } catch (e, s) {
      log('[$_name] shareAllCheckInsCsv 失败: $e',
          name: _name, error: e, stackTrace: s);
      if (context.mounted) {
        AppUtils.showSnackBar(context, '导出失败，请稍后重试', isError: true);
      }
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
