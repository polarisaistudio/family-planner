import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../translation_service.dart';

/// Provider for the translation service
final translationServiceProvider = Provider<TranslationService>((ref) {
  final service = TranslationService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// State for translation operations
class TranslationState {
  final String? translatedText;
  final bool isLoading;
  final String? error;
  final bool modelDownloaded;

  const TranslationState({
    this.translatedText,
    this.isLoading = false,
    this.error,
    this.modelDownloaded = false,
  });

  TranslationState copyWith({
    String? translatedText,
    bool? isLoading,
    String? error,
    bool? modelDownloaded,
  }) {
    return TranslationState(
      translatedText: translatedText ?? this.translatedText,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      modelDownloaded: modelDownloaded ?? this.modelDownloaded,
    );
  }
}

/// Notifier for translation operations
class TranslationNotifier extends StateNotifier<TranslationState> {
  final TranslationService _translationService;

  TranslationNotifier(this._translationService) : super(const TranslationState());

  /// Translate text
  Future<String?> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    if (text.trim().isEmpty) return text;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check if model is downloaded
      final isDownloaded = await _translationService.isModelDownloaded(targetLanguage);

      if (!isDownloaded) {
        state = state.copyWith(
          isLoading: false,
          modelDownloaded: false,
          error: 'Model not downloaded. Please download the language model first.',
        );
        return null;
      }

      final translatedText = await _translationService.translate(
        text: text,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );

      state = state.copyWith(
        translatedText: translatedText,
        isLoading: false,
        modelDownloaded: true,
      );

      return translatedText;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Check if a language model is downloaded
  Future<bool> checkModelDownloaded(String languageCode) async {
    final isDownloaded = await _translationService.isModelDownloaded(languageCode);
    state = state.copyWith(modelDownloaded: isDownloaded);
    return isDownloaded;
  }

  /// Download a language model
  Future<void> downloadModel(String languageCode) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _translationService.downloadModel(languageCode);
      state = state.copyWith(
        isLoading: false,
        modelDownloaded: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to download model: $e',
      );
    }
  }

  /// Get list of downloaded models
  Future<Set<String>> getDownloadedModels() async {
    return await _translationService.getDownloadedModels();
  }

  /// Clear translation state
  void clear() {
    state = const TranslationState();
  }
}

/// Provider for translation operations
final translationProvider = StateNotifierProvider<TranslationNotifier, TranslationState>((ref) {
  final service = ref.watch(translationServiceProvider);
  return TranslationNotifier(service);
});
