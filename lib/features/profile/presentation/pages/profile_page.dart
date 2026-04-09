import 'dart:io';
import 'package:palette_generator/palette_generator.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/user_profile_extensions.dart';

/// Экран профиля пользователя
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isUploading = false;
  PaletteGenerator? _paletteGenerator;
  String? _lastAvatarUrl;

  Future<void> _updatePalette(String url) async {
    if (_lastAvatarUrl == url && _paletteGenerator != null) return;
    _lastAvatarUrl = url;

    try {
      final palette = await PaletteGenerator.fromImageProvider(
        ResizeImage(CachedNetworkImageProvider(url), width: 100, height: 100),
        maximumColorCount: 10,
      );
      if (mounted) {
        setState(() => _paletteGenerator = palette);

        final color = palette.darkVibrantColor?.color ??
            palette.vibrantColor?.color ??
            palette.dominantColor?.color ??
            AppColors.primary;

        ref.read(appAccentColorProvider.notifier).setColor(color);
      }
    } catch (e) {
      debugPrint('Palette gen error: $e');
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final userId = ref.read(authRepositoryProvider).currentUserId;
      if (userId == null) throw Exception('No user found');

      final file = File(pickedFile.path);
      // Upload
      final publicUrl =
          await ref.read(authRepositoryProvider).uploadAvatar(file, userId);

      // Update Profile
      final currentProfile = ref.read(userProfileProvider).value;
      if (currentProfile != null) {
        final updatedProfile = currentProfile.copyWith(avatarUrl: publicUrl);
        await ref.read(authRepositoryProvider).createProfile(updatedProfile);

        // Trigger palette update immediately
        _updatePalette(publicUrl);
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Аватар обновлен')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProfileAsync = ref.watch(userProfileProvider);
    final globalAccentColor = ref.watch(appAccentColorProvider);

    final userName = userProfileAsync.value?.fullName ?? 'Пользователь';
    final phoneNumber = userProfileAsync.value?.phone ?? '';
    final avatarUrl = userProfileAsync.value?.avatarUrl;

    // Trigger palette update if needed
    if (avatarUrl != null &&
        globalAccentColor == null &&
        avatarUrl != _lastAvatarUrl &&
        _paletteGenerator == null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _updatePalette(avatarUrl));
    }

    // Determine Color
    Color bgColor = globalAccentColor ?? AppColors.primary;
    if (_paletteGenerator != null && avatarUrl != null) {
      // Pick a color: Dark Vibrant preferred for white text, then Vibrant, then Dominant
      bgColor = _paletteGenerator?.darkVibrantColor?.color ??
          _paletteGenerator?.vibrantColor?.color ??
          _paletteGenerator?.dominantColor?.color ??
          bgColor;
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // Header with avatar
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  bgColor,
                  bgColor.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Header with Avatar & Basic Info
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Avatar Section
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: bgColor.withValues(alpha: 0.3),
                                width: 4,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: bgColor.withValues(alpha: 0.1),
                              backgroundImage: avatarUrl != null
                                  ? CachedNetworkImageProvider(avatarUrl)
                                  : null,
                              child: avatarUrl == null
                                  ? Icon(
                                      Icons.person,
                                      size: 60,
                                      color: bgColor,
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: _pickAndUploadImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.scaffoldBackgroundColor,
                                    width: 2,
                                  ),
                                ),
                                child: _isUploading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors
                              .white, // Ensure text is visible on colored background
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phoneNumber,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white
                              .withValues(alpha: 0.8), // Ensure text is visible
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Edit Profile Button
                      OutlinedButton.icon(
                        onPressed: () => context.push('/profile/edit'),
                        icon: const Icon(Icons.edit_outlined,
                            color: Colors.white),
                        label: const Text(
                          'Редактировать профиль',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: SafeArea(
                    child: IconButton(
                      onPressed: () {
                        context.go('/profile/settings');
                      },
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        shape: const CircleBorder(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Personal Info Section
          _buildSection(
            theme,
            'Персональная информация',
            [
              _buildListTile(
                theme,
                Icons.person_outline,
                'Имя',
                userName,
                onTap: () {
                  // TODO: Edit name
                },
              ),
              _buildListTile(
                theme,
                Icons.phone_outlined,
                'Телефон',
                phoneNumber,
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Выйти'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Call Supabase SignOut via Repository
      await ref.read(authRepositoryProvider).signOut();
      await StorageService.logout(); // Clear local prefs too just in case
      // Router will handle redirect automatically due to authStateProvider listener
    }
  }

  Widget _buildSection(ThemeData theme, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? AppColors.grey800
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile(
    ThemeData theme,
    IconData icon,
    String title,
    String? subtitle, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null && subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }
}
