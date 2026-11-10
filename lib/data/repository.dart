import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'database.dart';
import 'models.dart';

/// 卡片读写入口。所有界面只经过这一层，未来若加账号只替换实现。
class CardRepository {
  CardRepository._();
  static final CardRepository instance = CardRepository._();

  Future<void> init() async {
    await AppDatabase.instance.ensureBuiltinSeed();
  }

  Future<List<CardItem>> all() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('cards', orderBy: 'sort_index ASC');
    return rows.map(CardItem.fromMap).toList();
  }

  Future<void> save(CardItem card) async {
    final db = await AppDatabase.instance.database;
    await db.insert('cards', card.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveAll(List<CardItem> cards) async {
    final db = await AppDatabase.instance.database;
    final batch = db.batch();
    for (final card in cards) {
      batch.insert('cards', card.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('cards', where: 'id = ?', whereArgs: [id]);
  }

  /// 删除家长自建卡片，内置卡片保留（PRD 的「清除数据」口径）。
  Future<void> clearCustom() async {
    final db = await AppDatabase.instance.database;
    await db.delete('cards', where: 'is_builtin = 0');
  }

  Future<void> reorder(List<CardItem> ordered) async {
    final db = await AppDatabase.instance.database;
    final batch = db.batch();
    for (var i = 0; i < ordered.length; i++) {
      batch.update('cards', {'sort_index': i},
          where: 'id = ?', whereArgs: [ordered[i].id]);
    }
    await batch.commit(noResult: true);
  }

  /// 下一次可用的排序位，避免新卡与内置卡撞序。
  Future<int> nextSortIndex() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('SELECT MAX(sort_index) AS m FROM cards');
    final max = rows.first['m'] as int?;
    return (max ?? 0) + 1;
  }

  /// 图片与录音目录，均在应用沙盒内。
  Future<Directory> mediaDir(String kind) async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, 'media', kind));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> rootDir() => getApplicationDocumentsDirectory();
}
