import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/storage_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/push_notification_service.dart';
import 'features/cart/presentation/widgets/global_cart_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация локального хранилища
  await StorageService.init();

  // Инициализация форматирования дат
  await initializeDateFormatting('ru_RU', null);

  // Инициализация Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Инициализация Push-уведомлений (FCM)
  await PushNotificationService.initialize();

  // Настройка ориентации - только портретная
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Настройка системного UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: SecretaireApp(),
    ),
  );
}

class SecretaireApp extends ConsumerWidget {
  const SecretaireApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    final accentColor = ref.watch(appAccentColorProvider);
    final isAdaptiveEnabled = ref.watch(adaptiveThemeEnabledProvider);

    // If adaptive is enabled, use AdaptiveTheme. If not, use state from themeProvider (simple approach: sync both)
    // Actually, AdaptiveTheme wraps MaterialApp usually.
    // The previous main.dart structure (Step 3127) did NOT use AdaptiveTheme wrapper, it just passed themeMode.
    // The previous edit (Step 2911) removed AdaptiveTheme wrapper because I used a custom ThemeProvider.
    // I should stick to that customized simple approach unless requested otherwise.
    // BUT the snippet above imports `adaptive_theme` and uses `savedThemeMode`.
    // `main.dart` in Step 3127 DOES NOT import `adaptive_theme` nor pass `savedThemeMode`. It uses `ref.watch(themeProvider)`.

    // I must stick to the EXISTING structure of `main.dart` from Step 3127 and ONLY Add `PushNotificationService`.

    return MaterialApp.router(
      title: 'Secretaire',
      debugShowCheckedModeBanner: false,

      // Темы
      theme: AppTheme.lightTheme(isAdaptiveEnabled ? accentColor : null),
      darkTheme: AppTheme.darkTheme(isAdaptiveEnabled ? accentColor : null),
      themeMode: themeMode,

      // Локализация
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
      ],

      // Роутер
      routerConfig: router,
      builder: (context, child) => GlobalCartObserver(child: child!),
    );
  }
}
