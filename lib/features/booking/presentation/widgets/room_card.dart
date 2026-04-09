import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/room.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../cart/domain/models/cart_item.dart';
import 'package:go_router/go_router.dart';

/// Карточка кабинета в стиле веб-версии (слоты сеткой 3x3)
class RoomCard extends ConsumerStatefulWidget {
  final Room room;
  final bool isGroupMode;
  final DateTime selectedDate;

  const RoomCard({
    super.key,
    required this.room,
    this.isGroupMode = false,
    required this.selectedDate,
  });

  @override
  ConsumerState<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends ConsumerState<RoomCard> {
  late DateTime selectedDate;
  // String? selectedSlot; // Logic moved to provider checking

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Group Price Logic
    final price = widget.isGroupMode ? 1500 : widget.room.pricePerHour;

    return GestureDetector(
      onTap: () {
        context.push('/booking/detail', extra: widget.room);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color:
              isDark ? AppColors.cardDark : Colors.white, // Light theme support
          borderRadius: BorderRadius.circular(20), // More rounded card
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Фото кабинета с бейджами
            _buildRoomImage(context),

            // Название и ЦЕНА
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.room.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  // Price moved here
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.grey800 : AppColors.grey200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$price₽',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textLight : AppColors.grey900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Сетка слотов 3x3
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildTimeGrid(price),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomImage(BuildContext context) {
    return Stack(
      children: [
        // Фото
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: CachedNetworkImage(
            imageUrl: widget.room.imageUrl,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(
              height: 200,
              color: AppColors.grey700,
              child:
                  const Icon(Icons.image, size: 48, color: AppColors.grey500),
            ),
          ),
        ),

        // Бейдж вместимости (слева вверху)
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  '${widget.room.area} чел.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Бейдж локации (справа вверху)
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Пресня',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeGrid(int price) {
    // 9 slots, 1.5 hours each, 10 min break. Starts 09:00.
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

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: allSlots.length,
      itemBuilder: (context, index) {
        final time = allSlots[index];
        return _buildTimeSlot(
          time,
          isAvailable: true,
          price: price,
          slotId: index + 1,
        );
      },
    );
  }

  Widget _buildTimeSlot(
    String time, {
    required bool isAvailable,
    required int price,
    required int slotId,
  }) {
    // Simplified mock availability logic: unlock specific slots always
    bool isSlotOccupied(String time) {
      return widget.room.occupiedSlots.contains(time);
    }

    final isOccupied = isSlotOccupied(time);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Normalize date for comparison
    final checkDate = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
    );

    final isSelected = ref.watch(cartProvider).any(
          (item) =>
              item.roomId == widget.room.id &&
              item.timeSlot == time &&
              item.date.year == checkDate.year &&
              item.date.month == checkDate.month &&
              item.date.day == checkDate.day,
        );

    Color bgColor;
    Color textColor;

    if (isOccupied) {
      // Занято
      bgColor = isDark
          ? AppColors.error.withValues(alpha: 0.15)
          : AppColors.error.withValues(alpha: 0.1);
      textColor = AppColors.error;
    } else if (isSelected) {
      // Выбран
      bgColor = theme.colorScheme.primary;
      textColor = Colors.white;
    } else if (isAvailable) {
      // Доступен
      bgColor = isDark ? AppColors.grey800 : Colors.white;
      textColor = isDark ? AppColors.textLight : AppColors.grey900;
    } else {
      // Недоступен
      bgColor = isDark ? AppColors.backgroundDark : AppColors.grey100;
      textColor = AppColors.grey500;
    }

    return GestureDetector(
      onTap: (isAvailable && !isOccupied)
          ? () {
              // Optimistic Update directly to Provider
              final cartNotifier = ref.read(cartProvider.notifier);

              if (isSelected) {
                // Remove logic (requires ID, we might need to find the item first)
                final item = ref.read(cartProvider).firstWhere(
                      (e) => e.roomId == widget.room.id && e.timeSlot == time,
                    );
                cartNotifier.removeItem(item.id);
              } else {
                // Add item
                final newItem = CartItem(
                  id: DateTime.now().toIso8601String(), // Temporary ID
                  roomId: widget.room.id,
                  roomName: widget.room.name,
                  imageUrl: widget.room.imageUrl,
                  date: checkDate,
                  timeSlot: time,
                  slotId: slotId,
                  price: price,
                  durationMinutes: 120, // 2 hours
                );
                // Call async addItem and handle result
                cartNotifier.addItem(newItem).then((success) {
                  if (!success && mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Слот уже занят или недоступен'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                });
              }
              // No local setState needed if we watch the provider!
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(50), // Fully rounded capsular
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : (isAvailable && !isOccupied)
                    ? (isDark ? AppColors.grey700 : AppColors.grey300)
                    : Colors.transparent,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            time,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700, // Bolder
              fontSize: 11, // Smaller
            ),
          ),
        ),
      ),
    );
  }
}
