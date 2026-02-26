import 'package:dartzen_ui_admin/src/theme/admin_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminThemeExtension.fallback', () {
    test('provides non-null defaults', () {
      final theme = AdminThemeExtension.fallback();

      expect(theme.headerColor, const Color(0xFFE0E0E0));
      expect(theme.rowColor, const Color(0xFFFFFFFF));
      expect(theme.alternateRowColor, const Color(0xFFF5F5F5));
      expect(theme.actionColor, const Color(0xFF1565C0));
      expect(theme.dangerColor, const Color(0xFFC62828));
      expect(theme.surfaceColor, const Color(0xFFFFFFFF));
      expect(theme.onSurfaceColor, const Color(0xFF212121));
      expect(theme.titleStyle.fontSize, 24);
      expect(theme.titleStyle.color, const Color(0xFF212121));
      expect(theme.bodyStyle.fontSize, 14);
      expect(theme.bodyStyle.color, const Color(0xFF212121));
      expect(theme.containerPadding, const EdgeInsets.all(24.0));
      expect(theme.spacing, 16.0);
    });
  });

  group('copyWith', () {
    test('copies with overrides', () {
      final original = AdminThemeExtension.fallback();
      final copy = original.copyWith(
        headerColor: const Color(0xFF000000),
        spacing: 8.0,
      );

      expect(copy.headerColor, const Color(0xFF000000));
      expect(copy.spacing, 8.0);
      // Unchanged properties.
      expect(copy.rowColor, original.rowColor);
      expect(copy.dangerColor, original.dangerColor);
    });

    test('copies without changes when no args', () {
      final original = AdminThemeExtension.fallback();
      final copy = original.copyWith();

      expect(copy.headerColor, original.headerColor);
      expect(copy.spacing, original.spacing);
    });
  });

  group('lerp', () {
    test('interpolates between two themes at t=0', () {
      final a = AdminThemeExtension.fallback();
      final b = a.copyWith(headerColor: const Color(0xFF000000), spacing: 32.0);

      final result = a.lerp(b, 0.0);

      expect(result.headerColor, a.headerColor);
      expect(result.spacing, a.spacing);
    });

    test('interpolates between two themes at t=1', () {
      final a = AdminThemeExtension.fallback();
      final b = a.copyWith(headerColor: const Color(0xFF000000), spacing: 32.0);

      final result = a.lerp(b, 1.0);

      expect(result.headerColor, const Color(0xFF000000));
      expect(result.spacing, 32.0);
    });

    test('returns self when other is different type', () {
      final a = AdminThemeExtension.fallback();

      final result = a.lerp(null, 0.5);

      expect(result, same(a));
    });

    test('interpolates at midpoint', () {
      final a = AdminThemeExtension.fallback().copyWith(spacing: 0.0);
      final b = a.copyWith(spacing: 100.0);

      final result = a.lerp(b, 0.5);

      expect(result.spacing, 50.0);
    });
  });

  testWidgets('is accessible from ThemeData', (tester) async {
    final extension = AdminThemeExtension.fallback();

    late AdminThemeExtension? retrieved;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [extension]),
        home: Builder(
          builder: (context) {
            retrieved = Theme.of(context).extension<AdminThemeExtension>();
            return const SizedBox();
          },
        ),
      ),
    );

    expect(retrieved, isNotNull);
    expect(retrieved!.headerColor, extension.headerColor);
  });

  group('AdminThemeExtension.fromColorScheme', () {
    test('derives colors from light ColorScheme', () {
      final scheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
      final theme = AdminThemeExtension.fromColorScheme(scheme);

      expect(theme.headerColor, scheme.surfaceContainerHighest);
      expect(theme.rowColor, scheme.surface);
      expect(theme.alternateRowColor, scheme.surfaceContainerLow);
      expect(theme.actionColor, scheme.primary);
      expect(theme.dangerColor, scheme.error);
      expect(theme.surfaceColor, scheme.surface);
      expect(theme.onSurfaceColor, scheme.onSurface);
      expect(theme.titleStyle.color, scheme.onSurface);
      expect(theme.bodyStyle.color, scheme.onSurface);
    });

    test('derives colors from dark ColorScheme', () {
      final scheme = ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.dark,
      );
      final theme = AdminThemeExtension.fromColorScheme(scheme);

      expect(theme.headerColor, scheme.surfaceContainerHighest);
      expect(theme.surfaceColor, scheme.surface);
      expect(theme.onSurfaceColor, scheme.onSurface);
      expect(theme.dangerColor, scheme.error);
    });
  });
}
