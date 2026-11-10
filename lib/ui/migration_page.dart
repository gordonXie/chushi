import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../services/package_service.dart';
import '../state/app_state.dart';
import 'widgets/section_card.dart';

/// 数据与迁移：第一期没有账号，作品靠 .renren 文件在设备之间走。
/// 这里不承诺自动同步，只承诺「能带走、能收回」。
class MigrationPage extends StatefulWidget {
  const MigrationPage({super.key});

  @override
  State<MigrationPage> createState() => _MigrationPageState();
}

class _MigrationPageState extends State<MigrationPage> {
  bool _busy = false;

  Future<void> _export() async {
    if (appState.customCount == 0) {
      _toast('还没有自定义卡片，先做一张再来导出');
      return;
    }
    setState(() => _busy = true);
    final result = await PackageService.instance.export();
    if (result == null) {
      setState(() => _busy = false);
      _toast('导出失败，请重试一次');
      return;
    }
    await appState.markBackupNow();
    final shared = await PackageService.instance.sharePackage(result.$1);
    setState(() => _busy = false);
    _toast(shared
        ? '作品包已生成，选微信发给另一台设备即可'
        : '作品包存在：${result.$1.path}');
  }

  Future<void> _import() async {
    setState(() => _busy = true);
    final count = await PackageService.instance.importFromPicker();
    if (!mounted) return;
    setState(() => _busy = false);
    if (count > 0) {
      await appState.refreshCards();
      _toast('导入了 $count 张卡片');
    } else if (count == 0) {
      _toast('没有选文件');
    } else {
      _toast('这个文件读不出来，可能不是「认认」的作品包');
    }
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius)),
        title: const Text('清空自定义卡片？'),
        content: const Text(
          '内置的 40 张会保留，你自己做的卡片、照片和录音都会被删掉。'
          '这一步无法撤销，建议先导出一次。',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('先留着'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await appState.clearCustom();
    _toast('已清空，内置卡片还在');
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String get _lastBackup {
    final at = appState.lastBackupAt;
    if (at == null) return '还没备份过';
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return '刚刚备份';
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前备份';
    if (diff.inDays < 1) return '${diff.inHours} 小时前备份';
    return '${diff.inDays} 天前备份';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据与迁移')),
      body: AnimatedBuilder(
        animation: appState,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('当前：$_lastBackup',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text(
                      '作品包是一个 .renren 文件，里面装着卡片清单、照片和录音。'
                      '通过微信或隔空投送发到另一台设备，对方点一下就能导入。'
                      '两份设备之间不会自动同步，改完记得再导出一次。',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.inkSoft,
                          height: 1.7),
                    ),
                  ],
                ),
              ),
              SectionCard(
                title: '把作品带走',
                children: [
                  ListTile(
                    enabled: !_busy,
                    onTap: _export,
                    leading: const Text('📤', style: TextStyle(fontSize: 22)),
                    title: const Text('导出并发送',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${appState.customCount} 张自定义卡片，图片与录音一并打包',
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.inkSoft),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.inkSoft),
                  ),
                  ListTile(
                    enabled: !_busy,
                    onTap: _import,
                    leading: const Text('📥', style: TextStyle(fontSize: 22)),
                    title: const Text('从文件导入',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    subtitle: const Text('选择另一台设备发来的 .renren 文件',
                        style: TextStyle(
                            fontSize: 12.5, color: AppColors.inkSoft)),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.inkSoft),
                  ),
                ],
              ),
              SectionCard(
                title: '清空数据',
                children: [
                  ListTile(
                    onTap: _clear,
                    leading: const Text('🧹', style: TextStyle(fontSize: 22)),
                    title: const Text('清除自定义卡片与媒体',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    subtitle: const Text('内置 40 张不受影响',
                        style: TextStyle(
                            fontSize: 12.5, color: AppColors.inkSoft)),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.inkSoft),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: const Text(
                  '导入遇到同名卡片时会保留两份并标注「副本」，不会覆盖原来的卡片。',
                  style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
