import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/models/room.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/horizontal_calendar.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../cart/domain/models/cart_item.dart';
import '../providers/room_provider.dart';

class CabinetDetailPage extends ConsumerStatefulWidget {
  final Room room;

  const CabinetDetailPage({super.key, required this.room});

  @override
  ConsumerState<CabinetDetailPage> createState() => _CabinetDetailPageState();
}

class _CabinetDetailPageState extends ConsumerState<CabinetDetailPage> {
  late DateTime _selectedDate = _truncateDate(DateTime.now());
  late DateTime _currentMonth = _truncateDate(DateTime.now());

  DateTime _truncateDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final roomsAsync = ref.watch(roomsProvider(_selectedDate));
    final liveRoom = roomsAsync.value?.firstWhere(
          (r) => r.id == widget.room.id,
          orElse: () => widget.room,
        ) ??
        widget.room;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: widget.room.imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const ColoredBox(
                  color: AppColors.grey800,
                  child: Center(child: Icon(Icons.error)),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.room.name,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${widget.room.pricePerHour}₽',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Вместимость: ${widget.room.area} чел.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Описание',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.room.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Calendar Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Выберите дату',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                            locale: const Locale('ru', 'RU'),
                            builder: (context, child) {
                              return Theme(
                                data: isDark
                                    ? Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.dark(
                                          primary: theme.colorScheme.primary,
                                          surface: AppColors.cardDark,
                                        ),
                                      )
                                    : Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: theme.colorScheme.primary,
                                          surface: Colors.white,
                                        ),
                                      ),
                                child: child!,
                              );
                            },
                          );
                          if (date != null) {
                            setState(() {
                              _selectedDate = date;
                              _currentMonth = date;
                            });
                          }
                        },
                        icon: Icon(
                          Icons.calendar_month,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  HorizontalCalendar(
                    selectedDate: _selectedDate,
                    month: _currentMonth,
                    onDateSelected: (date) {
                      setState(() => _selectedDate = date);
                    },
                    onPreviousMonth: () {
                      setState(() {
                        _currentMonth = DateTime(
                          _currentMonth.year,
                          _currentMonth.month - 1,
                        );
                      });
                    },
                    onNextMonth: () {
                      setState(() {
                        _currentMonth = DateTime(
                          _currentMonth.year,
                          _currentMonth.month + 1,
                        );
                      });
                    },
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'Доступные слоты',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildTimeSlots(theme, isDark, liveRoom),

                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlots(ThemeData theme, bool isDark, Room room) {
    // Generate at least 4 unlocked slots + some occupied
    // This is simplified logic similar to RoomCard
    final allSlots = [
      '09:00',
      '10:30',
      '12:00',
      '13:30',
      '15:00',
      '16:30',
      '18:00',
      '19:30',
      '21:00',
    ];

    // Check availability against room.occupiedSlots
    bool isSlotOccupied(String time) {
      return room.occupiedSlots.contains(time);
    }

    final now = DateTime.now();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: allSlots.length,
      itemBuilder: (_, index) {
        final time = allSlots[index];
        final isOccupied = isSlotOccupied(time);

        // Check if slot is in the past
        final parts = time.split(':');
        final slotDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
        final isPast = slotDateTime.isBefore(now);

        final isdisabled = isOccupied || isPast;

        final cartItems = ref.watch(cartProvider);
        final isSelected = cartItems.any(
          (item) =>
              item.roomId == widget.room.id &&
              item.timeSlot == time &&
              _isSameDay(item.date, _selectedDate),
        );

        final bgColor = isdisabled
            ? (isDark ? AppColors.grey800 : AppColors.grey200)
            : isSelected
                ? theme.colorScheme.primary
                : Colors.transparent;

        final borderColor = isdisabled
            ? Colors.transparent
            : isSelected
                ? theme.colorScheme.primary
                : (isDark ? AppColors.grey700 : AppColors.grey300);

        final textColor = isdisabled
            ? (isDark ? AppColors.grey600 : AppColors.grey500)
            : isSelected
                ? Colors.white
                : theme.colorScheme.onSurface;

        return GestureDetector(
          onTap: isdisabled
              ? null
              : () async {
                  final newItem = CartItem(
                    id: '${widget.room.id}_${_selectedDate.millisecondsSinceEpoch}_$time',
                    roomId: widget.room.id,
                    roomName: widget.room.name,
                    imageUrl: widget.room.imageUrl,
                    date: _selectedDate,
                    timeSlot: time,
                    slotId: index + 1,
                    price: widget.room.pricePerHour,
                    durationMinutes: 60,
                  );

                  if (isSelected) {
                    ref.read(cartProvider.notifier).removeItem(newItem.id);
                  } else {
                    final success =
                        await ref.read(cartProvider.notifier).addItem(newItem);

                    if (!mounted) return;

                    if (!success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Слот уже занят или недоступен'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: borderColor),
            ),
            alignment: Alignment.center,
            child: Text(
              time,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
