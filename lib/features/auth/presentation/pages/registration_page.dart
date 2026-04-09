import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/models/user_profile.dart';
import '../providers/auth_provider.dart';

class RegistrationPage extends ConsumerStatefulWidget {
  final String phoneNumber;

  const RegistrationPage({
    super.key,
    required this.phoneNumber,
  });

  @override
  ConsumerState<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends ConsumerState<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  // Name fields
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _patronymicController = TextEditingController();
  // Optional client profile fields
  final _workDirectionController = TextEditingController();
  final _socialNetworkController = TextEditingController();

  // State
  int _currentStep = 0;
  String? _workFormat; // 'group' or 'individual'
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _patronymicController.dispose();
    _workDirectionController.dispose();
    _socialNetworkController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);

      final currentUserId = authRepo.currentUserId;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Format phone number to +7 (xxx) xxx-xx-xx
      String formattedPhone = StringUtils.formatPhoneNumber(widget.phoneNumber);

      final profile = UserProfile(
        id: currentUserId,
        phone: formattedPhone,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        patronymic: _patronymicController.text.trim().isEmpty
            ? null
            : _patronymicController.text.trim(),
        role: 'patient', // Always patient, role selection removed
        education: null,
        workDirection: _workDirectionController.text.trim().isEmpty
            ? null
            : _workDirectionController.text.trim(),
        socialNetwork: _socialNetworkController.text.trim().isEmpty
            ? null
            : _socialNetworkController.text.trim(),
        workFormat: _workFormat,
      );

      await authRepo.createProfile(profile);

      // Force refresh data
      ref.invalidate(userProfileProvider);

      if (mounted) {
        context.go('/booking'); // Go to home
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка регистрации: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate required name fields
      if (_firstNameController.text.trim().isEmpty ||
          _lastNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Введите имя и фамилию')),
        );
        return;
      }
    }
    setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _currentStep == 0
              ? () async {
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) context.go('/phone-auth');
                }
              : _prevStep,
        ),
        title: const Text('Регистрация'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: (_currentStep + 1) / 2),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                backgroundColor: theme.scaffoldBackgroundColor,
                valueColor:
                    AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),

                      // Steps with Animation
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        layoutBuilder: (currentChild, previousChildren) {
                          return Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.2, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOut,
                                ),
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey(_currentStep),
                          child: _buildStepContent(theme),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: AppButton(
                text: _currentStep == 1 ? 'Завершить' : 'Далее',
                onPressed: _currentStep == 1 ? _handleRegistration : _nextStep,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(ThemeData theme) {
    if (_currentStep == 0) return _buildNameStep(theme);
    return _buildClientProfileStep(theme);
  }

  Widget _buildNameStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Как к вам обращаться?',
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Пожалуйста, вводите настоящие данные',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 32),
        AppTextField(
          controller: _firstNameController,
          label: 'Имя *',
          prefixIcon: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _lastNameController,
          label: 'Фамилия *',
          prefixIcon: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _patronymicController,
          label: 'Отчество (необязательно)',
          prefixIcon: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  Widget _buildClientProfileStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Дополнительная информация',
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Эти поля помогут нам лучше понять вас (необязательно)',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 32),
        AppTextField(
          controller: _workDirectionController,
          label: 'Направление работы (подход)',
          hint: 'Например: Психоанализ, КПТ, Гештальт',
          prefixIcon: Icons.work_outline,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _socialNetworkController,
          label: 'Соц.сеть или сайт',
          hint: 'Например: instagram.com/username',
          prefixIcon: Icons.link,
        ),
        const SizedBox(height: 24),
        Text(
          'Формат работы',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildWorkFormatCard(
                theme,
                'individual',
                'Индивидуальный',
                Icons.person,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildWorkFormatCard(
                theme,
                'group',
                'Групповой',
                Icons.groups,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Эти поля можно заполнить позже в настройках профиля',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkFormatCard(
    ThemeData theme,
    String value,
    String label,
    IconData icon,
  ) {
    final isSelected = _workFormat == value;
    return GestureDetector(
      onTap: () => setState(() => _workFormat = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? theme.colorScheme.primary : null,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
