import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/transaction_model.dart';
import 'package:intl/intl.dart';
import '../pages/transaction_detail_page.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isPositive =
        transaction.type == 'deposit' || transaction.type == 'refund';
    final amountPrefix = isPositive ? '+' : '-';

    IconData icon;
    Color iconColor;
    Color iconBg;
    String title;

    switch (transaction.type) {
      case 'deposit':
        icon = Icons.add;
        iconColor = Colors.blue;
        iconBg = Colors.blue.withValues(alpha: 0.1);
        title = 'Пополнение счета';
        break;
      case 'refund':
        icon = Icons.assignment_return;
        iconColor = Colors.green;
        iconBg = Colors.green.withValues(alpha: 0.1);
        title = 'Возврат средств';
        break;
      case 'payment':
      default:
        icon = Icons.credit_card;
        iconColor = Colors.grey;
        iconBg = Colors.grey.withValues(alpha: 0.1);
        title = 'Оплата услуг';
        break;
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                TransactionDetailPage(transaction: transaction),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.grey800 : AppColors.grey200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.description ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix${transaction.amount.abs().toStringAsFixed(0)} ₽',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        isPositive ? Colors.green : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                if (transaction.createdAt != null)
                  Text(
                    DateFormat('d MMM', 'ru').format(transaction.createdAt!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
