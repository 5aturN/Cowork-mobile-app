import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_animations.dart';
import '../../../booking/presentation/providers/booking_provider.dart';
import '../../../booking/domain/models/booking.dart';

/// Экран "Мои сессии" - записи прошедших сессий
class SessionsPage extends ConsumerStatefulWidget {
  const SessionsPage({super.key});

  @override
  ConsumerState<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends ConsumerState<SessionsPage> {
  final Map<String, bool> _expandedNotes = {};

  void _toggleNotes(String sessionId) {
    setState(() {
      _expandedNotes[sessionId] = !(_expandedNotes[sessionId] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              _buildHeader(theme, bookingsAsync.value?.length ?? 0),

              // Sessions list
              Expanded(
                child: bookingsAsync.when(
                  data: (sessions) {
                    if (sessions.isEmpty) return _buildEmptyState(theme);
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final isExpanded = _expandedNotes[session.id] ?? false;

                        return FadeInUp(
                          duration: AppAnimations.normal,
                          delay: Duration(milliseconds: index * 50),
                          child: _buildSessionCard(theme, session, isExpanded),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('Ошибка загрузки сессий: $error'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, int count) {
    return FadeInDown(
      duration: AppAnimations.normal,
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            bottom: BorderSide(
              color: theme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.transparent,
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/booking'),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Мои сессии',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '$count записей',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(ThemeData theme, Booking session, bool isExpanded) {
    final isDark = theme.brightness == Brightness.dark;
    final hasNotes = session.comment != null && session.comment!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasNotes ? () => _toggleNotes(session.id) : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.roomName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                session.formattedDate,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: session.statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${session.totalAmount.toInt()}₽',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: session.statusColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Time
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      session.formattedTime,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const Spacer(),
                    if (hasNotes)
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),

                // Notes (expandable)
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : AppColors.grey100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.note_outlined,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Заметки',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          session.comment ?? '',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: AppAnimations.fast,
                ),

                // Add note button if no notes (Placeholder as update is not implemented yet)
                // if (!hasNotes) ...[
                //   const SizedBox(height: 12),
                //   SizedBox(
                //     width: double.infinity,
                //     child: OutlinedButton.icon(
                //       onPressed: () => _addNoteDialog(session),
                //       icon: const Icon(Icons.add, size: 16),
                //       label: const Text('Добавить заметку'),
                //       style: OutlinedButton.styleFrom(
                //         padding: const EdgeInsets.symmetric(vertical: 12),
                //       ),
                //     ),
                //   ),
                // ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return FadeIn(
      duration: AppAnimations.slow,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 80,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Нет записей сессий',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'История сессий будет отображаться здесь',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
