import 'dart:io';
import 'package:image/image.dart';

void main() async {
  // Create a 100x100 transparent image
  final image =
      Image(width: 100, height: 100); // Default is transparent (0,0,0,0)

  // Save it
  final pngBytes = encodePng(image);
  final file = File('assets/icons/transparent_large.png');
  await file.writeAsBytes(pngBytes);
}
