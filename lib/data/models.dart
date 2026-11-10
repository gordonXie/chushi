import 'dart:convert';

/// 声音来源：家长录音优先，系统朗读兜底。
enum AudioType { record, tts }

/// 一张卡片。内置卡片与家长自建卡片共用一张表，用 [isBuiltin] 区分。
class CardItem {
  CardItem({
    required this.id,
    required this.word,
    this.note = '',
    required this.categoryId,
    this.imagePath,
    this.emoji = '🙂',
    this.audioType = AudioType.tts,
    this.audioPath,
    this.lang = 'zh-CN',
    this.rate = 0.45,
    this.showText = true,
    this.isBuiltin = false,
    this.sortIndex = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String word;
  String note;
  String categoryId;
  String? imagePath;
  String emoji;
  AudioType audioType;
  String? audioPath;
  String lang;
  double rate;
  bool showText;
  bool isBuiltin;
  int sortIndex;
  DateTime createdAt;
  DateTime updatedAt;

  /// 是否具备发声条件。PRD 要求「不允许出现哑卡」，保存与播放前都查这一项。
  bool get canSpeak => (audioType == AudioType.record && audioPath != null) ||
      (audioType == AudioType.tts && word.trim().isNotEmpty);

  bool get hasAudioFile =>
      audioType == AudioType.record &&
      audioPath != null &&
      audioPath!.isNotEmpty;

  CardItem copyWith({
    String? word,
    String? note,
    String? categoryId,
    String? imagePath,
    String? emoji,
    AudioType? audioType,
    String? audioPath,
    double? rate,
    bool? showText,
    int? sortIndex,
  }) {
    return CardItem(
      id: id,
      word: word ?? this.word,
      note: note ?? this.note,
      categoryId: categoryId ?? this.categoryId,
      imagePath: imagePath ?? this.imagePath,
      emoji: emoji ?? this.emoji,
      audioType: audioType ?? this.audioType,
      audioPath: audioPath ?? this.audioPath,
      lang: lang,
      rate: rate ?? this.rate,
      showText: showText ?? this.showText,
      isBuiltin: isBuiltin,
      sortIndex: sortIndex ?? this.sortIndex,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'word': word,
        'note': note,
        'category_id': categoryId,
        'image_path': imagePath,
        'emoji': emoji,
        'audio_type': audioType.name,
        'audio_path': audioPath,
        'lang': lang,
        'rate': rate,
        'show_text': showText ? 1 : 0,
        'is_builtin': isBuiltin ? 1 : 0,
        'sort_index': sortIndex,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory CardItem.fromMap(Map<String, Object?> m) => CardItem(
        id: m['id'] as String,
        word: m['word'] as String,
        note: (m['note'] as String?) ?? '',
        categoryId: m['category_id'] as String,
        imagePath: m['image_path'] as String?,
        emoji: (m['emoji'] as String?) ?? '🙂',
        audioType: (m['audio_type'] as String?) == 'record'
            ? AudioType.record
            : AudioType.tts,
        audioPath: m['audio_path'] as String?,
        lang: (m['lang'] as String?) ?? 'zh-CN',
        rate: (m['rate'] as num?)?.toDouble() ?? 0.45,
        showText: (m['show_text'] as int? ?? 1) == 1,
        isBuiltin: (m['is_builtin'] as int? ?? 0) == 1,
        sortIndex: (m['sort_index'] as int?) ?? 0,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int? ?? 0),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int? ?? 0),
      );

  Map<String, Object?> toJson() => {
        'word': word,
        'note': note,
        'category': categoryId,
        'audioType': audioType.name,
        'audio': audioPath,
        'image': imagePath,
        'emoji': emoji,
        'lang': lang,
        'rate': rate,
        'showText': showText,
      };

  static CardItem fromJson(Map<String, Object?> j, String id) => CardItem(
        id: id,
        word: (j['word'] as String?) ?? '',
        note: (j['note'] as String?) ?? '',
        categoryId: (j['category'] as String?) ?? 'mine',
        imagePath: j['image'] as String?,
        emoji: (j['emoji'] as String?) ?? '🙂',
        audioType: (j['audioType'] as String?) == 'record'
            ? AudioType.record
            : AudioType.tts,
        audioPath: j['audio'] as String?,
        lang: (j['lang'] as String?) ?? 'zh-CN',
        rate: (j['rate'] as num?)?.toDouble() ?? 0.45,
        showText: (j['showText'] as bool?) ?? true,
      );

  String encode() => jsonEncode(toJson());
}

/// 分类。首期 5 类，其中「家人」不预置图片，由家长自建。
class CardCategory {
  const CardCategory({
    required this.id,
    required this.name,
    required this.emoji,
    this.isBuiltinContent = false,
  });

  final String id;
  final String name;
  final String emoji;

  /// 该分类是否有内置卡片；没有的分类需要在空态里给出制作引导。
  final bool isBuiltinContent;

  static const animals = CardCategory(
      id: 'animals', name: '动物', emoji: '🐾', isBuiltinContent: true);
  static const food = CardCategory(
      id: 'food', name: '食物', emoji: '🍎', isBuiltinContent: true);
  static const daily = CardCategory(
      id: 'daily', name: '日常用品', emoji: '🧺', isBuiltinContent: true);
  static const family = CardCategory(id: 'family', name: '家人', emoji: '👨‍👩‍👧');
  static const mine = CardCategory(id: 'mine', name: '我的', emoji: '⭐');

  static const all = [animals, food, daily, family, mine];

  static CardCategory byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => mine);
}
