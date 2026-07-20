import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cek_label/main.dart';
import 'package:cek_label/services/theme_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final themeProvider = ThemeProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: themeProvider,
        child: const CekLabelApp(showOnboarding: false),
      ),
    );

    // Verify app renders (no crash)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
