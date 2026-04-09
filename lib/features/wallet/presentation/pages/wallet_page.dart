// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

import '../providers/wallet_provider.dart';
import '../widgets/transaction_card.dart';

class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final userProfileAsync = ref.watch(userProfileProvider);
    final transactionsAsync = ref.watch(userTransactionsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Fixed Header
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              child: Text(
                'Кошелек',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // Balance Card
                  _buildBalanceSection(
                    theme,
                    isDark,
                    userProfileAsync.value?.balance ?? 0,
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          theme,
                          icon: Icons.add_circle_outline,
                          label: 'Пополнить',
                          color: theme.colorScheme.primary,
                          textColor: Colors.white,
                          onTap: () {
                            // TODO: Implement Deposit
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Пополнение скоро будет доступно',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          theme,
                          icon: Icons.history,
                          label: 'История',
                          color: isDark ? AppColors.cardDark : Colors.white,
                          textColor: theme.colorScheme.onSurface,
                          borderColor:
                              isDark ? AppColors.grey800 : AppColors.grey300,
                          onTap: () => context.push('/wallet/history'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Transactions
                  Text(
                    'Последние операции',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  transactionsAsync.when(
                    data: (transactions) {
                      if (transactions.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              'История операций пуста',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: transactions
                            .take(5)
                            .map(
                              (t) => TransactionCard(
                                transaction: t,
                              ),
                            )
                            .toList(),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Ошибка загрузки: $e'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSection(ThemeData theme, bool isDark, double balance) {
    return Column(
      children: [
        Text(
          'ТЕКУЩИЙ БАЛАНС',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${balance.toStringAsFixed(0)} ₽',
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: borderColor != null ? Border.all(color: borderColor) : null,
          boxShadow: color == theme.colorScheme.primary
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
