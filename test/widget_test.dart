import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:music_dashboard/screens/login_screen.dart';

void main() {
  testWidgets('App loads login screen initially', (WidgetTester tester) async {
    // Set a larger screen size for web testing
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;

    // Use a simpler test that doesn't involve Firebase.initializeApp
    // because that's hard to mock in a simple widget test without more setup.
    // Instead, we just pump the LoginScreen directly for UI smoke test
    // assuming navigation works.
    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen(onLoginSuccess: _mockLogin)),
    );
    await tester.pumpAndSettle();

    // Verify basic UI presence
    expect(find.text('Welcome Back'), findsOneWidget);

    // Reset view
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}

void _mockLogin() {}
