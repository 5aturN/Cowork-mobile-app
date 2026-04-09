import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../shared/widgets/app_logo.dart';
import 'welcome_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../booking/presentation/providers/booking_provider.dart';
import '../../../booking/presentation/providers/room_provider.dart';
import '../../../booking/domain/models/room.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _showSlowConnection = false;
  Timer? _slowConnectionTimer;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  @override
  void dispose() {
    _slowConnectionTimer?.cancel();
    super.dispose();
  }

  Future<void> _startLoading() async {
    // 1. Minimum Splash Display Time
    final minDelay = Future.delayed(const Duration(seconds: 2));

    // 2. Slow Connection Timer
    _slowConnectionTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _showSlowConnection = true);
      }
    });

    try {
      // 3. Preload Data & Assets
      // We don't await strictly immediately to let minDelay run in parallel
      await Future.wait([
        minDelay,
        _preloadAssets(),
      ]);
    } catch (e) {
      debugPrint('Preloading failed (offline?): $e');
      // If preloading fails, we still verify auth and proceed
      // Ensure min delay is met regardless of error
      await minDelay;
    } finally {
      _slowConnectionTimer?.cancel();
    }

    if (!mounted) return;

    // 4. Navigation Logic
    final authState = ref.read(authStateProvider);
    final isAuthenticated = authState.asData?.value.session != null;

    if (isAuthenticated) {
      context.go('/home');
    } else {
      context.go('/welcome');
    }
  }

  Future<void> _preloadAssets() async {
    final imagesToCache = <String>[];

    // 1. Always preload Welcome Image (it's the first thing seen if not auth)
    imagesToCache.add(WelcomePage.heroImageUrl);

    // 2. Check Auth for User Data
    final authState = ref.read(authStateProvider);
    if (authState.asData?.value.session != null) {
      try {
        // Parallel fetch of critical data for Home Page
        final results = await Future.wait([
          ref.read(userProfileProvider.future),
          ref.read(myBookingsProvider.future),
          ref
              .read(roomsProvider(DateTime.now()).future)
              .catchError((_) => <Room>[]), // Handle rooms error specifically
        ]);

        if (!mounted) return;

        final profile = results[0] as dynamic; // UserProfile?
        final bookings = results[1] as List<dynamic>; // List<Booking>
        final rooms = results[2] as List<dynamic>; // List<Room>

        // A. Profile Avatar
        if (profile?.avatarUrl != null) {
          imagesToCache.add(profile.avatarUrl!);
        }

        // B. Next Session Room Image
        final now = DateTime.now();
        final upcoming = bookings.where((b) {
          if (!b.isActive) return false;
          final end = b.dateTime.add(Duration(minutes: b.duration));
          return end.isAfter(now);
        }).toList();

        if (upcoming.isNotEmpty) {
          if (upcoming.first.roomImageUrl.isNotEmpty) {
            imagesToCache.add(upcoming.first.roomImageUrl);
          }
        }

        // C. Quick Book Rooms (Top 3)
        for (var room in rooms.take(3)) {
          if (room.imageUrl.isNotEmpty) {
            imagesToCache.add(room.imageUrl);
          }
        }
      } catch (e) {
        debugPrint('User data preload error: $e');
      }
    }

    // 3. Precache All Collected Images
    if (imagesToCache.isNotEmpty) {
      try {
        await Future.wait(
          imagesToCache.map((url) {
            return precacheImage(NetworkImage(url), context).catchError((e) {});
          }),
        );
      } catch (e) {
        debugPrint('Image precache error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Pure Black as requested
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: FadeIn(
              duration: const Duration(milliseconds: 800),
              child: const AppLogo(
                size: 40,
                showIcon: false,
                withBackground: true,
              ),
            ),
          ),
          if (_showSlowConnection)
            Positioned(
              bottom: 100,
              child: FadeInUp(
                child: Column(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white54),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Медленное соединение...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Загружаем данные',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
