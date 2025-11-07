import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/providers/translation_provider.dart';
import '../../core/providers/locale_provider.dart';

/// Widget that automatically translates text based on current locale
/// Auto-detects source language and translates to current locale
class TranslatedText extends ConsumerStatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool enabled; // Whether translation is enabled

  const TranslatedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.enabled = true,
  });

  @override
  ConsumerState<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends ConsumerState<TranslatedText> {
  String? _translatedText;
  bool _isTranslating = false;
  String? _lastLocale;
  String? _lastSourceText;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!widget.enabled) {
      _translatedText = widget.text;
      return;
    }

    final currentLocale = ref.watch(localeProvider).languageCode;

    print('🔵 [TranslatedText] Current locale: $currentLocale, Last locale: $_lastLocale');
    print('🔵 [TranslatedText] Text: "${widget.text}", Last text: "$_lastSourceText"');

    // Translate if locale changed or text changed
    if (_lastLocale != currentLocale || _lastSourceText != widget.text) {
      print('🔵 [TranslatedText] Triggering translation');
      _lastLocale = currentLocale;
      _lastSourceText = widget.text;
      _translateIfNeeded();
    }
  }

  Future<void> _translateIfNeeded() async {
    if (!widget.enabled || widget.text.trim().isEmpty) {
      setState(() => _translatedText = widget.text);
      return;
    }

    final targetLang = _lastLocale ?? 'en';

    // Detect source language
    final sourceLang = _detectLanguage(widget.text);

    print('🔵 [TranslatedText] Source lang: $sourceLang, Target lang: $targetLang');

    // If source language matches target, no translation needed
    if (sourceLang == targetLang) {
      print('🔵 [TranslatedText] Same language, no translation needed');
      setState(() => _translatedText = widget.text);
      return;
    }

    // Perform translation
    setState(() => _isTranslating = true);

    try {
      print('🔵 [TranslatedText] Translating: "${widget.text}"');
      final translationService = ref.read(translationServiceProvider);
      final translated = await translationService.translate(
        text: widget.text,
        sourceLanguage: sourceLang,
        targetLanguage: targetLang,
      );

      print('🟢 [TranslatedText] Translated result: "$translated"');

      if (mounted) {
        setState(() {
          _translatedText = translated;
          _isTranslating = false;
        });
      }
    } catch (e) {
      print('❌ [TranslatedText] Translation error: $e');
      if (mounted) {
        setState(() {
          _translatedText = widget.text; // Fallback to original
          _isTranslating = false;
        });
      }
    }
  }

  /// Simple language detection based on character set
  String _detectLanguage(String text) {
    // Check if text contains Chinese characters
    final chineseRegex = RegExp(r'[\u4e00-\u9fa5]');
    if (chineseRegex.hasMatch(text)) {
      return 'zh';
    }

    // Default to English
    return 'en';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _translatedText ?? widget.text,
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}
