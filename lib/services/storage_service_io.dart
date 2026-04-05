import 'dart:developer';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  static const _uuid = Uuid();
  static const bool supportsPersistentImages = true;

  static Future<String?> saveImage(String tempPath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(appDir.path, 'check_in_images'));
      if (!imagesDir.existsSync()) {
        imagesDir.createSync(recursive: true);
      }

      final extension = path.extension(tempPath);
      final fileName = '${_uuid.v4()}$extension';
      final destinationPath = path.join(imagesDir.path, fileName);

      await File(tempPath).copy(destinationPath);
      log('[StorageService] 图片保存: $destinationPath', name: 'StorageService');
      return destinationPath;
    } catch (e, s) {
      log(
        '[StorageService] 图片保存失败: $e',
        name: 'StorageService',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  static Future<void> deleteImage(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
        log('[StorageService] 图片删除: $filePath', name: 'StorageService');
      }
    } catch (e) {
      log('[StorageService] 图片删除失败: $e', name: 'StorageService');
    }
  }

  static Future<List<String>> saveImages(List<String> tempPaths) async {
    final results = <String>[];
    for (final tempPath in tempPaths) {
      final saved = await saveImage(tempPath);
      if (saved != null) {
        results.add(saved);
      }
    }
    return results;
  }
}
