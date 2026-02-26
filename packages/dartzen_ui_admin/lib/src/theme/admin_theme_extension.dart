import 'package:flutter/material.dart';

/// Theme extension for DartZen Admin UI components.
///
/// Allows configuring colors, text styles, and spacing
/// specific to admin list, form, and dialog screens.
///
/// Use [AdminThemeExtension.fromColorScheme] to derive all
/// values from a Material [ColorScheme], which ensures proper
/// light/dark adaptation and WCAG 2.1 contrast compliance.
class AdminThemeExtension extends ThemeExtension<AdminThemeExtension> {
  /// Background color for table headers.
  final Color headerColor;

  /// Background color for table rows.
  final Color rowColor;

  /// Background color for alternating table rows.
  final Color alternateRowColor;

  /// Color for action buttons (edit, create).
  final Color actionColor;

  /// Color for destructive actions (delete).
  final Color dangerColor;

  /// Background / card surface color.
  final Color surfaceColor;

  /// Foreground color for text on the [surfaceColor] background.
  final Color onSurfaceColor;

  /// Text style for screen titles.
  final TextStyle titleStyle;

  /// Text style for table body text.
  final TextStyle bodyStyle;

  /// Padding for standard containers.
  final EdgeInsetsGeometry containerPadding;

  /// Spacing between UI elements.
  final double spacing;

  const AdminThemeExtension({
    required this.headerColor,
    required this.rowColor,
    required this.alternateRowColor,
    required this.actionColor,
    required this.dangerColor,
    required this.surfaceColor,
    required this.onSurfaceColor,
    required this.titleStyle,
    required this.bodyStyle,
    this.containerPadding = const EdgeInsets.all(24.0),
    this.spacing = 16.0,
  });

  /// Derives all values from the given [ColorScheme].
  ///
  /// This ensures the admin UI adapts to both light and dark
  /// mode and passes WCAG 2.1 contrast requirements.
  factory AdminThemeExtension.fromColorScheme(ColorScheme scheme) {
    return AdminThemeExtension(
      headerColor: scheme.surfaceContainerHighest,
      rowColor: scheme.surface,
      alternateRowColor: scheme.surfaceContainerLow,
      actionColor: scheme.primary,
      dangerColor: scheme.error,
      surfaceColor: scheme.surface,
      onSurfaceColor: scheme.onSurface,
      titleStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: scheme.onSurface,
      ),
      bodyStyle: TextStyle(fontSize: 14, height: 1.4, color: scheme.onSurface),
    );
  }

  /// Provides sensible light-mode defaults with WCAG-compliant
  /// contrast ratios.
  ///
  /// Prefer [fromColorScheme] to support both light and dark mode.
  factory AdminThemeExtension.fallback() => const AdminThemeExtension(
    headerColor: Color(0xFFE0E0E0),
    rowColor: Color(0xFFFFFFFF),
    alternateRowColor: Color(0xFFF5F5F5),
    actionColor: Color(0xFF1565C0),
    dangerColor: Color(0xFFC62828),
    surfaceColor: Color(0xFFFFFFFF),
    onSurfaceColor: Color(0xFF212121),
    titleStyle: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Color(0xFF212121),
    ),
    bodyStyle: TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF212121)),
  );

  @override
  AdminThemeExtension copyWith({
    Color? headerColor,
    Color? rowColor,
    Color? alternateRowColor,
    Color? actionColor,
    Color? dangerColor,
    Color? surfaceColor,
    Color? onSurfaceColor,
    TextStyle? titleStyle,
    TextStyle? bodyStyle,
    EdgeInsetsGeometry? containerPadding,
    double? spacing,
  }) {
    return AdminThemeExtension(
      headerColor: headerColor ?? this.headerColor,
      rowColor: rowColor ?? this.rowColor,
      alternateRowColor: alternateRowColor ?? this.alternateRowColor,
      actionColor: actionColor ?? this.actionColor,
      dangerColor: dangerColor ?? this.dangerColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      onSurfaceColor: onSurfaceColor ?? this.onSurfaceColor,
      titleStyle: titleStyle ?? this.titleStyle,
      bodyStyle: bodyStyle ?? this.bodyStyle,
      containerPadding: containerPadding ?? this.containerPadding,
      spacing: spacing ?? this.spacing,
    );
  }

  @override
  AdminThemeExtension lerp(
    covariant ThemeExtension<AdminThemeExtension>? other,
    double t,
  ) {
    if (other is! AdminThemeExtension) return this;
    return AdminThemeExtension(
      headerColor: Color.lerp(headerColor, other.headerColor, t)!,
      rowColor: Color.lerp(rowColor, other.rowColor, t)!,
      alternateRowColor: Color.lerp(
        alternateRowColor,
        other.alternateRowColor,
        t,
      )!,
      actionColor: Color.lerp(actionColor, other.actionColor, t)!,
      dangerColor: Color.lerp(dangerColor, other.dangerColor, t)!,
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t)!,
      onSurfaceColor: Color.lerp(onSurfaceColor, other.onSurfaceColor, t)!,
      titleStyle: TextStyle.lerp(titleStyle, other.titleStyle, t)!,
      bodyStyle: TextStyle.lerp(bodyStyle, other.bodyStyle, t)!,
      containerPadding: EdgeInsetsGeometry.lerp(
        containerPadding,
        other.containerPadding,
        t,
      )!,
      spacing: _lerpDouble(spacing, other.spacing, t),
    );
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}
