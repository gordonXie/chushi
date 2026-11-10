import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'builtin_cards.dart';

/// 本地存储：卡片清单走 SQLite，图片与录音放应用沙盒目录。
/// 不写系统相册、不申请存储权限，也不用网络。
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'renren.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cards (
            id TEXT PRIMARY KEY,
            word TEXT NOT NULL,
            note TEXT NOT NULL DEFAULT '',
            category_id TEXT NOT NULL,
            image_path TEXT,
            emoji TEXT NOT NULL DEFAULT '🙂',
            audio_type TEXT NOT NULL DEFAULT 'tts',
            audio_path TEXT,
            lang TEXT NOT NULL DEFAULT 'zh-CN',
            rate REAL NOT NULL DEFAULT 0.45,
            show_text INTEGER NOT NULL DEFAULT 1,
            is_builtin INTEGER NOT NULL DEFAULT 0,
            sort_index INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  /// 首启灌入 40 张内置卡片；已存在则跳过，保证升级不重复插入。
  Future<void> ensureBuiltinSeed() async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM cards WHERE is_builtin = 1',
    ));
    if ((count ?? 0) > 0) return;

    final batch = db.batch();
    for (var i = 0; i < kBuiltinSeed.length; i++) {
      final (emoji, word, category) = kBuiltinSeed[i];
      final now = DateTime.now().millisecondsSinceEpoch;
      batch.insert('cards', {
        'id': 'builtin_${category}_$i',
        'word': word,
        'note': '',
        'category_id': category,
        'emoji': emoji,
        'audio_type': 'tts',
        'lang': 'zh-CN',
        'rate': 0.45,
        'show_text': 1,
        'is_builtin': 1,
        'sort_index': i,
        'created_at': now,
        'updated_at': now,
      });
    }
    await batch.commit(noResult: true);
  }
}
