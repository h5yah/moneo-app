import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-speech for lesson slides 
class LessonTtsService {
  LessonTtsService._();

  static final LessonTtsService instance = LessonTtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool isSpeaking = false;
  String? lastInitError;

  bool get isReady => _initialized;

  Future<bool> ensureReady() async {
    if (_initialized) return true;
    return _initialize();
  }

  Future<bool> _initialize() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          ],
        );
      }

      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);
      await _tts.awaitSpeakCompletion(true);

      await _pickAndSetLanguage();

      _initialized = true;
      lastInitError = null;
      return true;
    } catch (e) {
      _initialized = false;
      lastInitError = e.toString();
      return false;
    }
  }

  Future<void> _pickAndSetLanguage() async {
    const preferred = ['en-US', 'en-GB', 'en-AU', 'en-IN', 'en'];
    try {
      final raw = await _tts.getLanguages;
      if (raw is! List || raw.isEmpty) {
        await _tts.setLanguage('en-US');
        return;
      }
      final languages = raw.map((e) => e.toString()).toList();
      for (final code in preferred) {
        final match = languages.firstWhere(
          (l) => l == code || l.startsWith('$code-'),
          orElse: () => '',
        );
        if (match.isNotEmpty) {
          await _tts.setLanguage(match);
          return;
        }
      }
      final anyEn = languages.where((l) => l.toLowerCase().startsWith('en')).toList();
      if (anyEn.isNotEmpty) {
        await _tts.setLanguage(anyEn.first);
        return;
      }
      await _tts.setLanguage(languages.first);
    } catch (_) {
      await _tts.setLanguage('en-US');
    }
  }

  void bindHandlers({
    required VoidCallback onStart,
    required VoidCallback onStop,
    void Function(String message)? onError,
  }) {
    _tts.setStartHandler(() {
      isSpeaking = true;
      onStart();
    });
    _tts.setCompletionHandler(() {
      isSpeaking = false;
      onStop();
    });
    _tts.setCancelHandler(() {
      isSpeaking = false;
      onStop();
    });
    _tts.setErrorHandler((message) {
      isSpeaking = false;
      onStop();
      onError?.call(message);
    });
  }

  Future<String?> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'Nothing to read on this slide.';

    if (!await ensureReady()) {
      return lastInitError ?? 'Text-to-speech could not start.';
    }

    try {
      await _tts.stop();
      final result = await _tts.speak(trimmed);
      if (defaultTargetPlatform == TargetPlatform.android && result != 1) {
        return 'Speech engine did not start (code $result).';
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> stop() async {
    if (!_initialized) return;
    try {
      await _tts.stop();
    } catch (_) {}
    isSpeaking = false;
  }

  Future<void> dispose() async {
    await stop();
    _initialized = false;
  }
}
