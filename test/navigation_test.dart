// Navigation smoke tests for the Nova Reader app.
//
// Verifies that the wired-up screens are reachable via the router.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nova_reader/app.dart';
import 'package:nova_reader/screens/library/library_screen.dart';
import 'package:nova_reader/screens/scanner/scanner_screen.dart';
import 'package:nova_reader/screens/cafe/cafe_screen.dart';
import 'package:nova_reader/screens/fireplace/fireplace_screen.dart';
import 'package:nova_reader/screens/converter/converter_screen.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(
        child: NovaReaderApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> teardown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 40));
  }

  // Navigate using a context inside the MaterialApp.router, then pump enough
  // frames for the route transition to complete.
  Future<void> goTo(WidgetTester tester, String route) async {
    final context = tester.element(find.byType(Scaffold).first);
    GoRouter.of(context).go(route);
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('Library screen is reachable', (WidgetTester tester) async {
    await pumpApp(tester);
    await goTo(tester, '/library');
    expect(find.byType(LibraryScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await teardown(tester);
  });

  testWidgets('Scanner screen is reachable', (WidgetTester tester) async {
    await pumpApp(tester);
    await goTo(tester, '/scanner');
    expect(find.byType(ScannerScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await teardown(tester);
  });

  testWidgets('Cafe screen is reachable', (WidgetTester tester) async {
    await pumpApp(tester);
    await goTo(tester, '/cafe');
    expect(find.byType(CafeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await teardown(tester);
  });

  testWidgets('Fireplace screen is reachable', (WidgetTester tester) async {
    await pumpApp(tester);
    await goTo(tester, '/fireplace');
    expect(find.byType(FireplaceScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await teardown(tester);
  });

  testWidgets('Converter screen is reachable', (WidgetTester tester) async {
    await pumpApp(tester);
    await goTo(tester, '/converter');
    expect(find.byType(ConverterScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await teardown(tester);
  });
}
