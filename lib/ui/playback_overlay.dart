import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../data/builtin_cards.dart';
import '../data/models.dart';
import '../services/voice_player.dart';

/// 播放层：全屏一张大卡，进来就发声；左右滑动换卡，向下滑关闭，8 秒没动自动退出。
/// 这里的每一次点击都会重播当前词，不弹任何按钮。
class PlaybackOverlay extends StatefulWidget {
  const PlaybackOverlay({
    super.key,
    required this.cards,
    required this.initialIndex,
    required this.showText,
  });

  final List<CardItem> cards;
  final int initialIndex;
  final bool showText;

  @override
  State<PlaybackOverlay> createState() => _PlaybackOverlayState();
}

class _PlaybackOverlayState extends State<PlaybackOverlay> {
  late int _index = widget.initialIndex;
  Timer? _autoClose;

  CardItem get _card => widget.cards[_index];

  @override
  void initState() {
    super.initState();
    _speak();
    _resetTimer();
  }

  void _resetTimer() {
    _autoClose?.cancel();
    _autoClose = Timer(const Duration(seconds: 8), _close);
  }

  Future<void> _speak() async {
    final ok = await VoicePlayer.instance.playCard(_card);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('这张卡还没有声音，请家长在设置里重新配声')),
      );
    }
  }

  void _close() {
    _autoClose?.cancel();
    VoicePlayer.instance.stop();
    if (mounted) Navigator.of(context).maybePop();
  }

  void _step(int delta) {
    final next = (_index + delta).clamp(0, widget.cards.length - 1);
    if (next == _index) return;
    setState(() => _index = next);
    _resetTimer();
    _speak();
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    VoicePlayer.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;
    final tint = categoryTint(card.categoryId);
    final hasImage =
        card.imagePath != null && File(card.imagePath!).existsSync();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _resetTimer();
          _speak();
        },
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -300) {
            _step(1);
          } else if (velocity > 300) {
            _step(-1);
          }
        },
        onVerticalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity > 240) _close();
        },
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          decoration: BoxDecoration(
                            color: tint,
                            borderRadius: BorderRadius.circular(36),
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.ink.withValues(alpha: 0.08),
                                blurRadius: 28,
                                offset: const Offset(0, 12),
                              )
                            ],
                          ),
                          child: Center(
                            child: hasImage
                                ? Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Image.file(File(card.imagePath!),
                                        fit: BoxFit.contain),
                                  )
                                : FittedBox(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Text(card.emoji,
                                          style:
                                              const TextStyle(fontSize: 150)),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.showText && card.showText)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(
                      card.word,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 12),
                  child: Text('点一下再听一次 · 左右滑动换一张',
                      style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
