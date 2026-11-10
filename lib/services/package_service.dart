import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models.dart';
import '../data/repository.dart';

String newId() {
  final t = DateTime.now().microsecondsSinceEpoch;
  final r = Random().nextInt(1 << 20);
  return '${t}_$r';
}

/// .renren 作品包：manifest.json + images/ + audio/ + cover.jpg
/// 全离线，靠系统分享面板把文件送到另一台设备，点开即导入。
class PackageService {
  PackageService._();
  static final PackageService instance = PackageService._();

  static const fileExtension = 'renren';
  static const formatVersion = 1;

  /// 导出：不传卡则导出全部自建卡片。返回文件路径与卡片数。
  Future<(File file, int count)?> export({List<CardItem>? cards}) async {
    try {
      final all = cards ?? await CardRepository.instance.all();
      final customs = all.where((c) => !c.isBuiltin).toList();
      if (customs.isEmpty) return null;

      final archive = Archive();
      final manifestCards = <Map<String, Object?>>[];
      Uint8List? coverBytes;

      for (final card in customs) {
        Map<String, Object?> entry = {
          'word': card.word,
          'note': card.note,
          'category': card.categoryId,
          'audioType': card.audioType.name,
          'emoji': card.emoji,
          'lang': card.lang,
          'rate': card.rate,
          'showText': card.showText,
          'createdAt': card.createdAt.toIso8601String(),
        };

        if (card.imagePath != null) {
          final file = File(card.imagePath!);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final name = 'images/${newId()}.jpg';
            archive.addFile(ArchiveFile(name, bytes.length, bytes));
            entry['image'] = name;
            coverBytes ??= bytes;
          }
        }
        if (card.audioPath != null) {
          final file = File(card.audioPath!);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final name = 'audio/${newId()}.m4a';
            archive.addFile(ArchiveFile(name, bytes.length, bytes));
            entry['audio'] = name;
          }
        }
        if (entry['audio'] == null) {
          // 录音本体丢了就降级成朗读，避免包内出现哑卡。
          entry['audioType'] = AudioType.tts.name;
        }
        manifestCards.add(entry);
      }

      if (coverBytes != null) {
        archive.addFile(
            ArchiveFile('cover.jpg', coverBytes.length, coverBytes));
      }

      final manifest = {
        'formatVersion': formatVersion,
        'workPackageId': newId(),
        'name': '认认作品',
        'createdAt': DateTime.now().toIso8601String(),
        'platform': Platform.operatingSystem,
        'cards': manifestCards,
      };
      final manifestBytes = utf8.encode(jsonEncode(manifest));
      archive.addFile(
          ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) return null;
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '')
          .replaceAll('.', '')
          .substring(0, 15);
      final file = File(p.join(dir.path, 'renren_$stamp.$fileExtension'));
      await file.writeAsBytes(zipBytes);
      return (file, customs.length);
    } catch (e) {
      debugPrint('导出失败: $e');
      return null;
    }
  }

  /// 调起系统分享面板，把作品包发出去。
  Future<bool> sharePackage(File file) async {
    try {
      await Share.shareXFiles([XFile(file.path)],
          subject: '认认作品包', text: '用「认认」打开即可导入');
      return true;
    } catch (e) {
      debugPrint('分享失败: $e');
      return false;
    }
  }

  /// 从系统文件里选一个作品包并导入；返回导入条数，失败返回 -1。
  Future<int> importFromPicker() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      final path = result?.files.single.path;
      if (path == null) return 0;
      return await importFromFile(File(path));
    } catch (e) {
      debugPrint('选择文件失败: $e');
      return -1;
    }
  }

  /// 点开 .renren 文件后由系统调起应用时也走这里。
  Future<int> importFromFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      ArchiveFile? manifestFile;
      for (final f in archive.files) {
        if (f.name == 'manifest.json') {
          manifestFile = f;
          break;
        }
      }
      if (manifestFile == null) return -1;

      final content = manifestFile.content;
      if (content is! List<int>) return -1;
      final manifest = jsonDecode(utf8.decode(content)) as Map<String, Object?>;
      final version = (manifest['formatVersion'] as num?)?.toInt() ?? 1;
      if (version > formatVersion) return -1;

      final entries = (manifest['cards'] as List?) ?? const [];
      final existing = await CardRepository.instance.all();
      final existingWords =
          existing.where((c) => !c.isBuiltin).map((c) => c.word).toSet();
      final imageDir = await CardRepository.instance.mediaDir('images');
      final audioDir = await CardRepository.instance.mediaDir('audio');

      final imported = <CardItem>[];
      var sort = await CardRepository.instance.nextSortIndex();

      for (final raw in entries) {
        final entry = raw as Map<String, Object?>;
        final word = (entry['word'] as String?)?.trim() ?? '';
        if (word.isEmpty) continue;

        String? imagePath;
        final imageEntry = entry['image'] as String?;
        if (imageEntry != null) {
          final f = _find(archive, imageEntry);
          if (f != null) {
            final fbytes = f.content;
            if (fbytes is! List<int>) continue;
            final target = p.join(imageDir.path, '${newId()}.jpg');
            await File(target).writeAsBytes(fbytes);
            imagePath = target;
          }
        }

        String? audioPath;
        final audioEntry = entry['audio'] as String?;
        if (audioEntry != null) {
          final f = _find(archive, audioEntry);
          if (f != null) {
            final fbytes = f.content;
            if (fbytes is! List<int>) continue;
            final target = p.join(audioDir.path, '${newId()}.m4a');
            await File(target).writeAsBytes(fbytes);
            audioPath = target;
          }
        }

        final finalWord =
            existingWords.contains(word) ? '$word（副本）' : word;
        final audioType = audioPath == null
            ? AudioType.tts
            : ((entry['audioType'] as String?) == 'record'
                ? AudioType.record
                : AudioType.tts);

        imported.add(CardItem(
          id: 'imported_${newId()}',
          word: finalWord,
          note: (entry['note'] as String?) ?? '',
          categoryId: (entry['category'] as String?) ?? 'mine',
          imagePath: imagePath,
          emoji: (entry['emoji'] as String?) ?? '🙂',
          audioType: audioType,
          audioPath: audioPath,
          lang: (entry['lang'] as String?) ?? 'zh-CN',
          rate: (entry['rate'] as num?)?.toDouble() ?? 0.45,
          showText: (entry['showText'] as bool?) ?? true,
          sortIndex: sort++,
        ));
      }

      if (imported.isNotEmpty) {
        await CardRepository.instance.saveAll(imported);
      }
      return imported.length;
    } catch (e) {
      debugPrint('导入失败: $e');
      return -1;
    }
  }

  ArchiveFile? _find(Archive archive, String name) {
    for (final f in archive.files) {
      if (f.name == name) return f;
    }
    return null;
  }
}
