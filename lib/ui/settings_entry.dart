import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
import '../state/app_state.dart';
import 'gate_dialog.dart';
import 'settings_page.dart';

/// 设置入口：首页右上角 40 像素、贴边、无文字。
/// 单击、连点、滑动一律无反应；长按满 2 秒才出现算式。已通过验证的 10 分钟内只需长按 0.4 秒。
class SettingsEntry extends StatefulWidget {
  const SettingsEntry({super.key});

  @override
  State<SettingsEntry> createState() => _SettingsEntryState();
}

class _SettingsEntryState extends State<SettingsEntry> {
  Timer? _holdTimer;
  bool _holding = false;

  void _beginHold() {
    if (_holdTimer != null) return;
    setState(() => _holding = true);
    final duration = appState.gateOpen
        ? const Duration(milliseconds: 400)
        : const Duration(seconds: 2);
    _holdTimer = Timer(duration, () {
      _holdTimer = null;
      if (!mounted) return;
      setState(() => _holding = false);
      HapticFeedback.mediumImpact();
      _open();
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    if (_holding) setState(() => _holding = false);
  }

  Future<void> _open() async {
    if (appState.gateOpen) {
      _go();
      return;
    }
    final passed = await showGateDialog(context);
    if (!mounted || !passed) return;
    _go();
  }

  void _go() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _beginHold(),
      onPointerUp: (_) => _cancelHold(),
      onPointerCancel: (_) => _cancelHold(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _holding
              ? AppColors.coralSoft
              : Colors.white.withValues(alpha: 0.55),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
        ),
        child: Center(
          child: Icon(
            _holding ? Icons.hourglass_bottom_rounded : Icons.tune_rounded,
            size: 22,
            color: AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}
