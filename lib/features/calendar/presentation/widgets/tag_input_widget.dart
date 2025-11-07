import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/translated_text.dart';

class TagInputWidget extends StatefulWidget {
  final List<String> tags;
  final Function(List<String>) onTagsChanged;

  const TagInputWidget({
    Key? key,
    required this.tags,
    required this.onTagsChanged,
  }) : super(key: key);

  @override
  State<TagInputWidget> createState() => _TagInputWidgetState();
}

class _TagInputWidgetState extends State<TagInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isEmpty) return;
    if (widget.tags.contains(trimmedTag)) return;

    final updatedTags = [...widget.tags, trimmedTag];
    widget.onTagsChanged(updatedTags);
    _controller.clear();
  }

  void _removeTag(String tag) {
    final updatedTags = widget.tags.where((t) => t != tag).toList();
    widget.onTagsChanged(updatedTags);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.tags,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),

        // Tag input field
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.addTags,
            prefixIcon: const Icon(Icons.label_outline, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onSubmitted: (value) {
            _addTag(value);
            _focusNode.requestFocus();
          },
          textInputAction: TextInputAction.done,
        ),

        const SizedBox(height: 12),

        // Display current tags
        if (widget.tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.tags.map((tag) {
              return Chip(
                label: TranslatedText(
                  tag,
                  style: TextStyle(
                    color: colorScheme.onSecondaryContainer,
                    fontSize: 13,
                  ),
                ),
                deleteIcon: Icon(
                  Icons.close,
                  size: 16,
                  color: colorScheme.onSecondaryContainer,
                ),
                onDeleted: () => _removeTag(tag),
                backgroundColor: colorScheme.secondaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),

        // Common tag suggestions
        if (widget.tags.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.suggestions,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _getCommonTags(context).map((tag) {
              return InkWell(
                onTap: () => _addTag(tag),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TranslatedText(
                    tag,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // Common tag suggestions - get from localization
  List<String> _getCommonTags(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.tagUrgent,
      l10n.tagImportant,
      l10n.tagToday,
      l10n.tagWeekly,
      l10n.tagMonthly,
      l10n.tagRecurring,
      l10n.tagFollowUp,
      l10n.tagWaiting,
    ];
  }
}
