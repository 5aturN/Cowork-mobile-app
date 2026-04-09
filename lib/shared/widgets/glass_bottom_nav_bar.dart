import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Плавающая Bottom Navigation Bar (как в веб-версии)
class GlassBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartItemCount; // Количество товаров в корзине

  const GlassBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.cartItemCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        height: 72, // Увеличено с 70 до 72 для устранения overflow
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.grey900.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppColors.grey200.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    context,
                    Icons.home_outlined,
                    Icons.home,
                    'Главная',
                    0,
                  ),
                  _buildNavItem(
                    context,
                    Icons.calendar_month_outlined,
                    Icons.calendar_month,
                    'Бронь',
                    1,
                  ),
                  _buildNavItem(
                    context,
                    Icons.shopping_cart_outlined,
                    Icons.shopping_cart,
                    'Корзина',
                    2,
                    badge: cartItemCount > 0 ? cartItemCount : null,
                  ),
                  _buildNavItem(
                    context,
                    Icons.account_balance_wallet_outlined,
                    Icons.account_balance_wallet,
                    'Кошелек',
                    3,
                  ),
                  _buildNavItem(
                    context,
                    Icons.person_outline,
                    Icons.person,
                    'Профиль',
                    4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    IconData activeIcon,
    String label,
    int index, {
    int? badge,
  }) {
    final isSelected = currentIndex == index;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 6,
              horizontal: 4,
            ), // Уменьшен padding
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isSelected ? activeIcon : icon,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : isDark
                                ? AppColors.grey400
                                : AppColors.grey600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 2), // Уменьшен с 4 до 2
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : isDark
                                ? AppColors.grey400
                                : AppColors.grey600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                // Бейдж
                if (badge != null)
                  Positioned(
                    top: 0,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        badge > 9 ? '9+' : badge.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
