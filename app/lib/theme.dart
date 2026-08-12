import 'package:flutter/material.dart';

/// Radius scale for panels and controls (soft 12–20 px corners).
const double radiusSm = 12;
const double panelRadius = 16;
const double radiusLg = 20;

/// Design tokens for the dark developer-tool theme.
///
/// Exposed as a [ThemeExtension] so widgets can read them via `AppColors.of(context)`.
class AppColors extends ThemeExtension<AppColors> {
  // canvas + surfaces
  final Color canvas;
  final Color surface;
  final Color surfaceRaised;
  final Color hairline;
  // text
  final Color textPrimary;
  final Color textBody;
  final Color textMuted;
  // accents
  final Color coral;
  final Color blue;
  final Color violet;
  final Color cyan;
  final Color orange;
  final Color green;
  // pink → purple gradient for primary actions
  final Color gradientStart;
  final Color gradientEnd;

  const AppColors({
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.hairline,
    required this.textPrimary,
    required this.textBody,
    required this.textMuted,
    required this.coral,
    required this.blue,
    required this.violet,
    required this.cyan,
    required this.orange,
    required this.green,
    required this.gradientStart,
    required this.gradientEnd,
  });

  static const AppColors dark = AppColors(
    canvas: Color(0xFF0B0F1A),
    surface: Color(0xFF141A2A),
    surfaceRaised: Color(0xFF1B2234),
    hairline: Color(0xFF2A3350),
    textPrimary: Color(0xFFF0F2F8),
    textBody: Color(0xFFA9B2C6),
    textMuted: Color(0xFF6C7591),
    coral: Color(0xFFFF5A6A),
    blue: Color(0xFF4D8DFF),
    violet: Color(0xFF9D7BFF),
    cyan: Color(0xFF3BC9E8),
    orange: Color(0xFFFFA03C),
    green: Color(0xFF3DD68C),
    gradientStart: Color(0xFFF472B6),
    gradientEnd: Color(0xFF8B5CF6),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? dark;

  @override
  AppColors copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceRaised,
    Color? hairline,
    Color? textPrimary,
    Color? textBody,
    Color? textMuted,
    Color? coral,
    Color? blue,
    Color? violet,
    Color? cyan,
    Color? orange,
    Color? green,
    Color? gradientStart,
    Color? gradientEnd,
  }) {
    return AppColors(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      hairline: hairline ?? this.hairline,
      textPrimary: textPrimary ?? this.textPrimary,
      textBody: textBody ?? this.textBody,
      textMuted: textMuted ?? this.textMuted,
      coral: coral ?? this.coral,
      blue: blue ?? this.blue,
      violet: violet ?? this.violet,
      cyan: cyan ?? this.cyan,
      orange: orange ?? this.orange,
      green: green ?? this.green,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textBody: Color.lerp(textBody, other.textBody, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      coral: Color.lerp(coral, other.coral, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      violet: Color.lerp(violet, other.violet, t)!,
      cyan: Color.lerp(cyan, other.cyan, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      green: Color.lerp(green, other.green, t)!,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
    );
  }
}

/// The app's dark theme.
ThemeData buildDarkTheme() {
  const c = AppColors.dark;
  final colorScheme = ColorScheme.dark(
    primary: c.blue,
    onPrimary: Colors.white,
    secondary: c.violet,
    onSecondary: Colors.white,
    error: c.coral,
    onError: Colors.white,
    surface: c.surface,
    onSurface: c.textPrimary,
    onSurfaceVariant: c.textBody,
    outline: c.hairline,
  );

  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);

  final textTheme = TextTheme(
    headlineMedium: base.textTheme.headlineMedium?.copyWith(
      color: c.textPrimary,
      fontSize: 24,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: base.textTheme.titleLarge?.copyWith(
      color: c.textPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: base.textTheme.titleMedium?.copyWith(
      color: c.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: base.textTheme.bodyLarge?.copyWith(color: c.textBody, fontSize: 16),
    bodyMedium: base.textTheme.bodyMedium?.copyWith(color: c.textBody, fontSize: 14),
    bodySmall: base.textTheme.bodySmall?.copyWith(color: c.textMuted, fontSize: 12),
    labelLarge: base.textTheme.labelLarge?.copyWith(color: c.textPrimary),
    labelMedium: base.textTheme.labelMedium?.copyWith(
      color: c.textMuted,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.4,
    ),
  );

  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.transparent,
    extensions: [c],
    textTheme: textTheme,
    dividerTheme: DividerThemeData(color: c.hairline, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: c.textPrimary,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      indicatorColor: c.blue.withValues(alpha: 0.16),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
        color: states.contains(WidgetState.selected) ? c.blue : c.textMuted,
      )),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
        fontSize: 12,
        fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
        color: states.contains(WidgetState.selected) ? c.textPrimary : c.textMuted,
      )),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(panelRadius)),
        side: BorderSide(color: c.hairline),
      ),
    ),
  );
}

/// Monospace style for numeric values, IDs, and codes.
TextStyle monoStyle(BuildContext context, {double fontSize = 14, Color? color, FontWeight? fontWeight}) {
  final c = AppColors.of(context);
  return TextStyle(
    fontFamily: 'monospace',
    fontSize: fontSize,
    color: color ?? c.textBody,
    fontWeight: fontWeight,
  );
}
