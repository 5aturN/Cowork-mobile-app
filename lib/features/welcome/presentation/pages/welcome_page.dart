import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_logo.dart';

/// Экран приветствия (Welcome/Onboarding Screen)
class WelcomePage extends StatelessWidget {
  static const heroImageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCqNI4ROCJfH05qkPI73IneiyrisgcvurI7DwgW_lVaWQjUfIGmkrIp6ChNF4yIw5xPBhKRIcVkpZMlNcXIPqvdR9nsKNvgKU4Y2gUmFSQQVumq90IpOGsTHaL1rXj5Okn-VjlVC-qgYPtEdPTmiZdPh3JR-pMGH0DCKQC6iEDdaGHL3q4ZTnBQM-nK7xeIO9XAkz6g7CVDpPh92a2namSJDwsCslWjSVqEl2Q31eJoyTCabelMqnFJNjUp-8W-zdx4r37OkQYv0ac';

  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Логотип сверху
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: AppLogo(size: 28, showIcon: false),
            ),

            // Основной контент (прокручиваемый)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Hero Image с градиентом
                    _buildHeroImage(size, theme),
                    const SizedBox(height: 16),

                    // Заголовок
                    Text(
                      AppStrings.welcomeTitle,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Подзаголовок
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        AppStrings.welcomeSubtitle,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Кнопка "Начать"
                    AppButton(
                      text: AppStrings.welcomeButtonText,
                      icon: Icons.arrow_forward,
                      onPressed: () {
                        context.go('/phone-auth');
                      },
                      width: double.infinity,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage(Size size, ThemeData theme) {
    return Container(
      width: double.infinity,
      height: size.height * 0.45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Основное изображение
            Image.network(
              WelcomePage.heroImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if image fails to load
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.grey700,
                        AppColors.grey800,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: AppColors.grey500,
                    ),
                  ),
                );
              },
            ),

            // Градиентный оверлей снизу
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.backgroundDark.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
            ),

            // Декоративный оверлей с primary цветом
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
