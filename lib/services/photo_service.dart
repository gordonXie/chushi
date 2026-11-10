import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../data/repository.dart';
import 'package_service.dart';

/// 选图与压缩：统一转 JPEG，长边不超过 1200 像素，质量 0.8。
/// 图片留在应用沙盒，不写相册。
class PhotoService {
  PhotoService._();
  static final PhotoService instance = PhotoService._();

  final ImagePicker _picker = ImagePicker();

  Future<String?> pickAndStore({bool fromCamera = false}) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 92,
      );
      if (picked == null) return null;
      final dir = await CardRepository.instance.mediaDir('images');
      final target = p.join(dir.path, 'img_${newId()}.jpg');
      final bytes = await picked.readAsBytes();
      final compressed = _compress(bytes);
      await File(target).writeAsBytes(compressed ?? bytes);
      return target;
    } catch (e) {
      debugPrint('选图失败: $e');
      return null;
    }
  }

  Uint8List? _compress(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      final resized = decoded.width > 1200
          ? img.copyResize(decoded,
              width: 1200, interpolation: img.Interpolation.average)
          : decoded;
      return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
    } catch (e) {
      debugPrint('压缩失败: $e');
      return null;
    }
  }
}
