import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_animations.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';

/// Экран входа по номеру телефона
class PhoneAuthPage extends ConsumerStatefulWidget {
  const PhoneAuthPage({super.key});

  @override
  ConsumerState<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends ConsumerState<PhoneAuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  final _phoneMask = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {'#': RegExp(r'[0-9]')},
  );

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final phone = _phoneController.text;

    try {
      final authRepo = ref.read(authRepositoryProvider);

      // 1. Sign In (Create Auth User)
      final userId = await authRepo.signInWithPhone(phone);

      // 2. Check if Profile Exists
      final profile = await authRepo.getUserProfile(userId);

      if (mounted) {
        setState(() => _isLoading = false);

        if (profile != null &&
            profile.name != null &&
            profile.name!.isNotEmpty) {
          // Profile exists and is complete -> Go Home
          // Update local cache if needed, but we rely on remote mostly now
          await StorageService.saveAuthData(
            phoneNumber: phone,
            userName: profile.name,
          );
          if (mounted) context.go('/booking');
        } else {
          // Profile missing -> Go Registration
          context.push('/registration', extra: phone);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка входа: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Hero header
              _buildHeroHeader(size),

              const SizedBox(height: 40),

              // Form
              FadeInUp(
                duration: AppAnimations.slow,
                delay: const Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title
                        Text(
                          'Войти в аккаунт',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Введите номер телефона для входа',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        // Phone field
                        FadeInUp(
                          duration: AppAnimations.normal,
                          delay: const Duration(milliseconds: 300),
                          child: AppTextField(
                            controller: _phoneController,
                            label: 'Номер телефона',
                            hint: '+7 (___) ___-__-__',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [_phoneMask],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Введите номер телефона';
                              }
                              final numbers =
                                  StringUtils.cleanPhoneNumber(value);
                              if (numbers.length < 11) {
                                return 'Введите полный номер телефона';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Login button
                        FadeInUp(
                          duration: AppAnimations.normal,
                          delay: const Duration(milliseconds: 400),
                          child: AppButton(
                            text: 'Войти',
                            onPressed: _handleLogin,
                            isLoading: _isLoading,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Info text
                        FadeInUp(
                          duration: AppAnimations.normal,
                          delay: const Duration(milliseconds: 500),
                          child: Text(
                            'При входе вы соглашаетесь с условиями\nиспользования и политикой конфиденциальности',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(Size size) {
    return FadeInDown(
      duration: AppAnimations.slow,
      child: Container(
        height: size.height * 0.35,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.8),
              AppColors.primary,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Pattern overlay
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: CustomPaint(
                  painter: _DotPatternPainter(),
                ),
              ),
            ),

            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_android_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Secretaire',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Бронирование кабинетов',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Painter for dot pattern
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
