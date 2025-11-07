import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// Service for on-device translation using Google ML Kit
class TranslationService {
  final Map<String, OnDeviceTranslator> _translators = {};
  final Map<String, bool> _modelDownloaded = {};

  /// Translate text from one language to another
  ///
  /// [text] - The text to translate
  /// [sourceLanguage] - Source language code (e.g., 'en', 'zh')
  /// [targetLanguage] - Target language code (e.g., 'en', 'zh')
  ///
  /// Returns the translated text or throws an exception if translation fails
  Future<String> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    if (text.trim().isEmpty) return text;

    final translatorKey = '${sourceLanguage}_$targetLanguage';

    try {
      // Get or create translator
      final translator = _getTranslator(sourceLanguage, targetLanguage);

      // Check if model is downloaded
      final modelManager = OnDeviceTranslatorModelManager();
      final isDownloaded = await modelManager.isModelDownloaded(targetLanguage);

      _modelDownloaded[translatorKey] = isDownloaded;

      if (!isDownloaded) {
        print('⚠️ [TRANSLATION] Model for $targetLanguage not downloaded, downloading...');
        await downloadModel(targetLanguage);
      }

      // Translate
      final translatedText = await translator.translateText(text);
      return translatedText;
    } catch (e) {
      print('❌ [TRANSLATION] Error translating text: $e');
      return text; // Return original on error
    }
  }

  /// Translate multiple texts at once (more efficient)
  Future<List<String>> translateBatch({
    required List<String> texts,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final results = <String>[];

    for (final text in texts) {
      if (text.trim().isEmpty) {
        results.add(text);
      } else {
        try {
          final translated = await translate(
            text: text,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
          );
          results.add(translated);
        } catch (e) {
          results.add(text); // Keep original on error
        }
      }
    }

    return results;
  }

  /// Check if a language model is downloaded
  Future<bool> isModelDownloaded(String languageCode) async {
    final modelManager = OnDeviceTranslatorModelManager();
    return await modelManager.isModelDownloaded(languageCode);
  }

  /// Download a language model
  Future<void> downloadModel(String languageCode) async {
    print('📥 [TRANSLATION] Downloading $languageCode model...');
    final modelManager = OnDeviceTranslatorModelManager();
    await modelManager.downloadModel(languageCode);
    print('✅ [TRANSLATION] $languageCode model downloaded');
  }

  /// Ensure both English and Chinese models are downloaded
  Future<void> ensureBidirectionalModels() async {
    final modelManager = OnDeviceTranslatorModelManager();

    // Check and download English model
    final enDownloaded = await modelManager.isModelDownloaded('en');
    if (!enDownloaded) {
      print('📥 [TRANSLATION] Downloading English model...');
      await modelManager.downloadModel('en');
      print('✅ [TRANSLATION] English model downloaded');
    }

    // Check and download Chinese model
    final zhDownloaded = await modelManager.isModelDownloaded('zh');
    if (!zhDownloaded) {
      print('📥 [TRANSLATION] Downloading Chinese model...');
      await modelManager.downloadModel('zh');
      print('✅ [TRANSLATION] Chinese model downloaded');
    }
  }

  /// Delete a language model to free up space
  Future<void> deleteModel(String languageCode) async {
    final modelManager = OnDeviceTranslatorModelManager();
    await modelManager.deleteModel(languageCode);
  }

  /// Get list of available downloaded models
  Future<Set<String>> getDownloadedModels() async {
    final modelManager = OnDeviceTranslatorModelManager();
    // Note: getAvailableModels() is not available in this version
    // Returning empty set for now
    return {};
  }

  /// Get or create a translator for a language pair
  OnDeviceTranslator _getTranslator(String sourceLanguage, String targetLanguage) {
    final key = '${sourceLanguage}_$targetLanguage';

    if (!_translators.containsKey(key)) {
      _translators[key] = OnDeviceTranslator(
        sourceLanguage: _getLanguageCode(sourceLanguage),
        targetLanguage: _getLanguageCode(targetLanguage),
      );
    }

    return _translators[key]!;
  }

  /// Convert language code to TranslateLanguage
  TranslateLanguage _getLanguageCode(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'en':
        return TranslateLanguage.english;
      case 'zh':
        return TranslateLanguage.chinese;
      case 'es':
        return TranslateLanguage.spanish;
      case 'fr':
        return TranslateLanguage.french;
      case 'de':
        return TranslateLanguage.german;
      case 'ja':
        return TranslateLanguage.japanese;
      case 'ko':
        return TranslateLanguage.korean;
      case 'pt':
        return TranslateLanguage.portuguese;
      case 'ru':
        return TranslateLanguage.russian;
      case 'ar':
        return TranslateLanguage.arabic;
      case 'hi':
        return TranslateLanguage.hindi;
      case 'it':
        return TranslateLanguage.italian;
      default:
        throw Exception('Unsupported language code: $languageCode');
    }
  }

  /// Clean up all translators
  Future<void> dispose() async {
    for (final translator in _translators.values) {
      await translator.close();
    }
    _translators.clear();
    _modelDownloaded.clear();
  }
}
