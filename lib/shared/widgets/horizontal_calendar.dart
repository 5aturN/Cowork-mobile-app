import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

import 'package:intl/intl.dart';

/// Горизонтальный календарь для выбора даты
class HorizontalCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime month; // Used as initial focus
  final VoidCallback? onPreviousMonth; // Optional now, as we scroll
  final VoidCallback? onNextMonth;

  const HorizontalCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.month,
    this.onPreviousMonth,
    this.onNextMonth,
  });

  @override
  State<HorizontalCalendar> createState() => _HorizontalCalendarState();
}

class _HorizontalCalendarState extends State<HorizontalCalendar> {
  late PageController _pageController;
  late DateTime _currentWeekStart;

  @override
  void initState() {
    super.initState();
    // Initialize centered on the provided month/date (or today)
    // We arbitrarily define "Page 1000" as the current week to allow scrolling back/forth
    _pageController = PageController(initialPage: 1000);
    _currentWeekStart = _getStartOfWeek(widget.month);
  }

  @override
  void didUpdateWidget(HorizontalCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the parent explicitly changes the "month", jump to that week
    if (!isSameWeek(oldWidget.month, widget.month)) {
      _currentWeekStart = _getStartOfWeek(widget.month);
      // Reset logic could be complex with infinite scroll,
      // for simplicity we just update the base reference or jump to 1000
      // But to preserve smooth scroll, better to just let the user scroll or
      // only jump if significantly different.
      // Here we prioritize user's manual scroll, unless drastic change.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Month Navigation (Keep or remove? User wants scroll.
        // Let's keep it as a "Jump to month" header but rely on swipe for weeks)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                _getMonthName(_currentWeekStart), // Show month of visible week
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        // Weeks PageView
        SizedBox(
          height: 50, // Ultra Compact height (was 60)
          child: PageView.builder(
            controller: _pageController,
            // ...
            itemBuilder: (context, index) {
              final weekOffset = index - 1000;
              final weekStart =
                  _currentWeekStart.add(Duration(days: weekOffset * 7));
              final days =
                  List.generate(7, (i) => weekStart.add(Duration(days: i)));

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: days
                      .map((date) => _buildDayItem(date, theme, isDark))
                      .toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayItem(DateTime date, ThemeData theme, bool isDark) {
    final isSelected = _isSameDay(date, widget.selectedDate);
    final isToday = _isSameDay(date, DateTime.now());
    final isPast = date.isBefore(DateTime.now()) && !isToday;

    return Expanded(
      child: GestureDetector(
        onTap: isPast ? null : () => widget.onDateSelected(date),
        child: AnimatedScale(
          scale: isSelected ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1), // Tighter margin
            height: 44, // Extra Ultra Compact (was 52)
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : isDark
                      ? AppColors.grey800
                      : Colors.white,
              borderRadius: BorderRadius.circular(10), // Slightly less rounded
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : isDark
                        ? Colors.transparent
                        : AppColors.grey200,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatDayName(date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface.withValues(
                            alpha: isPast ? 0.3 : 0.5,
                          ),
                  ),
                ),
                const SizedBox(height: 0), // Tightest
                Text(
                  '${date.day}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12, // Smaller font (was 13)
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface.withValues(
                            alpha: isPast ? 0.3 : 1.0,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  bool isSameWeek(DateTime a, DateTime b) {
    final aStart = _getStartOfWeek(a);
    final bStart = _getStartOfWeek(b);
    return _isSameDay(aStart, bStart);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDayName(DateTime date) {
    return toBeginningOfSentenceCase(DateFormat.E('ru').format(date)) ?? '';
  }

  String _getMonthName(DateTime date) {
    return toBeginningOfSentenceCase(DateFormat('LLLL y', 'ru').format(date)) ??
        '';
  }
}
