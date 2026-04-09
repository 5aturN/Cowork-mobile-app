import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Фильтры для экрана бронирования
class FilterChips extends StatelessWidget {
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;

  const FilterChips({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == selectedFilter;

          return GestureDetector(
            onTap: () => onFilterSelected(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? Colors.white : AppColors.grey900)
                    : (isDark ? AppColors.grey800 : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? null
                    : Border.all(
                        color: isDark ? Colors.transparent : AppColors.grey200,
                      ),
              ),
              child: Text(
                filter,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? (isDark ? AppColors.backgroundDark : Colors.white)
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
