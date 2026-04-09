import 'package:flutter/animation.dart';

/// Константы для анимаций приложения
class AppAnimations {
  // Durations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  // Curves
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve elasticOut = Curves.elasticOut;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;

  // Stagger delays
  static const Duration staggerDelay = Duration(milliseconds: 50);
  static const Duration listItemDelay = Duration(milliseconds: 100);

  // Page transitions
  static const Duration pageTransition = Duration(milliseconds: 350);
}
