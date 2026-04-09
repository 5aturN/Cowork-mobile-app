import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/transaction_model.dart';

class TransactionDetailPage extends ConsumerWidget {
  final TransactionModel transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Детали операции'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.grey800 : AppColors.grey200,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _getIcon(),
                    size: 64,
                    color: _getIconColor(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getTitle(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_isPositive() ? '+' : ''}${transaction.amount.toStringAsFixed(0)} ₽',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: _isPositive()
                          ? Colors.green
                          : theme.colorScheme.error,
                    ),
                  ),
                  if (transaction.createdAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('d MMMM yyyy, HH:mm', 'ru')
                          .format(transaction.createdAt!),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Details Section
            _buildDetailsSection(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(ThemeData theme, bool isDark) {
    final metadata = transaction.metadata;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.grey800 : AppColors.grey200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Информация о транзакции',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _DetailRow(
            label: 'ID операции',
            value: '#${transaction.id.substring(0, 8)}',
          ),

          if (transaction.description != null) ...[
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Описание',
              value: transaction.description!,
            ),
          ],

          // Payment/Refund specific details
          if (metadata != null &&
              (transaction.type == 'payment' ||
                  transaction.type == 'refund')) ...[
            const SizedBox(height: 20),
            Divider(color: theme.dividerColor.withValues(alpha: 0.3)),
            const SizedBox(height: 16),

            Text(
              transaction.type == 'payment'
                  ? 'Детали оплаты'
                  : 'Детали возврата',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Single booking details
            if (metadata['room_name'] != null) ...[
              _DetailRow(
                label: 'Кабинет',
                value: metadata['room_name'] as String,
              ),
              const SizedBox(height: 12),
            ],

            if (metadata['date'] != null) ...[
              _DetailRow(
                label: 'Дата',
                value: DateFormat('d MMMM yyyy', 'ru').format(
                  DateTime.parse(metadata['date'] as String),
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (metadata['time_slot'] != null) ...[
              _DetailRow(
                label: 'Время',
                value: metadata['time_slot'] as String,
              ),
            ],

            // Multiple bookings from cart
            if (metadata['bookings'] != null) ...[
              const SizedBox(height: 16),
              Text(
                'Забронировано слотов: ${metadata['total_bookings']}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ..._buildBookingsList(metadata['bookings'] as List, theme),
            ],
          ],
        ],
      ),
    );
  }

  List<Widget> _buildBookingsList(List bookings, ThemeData theme) {
    return bookings.asMap().entries.map((entry) {
      final index = entry.key;
      final booking = entry.value as Map<String, dynamic>;

      return Padding(
        padding: EdgeInsets.only(bottom: index < bookings.length - 1 ? 12 : 0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking['room_name'] as String,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${DateFormat('d MMM', 'ru').format(DateTime.parse(booking['date'] as String))} • ${booking['time_slot']}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                '${booking['price']} ₽',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  bool _isPositive() {
    return transaction.type == 'deposit' || transaction.type == 'refund';
  }

  IconData _getIcon() {
    switch (transaction.type) {
      case 'deposit':
        return Icons.add_circle;
      case 'refund':
        return Icons.assignment_return;
      case 'payment':
      default:
        return Icons.credit_card;
    }
  }

  Color _getIconColor() {
    switch (transaction.type) {
      case 'deposit':
        return Colors.blue;
      case 'refund':
        return Colors.green;
      case 'payment':
      default:
        return Colors.grey;
    }
  }

  String _getTitle() {
    switch (transaction.type) {
      case 'deposit':
        return 'Пополнение счета';
      case 'refund':
        return 'Возврат средств';
      case 'payment':
      default:
        return 'Оплата';
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
