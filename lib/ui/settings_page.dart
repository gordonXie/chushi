import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../services/voice_player.dart';
import '../state/app_state.dart';
import 'card_manage_page.dart';
import 'migration_page.dart';
import 'widgets/section_card.dart';

/// 设置：卡片管理、数据与迁移、通用设置、关于。
/// 这一页是家长唯一的生产入口，幼儿要长按 2 秒并答对算式才进得来。
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: AnimatedBuilder(
        animation: appState,
        builder: (context, _) {
          final customs = appState.customCount;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              if (appState.needBreak)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.sunnySoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text('已经连续用了 15 分钟，建议让孩子歇一会儿，眼睛比多认两个词重要。',
                        style: TextStyle(fontSize: 13, color: AppColors.ink)),
                  ),
                ),
              SectionCard(
                title: '卡片管理',
                children: [
                  _Row(
                    icon: '🗂️',
                    title: '我的卡片',
                    subtitle: customs == 0 ? '还没有，先做一张吧' : '$customs 张自定义卡片',
                    onTap: () => _go(const CardManagePage()),
                  ),
                  _Row(
                    icon: '➕',
                    title: '做一张新卡',
                    subtitle: '选图、命名、配声，三步',
                    onTap: () => _go(const CardManagePage(openNew: true)),
                  ),
                ],
              ),
              SectionCard(
                title: '数据与迁移',
                children: [
                  _Row(
                    icon: '📦',
                    title: '作品库与导出',
                    subtitle: appState.lastBackupAt == null
                        ? '还没备份过，导出后可以通过微信发到另一台设备'
                        : '上次备份：${_format(appState.lastBackupAt!)}',
                    highlight: appState.backupStale,
                    onTap: () => _go(const MigrationPage()),
                  ),
                  if (appState.backupStale)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text('建议现在导出一份，换手机或重装时卡片才不会丢。',
                          style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                    ),
                ],
              ),
              SectionCard(
                title: '通用设置',
                children: [
                  SwitchListTile(
                    value: appState.textVisible,
                    onChanged: appState.setTextVisible,
                    title: const Text('卡片上显示文字', style: _rowTitle),
                    subtitle: const Text('关掉后只看图，避免孩子只认字不认物',
                        style: _rowSub),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('朗读语速', style: _rowTitle),
                        Row(
                          children: [
                            const Text('慢',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.inkSoft)),
                            Expanded(
                              child: Slider(
                                value: appState.defaultRate,
                                min: 0.3,
                                max: 0.7,
                                divisions: 8,
                                activeColor: AppColors.coral,
                                onChanged: appState.setDefaultRate,
                              ),
                            ),
                            const Text('快',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.inkSoft)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SwitchListTile(
                    value: appState.breakReminder,
                    onChanged: appState.setBreakReminder,
                    title: const Text('连续 15 分钟提示休息', style: _rowTitle),
                    subtitle: const Text('只在设置页提示，首页不打扰孩子', style: _rowSub),
                  ),
                  ListTile(
                    title: const Text('系统朗读', style: _rowTitle),
                    subtitle: Text(
                      VoicePlayer.instance.ttsAvailable
                          ? '可用，中文音色正常'
                          : '这台设备缺中文音色，建议家长自己录音',
                      style: _rowSub,
                    ),
                    trailing: Icon(
                      VoicePlayer.instance.ttsAvailable
                          ? Icons.check_circle_rounded
                          : Icons.info_outline_rounded,
                      color: VoicePlayer.instance.ttsAvailable
                          ? AppColors.mint
                          : AppColors.sunny,
                    ),
                  ),
                ],
              ),
              SectionCard(
                title: '关于',
                children: [
                  const ListTile(
                    title: Text('认认 0.1.0', style: _rowTitle),
                    subtitle: Text(
                        '不注册、不登录、不联网，照片与录音只留在这台设备上',
                        style: _rowSub),
                  ),
                  ListTile(
                    title: const Text('重新上锁', style: _rowTitle),
                    subtitle: const Text('让设置入口马上回到长按加算式',
                        style: _rowSub),
                    onTap: () async {
                      await appState.closeGate();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已重新上锁')),
                      );
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _go(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  String _format(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
    if (diff.inDays < 1) return '${diff.inHours} 小时前';
    return '${diff.inDays} 天前';
  }
}

const _rowTitle = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
const _rowSub = TextStyle(fontSize: 12.5, color: AppColors.inkSoft);

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.highlight = false,
  });

  final String icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Text(icon, style: const TextStyle(fontSize: 22)),
      title: Text(title, style: _rowTitle),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!,
              style: TextStyle(
                fontSize: 12.5,
                color: highlight ? AppColors.coral : AppColors.inkSoft,
              )),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.inkSoft),
    );
  }
}
