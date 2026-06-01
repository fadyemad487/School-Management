import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wecircle/main.dart';

void main() {
  testWidgets('App launches correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const WeCircleApp(initialLang: 'ar', initialTheme: 'light'));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
