import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Логотип приложения Secretaire
class AppLogo extends StatelessWidget {
  final double size;
  final bool showName;
  final bool showIcon;
  final bool withBackground;

  const AppLogo({
    super.key,
    this.size = 32,
    this.showName = true,
    this.showIcon = true,
    this.withBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final logoContent = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon
        if (showIcon)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(size / 4),
            ),
            child: Icon(
              Icons.spa_outlined,
              color: AppColors.textDark,
              size: size * 0.6,
            ),
          ),
        if (showIcon && showName) SizedBox(width: size * 0.3),
        Text(
          'Secretaire',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: size * 0.6,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );

    if (!withBackground) {
      return logoContent;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.4,
        vertical: size * 0.25,
      ),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.backgroundDark : AppColors.backgroundLight)
            .withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(size),
        border: Border.all(
          color: isDark ? AppColors.grey800 : AppColors.grey200,
          width: 1,
        ),
      ),
      child: logoContent,
    );
  }
}
