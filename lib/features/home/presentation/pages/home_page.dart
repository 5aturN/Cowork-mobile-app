import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/update_service.dart';
import '../providers/notifications_provider.dart';
import '../../../booking/presentation/providers/room_provider.dart';
import '../../../booking/presentation/providers/booking_provider.dart';
import '../../../booking/presentation/controllers/booking_controller.dart';
import '../../../booking/domain/models/booking.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/user_profile_extensions.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _checkForUpdates();
  }

  Future<void> _requestNotificationPermission() async {
    // Request notification permission on first load
    // This handles Android 13+ runtime permissions
    final status = await Permission.notification.status;
    if (status.isDenied || status.isProvisional) {
      // Don't await here to avoid blocking UI, or do?
      // Better to just call request. The OS handles the dialog.
      await Permission.notification.request();
    }
  }

  Future<void> _checkForUpdates() async {
    // Wait a bit for the app to settle
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final update = await UpdateService.checkForUpdate();
    if (update != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: !update.isMandatory,
        builder: (context) => AlertDialog(
          title: Text('Доступна новая версия ${update.version}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (update.releaseNotes != null) Text(update.releaseNotes!),
              const SizedBox(height: 10),
              const Text('Рекомендуем обновиться для стабильной работы.'),
            ],
          ),
          actions: [
            if (!update.isMandatory)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Позже'),
              ),
            FilledButton(
              onPressed: () {
                launchUrl(
                  Uri.parse(update.url),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: const Text('Обновить'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // No standard AppBar, custom header
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myBookingsProvider);
            ref.invalidate(userProfileProvider);
            try {
              await ref.read(myBookingsProvider.future);
            } catch (e) {
              // Ignore error on refresh
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header
                _buildHeader(theme, context, ref),
                const SizedBox(height: 24),

                // Search Bar removed as per request

                // 3. Next Session
                _buildNextSessionCard(context, theme, isDark, ref),

                // 4. News & Promotions
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(Icons.campaign, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Новости и акции',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildNewsList(theme, isDark),
                const SizedBox(height: 32),

                // 5. Quick Book
                // 5. Quick Book handled inside handled inside the list widget to hide if empty
                const SizedBox(height: 12),
                _buildQuickBookList(context, theme, isDark, ref),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, BuildContext context, WidgetRef ref) {
    // Watch user profile for real name
    final userProfileAsync = ref.watch(userProfileProvider);
    final unreadCount = ref.watch(notificationsProvider);

    // Dynamic Greeting
    final hour = DateTime.now().hour;
    String greeting;
    if (hour >= 6 && hour < 12) {
      greeting = 'Доброе утро,';
    } else if (hour >= 12 && hour < 18) {
      greeting = 'Добрый день,';
    } else if (hour >= 18 && hour < 23) {
      greeting = 'Добрый вечер,';
    } else {
      greeting = 'Доброй ночи,';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
                image: userProfileAsync.value?.avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(userProfileAsync.value!.avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: userProfileAsync.value?.avatarUrl == null
                  ? Icon(Icons.person, color: theme.colorScheme.primary)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  userProfileAsync.value?.shortName ?? 'Пользователь',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ref.read(notificationsProvider.notifier).refresh();
              context.push('/notifications');
            },
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, size: 28),
                if (unreadCount > 0)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 1.5,
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
  }

  Widget _buildNextSessionCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    WidgetRef ref,
  ) {
    final bookingsAsync = ref.watch(myBookingsProvider);

    return bookingsAsync.when(
      data: (bookings) {
        // Find next active booking
        // "Active" typically means future or strictly currently ongoing.
        // We filter for "not completed and not cancelled" via isActive
        // Then we refine: start_time is in future OR we are inside [start, end]
        // Currently 'isActive' just checks status.

        final now = DateTime.now();

        final upcomingBookings = bookings.where((b) {
          if (!b.isActive) return false;

          // Calculate end time
          final end = b.dateTime.add(Duration(minutes: b.duration));

          // Show if it ends in the future (so it includes "Current" sessions)
          return end.isAfter(now);
        }).toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

        // Combined Empty State for "No Future Sessions"
        if (upcomingBookings.isEmpty) {
          final hasHistory = bookings.isNotEmpty;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_today_outlined,
                    size: 48,
                    color: theme.colorScheme.primary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Нет ближайших сессий',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Запланируйте свою следующую консультацию,\nчтобы она отобразилась здесь',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/booking'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Найти кабинет',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // History Button (Only if history exists)
                if (hasHistory) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/my-bookings'),
                    child: const Text('Посмотреть расписание'),
                  ),
                ],

                const SizedBox(height: 16),
              ],
            ),
          );
        }

        final nextBooking = upcomingBookings.first;
        final timeUntil = nextBooking.dateTime.difference(now);
        String timeUntilString = '';
        if (timeUntil.inHours > 0) {
          timeUntilString = 'Через ${timeUntil.inHours} ч';
        } else if (timeUntil.inMinutes > 0) {
          timeUntilString = 'Через ${timeUntil.inMinutes} мин';
        } else {
          timeUntilString = 'Сейчас';
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Моя следующая сессия',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/my-bookings'),
                    child: const Text('Расписание'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: isDark ? AppColors.cardDark : Colors.white,
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
                  children: [
                    Expanded(
                      flex: 3,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            nextBooking.roomImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.8),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Text(
                                timeUntilString,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${nextBooking.dateTime.day}.${nextBooking.dateTime.month} • ${nextBooking.formattedTime}',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color:
                                            Colors.white.withValues(alpha: 0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  nextBooking.roomName,
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
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
                    Expanded(
                      flex: 1,
                      child: Container(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _handleCancelBooking(
                                  context,
                                  ref,
                                  nextBooking,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.error,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      12,
                                    ),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Я не приду'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.map_outlined),
                              style: IconButton.styleFrom(
                                backgroundColor: isDark
                                    ? AppColors.grey800
                                    : AppColors.grey100,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.more_horiz),
                              style: IconButton.styleFrom(
                                backgroundColor: isDark
                                    ? AppColors.grey800
                                    : AppColors.grey100,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          height: 240,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (e, s) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Error loading next session: $e',
          style: const TextStyle(
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildNewsList(ThemeData theme, bool isDark) {
    return SizedBox(
      height: 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width -
                40, // Full width minus padding
            child: _buildNewsItem(
              theme,
              isDark,
              color: Colors.pink,
              icon: Icons.favorite,
              title: 'Сообщение для тестеров',
              description:
                  'Тестируйте внимательно, я все постараюсь исправить, надеюсь это приложение вам нравится больше предыдущего ❤️',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsItem(
    ThemeData theme,
    bool isDark, {
    required Color color,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final bgColor =
        isDark ? color.withValues(alpha: 0.1) : color.withValues(alpha: 0.05);
    final borderColor =
        isDark ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.1);

    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? color.withValues(alpha: 0.9)
                        : color.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? color.withValues(alpha: 0.7)
                        : color.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickBookList(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    WidgetRef ref,
  ) {
    // Check if user has bookings to decide whether to show this section at all
    // Check if user has bookings to decide whether to show this section at all
    final bookingsAsync = ref.watch(myBookingsProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final roomsAsync = ref.watch(roomsProvider(today));

    return bookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) return const SizedBox(); // Hide if no history

        // Show section title + list
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Забронировать снова',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/booking'),
                    child: const Text('Все кабинеты'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            roomsAsync.when(
              data: (rooms) {
                // Extract room IDs from user's bookings to show only previously booked rooms
                final bookedRoomIds =
                    bookings.map((b) => b.roomId).toSet().toList();

                // Filter rooms to only show previously booked ones
                final displayRooms = rooms
                    .where((room) => bookedRoomIds.contains(room.id))
                    .take(3)
                    .toList();

                return SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: displayRooms.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final room = displayRooms[index];
                      return GestureDetector(
                        onTap: () =>
                            context.push('/booking/detail', extra: room),
                        child: SizedBox(
                          width: 120,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        image: DecorationImage(
                                          image: NetworkImage(room.imageUrl),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withValues(alpha: 0.6),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: InkWell(
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                room.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${room.pricePerHour} ₽', // per slot
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Future<void> _handleCancelBooking(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) async {
    final controller = ref.read(bookingControllerProvider);
    final theme = Theme.of(context);

    // Check if refund is possible
    final canGetRefund = controller.canRefund(booking.dateTime);

    // Show appropriate confirmation dialog
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
                      'Отменяя бронирование менее чем за 24 часа до начала, вы не получите возврат средств согласно правилам.',
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
            child: const Text('Отменить бронирование'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Cancel booking through controller
      final result = await controller.cancelBooking(booking);

      // Close loading dialog first
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!mounted) return;

      if (result.success) {
        // Refresh bookings
        ref.invalidate(myBookingsProvider);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.refunded
                    ? 'Бронирование отменено. ${result.refundAmount.toStringAsFixed(0)} ₽ возвращено на счет.'
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
              content: Text('Ошибка отмены: ${result.error}'),
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
}
