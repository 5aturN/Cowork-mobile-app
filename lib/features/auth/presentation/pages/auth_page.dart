import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/segmented_control.dart';

/// Экран авторизации (вход и регистрация)
class AuthPage extends StatefulWidget {
  final bool isLogin;

  const AuthPage({super.key, this.isLogin = true});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late int _selectedTab;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.isLogin ? 0 : 1;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isLogin => _selectedTab == 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Column(
        children: [
          // Hero Header
          _buildHeroHeader(size),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: Column(
                  children: [
                    // Segmented Control
                    SegmentedControl(
                      selectedIndex: _selectedTab,
                      tabs: const [
                        AppStrings.loginTitle,
                        AppStrings.registerTitle,
                      ],
                      onChanged: (index) {
                        setState(() {
                          _selectedTab = index;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email Field
                          AppTextField(
                            label: AppStrings.email,
                            hint: 'email@example.com',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            textInputAction: TextInputAction.next,
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          AppTextField(
                            label: AppStrings.password,
                            hint: '••••••••',
                            controller: _passwordController,
                            keyboardType: TextInputType.visiblePassword,
                            obscureText: true,
                            prefixIcon: Icons.lock_outline,
                            textInputAction: _isLogin
                                ? TextInputAction.done
                                : TextInputAction.next,
                            validator: _validatePassword,
                          ),

                          // Confirm Password Field (только для регистрации)
                          if (!_isLogin) ...[
                            const SizedBox(height: 20),
                            AppTextField(
                              label: AppStrings.confirmPassword,
                              hint: '••••••••',
                              controller: _confirmPasswordController,
                              keyboardType: TextInputType.visiblePassword,
                              obscureText: true,
                              prefixIcon: Icons.lock_outline,
                              textInputAction: TextInputAction.done,
                              validator: _validateConfirmPassword,
                            ),
                          ],

                          // Forgot Password (только для входа)
                          if (_isLogin) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // TODO: Forgot password logic
                                },
                                child: Text(
                                  AppStrings.forgotPassword,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Primary Action Button
                          AppButton(
                            text: _isLogin
                                ? AppStrings.loginButton
                                : AppStrings.registerButton,
                            icon: Icons.arrow_forward,
                            onPressed: _handleSubmit,
                            isLoading: _isLoading,
                            width: double.infinity,
                          ),

                          const SizedBox(height: 24),

                          // Divider
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'ИЛИ ЧЕРЕЗ',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.4),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),

                          const SizedBox(height: 24),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(Size size) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            CachedNetworkImage(
              imageUrl:
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuBE8jeiVFX0CbL2t55JznvJMDZ1b_jlD4JD3Y2l79AaXkQondelHUYluKzSIRzWuVXZUMCtdBBEMPbbdGCjM0jcTs7lvkHjKBJor21Q2hlt6Q7w7TQA6npiGi7nr4CcvhrJ3vNB3T6REuovibIJh2a1nIDBR0bWbrUjxxayrtpbXhzfS4CmOARj1Wyww_0nA9cDzYFOV19D7zxW9mo3EbL94aa__BgnkCrLzC_J-Ta30go3RQ0qyNg49ef2kgf3lkkXvC0t5ztJCGg',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppColors.backgroundDark,
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.grey800,
                      AppColors.grey900,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.backgroundDark.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),

            // Dark Overlay
            Container(
              color: AppColors.backgroundDark.withValues(alpha: 0.4),
            ),

            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.event_seat_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title
                    const Text(
                      'Бронирование\nКабинетов',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Subtitle
                    Text(
                      'Пространство для психологов',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.errorFieldRequired;
    }
    if (!value.contains('@') || !value.contains('.')) {
      return AppStrings.errorInvalidEmail;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.errorFieldRequired;
    }
    if (value.length < 6) {
      return AppStrings.errorPasswordTooShort;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.errorFieldRequired;
    }
    if (value != _passwordController.text) {
      return AppStrings.errorPasswordMismatch;
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      // TODO: Implement actual authentication logic with Supabase
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
