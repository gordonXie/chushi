import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
import '../state/app_state.dart';

/// 设置入口的门禁：一道两位数加法。
/// 大人 3 秒能算完，1—3 岁孩子几乎不可能过；答错直接关掉，不提示答案。
Future<bool> showGateDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => const _GateDialog(),
  );
  return result ?? false;
}

class _GateDialog extends StatefulWidget {
  const _GateDialog();

  @override
  State<_GateDialog> createState() => _GateDialogState();
}

class _GateDialogState extends State<_GateDialog> {
  late final int _a;
  late final int _b;
  final TextEditingController _controller = TextEditingController();
  String? _error;
  bool _checking = false;

  int get _answer => _a + _b;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _a = 10 + random.nextInt(80);
    _b = 10 + random.nextInt(80);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = int.tryParse(_controller.text.trim());
    if (value == null) {
      setState(() => _error = '请填一个数字');
      return;
    }
    if (value != _answer) {
      setState(() => _error = '答案不对，请再试一次');
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() => _checking = true);
    await appState.openGate();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cream,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('这里是给大人的', style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            )),
            const SizedBox(height: 6),
            const Text('答对这道题就能进设置，10 分钟内不用再答',
                style: TextStyle(fontSize: 13, color: AppColors.inkSoft)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.line, width: 1.4),
              ),
              child: Row(
                children: [
                  Text('$_a + $_b = ',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink)),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: '答案',
                        hintStyle: TextStyle(color: AppColors.inkSoft),
                      ),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: const TextStyle(color: Color(0xFFE05A4B), fontSize: 13)),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _checking
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _checking ? null : _submit,
                    child: Text(_checking ? '验证中' : '进入'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
