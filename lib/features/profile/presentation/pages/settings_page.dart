import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = true;
  String _appVersion = '';
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = StorageService.notificationsEnabled;
    _initNotifications();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    }
  }

  Future<void> _initNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);

    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'test_channel_id',
      'Test Channel',
      description: 'For testing push notifications',
      importance: Importance.max,
    );

    await androidImplementation?.createNotificationChannel(channel);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final adaptiveEnabled = ref.watch(adaptiveThemeEnabledProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Настройки',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            theme,
            'Основные',
            [
              _buildSwitchTile(
                theme,
                Icons.notifications_outlined,
                'Уведомления',
                _notificationsEnabled,
                (value) {
                  setState(() => _notificationsEnabled = value);
                  StorageService.setNotificationsEnabled(value);
                },
              ),
              _buildSwitchTile(
                theme,
                Icons.color_lens_outlined,
                'Адаптивные цвета',
                adaptiveEnabled,
                (value) {
                  ref
                      .read(adaptiveThemeEnabledProvider.notifier)
                      .setEnabled(value);
                },
              ),
              _buildSwitchTile(
                theme,
                Icons.dark_mode_outlined,
                'Темная тема',
                isDark,
                (value) {
                  ref.read(themeProvider.notifier).toggleTheme(value);
                },
              ),
              _buildListTile(
                theme,
                Icons.language_outlined,
                'Язык',
                'Русский',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            theme,
            'Помощь',
            [
              _buildListTile(
                theme,
                Icons.help_outline,
                'Помощь и поддержка',
                '',
                onTap: () {},
              ),
              _buildListTile(
                theme,
                Icons.info_outlined,
                'О приложении',
                _appVersion,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? AppColors.grey800
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
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
      leading: Icon(icon, color: theme.colorScheme.onSurface),
      title: Text(title, style: theme.textTheme.bodyLarge),
      subtitle: subtitle != null && subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    ThemeData theme,
    IconData icon,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      secondary: Icon(icon, color: theme.colorScheme.onSurface),
      title: Text(title, style: theme.textTheme.bodyLarge),
      value: value,
      onChanged: onChanged,
      activeThumbColor: theme.colorScheme.primary,
    );
  }
}
