import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../data/builtin_cards.dart';
import '../data/models.dart';
import '../services/package_service.dart';
import '../services/photo_service.dart';
import '../services/recorder_service.dart';
import '../services/voice_player.dart';
import '../state/app_state.dart';
import 'widgets/section_card.dart';

/// 制作页：选图 → 命名 → 配声 → 试听 → 保存。
/// 没有声音也没有词名的不允许保存，从流程上杜绝「哑卡」。
class CardEditPage extends StatefulWidget {
  const CardEditPage({super.key, this.card, this.categoryId = 'family'});

  final CardItem? card;
  final String categoryId;

  @override
  State<CardEditPage> createState() => _CardEditPageState();
}

class _CardEditPageState extends State<CardEditPage> {
  late final TextEditingController _word;
  late final TextEditingController _note;
  late String _categoryId;
  late String _emoji;
  String? _imagePath;
  AudioType _audioType = AudioType.tts;
  String? _audioPath;
  bool _showText = true;
  double _rate = 0.45;

  bool _recording = false;
  int _seconds = 0;
  Timer? _tick;
  bool _saving = false;

  bool get _isNew => widget.card == null;

  @override
  void initState() {
    super.initState();
    final card = widget.card;
    _word = TextEditingController(text: card?.word ?? '');
    _note = TextEditingController(text: card?.note ?? '');
    _categoryId = card?.categoryId ?? widget.categoryId;
    _emoji = card?.emoji ?? '🙂';
    _imagePath = card?.imagePath;
    _audioType = card?.audioType ?? AudioType.tts;
    _audioPath = card?.audioPath;
    _showText = card?.showText ?? true;
    _rate = card?.rate ?? appState.defaultRate;
  }

