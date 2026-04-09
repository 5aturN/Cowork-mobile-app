import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../../shared/widgets/segmented_control.dart';
import '../../../../shared/widgets/horizontal_calendar.dart';
import '../widgets/room_card.dart';
import '../providers/room_provider.dart';

/// Главный экран бронирования (стиль веб-версии)
class BookingPage extends ConsumerStatefulWidget {
  const BookingPage({super.key});

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  int _tabIndex = 0; // 0 = Индивидуальный, 1 = Групповой
  String _selectedLocation = 'Пресня';
  // Stabilize date to avoid unnecessary stream recreations
  late DateTime _selectedDate = _truncateDate(DateTime.now());
  late DateTime _currentMonth = _truncateDate(DateTime.now());

  DateTime _truncateDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Watch rooms provider with selected date
    final roomsAsync = ref.watch(roomsProvider(_selectedDate));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header - Compact
          _buildHeader(theme),

          // Горизонтальный календарь - Scrollable
          HorizontalCalendar(
            selectedDate: _selectedDate,
            month: _currentMonth,
            onDateSelected: (date) {
              setState(() => _selectedDate = date);
            },
            onPreviousMonth: () {
              setState(() {
                _currentMonth =
                    DateTime(_currentMonth.year, _currentMonth.month - 1);
              });
            },
            onNextMonth: () {
              setState(() {
                _currentMonth =
                    DateTime(_currentMonth.year, _currentMonth.month + 1);
              });
            },
          ),

          // Filters - Compact
          _buildFilters(theme),

          // Tabs - Compact
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SegmentedControl(
              selectedIndex: _tabIndex,
              tabs: const ['Индивидуальный', 'Групповой'],
              onChanged: (index) {
                setState(() => _tabIndex = index);
              },
            ),
          ),

          Expanded(
            child: roomsAsync.when(
              data: (rooms) {
                return Column(
                  children: [
                    // Info текст
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Text(
                        'Доступно кабинетов: ${rooms.length}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.grey600,
                        ),
                      ),
                    ),

                    // Список кабинетов
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                        itemCount: rooms.length,
                        itemBuilder: (context, index) {
                          final room = rooms[index];
                          return RoomCard(
                            room: room,
                            isGroupMode: _tabIndex == 1,
                            selectedDate: _selectedDate,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Ошибка: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Text(
            AppStrings.bookingTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ), // Reduced from 8 to 4
      color: theme.scaffoldBackgroundColor,
      child: Row(
        children: [
          // Фильтр локации
          Expanded(
            child: _buildFilterButton(
              theme,
              icon: Icons.location_on_outlined,
              label: _selectedLocation,
              onTap: () {
                _showLocationPicker();
              },
            ),
          ),

          const SizedBox(width: 8),

          // Кнопка выбора дальней даты (полный календарь)
          _buildFilterButton(
            theme,
            icon: Icons.calendar_month,
            label: 'Календарь',
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: isDark
                        ? Theme.of(context).copyWith(
                            colorScheme: ColorScheme.dark(
                              primary: Theme.of(context).colorScheme.primary,
                              surface: AppColors.cardDark,
                            ),
                          )
                        : Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: Theme.of(context).colorScheme.primary,
                              surface: Colors.white,
                            ),
                          ),
                    child: child!,
                  );
                },
                locale: const Locale('ru', 'RU'),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                  _currentMonth = date;
                });
              }
            },
            isCompact: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isCompact = false,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.grey700 : AppColors.grey300;
    final bgColor = isDark ? AppColors.grey800 : Colors.white;
    final textColor = isDark ? AppColors.textLight : AppColors.grey900;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: textColor),
            if (!isCompact) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ... _showLocationPicker and _buildTabs ...

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true, // Fix Z-Index issue
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final spacesAsync = ref.watch(spacesProvider);

          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Выберите локацию',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textLight,
                      ),
                ),
                const SizedBox(height: 16),
                spacesAsync.when(
                  data: (spaces) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: spaces.map((space) {
                      final isEnabled = space.name == 'Пресня';

                      return ListTile(
                        title: Text(
                          space.name,
                          style: TextStyle(
                            color: isEnabled
                                ? AppColors.textLight
                                : AppColors.grey600,
                          ),
                        ),
                        trailing: _selectedLocation == space.name
                            ? Icon(
                                Icons.check,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                        enabled: isEnabled,
                        onTap: isEnabled
                            ? () {
                                setState(() => _selectedLocation = space.name);
                                Navigator.pop(context);
                              }
                            : null,
                      );
                    }).toList(),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Text(
                    'Ошибка: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
