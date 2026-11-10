import 'package:flutter/material.dart';

import '../data/models.dart';

/// 首批内置 40 张，只覆盖动物、食物、日常用品三类。
/// 图片位先用大号 emoji 承载：体积小、跨端一致，插画上线后替换 imagePath 即可。
const List<(String emoji, String word, String category)> kBuiltinSeed = [
  // 动物 15
  ('🐱', '猫', 'animals'),
  ('🐶', '狗', 'animals'),
  ('🐰', '兔子', 'animals'),
  ('🐷', '猪', 'animals'),
  ('🐮', '牛', 'animals'),
  ('🐑', '羊', 'animals'),
  ('🐔', '鸡', 'animals'),
  ('🦆', '鸭', 'animals'),
  ('🐟', '鱼', 'animals'),
  ('🐘', '大象', 'animals'),
  ('🐯', '老虎', 'animals'),
  ('🐵', '猴子', 'animals'),
  ('🐻', '熊', 'animals'),
  ('🐦', '小鸟', 'animals'),
  ('🦋', '蝴蝶', 'animals'),
  // 食物 15
  ('🍎', '苹果', 'food'),
  ('🍌', '香蕉', 'food'),
  ('🍇', '葡萄', 'food'),
  ('🍉', '西瓜', 'food'),
  ('🍓', '草莓', 'food'),
  ('🍊', '橘子', 'food'),
  ('🥕', '胡萝卜', 'food'),
  ('🌽', '玉米', 'food'),
  ('🍞', '面包', 'food'),
  ('🥛', '牛奶', 'food'),
  ('🥚', '鸡蛋', 'food'),
  ('🍚', '米饭', 'food'),
  ('🍜', '面条', 'food'),
  ('🍪', '饼干', 'food'),
  ('🍰', '蛋糕', 'food'),
  // 日常用品 10
  ('🥤', '杯子', 'daily'),
  ('🥄', '勺子', 'daily'),
  ('🥣', '碗', 'daily'),
  ('🪥', '牙刷', 'daily'),
  ('🧴', '毛巾', 'daily'),
  ('👟', '鞋子', 'daily'),
  ('🧢', '帽子', 'daily'),
  ('🪑', '椅子', 'daily'),
  ('🛏️', '床', 'daily'),
  ('⚽', '球', 'daily'),
];

/// 「家人」类别的空态占位卡：不预置内容，只告诉家长这里可以放谁。
class FamilyHint {
  static const List<(String emoji, String label)> tips = [
    ('👩', '妈妈'),
    ('👨', '爸爸'),
    ('👵', '奶奶'),
    ('👴', '爷爷'),
  ];
}

/// 分类色调：同一分类下卡片同色，帮助幼儿建立分类感。
Color categoryTint(String categoryId) {
  switch (categoryId) {
    case 'animals':
      return const Color(0xFFDFF3EA);
    case 'food':
      return const Color(0xFFFFE3D9);
    case 'daily':
      return const Color(0xFFE3F1FB);
    case 'family':
      return const Color(0xFFFFF0D2);
    default:
      return const Color(0xFFF3EBE3);
  }
}

String categoryLabel(String id) => CardCategory.byId(id).name;
