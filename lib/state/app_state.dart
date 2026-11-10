import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../services/voice_player.dart';

/// 全应用状态：卡片清单、家长设置、设置入口的门禁。
/// 第一期没有账号，所有状态只活在本机。
class AppState extends ChangeNotifier {
  static const _kTextVisible = 'text_visible';
  static const _kRate = 'default_rate';
  static const _kBreakReminder = 'break_reminder';
  static const _kGateExpireAt = 'gate_expire_at';
  static const _kLastBackupAt = 'last_backup_at';

  final List<CardItem> cards = [];
  bool loading = true;

  bool textVisible = true;
  double defaultRate = 0.45;
  bool breakReminder = true;
  DateTime? gateExpireAt;
  DateTime? lastBackupAt;

  DateTime sessionStart = DateTime.now();

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    textVisible = _prefs!.getBool(_kTextVisible) ?? true;
    defaultRate = _prefs!.getDouble(_kRate) ?? 0.45;
    breakReminder = _prefs!.getBool(_kBreakReminder) ?? true;
    final gate = _prefs!.getInt(_kGateExpireAt);
    gateExpireAt =
        gate == null ? null : DateTime.fromMillisecondsSinceEpoch(gate);
    final backup = _prefs!.getInt(_kLastBackupAt);
    lastBackupAt =
        backup == null ? null : DateTime.fromMillisecondsSinceEpoch(backup);

    await CardRepository.instance.init();
    await refreshCards();
    loading = false;
    notifyListeners();
  }

  Future<void> refreshCards() async {
    final rows = await CardRepository.instance.all();
    cards
      ..clear()
      ..addAll(rows);
    notifyListeners();
  }

  List<CardItem> cardsOf(String categoryId) =>
      cards.where((c) => c.categoryId == categoryId).toList();

  int get customCount => cards.where((c) => !c.isBuiltin).length;

  /// 设置入口：通过一道两位数加法后 10 分钟内免重复验证。
  bool get gateOpen {
    final expire = gateExpireAt;
    return expire != null && DateTime.now().isBefore(expire);
  }

  Future<void> openGate() async {
    gateExpireAt = DateTime.now().add(const Duration(minutes: 10));
    await _prefs?.setInt(
        _kGateExpireAt, gateExpireAt!.millisecondsSinceEpoch);
    notifyListeners();
  }

  Future<void> closeGate() async {
    gateExpireAt = null;
    await _prefs?.remove(_kGateExpireAt);
    notifyListeners();
  }

  Future<void> setTextVisible(bool value) async {
    textVisible = value;
    await _prefs?.setBool(_kTextVisible, value);
    notifyListeners();
  }

  Future<void> setDefaultRate(double value) async {
    defaultRate = value;
    await _prefs?.setDouble(_kRate, value);
    notifyListeners();
  }

  Future<void> setBreakReminder(bool value) async {
    breakReminder = value;
    await _prefs?.setBool(_kBreakReminder, value);
    notifyListeners();
  }

  Future<void> markBackupNow() async {
    lastBackupAt = DateTime.now();
    await _prefs?.setInt(
        _kLastBackupAt, lastBackupAt!.millisecondsSinceEpoch);
    notifyListeners();
  }

  /// 上次备份超过 30 天或从未备份时提示。
  bool get backupStale {
    final at = lastBackupAt;
    if (at == null) return customCount > 0;
    return DateTime.now().difference(at).inDays > 30;
  }

  bool get needBreak =>
      breakReminder &&
      DateTime.now().difference(sessionStart) > const Duration(minutes: 15);

  Future<void> upsertCard(CardItem card) async {
    await CardRepository.instance.save(card);
    await refreshCards();
  }

  Future<void> removeCard(CardItem card) async {
    await CardRepository.instance.delete(card.id);
    _deleteQuietly(card.imagePath);
    _deleteQuietly(card.audioPath);
    await refreshCards();
  }

  Future<void> clearCustom() async {
    final customs = cards.where((c) => !c.isBuiltin).toList();
    await CardRepository.instance.clearCustom();
    for (final card in customs) {
      _deleteQuietly(card.imagePath);
      _deleteQuietly(card.audioPath);
    }
    await refreshCards();
  }

  Future<void> reorder(List<CardItem> ordered) async {
    await CardRepository.instance.reorder(ordered);
    await refreshCards();
  }

  Future<void> speakCheck() => VoicePlayer.instance.ensureTts();

  void _deleteQuietly(String? path) {
    if (path == null) return;
    final file = File(path);
    file.exists().then((exists) {
      if (exists) file.delete().ignore();
    }).ignore();
  }
}

/// 全局单例，界面直接取用，避免层层传参。
final AppState appState = AppState();
