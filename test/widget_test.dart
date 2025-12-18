// Test dasar untuk aplikasi Azan Indonesia

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:azan/main.dart';

void main() {
  testWidgets('Azan app should load home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AzanApp());

    // Verify that the app loads
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
