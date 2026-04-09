import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/cart/presentation/providers/cart_provider.dart';
import 'glass_bottom_nav_bar.dart';

class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  final Widget child;

  const ScaffoldWithNavBar({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/booking')) return 1;
    if (location.startsWith('/cart')) return 2;
    if (location.startsWith('/wallet')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/booking');
        break;
      case 2:
        context.go('/cart');
        break;
      case 3:
        context.go('/wallet');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int currentIndex = _calculateSelectedIndex(context);
    // Watch cart provider for badge count
    final cartItems = ref.watch(cartProvider);

    // Using Stack to maintain GlassBottomNavBar floating effect
    return Scaffold(
      extendBody: true, // Important for glass effect
      body: Stack(
        children: [
          // Child with transition
          _buildTransition(context, widget.child, currentIndex),

          // Persistent Floating Navbar
          GlassBottomNavBar(
            currentIndex: currentIndex,
            onTap: (index) => _onItemTapped(index, context),
            cartItemCount: cartItems.length,
          ),
        ],
      ),
    );
  }

  // Custom Transition Logic
  Widget _buildTransition(
    BuildContext context,
    Widget child,
    int currentIndex,
  ) {
    // AnimatedSwitcher causing Duplicate GlobalKey issues with ShellRoute's Navigator.
    // Returning child directly for stability.
    return child;
  }
}
