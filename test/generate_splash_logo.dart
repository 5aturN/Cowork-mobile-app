import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secretaire/shared/widgets/app_logo.dart';

void main() {
  testWidgets('Generate Splash Logo PNG', (WidgetTester tester) async {
    debugPrint('Starting Splash Logo Generation...');

    // 1. Define the widget to capture
    const double logoSize = 120.0; // Increased size for better quality

    // Create the widget wrapped in RepaintBoundary
    final widget = MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: RepaintBoundary(
            child: Theme(
              data: ThemeData.dark().copyWith(
                scaffoldBackgroundColor: const Color(0xFF1E1E1E),
                // Force basic font to avoid GoogleFonts network timeout in test environment
                textTheme:
                    Typography.material2021().white.apply(fontFamily: ''),
              ),
              child: const AppLogo(
                size: logoSize,
                showIcon: false,
                withBackground: true,
              ),
            ),
          ),
        ),
      ),
    );

    // 2. Pump widget
    debugPrint('Pumping widget...');
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
    debugPrint('Widget pumped.');

    // 3. Find RenderRepaintBoundary
    final boundary = tester
        .firstRenderObject<RenderRepaintBoundary>(find.byType(RepaintBoundary));

    // 4. Convert to Image
    debugPrint('Converting to image...');
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    // 5. Save to file
    final file = File('assets/images/splash_logo_generated.png');
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    await file.writeAsBytes(pngBytes);

    debugPrint(
      'Successfully generated assets/images/splash_logo_generated.png (${pngBytes.length} bytes)',
    );
  });
}
