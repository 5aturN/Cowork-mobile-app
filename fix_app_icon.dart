import 'dart:io';
import 'package:image/image.dart';

void main() async {
  // 1. Load original icon
  final iconFile = File('assets/icons/app_icon.png');
  if (!iconFile.existsSync()) {
    return;
  }

  final original = decodeImage(iconFile.readAsBytesSync());
  if (original == null) {
    return;
  }

  // 2. Create new canvas (Foreground) - Standard 1024x1024 or 512x512
  // We'll match original size
  final size = original.width;
  final padded = Image(width: size, height: size); // Transparent by default

  // 3. Scale down original to 65% (Safe zone is approx 66% diameter)
  // We'll use 75% to be safe and elegant (User requested Zoom Out further)
  const scale = 0.75;
  final newWidth = (size * scale).round();
  final newHeight = (size * scale).round();

  final resized = copyResize(
    original,
    width: newWidth,
    height: newHeight,
    interpolation: Interpolation.cubic,
  );

  // 4. Center it
  final x = (size - newWidth) ~/ 2;
  final y = (size - newHeight) ~/ 2;

  compositeImage(padded, resized, dstX: x, dstY: y);

  // 5. Save as app_icon_foreground.png
  final foregroundFile = File('assets/icons/app_icon_foreground.png');
  await foregroundFile.writeAsBytes(encodePng(padded));

  // 6. Creating Background color image just in case or we use hex in pubspec
  // We'll assume background is #1E1E1E based on app theme
}
