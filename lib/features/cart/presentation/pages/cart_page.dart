import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/cart_provider.dart';
import '../../domain/models/cart_item.dart';
import '../../../booking/presentation/providers/booking_provider.dart';
import '../../../booking/presentation/providers/room_provider.dart';
import '../../../booking/domain/models/booking.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/domain/models/transaction_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyCartAvailability(silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cartItems = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final unavailableItemIds = ref.watch(unavailableSlotsProvider);

    // Group items logic
    final groupedItems = <String, List<CartItem>>{};
    for (var item in cartItems) {
      final key = '${item.roomId}_${item.date.day}';
      if (!groupedItems.containsKey(key)) {
        groupedItems[key] = [];
      }
      groupedItems[key]!.add(item);
    }
    final groupedKeys = groupedItems.keys.toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header - Centered & Big
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // No back button
                  Text(
                    'Корзина',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: cartItems.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                            ),
                            onPressed: () =>
                                ref.read(cartProvider.notifier).clear(),
                          )
                        : const SizedBox(width: 48),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: cartItems.isEmpty
                ? _buildEmptyState(theme)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    itemCount: groupedKeys.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final key = groupedKeys[index];
                      final items = groupedItems[key]!;
                      final mainItem = items.first;
                      final itemTotal =
                          items.fold(0, (sum, e) => sum + e.price);

                      return Dismissible(
                        key: ValueKey(key),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          for (var item in items) {
                            ref.read(cartProvider.notifier).removeItem(item.id);
                          }
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isDark
                                ? null
                                : [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      mainItem.imageUrl,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 60,
                                        height: 60,
                                        color:
                                            Colors.grey.withValues(alpha: 0.3),
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mainItem.roomName,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDate(mainItem.date),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '$itemTotal₽',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: items.map((item) {
                                  final isUnavailable =
                                      unavailableItemIds.contains(item.id);

                                  return Container(
                                    padding:
                                        const EdgeInsets.fromLTRB(16, 8, 8, 8),
                                    decoration: BoxDecoration(
                                      color: isUnavailable
                                          ? AppColors.error
                                              .withValues(alpha: 0.1)
                                          : theme.colorScheme.primary
                                              .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(50),
                                      // Optional: Add subtle border
                                      border: Border.all(
                                        color: isUnavailable
                                            ? AppColors.error
                                            : theme.colorScheme.primary
                                                .withValues(alpha: 0.1),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item.timeSlot +
                                              (isUnavailable ? ' (!)' : ''),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: isUnavailable
                                                ? AppColors.error
                                                : theme.colorScheme.primary,
                                            height: 1.1,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () => ref
                                                .read(cartProvider.notifier)
                                                .removeItem(item.id),
                                            borderRadius:
                                                BorderRadius.circular(50),
                                            child: Padding(
                                              padding: const EdgeInsets.all(4),
                                              child: Icon(
                                                Icons.close_rounded,
                                                size: 16,
                                                color: isUnavailable
                                                    ? AppColors.error
                                                    : theme.colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Footer Total - Pinned to bottom, respecting visual weight
          if (cartItems.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 34 + 90, // Safe area + extra space for bottom nav
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Итого:',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        '$total₽',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Оплатить',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    final user = ref.read(authRepositoryProvider).currentUserId;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка: Пользователь не найден')),
        );
      }
      return;
    }

    // Always show rules dialog on every booking
    if (!mounted) return;
    final accepted = await _showRulesDialog();
    if (accepted != true) return; // User cancelled

    // Check Availability
    final isAvailable = await _verifyCartAvailability(silent: false);
    if (!isAvailable) return;

    _proceedWithPayment(user);
  }

  Future<bool> _verifyCartAvailability({bool silent = false}) async {
    if (!silent) setState(() => _isProcessing = true);

    if (!silent) {
      ref.read(unavailableSlotsProvider.notifier).state = {};
    }

    List<String> takenSlotsMessages = [];
    Set<String> newUnavailableIds = {};

    try {
      final cartItems = ref.read(cartProvider);
      final bookingRepo = ref.read(bookingRepositoryProvider);

      // Group by room and date
      final Map<String, List<CartItem>> groupedToCheck = {};
      for (var item in cartItems) {
        final dateKey = '${item.date.year}-${item.date.month}-${item.date.day}';
        final key = '${item.roomId}|$dateKey';
        if (!groupedToCheck.containsKey(key)) groupedToCheck[key] = [];
        groupedToCheck[key]!.add(item);
      }

      for (var key in groupedToCheck.keys) {
        final parts = key.split('|');
        final roomId = parts[0];
        final dateParts = parts[1].split('-');
        final date = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
        );

        final occupiedIds = await bookingRepo.getOccupiedSlotIds(roomId, date);
        for (var item in groupedToCheck[key]!) {
          if (occupiedIds.contains(item.slotId)) {
            takenSlotsMessages.add(
              '${_formatDate(item.date)}, ${item.timeSlot} (${item.roomName})',
            );
            newUnavailableIds.add(item.id);
          }
        }
      }
    } catch (e) {
      if (!silent && mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка проверки доступности: $e')),
        );
      }
      return false;
    }

    // Update State
    if (mounted) {
      ref.read(unavailableSlotsProvider.notifier).state = newUnavailableIds;
    }

    if (takenSlotsMessages.isNotEmpty) {
      if (!silent && mounted) {
        setState(() => _isProcessing = false);
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Слоты уже заняты'),
            content: Text(
              'К сожалению, следующие слоты были заняты другим пользователем:\n\n${takenSlotsMessages.map((e) => '• $e').join('\n')}\n\nОни выделены красным цветом. Пожалуйста, удалите их из корзины, чтобы продолжить.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Понятно'),
              ),
            ],
          ),
        );
      }
      return false;
    }

    return true;
  }

  // void _subscribeToBookings() {} // Logic moved to GlobalCartObserver

  Future<void> _proceedWithPayment(String user) async {
    final totalPrice = ref.read(cartTotalProvider);
    final cartItems = ref.read(cartProvider);

    // Only set processing if not already set (it is set above, but safe to keep)
    if (!_isProcessing) setState(() => _isProcessing = true);

    try {
      const uuid = Uuid();

      // 1. Create Bookings and collect IDs
      final List<String> bookingIds = [];
      for (var item in cartItems) {
        final dateOnly =
            DateTime(item.date.year, item.date.month, item.date.day);

        final booking = Booking(
          id: uuid.v4(),
          userId: user,
          roomId: item.roomId,
          date: dateOnly,
          slotId: item.slotId, // Ensure this is passed
          // status is default
          totalAmount: item.price.toDouble(),
          createdAt: DateTime.now(),
        );

        await ref.read(bookingRepositoryProvider).createBooking(booking);
        bookingIds.add(booking.id);
      }

      // 2. Create Transaction with metadata
      final bookingsMetadata = cartItems
          .map((item) => {
                'room_name': item.roomName,
                'date': item.date.toIso8601String(),
                'time_slot': item.timeSlot,
                'price': item.price,
              })
          .toList();

      final transaction = TransactionModel(
        id: uuid.v4(),
        userId: user,
        amount: -totalPrice.toDouble(),
        type: 'payment',
        description: 'Оплата бронирования',
        bookingId:
            null, // Don't link to specific booking for multi-booking payments
        metadata: {
          'bookings': bookingsMetadata,
          'total_bookings': cartItems.length,
        },
        createdAt: DateTime.now(),
      );
      await ref.read(walletRepositoryProvider).createTransaction(transaction);

      // 3. Clear Cart
      ref.read(cartProvider.notifier).clear();

      // Force refresh of bookings list so Home Page updates
      ref.invalidate(myBookingsProvider);

      // Force refresh of room slots for affected dates
      final uniqueDates = cartItems
          .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
          .toSet();
      for (final date in uniqueDates) {
        ref.invalidate(roomsProvider(date));
      }

      if (mounted) {
        context.go('/payment-success');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка оплаты: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<bool?> _showRulesDialog() {
    final theme = Theme.of(context);
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Правила использования',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Пожалуйста, ознакомьтесь с правилами посещения:',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _buildRuleItem(
                  theme,
                  '1. Пожалуйста, оставляйте кабинет в том же состоянии, в котором он вас встречает. Если вы передвигали мебель — верните её на место.',
                ),
                _buildRuleItem(
                  theme,
                  '2. Мы используем только стеклянные стаканы. Пожалуйста, помойте стакан после себя и поставьте его сушиться на полку.',
                ),
                _buildRuleItem(
                  theme,
                  '3. Бесплатная отмена или перенос слота возможны за 24 часа до начала.',
                ),
                _buildRuleItem(
                  theme,
                  '4. Если вы отменяете бронирование менее чем за 24 часа — слот необходимо оплатить полностью.',
                ),
                _buildRuleItem(
                  theme,
                  '5. При бронировании кабинета на целый день бесплатная отмена возможна за 48 часов.',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Нажимая "Согласен", вы подтверждаете, что ознакомились с правилами и обязуетесь их выполнять.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Отмена',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Я ознакомился и согласен',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: AppColors.grey500,
          ),
          const SizedBox(height: 16),
          Text(
            'Корзина пуста',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите время бронирования',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.grey500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/booking'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'К кабинетам',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMMM', 'ru').format(date);
  }
}
