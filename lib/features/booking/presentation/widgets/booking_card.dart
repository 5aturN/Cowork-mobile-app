import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';

import '../../domain/models/booking.dart';

/// Карточка бронирования с анимациями
class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onCancel;
  final VoidCallback? onReschedule;
  final VoidCallback? onRepeat;
  final int index;

  const BookingCard({
    super.key,
    required this.booking,
    this.onCancel,
    this.onReschedule,
    this.onRepeat,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget card = Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Image Header Section
          SizedBox(
            height: 180,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                Image.network(
                  booking.roomImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                      size: 40,
                    ),
                  ),
                ),

                // Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),

                // Top Left: Status Badge (Glass)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          booking.statusIcon,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          booking.statusDisplayName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top Right: Price Badge (Glass)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${booking.totalAmount.toStringAsFixed(0)} ₽',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                // Bottom Left: Info Overlay
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date & Time
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${booking.formattedDate}  •  ${booking.formattedTime}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Room Name
                      Text(
                        booking.roomName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Bottom Actions & Details Section
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? AppColors.cardDark : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Comment (if any)
                if (booking.comment != null && booking.comment!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : AppColors.grey50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking.comment!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.8),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                if (booking.isActive) ...[
                  // Check if more than 24 hours until booking
                  Builder(
                    builder: (context) {
                      final now = DateTime.now();
                      final hoursUntil =
                          booking.dateTime.difference(now).inHours;
                      final canReschedule = hoursUntil >= 24;

                      return Column(
                        children: [
                          // Cancel button (always shown for active bookings)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: onCancel,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: BorderSide(
                                  color: AppColors.error.withValues(alpha: 0.5),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Отменить бронирование'),
                            ),
                          ),
                          // Reschedule button (only if >24h)
                          if (canReschedule && onReschedule != null) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: onReschedule,
                                icon: const Icon(Icons.calendar_month),
                                label: const Text('Перенести слот'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ] else
                  // Past -> Repeat (Primary Filled)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onRepeat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Повторить',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    // Fade In Animation
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      delay: Duration(milliseconds: index * 50),
      child: card,
    );
  }
}
