// Basic smoke tests for the Nova Reader app.
//
// Verifies that the app builds and renders without crashing.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nova_reader/app.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    // Provide mock SharedPreferences so the settings provider can initialize.
    SharedPreferences.setMockInitialValues({});

    // Use a phone-sized surface so the layout fits.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    // Build our app inside a ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: NovaReaderApp(),
      ),
    );

    // The home screen has looping animations and periodic timers, so pump a
    // few frames instead of pumpAndSettle (which would time out).
    await tester.pump(const Duration(milliseconds: 100));

    // The home screen should render without crashing.
    expect(tester.takeException(), isNull);

    // Tear down the widget tree so the home screen's timers are cancelled.
    await tester.pumpWidget(const SizedBox.shrink());

    // Advance time past the home screen's periodic timers (15s/30s) so any
    // pending timers fire and are cleaned up before the test ends.
    await tester.pump(const Duration(seconds: 40));
  });
}
