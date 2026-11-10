import 'package:flutter_test/flutter_test.dart';

import 'package:chushi/data/builtin_cards.dart';
import 'package:chushi/data/models.dart';
import 'package:chushi/app/theme.dart';

void main() {
  test('内置卡片正好 40 张，只覆盖动物、食物、日常用品三类', () {
    expect(kBuiltinSeed.length, 40);
    final categories =
        kBuiltinSeed.map((e) => e.$3).toSet();
    expect(categories, {'animals', 'food', 'daily'});
    // 每张卡的词不重复，避免孩子在不同格子里点到同一个词。
    final words = kBuiltinSeed.map((e) => e.$2).toSet();
    expect(words.length, kBuiltinSeed.length);
  });

  test('分类共 5 类，家人与我的没有内置内容', () {
    expect(CardCategory.all.length, 5);
    expect(CardCategory.family.isBuiltinContent, isFalse);
    expect(CardCategory.mine.isBuiltinContent, isFalse);
    expect(CardCategory.animals.isBuiltinContent, isTrue);
  });

  test('没有录音、词名也为空的卡片不允许发声', () {
    final card = CardItem(id: 't1', word: '', categoryId: 'mine');
    expect(card.canSpeak, isFalse);

    final spoken = CardItem(id: 't2', word: '苹果', categoryId: 'mine');
    expect(spoken.canSpeak, isTrue);
  });

  test('录音卡片能认出音频文件', () {
    final card = CardItem(
      id: 't3',
      word: '奶奶',
      categoryId: 'family',
      audioType: AudioType.record,
      audioPath: '/tmp/a.m4a',
    );
    expect(card.hasAudioFile, isTrue);
  });

  test('主题主色与配色一致，避免引入第二种鲜艳主色', () {
    final theme = AppTheme.build();
    expect(theme.colorScheme.primary, AppColors.coral);
    expect(theme.scaffoldBackgroundColor, AppColors.cream);
  });
}
