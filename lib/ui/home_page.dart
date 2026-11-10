import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../data/builtin_cards.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import 'card_edit_page.dart';
import 'playback_overlay.dart';
import 'settings_entry.dart';
import 'widgets/card_tile.dart';

/// 首页：只有分类图标、卡片、右上角无文字设置入口。
/// 幼儿点一下就出声，不出现任何文字导航与弹窗。
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _categoryId = CardCategory.animals.id;

  @override
  void initState() {
    super.initState();
    appState.speakCheck();
  }

  List<CardItem> get _visibleCards => appState.cardsOf(_categoryId);

  void _openCard(CardItem card) {
    final cards = _visibleCards;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        barrierColor: Colors.transparent,
        pageBuilder: (_, __, ___) => PlaybackOverlay(
          cards: cards,
          initialIndex: cards.indexOf(card),
          showText: appState.textVisible,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (appState.loading) {
      return const Scaffold(
        body: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColors.coral,
            ),
          ),
        ),
      );
    }

    final landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final columns = landscape ? 4 : 2;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 8),
                _CategoryBar(
                  selectedId: _categoryId,
                  onSelected: (id) => setState(() => _categoryId = id),
                ),
                Expanded(
                  child: _visibleCards.isEmpty
                      ? _EmptyCategory(categoryId: _categoryId)
                      : Center(
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(maxWidth: columns * 200.0),
                            child: GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.92,
                              ),
                              itemCount: _visibleCards.length,
                              itemBuilder: (context, index) {
                                final card = _visibleCards[index];
                                return CardTile(
                                  card: card,
                                  showText: appState.textVisible &&
                                      card.showText,
                                  onTap: () => _openCard(card),
                                );
                              },
                            ),
                          ),
                        ),
                ),
              ],
            ),
            const Positioned(top: 10, right: 0, child: SettingsEntry()),
          ],
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.selectedId, required this.onSelected});

  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        itemCount: CardCategory.all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = CardCategory.all[index];
          final selected = category.id == selectedId;
          return GestureDetector(
            onTap: () => onSelected(category.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? AppColors.line : Colors.transparent,
                  width: 1.4,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(category.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 6),
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.ink : AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 「家人」「我的」本来就没有内置卡片，空态要直接给家长一条可执行的路。
class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory({required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final isFamily = categoryId == CardCategory.family.id;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isFamily ? '👨‍👩‍👧' : '⭐',
                style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              isFamily ? '这里放家里人' : '这里放你做的卡片',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFamily
                  ? '给爷爷奶奶、爸爸妈妈各拍一张照片，配上你喊他的声音，孩子点一下就能听见。'
                  : '拍一张家里的东西，念出它的名字，三步就能做好。',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.inkSoft, height: 1.6),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CardEditPage(categoryId: categoryId),
                  ),
                );
              },
              child: const Text('做一张卡片'),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: isFamily
                  ? FamilyHint.tips
                      .map((tip) => Chip(
                            label: Text('${tip.$1} ${tip.$2}'),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.line),
                            labelStyle: const TextStyle(
                                fontSize: 13, color: AppColors.inkSoft),
                          ))
                      .toList()
                  : const [],
            ),
          ],
        ),
      ),
    );
  }
}
