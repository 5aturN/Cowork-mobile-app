import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Кастомная кнопка приложения с поддержкой иконок и различных стилей
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final bool iconRight;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsets? padding;
  final double? width;
  final double height;
  final double borderRadius;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.iconRight = true,
    this.backgroundColor,
    this.textColor,
    this.padding,
    this.width,
    this.height = 56,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      height: height,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: textColor ?? theme.colorScheme.onSurface,
                side: BorderSide(
                  color: textColor ??
                      theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                padding: padding ??
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: _buildContent(theme),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor ?? AppColors.primary,
                foregroundColor: textColor ?? AppColors.textDark,
                elevation: 0,
                shadowColor: (backgroundColor ?? AppColors.primary)
                    .withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                padding: padding ??
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: _buildContent(theme),
            ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            textColor ??
                (isOutlined ? theme.colorScheme.onSurface : AppColors.textDark),
          ),
        ),
      );
    }

    if (icon == null) {
      return Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: textColor ??
              (isOutlined ? theme.colorScheme.onSurface : AppColors.textDark),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!iconRight) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: textColor ??
                (isOutlined ? theme.colorScheme.onSurface : AppColors.textDark),
          ),
        ),
        if (iconRight) ...[
          const SizedBox(width: 8),
          Icon(icon, size: 20),
        ],
      ],
    );
  }
}
