import 'dart:io';
import 'dart:convert';

void main() async {
  const base64Png =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==';
  final bytes = base64Decode(base64Png);

  final file = File('assets/icons/transparent.png');
  await file.writeAsBytes(bytes);
}
