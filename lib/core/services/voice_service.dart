import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> hasPermission() async {
    return _recorder.hasPermission();
  }

  Future<void> startRecording() async {
    final allowed = await hasPermission();
    if (!allowed) {
      throw Exception('No se concedió permiso de micrófono');
    }

    final path = await _buildAudioPath();

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );
  }

  Future<String?> stopRecording() async {
    return _recorder.stop();
  }

  Future<void> cancelRecording() async {
    await _recorder.cancel();
  }

  Future<bool> isRecording() async {
    return _recorder.isRecording();
  }

  Future<String> _buildAudioPath() async {
    final fileName =
        'report_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

    if (kIsWeb) {
      return fileName;
    }

    final dir = await getTemporaryDirectory();
    return '${dir.path}/$fileName';
  }

  void dispose() {
    _recorder.dispose();
  }
}
