import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caller_id_app/overlay_window.dart';

void main() {
  testWidgets('CallerOverlayWindow smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CallerOverlayWindow(),
      ),
    );

    // Initial state shows search or indicator
    expect(find.byType(CallerOverlayWindow), findsOneWidget);
  });
}

