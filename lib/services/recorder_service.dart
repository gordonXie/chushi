import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:record/record.dart';

import '../data/repository.dart';

/// 家长录音：16kHz 单声道 AAC，单条最长 15 秒，到点自动停。
/// 拒绝麦克风时不报错，由上层降级为系统朗读。
class RecorderService {
  RecorderService._();
  static final RecorderService instance = RecorderService._();

  final AudioRecorder _recorder = AudioRecorder();
  Timer? _limitTimer;
  String? _currentPath;
  DateTime? _startedAt;

  bool get isRecording => _currentPath != null;

  Future<bool> hasPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (_) {
      return false;
    }
  }

  /// 开始录音并返回路径；权限不足时返回 null。
  Future<String?> start() async {
    if (!await hasPermission()) return null;
    final dir = await CardRepository.instance.mediaDir('audio');
    final name = 'rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final path = p.join(dir.path, name);
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 64000,
      ),
      path: path,
    );
    _currentPath = path;
    _startedAt = DateTime.now();
    _limitTimer = Timer(const Duration(seconds: 15), () {
      stop();
    });
    return path;
  }

  /// 停止并返回文件路径与时长；过短（<0.6 秒）视为误触，返回 null。
  Future<(String path, Duration duration)?> stop() async {
    _limitTimer?.cancel();
    _limitTimer = null;
    final path = _currentPath;
    final started = _startedAt;
    _currentPath = null;
    _startedAt = null;
    if (path == null) return null;
    try {
      await _recorder.stop();
    } catch (_) {}
    final duration =
        started == null ? Duration.zero : DateTime.now().difference(started);
    if (duration < const Duration(milliseconds: 600)) {
      return null;
    }
    return (path, duration);
  }

  Future<void> cancel() async {
    _limitTimer?.cancel();
    _limitTimer = null;
    _currentPath = null;
    _startedAt = null;
    try {
      await _recorder.cancel();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
