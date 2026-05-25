import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cross_file/cross_file.dart';

class ReportAudioPlayer extends StatefulWidget {
  const ReportAudioPlayer({super.key, required this.audioPath});

  final String audioPath;

  @override
  State<ReportAudioPlayer> createState() => _ReportAudioPlayerState();
}

class _ReportAudioPlayerState extends State<ReportAudioPlayer> {
  final AudioPlayer _player = AudioPlayer();

  bool _isReady = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAudio();
  }

  Future<void> _loadAudio() async {
    try {
      final path = widget.audioPath.trim();

      if (path.isEmpty) {
        setState(() {
          _errorMessage = 'No hay audio disponible';
        });
        return;
      }

      if (path.startsWith('http://') || path.startsWith('https://')) {
        await _player.setUrl(path);
      } else if (kIsWeb) {
        setState(() {
          _errorMessage = 'No se pudo cargar el audio';
        });
        return;
      } else {
        try {
          final length = await XFile(path).length();
          if (length <= 0) {
            throw Exception('Archivo vacío');
          }
        } catch (_) {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'No se pudo cargar el audio';
          });
          return;
        }
        await _player.setFilePath(path);
      }

      if (!mounted) return;

      setState(() {
        _isReady = true;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'No se pudo cargar el audio';
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_errorMessage != null) {
      return Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_errorMessage!, style: theme.textTheme.bodyMedium),
          ),
        ],
      );
    }

    if (!_isReady) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Cargando audio...'),
          ],
        ),
      );
    }

    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, playerSnapshot) {
        final isPlaying = playerSnapshot.data?.playing ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    if (isPlaying) {
                      await _player.pause();
                    } else {
                      await _player.play();
                    }
                  },
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                  label: Text(isPlaying ? 'Pausar audio' : 'Reproducir audio'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await _player.pause();
                    await _player.seek(Duration.zero);
                  },
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Detener'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<Duration?>(
              stream: _player.durationStream,
              builder: (context, durationSnapshot) {
                final total = durationSnapshot.data ?? Duration.zero;

                return StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  builder: (context, positionSnapshot) {
                    var position = positionSnapshot.data ?? Duration.zero;

                    if (position > total && total != Duration.zero) {
                      position = total;
                    }

                    final maxValue = total.inMilliseconds <= 0
                        ? 1.0
                        : total.inMilliseconds.toDouble();
                    final currentValue = position.inMilliseconds
                        .clamp(0, maxValue.toInt())
                        .toDouble();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Slider(
                          value: currentValue,
                          max: maxValue,
                          onChanged: (value) async {
                            await _player.seek(
                              Duration(milliseconds: value.toInt()),
                            );
                          },
                        ),
                        Text(
                          '${_formatDuration(position)} / ${_formatDuration(total)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}
