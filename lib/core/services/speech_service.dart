import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechServiceException implements Exception {
  final String message;

  const SpeechServiceException(this.message);

  @override
  String toString() => message;
}

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  bool _available = false;

  bool get isListening => _speech.isListening;

  Future<bool> initialize() async {
    if (_initialized) return _available;

    try {
      _available = await _speech.initialize();
    } catch (_) {
      _available = false;
    }

    _initialized = true;
    return _available;
  }

  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    String localeId = 'es_CO',
  }) async {
    if (isListening) {
      await stopListening();
    }

    if (!await initialize()) {
      throw const SpeechServiceException(
        'El reconocimiento de voz no está disponible',
      );
    }

    Future<void> listenWithLocale(String value) {
      return _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          onResult(result.recognizedWords, result.finalResult);
        },
        localeId: value,
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 4),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
        ),
      );
    }

    try {
      await listenWithLocale(localeId);
    } catch (_) {
      try {
        if (localeId == 'es_ES') rethrow;
        await listenWithLocale('es_ES');
      } catch (_) {
        throw const SpeechServiceException(
          'No se pudo iniciar la transcripción',
        );
      }
    }
  }

  Future<void> stopListening() async {
    try {
      if (isListening) {
        await _speech.stop();
      }
    } catch (_) {}
  }

  Future<void> cancelListening() async {
    try {
      await _speech.cancel();
    } catch (_) {}
  }
}
