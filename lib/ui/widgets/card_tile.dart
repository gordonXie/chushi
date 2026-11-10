import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/builtin_cards.dart';
import '../../data/models.dart';

/// 卡片格子：一张图 + 一个词。图片缺失时用 emoji 顶住，保证任何时候都能发声、都有画面。
class CardTile extends StatelessWidget {
  const CardTile({
    super.key,
    required this.card,
    required this.showText,
    this.onTap,
    this.onLongPress,
    this.elevated = false,
  });

  final CardItem card;
  final bool showText;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final tint = categoryTint(card.categoryId);
    final hasImage =
        card.imagePath != null && File(card.imagePath!).existsSync();

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: elevated
              ? [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  )
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: hasImage
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.file(
                          File(card.imagePath!),
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(card.emoji,
                              style: const TextStyle(fontSize: 56)),
                        ),
                      ),
              ),
            ),
            if (showText)
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
                child: Text(
                  card.word,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
