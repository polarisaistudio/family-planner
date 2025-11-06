import 'package:flutter/material.dart';
import 'package:family_planner/features/todos/domain/entities/category_entity.dart';

class CategoryPickerWidget extends StatelessWidget {
  final String? selectedCategoryId;
  final Function(String?) onCategorySelected;

  const CategoryPickerWidget({
    Key? key,
    this.selectedCategoryId,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categories = PredefinedCategories.categories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // None option
            _CategoryChip(
              category: null,
              isSelected: selectedCategoryId == null,
              onTap: () => onCategorySelected(null),
            ),
            // Category options
            ...categories.map((category) => _CategoryChip(
                  category: category,
                  isSelected: selectedCategoryId == category.id,
                  onTap: () => onCategorySelected(category.id),
                )),
          ],
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final CategoryEntity? category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Get language code from current locale
    final languageCode = Localizations.localeOf(context).languageCode;

    final label = category?.getLocalizedName(languageCode) ?? 'None';
    final iconCodePoint = category?.iconCodePoint;
    final colorValue = category?.colorValue;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (colorValue != null
                  ? Color(colorValue).withValues(alpha: 0.15)
                  : colorScheme.primaryContainer)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? (colorValue != null ? Color(colorValue) : colorScheme.primary)
                : colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconCodePoint != null) ...[
              Icon(
                IconData(iconCodePoint, fontFamily: 'MaterialIcons'),
                size: 18,
                color: isSelected
                    ? (colorValue != null ? Color(colorValue) : colorScheme.primary)
                    : colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? (colorValue != null ? Color(colorValue) : colorScheme.primary)
                    : colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
