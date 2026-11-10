import 'dart:io';

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../data/builtin_cards.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import 'card_edit_page.dart';

/// 卡片管理：只列家长自建的卡片，支持拖拽排序、改、删。
/// 内置卡片不给改，避免家长把 40 张基础词弄乱。
class CardManagePage extends StatefulWidget {
  const CardManagePage({super.key, this.openNew = false});

  final bool openNew;

  @override
  State<CardManagePage> createState() => _CardManagePageState();
}

class _CardManagePageState extends State<CardManagePage> {
  @override
  void initState() {
    super.initState();
    if (widget.openNew) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _createNew());
    }
  }

  Future<void> _createNew() async {
    final result = await Navigator.of(context).push<CardItem>(
      MaterialPageRoute(builder: (_) => const CardEditPage()),
    );
    if (result == null || !mounted) return;
    await appState.upsertCard(result);
  }

  Future<void> _edit(CardItem card) async {
    final result = await Navigator.of(context).push<CardItem>(
      MaterialPageRoute(builder: (_) => CardEditPage(card: card)),
    );
    if (result == null || !mounted) return;
    await appState.upsertCard(result);
  }

  Future<void> _delete(CardItem card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius)),
        title: const Text('删除这张卡片？'),
        content: Text('「${card.word}」的图片和录音会一起删掉，删除后无法恢复。',
            style: const TextStyle(fontSize: 14, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('先留着'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await appState.removeCard(card);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的卡片')),
      body: AnimatedBuilder(
        animation: appState,
        builder: (context, _) {
          final customs = appState.cards.where((c) => !c.isBuiltin).toList();
          if (customs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🃏', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 16),
                    const Text('还没有自己的卡片',
                        style: TextStyle(
                            fontSize: 19,
                        fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                    const SizedBox(height: 8),
                    const Text('拍一张家里的东西，念出名字，孩子点一下就能听见。',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14,
                            color: AppColors.inkSoft,
                            height: 1.6)),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _createNew,
                      child: const Text('做一张卡片'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: customs.length,
                  onReorderItem: (oldIndex, newIndex) {
                    final list = [...customs];
                    final moved = list.removeAt(oldIndex);
                    list.insert(newIndex, moved);
                    // 排序复核后落库：内置卡片不在列表里，位置保持不动。
                    final builtin = appState.cards
                        .where((c) => c.isBuiltin)
                        .toList();
                    appState.reorder([...builtin, ...list]);
                  },
                  itemBuilder: (context, index) {
                    final card = customs[index];
                    return _ManageTile(
                      key: ValueKey(card.id),
                      card: card,
                      index: index,
                      onEdit: () => _edit(card),
                      onDelete: () => _delete(card),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _createNew,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('做一张新卡'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ManageTile extends StatelessWidget {
  const _ManageTile({
    super.key,
    required this.card,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  final CardItem card;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        card.imagePath != null && File(card.imagePath!).existsSync();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: categoryTint(card.categoryId),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasImage
                      ? Image.file(File(card.imagePath!), fit: BoxFit.cover)
                      : Center(
                          child: Text(card.emoji,
                              style: const TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.word,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(
                        '${categoryLabel(card.categoryId)} · '
                        '${card.hasAudioFile ? "家长录音" : "系统朗读"}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.inkSoft),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.inkSoft),
                  tooltip: '删除',
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.drag_handle_rounded,
                        color: AppColors.inkSoft),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
