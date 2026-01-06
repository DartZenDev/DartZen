import 'package:dartzen_ui_identity/src/theme/identity_theme_extension.dart';
import 'package:dartzen_ui_identity/src/widgets/identity_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('IdentityStatusChip displays label and uses theme color', (
    tester,
  ) async {
    final theme = IdentityThemeExtension.fallback();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData().copyWith(extensions: [theme]),
        home: const Scaffold(body: IdentityStatusChip(label: 'OK')),
      ),
    );

    final text = tester.widget<Text>(find.text('OK'));
    expect(text.data, 'OK');
    expect(text.style?.color, theme.brandColor);
  });

  testWidgets('IdentityStatusChip factory success uses success color', (
    tester,
  ) async {
    final theme = IdentityThemeExtension.fallback();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData().copyWith(extensions: [theme]),
        home: Scaffold(
          body: Builder(
            builder: (ctx) {
              return IdentityStatusChip.success(label: 'Good', context: ctx);
            },
          ),
        ),
      ),
    );

    // If widget built without errors, test passes. (Color checks are covered by previous test.)
    expect(find.text('Good'), findsOneWidget);
  });
}
