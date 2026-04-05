import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

/// 截图字节写入临时文件并唤起系统分享（非 Web）。
class ShareExportService {
  ShareExportService._();

  /// 将离屏 Widget 渲染为 PNG（需传入 [context] 以继承 Theme / 字体）。
  static Future<Uint8List> captureWidgetToPng(
    BuildContext context,
    Widget widget, {
    Size targetSize = const Size(360, 720),
    Duration delay = const Duration(milliseconds: 500),
    double? pixelRatio,
  }) async {
    final controller = ScreenshotController();
    final ratio =
        pixelRatio ?? MediaQuery.devicePixelRatioOf(context).clamp(1.0, 4.0);
    return controller.captureFromWidget(
      widget,
      context: context,
      targetSize: targetSize,
      delay: delay,
      pixelRatio: ratio,
    );
  }

  static Future<void> sharePngBytes(
    Uint8List bytes,
    String fileStem, {
    String? text,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('sharePngBytes on web');
    }
    final dir = await getTemporaryDirectory();
    final name = '$fileStem.png';
    final path = p.join(dir.path, name);
    final file = File(path);
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [
        XFile(
          path,
          mimeType: 'image/png',
          name: name,
        ),
      ],
      text: text,
    );
  }

  static Future<void> shareTextFile(
    String content,
    String fileStem, {
    String? subject,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('shareTextFile on web');
    }
    final dir = await getTemporaryDirectory();
    final name = '$fileStem.csv';
    final path = p.join(dir.path, name);
    await File(path).writeAsString(content, encoding: utf8);
    await Share.shareXFiles(
      [XFile(path, mimeType: 'text/csv', name: name)],
      subject: subject,
    );
  }
}
