// Basic smoke tests for the Nova Reader app.
//
// Verifies that the app builds and renders the home screen without crashing.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nova_reader/app.dart';

void main() {
  testWidgets('App builds and shows the home screen', (WidgetTester tester) async {
    // Provide mock SharedPreferences so the settings provider can initialize.
    SharedPreferences.setMockInitialValues({});

    // Build our app inside a ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: NovaReaderApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The home screen should render the app title.
    expect(find.text('Nova Reader'), findsWidgets);
  });
}