  @override
  void dispose() {
    _word.dispose();
    _note.dispose();
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _pickImage({bool camera = false}) async {
    final path = await PhotoService.instance.pickAndStore(fromCamera: camera);
    if (path == null || !mounted) return;
    setState(() => _imagePath = path);
  }

  Future<void> _toggleRecord() async {
    if (_recording) {
      final result = await RecorderService.instance.stop();
      _tick?.cancel();
      setState(() {
        _recording = false;
        _seconds = 0;
      });
      if (result == null) {
        _toast('录音太短了，按住多念一会儿');
        return;
      }
      setState(() {
        _audioPath = result.$1;
        _audioType = AudioType.record;
      });
      return;
    }
    final path = await RecorderService.instance.start();
    if (path == null) {
      if (!mounted) return;
      setState(() => _audioType = AudioType.tts);
      _toast('没有麦克风权限，先改用系统朗读');
      return;
    }
    setState(() {
      _recording = true;
      _seconds = 0;
    });
    _tick = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _seconds++);
      if (_seconds >= 15) _toggleRecord();
    });
  }

  Future<void> _preview() async {
    if (_audioPath != null && _audioType == AudioType.record) {
      await VoicePlayer.instance.playFile(_audioPath!);
      return;
    }
    final word = _word.text.trim();
    if (word.isEmpty) {
      _toast('先写一个词，才有得读');
      return;
    }
    await VoicePlayer.instance.previewTts(word, rate: _rate);
  }

  Future<void> _save() async {
    final word = _word.text.trim();
    if (word.isEmpty && _audioPath == null) {
      _toast('写一个词，或者先录一段声音');
      return;
    }
    setState(() => _saving = true);
    final card = widget.card?.copyWith(
          word: word.isEmpty ? _word.text : word,
          note: _note.text.trim(),
          categoryId: _categoryId,
          imagePath: _imagePath,
          emoji: _emoji,
          audioType: _audioType,
          audioPath: _audioPath,
          rate: _rate,
          showText: _showText,
        ) ??
        CardItem(
          id: 'custom_${newId()}',
          word: word,
          note: _note.text.trim(),
          categoryId: _categoryId,
          imagePath: _imagePath,
          emoji: _emoji,
          audioType: _audioType,
          audioPath: _audioPath,
          rate: _rate,
          showText: _showText,
          sortIndex: 0,
        );
    if (mounted) Navigator.of(context).pop(card);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage =
        _imagePath != null && File(_imagePath!).existsSync();

    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? '做一张新卡' : '编辑卡片')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          SectionCard(
            title: '图片',
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () => _pickImage(),
                  child: AspectRatio(
                    aspectRatio: 1.4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: categoryTint(_categoryId),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.line, width: 1.4),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: hasImage
                          ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_emoji,
                                    style: const TextStyle(fontSize: 48)),
                                const SizedBox(height: 8),
                                const Text('点这里选一张照片',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.inkSoft)),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(),
                        icon: const Icon(Icons.photo_library_outlined, size: 18),
                        label: const Text('相册'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(camera: true),
                        icon: const Icon(Icons.photo_camera_outlined, size: 18),
                        label: const Text('拍照'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SectionCard(
            title: '词名',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _word,
                  maxLength: 12,
                  decoration: const InputDecoration(
                    hintText: '孩子听到的那个词，比如「苹果」「奶奶」',
                    border: InputBorder.none,
                    counterStyle:
                        TextStyle(fontSize: 11, color: AppColors.inkSoft),
                  ),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _note,
                  decoration: const InputDecoration(
                    hintText: '备注（可空），比如「奶奶家的狗」',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          SectionCard(
            title: '声音',
            children: [
              ListTile(
                title: Text(_recording ? '正在录音，$_seconds 秒' : '家长录音',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                subtitle: const Text('说出这个词，最长 15 秒',
                    style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
                trailing: FilledButton(
                  onPressed: _toggleRecord,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        _recording ? AppColors.ink : AppColors.coral,
                    minimumSize: const Size(88, 40),
                  ),
                  child: Text(_recording ? '停止' : '开始'),
                ),
              ),
              if (_audioPath != null)
                ListTile(
                  leading: const Icon(Icons.graphic_eq_rounded,
                      color: AppColors.mint),
                  title: const Text('已录好一段',
                      style: TextStyle(fontSize: 14)),
                  trailing: TextButton(
                    onPressed: () => setState(() {
                      _audioPath = null;
                      _audioType = AudioType.tts;
                    }),
                    child: const Text('删除'),
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.record_voice_over_rounded,
                    color: AppColors.sky),
                title: const Text('用系统朗读兜底',
                    style: TextStyle(fontSize: 14)),
                subtitle: const Text('没有录音或录音丢了，也能出声',
                    style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                trailing: Switch(
                  value: _audioPath == null || _audioType == AudioType.tts,
                  onChanged: (value) {
                    setState(() {
                      _audioType = value
                          ? AudioType.tts
                          : (_audioPath == null
                              ? AudioType.record
                              : AudioType.record);
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    const Text('语速', style: TextStyle(fontSize: 13)),
                    Expanded(
                      child: Slider(
                        value: _rate,
                        min: 0.3,
                        max: 0.7,
                        divisions: 8,
                        activeColor: AppColors.coral,
                        onChanged: (value) => setState(() => _rate = value),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _preview,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('试听'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SectionCard(
            title: '分类与显示',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CardCategory.all.map((category) {
                    final selected = category.id == _categoryId;
                    return ChoiceChip(
                      label: Text('${category.emoji} ${category.name}'),
                      selected: selected,
                      onSelected: (_) => setState(() => _categoryId = category.id),
                      selectedColor: AppColors.coralSoft,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.line),
                      labelStyle: TextStyle(
                        fontSize: 13,
                        color: selected ? AppColors.ink : AppColors.inkSoft,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    );
                  }).toList(),
                ),
              ),
              SwitchListTile(
                value: _showText,
                onChanged: (value) => setState(() => _showText = value),
                title: const Text('这张卡显示文字',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                subtitle: const Text('关掉后只看图，家长自己心里有数',
                    style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? '保存中' : '保存'),
            ),
          ),
        ],
      ),
    );
  }
}
