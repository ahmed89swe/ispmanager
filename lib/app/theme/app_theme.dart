import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _scheme = FlexScheme.deepBlue;

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
    cardElevation: 1.0,
    bottomNavigationBarElevation: 2,
    navigationBarElevation: 2,
  );

  static ThemeData light() {
    final base = FlexThemeData.light(
      scheme: _scheme,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 7,
      subThemesData: _subThemesData,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      useMaterial3: true,
      fontFamily: GoogleFonts.cairo().fontFamily,
    );

    return base.copyWith(
      textTheme: GoogleFonts.cairoTextTheme(base.textTheme),
      cardTheme: base.cardTheme.copyWith(
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: base.colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
    );
  }

  static ThemeData dark() {
    final base = FlexThemeData.dark(
      scheme: _scheme,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 10,
      subThemesData: _subThemesData,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      useMaterial3: true,
      fontFamily: GoogleFonts.cairo().fontFamily,
    );

    return base.copyWith(
      textTheme: GoogleFonts.cairoTextTheme(base.textTheme),
      cardTheme: base.cardTheme.copyWith(
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: base.colorScheme.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
    );
  }
}
