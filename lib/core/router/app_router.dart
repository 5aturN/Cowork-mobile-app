import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/welcome/presentation/pages/welcome_page.dart';
import '../../features/welcome/presentation/pages/splash_page.dart';
import '../../features/welcome/presentation/pages/loading_page.dart';
import '../../features/auth/presentation/pages/phone_auth_page.dart';
import '../../features/auth/presentation/pages/registration_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/booking/presentation/pages/cabinet_detail_page.dart';
import '../../features/booking/domain/models/room.dart';
import '../../features/booking/presentation/pages/booking_page.dart';
import '../../features/booking/presentation/pages/my_bookings_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/cart/presentation/pages/payment_success_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/notifications_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';
import '../../features/wallet/presentation/pages/wallet_history_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/profile_edit_page.dart';
import '../../features/profile/presentation/pages/settings_page.dart';

import '../../shared/widgets/scaffold_with_nav_bar.dart';

/// Провайдер для GoRouter
final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

  // Watch auth state
  final authState = ref.watch(authStateProvider);
  final session = authState.asData?.value.session;
  final isAuthenticated = session != null;

  // Watch profile state to gate access (Only listen to completeness changes)
  final hasCompleteProfile = ref.watch(
    userProfileProvider.select((asyncValue) {
      final profile = asyncValue.asData?.value;
      // Check new firstName and lastName fields instead of deprecated name field
      return profile != null &&
          profile.firstName != null &&
          profile.firstName!.isNotEmpty &&
          profile.lastName != null &&
          profile.lastName!.isNotEmpty;
    }),
  );

  // Watch loading state
  final isProfileLoading =
      ref.watch(userProfileProvider.select((v) => v.isLoading));

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: '/phone-auth',
        builder: (context, state) => const PhoneAuthPage(),
      ),
      GoRoute(
        path: '/registration',
        builder: (context, state) {
          // Try extra first, then query param
          String? phone = state.extra as String?;
          phone ??= state.uri.queryParameters['phone'];
          return RegistrationPage(phoneNumber: phone ?? '');
        },
      ),
      // Shell Route for Floating Bottom Nav
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              transitionDuration: const Duration(milliseconds: 150),
              reverseTransitionDuration: const Duration(milliseconds: 150),
              child: const HomePage(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
          GoRoute(
            path: '/my-bookings',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              transitionDuration: const Duration(milliseconds: 150),
              reverseTransitionDuration: const Duration(milliseconds: 150),
              child: const MyBookingsPage(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
          GoRoute(
            path: '/booking',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              transitionDuration: const Duration(milliseconds: 150),
              reverseTransitionDuration: const Duration(milliseconds: 150),
              child: const BookingPage(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
            routes: [
              GoRoute(
                path: 'detail',
                builder: (context, state) {
                  final room = state.extra as Room;
                  return CabinetDetailPage(room: room);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/cart',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              transitionDuration: const Duration(milliseconds: 150),
              reverseTransitionDuration: const Duration(milliseconds: 150),
              child: const CartPage(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
          GoRoute(
            path: '/wallet',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              transitionDuration: const Duration(milliseconds: 150),
              reverseTransitionDuration: const Duration(milliseconds: 150),
              child: const WalletPage(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
            routes: [
              GoRoute(
                path: 'history',
                builder: (context, state) => const WalletHistoryPage(),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              transitionDuration: const Duration(milliseconds: 150),
              reverseTransitionDuration: const Duration(milliseconds: 150),
              child: const ProfilePage(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => const ProfileEditPage(),
              ),
              GoRoute(
                path: 'settings',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/loading',
        builder: (context, state) => const LoadingPage(),
      ),
      GoRoute(
        path: '/payment-success',
        builder: (context, state) => const PaymentSuccessPage(),
      ),
    ],
    redirect: (context, state) {
      final isGoingToAuth = state.matchedLocation == '/welcome' ||
          state.matchedLocation == '/phone-auth' ||
          state.matchedLocation == '/registration';

      // 0. Splash - Always allow
      if (state.matchedLocation == '/splash') return null;

      // 1. Unauthenticated -> Block access to protected routes
      if (!isAuthenticated) {
        if (!isGoingToAuth) return '/welcome';
        return null;
      }

      // 2. Authenticated -> Check Profile Completeness
      // If profile is loading, show loading screen to prevent flash of protected content
      if (isProfileLoading) {
        if (state.matchedLocation == '/loading') return null;
        return '/loading';
      }

      if (!hasCompleteProfile) {
        // If incomplete, Force Registration
        if (state.matchedLocation == '/registration') return null;

        String phone = session.user.phone ?? '';
        if (phone.isEmpty && session.user.email != null) {
          final email = session.user.email!;
          if (email.endsWith('@example.com')) {
            final cleanPhone = email.split('@').first;
            phone = '+$cleanPhone';
          }
        }
        return '/registration?phone=$phone';
      }

      // 3. Authenticated & Complete Profile -> Redirect away from auth pages
      if (isGoingToAuth || state.matchedLocation == '/loading') {
        return '/home';
      }

      return null;
    },
  );
});
