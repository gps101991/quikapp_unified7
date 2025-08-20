// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quikapp_unified6/module/myapp.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const MyApp(
        webUrl: 'https://example.com',
        isBottomMenu: false,
        isSplash: false,
        splashLogo: '',
        splashBg: '',
        splashDuration: 1,
        splashAnimation: 'fade',
        bottomMenuItems: '[]',
        isDomainUrl: false,
        backgroundColor: '#FFFFFF',
        activeTabColor: '#000000',
        textColor: '#000000',
        iconColor: '#000000',
        iconPosition: 'above',
        taglineColor: '#000000',
        spbgColor: '#FFFFFF',
        isLoadIndicator: false,
        splashTagline: '',
        taglineFont: 'Roboto',
        taglineSize: 16.0,
        taglineBold: false,
        taglineItalic: false,
      ),
    );

    // Verify that our app loads without crashing
    expect(find.byType(MyApp), findsOneWidget);

    // Wait for any async operations to complete
    await tester.pumpAndSettle();

    // Verify the app is still running
    expect(find.byType(MyApp), findsOneWidget);
  });
}
