import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modiin4u/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App launches and leaves the splash screen', (tester) async {
    SharedPreferences.setMockInitialValues({'has_seen_onboarding': false});

    await tester.pumpWidget(const ProviderScope(child: Modiin4uApp()));
    expect(find.byType(MaterialApp), findsOneWidget);

    // Splash waits 2.2s before routing on to onboarding.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
