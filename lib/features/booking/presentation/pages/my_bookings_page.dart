import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/segmented_control.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_card.dart';
import '../controllers/booking_controller.dart';
import '../../domain/models/booking.dart';

class MyBookingsPage extends ConsumerStatefulWidget {
  const MyBookingsPage({super.key});

  @override
  ConsumerState<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends ConsumerState<MyBookingsPage> {
  int _tabIndex = 0; // 0 = Предстоящие, 1 = Прошедшие

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor, // Ensure consistent background
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: theme.colorScheme.onSurface,
                      ),
                      onPressed: () => context.go('/home'),
                    ),
                  ),
                  Text(
                    'Мои бронирования',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // Segment Control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedControl(
                selectedIndex: _tabIndex,
                tabs: const ['Предстоящие', 'История'],
                onChanged: (index) => setState(() => _tabIndex = index),
              ),
            ),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: bookingsAsync.when(
                data: (bookings) {
                  final now = DateTime.now();
                  final upcoming = bookings
                      .where(
                        (b) =>
                            b.isActive &&
                            b.dateTime
                                .add(Duration(minutes: b.duration))
                                .isAfter(now),
                      )
                      .toList()
                    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

                  final history = bookings
                      .where(
                        (b) =>
                            !b.isActive ||
                            b.dateTime
                                .add(Duration(minutes: b.duration))
                                .isBefore(now),
                      )
                      .toList()
                    ..sort(
                      (a, b) => b.dateTime.compareTo(a.dateTime),
                    ); // Descending for history

                  final displayList = _tabIndex == 0 ? upcoming : history;

                  if (displayList.isEmpty) {
                    return _buildEmptyState(theme, _tabIndex == 0);
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.refresh(myBookingsProvider.future),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: displayList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final booking = displayList[index];
                        return BookingCard(
                          booking: booking,
                          index: index,
                          onCancel: booking.isActive
                              ? () => _cancelBooking(booking)
                              : null,
                          onReschedule: booking.isActive
                              ? () => _rescheduleBooking(booking)
                              : null,
                          onRepeat: !booking.isActive
                              ? () => _repeatBooking(booking)
                              : null,
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Ошибка: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isUpcoming) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isUpcoming ? Icons.calendar_today_outlined : Icons.history,
            size: 64,
            color: AppColors.grey500,
          ),
          const SizedBox(height: 16),
          Text(
            isUpcoming ? 'Нет активных бронирований' : 'История пуста',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (isUpcoming)
            ElevatedButton(
              onPressed: () => context.go('/booking'), // Adjust route if needed
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Забронировать',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking(Booking booking) async {
    final controller = ref.read(bookingControllerProvider);
    final theme = Theme.of(context);

    // Check if refund is possible
    final canGetRefund = controller.canRefund(booking.dateTime);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить бронирование?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (canGetRefund) ...[
              const Text(
                'Средства будут возвращены на ваш счет.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Сумма возврата: ${booking.totalAmount.toStringAsFixed(0)} ₽',
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: theme.colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Возврат средств невозможен',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Отменяя бронирование менее чем за 24 часа, вы не получите возврат средств согласно правилам.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Назад'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Отменить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await controller.cancelBooking(booking);

      // Close loading dialog first
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!mounted) return;

      if (result.success) {
        ref.invalidate(myBookingsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.refunded
                    ? 'Отменено. ${result.refundAmount.toStringAsFixed(0)} ₽ возвращено.'
                    : 'Бронирование отменено',
              ),
              backgroundColor: theme.colorScheme.primary,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: ${result.error}'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  void _repeatBooking(Booking booking) {
    context.go('/booking');
  }

  void _rescheduleBooking(Booking booking) async {
    final controller = ref.read(bookingControllerProvider);
    final theme = Theme.of(context);

    // Check if reschedule is possible (>24h)
    final canReschedule = controller.canRefund(booking.dateTime);

    if (!canReschedule) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Перенос возможен только за 24 часа до сеанса',
          ),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    // Show dialog explaining the process
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Перенести бронирование'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Для переноса бронирования:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('1. Текущее бронирование будет отменено'),
            const SizedBox(height: 8),
            Text(
              '2. ${booking.totalAmount.toStringAsFixed(0)} ₽ вернутся на ваш счет',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text('3. Вы сможете выбрать новую дату и время'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to  booking page
              context.go('/booking');
              // Show info snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Сначала отмените текущее бронирование, затем выберите новое',
                  ),
                  duration: Duration(seconds: 4),
                ),
              );
            },
            child: const Text('Перейти к бронированию'),
          ),
        ],
      ),
    );
  }
}
