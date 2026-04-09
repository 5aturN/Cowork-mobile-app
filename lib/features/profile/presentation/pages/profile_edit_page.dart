import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();

  // Name fields
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _patronymicController;

  // Optional client profile fields
  late final TextEditingController _workDirectionController;
  late final TextEditingController _socialNetworkController;

  String? _workFormat;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with current values
    final profile = ref.read(userProfileProvider).value;

    _firstNameController =
        TextEditingController(text: profile?.firstName ?? '');
    _lastNameController = TextEditingController(text: profile?.lastName ?? '');
    _patronymicController =
        TextEditingController(text: profile?.patronymic ?? '');
    _workDirectionController =
        TextEditingController(text: profile?.workDirection ?? '');
    _socialNetworkController =
        TextEditingController(text: profile?.socialNetwork ?? '');
    _workFormat = profile?.workFormat;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _patronymicController.dispose();
    _workDirectionController.dispose();
    _socialNetworkController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate required fields
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Имя и фамилия обязательны')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final currentProfile = ref.read(userProfileProvider).value;

      if (currentProfile == null) throw Exception('Profile not found');

      // Create updated profile
      final updatedProfile = currentProfile.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        patronymic: _patronymicController.text.trim().isEmpty
            ? null
            : _patronymicController.text.trim(),
        workDirection: _workDirectionController.text.trim().isEmpty
            ? null
            : _workDirectionController.text.trim(),
        socialNetwork: _socialNetworkController.text.trim().isEmpty
            ? null
            : _socialNetworkController.text.trim(),
        workFormat: _workFormat,
      );

      // Save to database
      await authRepo.createProfile(updatedProfile);

      // Refresh profile
      ref.invalidate(userProfileProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Профиль обновлен'),
          backgroundColor: Colors.green,
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сохранения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать профиль'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 100, // Extra padding to prevent nav bar overlap
          ),
          children: [
            Text(
              'Личные данные',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
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
              label: 'Отчество',
              prefixIcon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 32),
            Text(
              'Дополнительная информация',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Опциональные поля',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 32),
            AppButton(
              text: 'Сохранить',
              onPressed: _saveProfile,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
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
