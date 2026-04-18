import 'dart:typed_data';

class StorageService {
  static const bool supportsPersistentImages = false;

  static Future<String?> saveImage(String tempPath) async {
    return null;
  }

  static Future<void> deleteImage(String filePath) async {}

  static Future<List<String>> saveImages(List<String> tempPaths) async {
    return const [];
  }

  static Future<String?> saveBytes(
    Uint8List bytes, {
    String folderName = 'generated_assets',
    String extension = 'png',
  }) async {
    return null;
  }
}
