// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolekt/screens/sign_in_screen.dart';

void main() {
  testWidgets('shows the nOVa sign-in screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SignInScreen()),
    );

    expect(find.text('Se connecter'), findsWidgets);
    expect(find.text('Créer un compte'), findsOneWidget);
  });
}
