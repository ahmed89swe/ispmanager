import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _scheme = FlexScheme.deepBlue;

  // Rich, non-washed-out card colors for Light & Dark modes
  static const Color lightScaffoldColor = Color(0xFFF0F4F8);
  static const Color lightCardColor = Color(0xFFDCE6F2);
  static const Color lightCardBorderColor = Color(0xFFB0C4DE);

  static const Color darkScaffoldColor = Color(0xFF080C14);
  static const Color darkCardColor = Color(0xFF131E32);
  static const Color darkCardBorderColor = Color(0xFF283B5B);

  static Color cardColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkCardColor
          : lightCardColor;

  static Color cardBorderColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkCardBorderColor
          : lightCardBorderColor;

  static BoxDecoration cardDecoration(
    BuildContext context, {
    double borderRadius = 16,
    Color? borderColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? darkCardColor : lightCardColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? (isDark ? darkCardBorderColor : lightCardBorderColor),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.07),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  static TextTheme _enhanceTextTheme(TextTheme base, {required bool isDark}) {
    final cairo = GoogleFonts.cairoTextTheme(base);
    final primaryText =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final secondaryText =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B);

    return cairo.copyWith(
      displayLarge: cairo.displayLarge?.copyWith(
          fontWeight: FontWeight.w800, color: primaryText),
      displayMedium: cairo.displayMedium?.copyWith(
          fontWeight: FontWeight.w800, color: primaryText),
      displaySmall: cairo.displaySmall?.copyWith(
          fontWeight: FontWeight.w800, color: primaryText),
      headlineLarge: cairo.headlineLarge?.copyWith(
          fontSize: 28, fontWeight: FontWeight.w800, color: primaryText),
      headlineMedium: cairo.headlineMedium?.copyWith(
          fontSize: 24, fontWeight: FontWeight.w800, color: primaryText),
      headlineSmall: cairo.headlineSmall?.copyWith(
          fontSize: 21, fontWeight: FontWeight.w700, color: primaryText),
      titleLarge: cairo.titleLarge?.copyWith(
          fontSize: 20, fontWeight: FontWeight.w800, color: primaryText),
      titleMedium: cairo.titleMedium?.copyWith(
          fontSize: 17, fontWeight: FontWeight.w700, color: primaryText),
      titleSmall: cairo.titleSmall?.copyWith(
          fontSize: 15, fontWeight: FontWeight.w700, color: primaryText),
      bodyLarge: cairo.bodyLarge?.copyWith(
          fontSize: 16, fontWeight: FontWeight.w600, color: primaryText),
      bodyMedium: cairo.bodyMedium?.copyWith(
          fontSize: 14.5, fontWeight: FontWeight.w600, color: primaryText),
      bodySmall: cairo.bodySmall?.copyWith(
          fontSize: 13, fontWeight: FontWeight.w600, color: secondaryText),
      labelLarge: cairo.labelLarge?.copyWith(
          fontSize: 14.5, fontWeight: FontWeight.w700, color: primaryText),
      labelMedium: cairo.labelMedium?.copyWith(
          fontSize: 13, fontWeight: FontWeight.w700, color: secondaryText),
      labelSmall: cairo.labelSmall?.copyWith(
          fontSize: 12, fontWeight: FontWeight.w700, color: secondaryText),
    );
  }

  static const _subThemesData = FlexSubThemesData(
    interactionEffects: true,
    tintedDisabledControls: true,
    useM2StyleDividerInM3: false,
    inputDecoratorIsFilled: true,
    inputDecoratorBorderType: FlexInputBorderType.outline,
    inputDecoratorUnfocusedBorderIsColored: false,
    defaultRadius: 16.0,
    elevatedButtonRadius: 16.0,
    filledButtonRadius: 16.0,
    outlinedButtonRadius: 16.0,
    textButtonRadius: 16.0,
    inputDecoratorRadius: 16.0,
    cardRadius: 20.0,
    dialogRadius: 24.0,
    bottomSheetRadius: 24.0,
    cardElevation: 2.0,
    bottomNavigationBarElevation: 3,
    navigationBarElevation: 3,
  );

  static ThemeData light() {
    final base = FlexThemeData.light(
      scheme: _scheme,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 12,
      subThemesData: _subThemesData,
      visualDensity: VisualDensity.standard,
      useMaterial3: true,
      fontFamily: GoogleFonts.cairo().fontFamily,
    );

    final cs = base.colorScheme.copyWith(
      surface: const Color(0xFFEAF0F7),
      surfaceContainerLowest: const Color(0xFFE4ECF5),
      surfaceContainerLow: lightCardColor,
      surfaceContainer: lightCardColor,
      surfaceContainerHigh: const Color(0xFFD2DFEE),
      surfaceContainerHighest: const Color(0xFFC8D7EA),
      onSurface: const Color(0xFF0F172A),
      onSurfaceVariant: const Color(0xFF1E293B),
      outline: const Color(0xFF334155),
      outlineVariant: lightCardBorderColor,
    );

    return base.copyWith(
      scaffoldBackgroundColor: lightScaffoldColor,
      colorScheme: cs,
      cardColor: lightCardColor,
      textTheme: _enhanceTextTheme(base.textTheme, isDark: false),
      cardTheme: base.cardTheme.copyWith(
        color: lightCardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 2.0,
        shadowColor: const Color(0xFF0F2B48).withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: lightCardBorderColor,
            width: 1.2,
          ),
        ),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 15.5,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
        ),
        subtitleTextStyle: GoogleFonts.cairo(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF334155),
        ),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: const Color(0xFFE4ECF5),
        foregroundColor: const Color(0xFF0F172A),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: const Color(0xFFEAF0F7),
        constraints: const BoxConstraints(maxWidth: 640),
      ),
    );
  }

  static ThemeData dark() {
    final base = FlexThemeData.dark(
      scheme: _scheme,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 14,
      subThemesData: _subThemesData,
      visualDensity: VisualDensity.standard,
      useMaterial3: true,
      fontFamily: GoogleFonts.cairo().fontFamily,
    );

    final cs = base.colorScheme.copyWith(
      surface: const Color(0xFF0E1626),
      surfaceContainerLowest: const Color(0xFF080C14),
      surfaceContainerLow: darkCardColor,
      surfaceContainer: darkCardColor,
      surfaceContainerHigh: const Color(0xFF1A2942),
      surfaceContainerHighest: const Color(0xFF213352),
      onSurface: const Color(0xFFF8FAFC),
      onSurfaceVariant: const Color(0xFFCBD5E1),
      outline: const Color(0xFF94A3B8),
      outlineVariant: darkCardBorderColor,
    );

    return base.copyWith(
      scaffoldBackgroundColor: darkScaffoldColor,
      colorScheme: cs,
      cardColor: darkCardColor,
      textTheme: _enhanceTextTheme(base.textTheme, isDark: true),
      cardTheme: base.cardTheme.copyWith(
        color: darkCardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 3.0,
        shadowColor: Colors.black.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: darkCardBorderColor,
            width: 1.2,
          ),
        ),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 15.5,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFF8FAFC),
        ),
        subtitleTextStyle: GoogleFonts.cairo(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFCBD5E1),
        ),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: const Color(0xFF0E1626),
        foregroundColor: const Color(0xFFF8FAFC),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: const Color(0xFF131E32),
        constraints: const BoxConstraints(maxWidth: 640),
      ),
    );
  }
}
