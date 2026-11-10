import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../data/models.dart';

/// 全应用唯一的声音出口。
/// PRD 要求「同一时刻只允许一条声音在播，点另一张卡就切过去」，因此任何一次
/// 播放都先停掉上一个来源：录音播放器与系统朗读都归它管。
class VoicePlayer {
  VoicePlayer._();
  static final VoicePlayer instance = VoicePlayer._();

  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;
  bool _ttsAvailable = true;
  String? _playingCardId;

  String? get playingCardId => _playingCardId;

  /// 进入首页时做一次音色自检；缺失中文音色时上层引导家长录音。
  Future<bool> ensureTts() async {
    if (_ttsReady) return _ttsAvailable;
    try {
      final languages = await _tts.getLanguages;
      final available = (languages is List)
          ? languages.any((l) => l.toString().toLowerCase().contains('zh'))
          : true;
      _ttsAvailable = available;
      if (available) {
        await _tts.setLanguage('zh-CN');
        await _tts.setSpeechRate(0.45);
        await _tts.setPitch(1.2);
        await _tts.awaitSpeakCompletion(true);
      }
    } catch (e) {
      debugPrint('TTS 自检失败: $e');
      _ttsAvailable = false;
    }
    _ttsReady = true;
    return _ttsAvailable;
  }

  bool get ttsAvailable => _ttsAvailable;

  /// 播放一张卡片；返回是否真的有声音出来。没有声音的卡片由界面给出提示。
  Future<bool> playCard(CardItem card) async {
    await stop();
    _playingCardId = card.id;

    if (card.hasAudioFile) {
      final file = File(card.audioPath!);
      if (await file.exists()) {
        await _player.play(DeviceFileSource(card.audioPath!));
        _player.onPlayerComplete.first.then((_) {
          if (_playingCardId == card.id) _playingCardId = null;
        });
        return true;
      }
    }

    // 录音丢了就退到朗读，不让幼儿遇到「点了没声音」。
    await ensureTts();
    if (!_ttsAvailable) return false;
    final text = card.word.trim().isEmpty ? card.note.trim() : card.word.trim();
    if (text.isEmpty) return false;
    await _tts.setSpeechRate(card.rate);
    await _tts.speak(text);
    return true;
  }

  Future<void> previewTts(String text, {double rate = 0.45}) async {
    await stop();
    await ensureTts();
    if (!_ttsAvailable) return;
    await _tts.setSpeechRate(rate);
    await _tts.speak(text);
  }

  Future<void> playFile(String path) async {
    await stop();
    await _player.play(DeviceFileSource(path));
  }

  Future<void> stop() async {
    _playingCardId = null;
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
