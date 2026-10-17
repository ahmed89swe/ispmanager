import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppColorTheme {
  deepBlue(
    scheme: FlexScheme.deepBlue,
    labelAr: 'الأزرق الملكي',
    labelEn: 'Royal Blue',
    previewColor: Color(0xFF1E88E5),
    lightScaffold: Color(0xFFF0F4F8),
    lightCard: Color(0xFFDCE6F2),
    lightBorder: Color(0xFFB0C4DE),
    darkScaffold: Color(0xFF080C14),
    darkCard: Color(0xFF131E32),
    darkBorder: Color(0xFF283B5B),
  ),
  emeraldTeal(
    scheme: FlexScheme.jungle,
    labelAr: 'الأخضر الزمردي',
    labelEn: 'Emerald Teal',
    previewColor: Color(0xFF00897B),
    lightScaffold: Color(0xFFEEF6F4),
    lightCard: Color(0xFFD6EAE5),
    lightBorder: Color(0xFFA2C9BF),
    darkScaffold: Color(0xFF071311),
    darkCard: Color(0xFF102824),
    darkBorder: Color(0xFF214D46),
  ),
  royalPurple(
    scheme: FlexScheme.deepPurple,
    labelAr: 'البنفسجي الملكي',
    labelEn: 'Royal Purple',
    previewColor: Color(0xFF7B1FA2),
    lightScaffold: Color(0xFFF4F0F9),
    lightCard: Color(0xFFE4DCF2),
    lightBorder: Color(0xFFC2B0DE),
    darkScaffold: Color(0xFF0D0814),
    darkCard: Color(0xFF1C1330),
    darkBorder: Color(0xFF3A285B),
  ),
  indigoSlate(
    scheme: FlexScheme.indigo,
    labelAr: 'النيلي الاحترافي',
    labelEn: 'Indigo Slate',
    previewColor: Color(0xFF3949AB),
    lightScaffold: Color(0xFFEEF0F8),
    lightCard: Color(0xFFDCE0F2),
    lightBorder: Color(0xFFB0B8DE),
    darkScaffold: Color(0xFF090B16),
    darkCard: Color(0xFF151933),
    darkBorder: Color(0xFF2C3463),
  ),
  amberBronze(
    scheme: FlexScheme.amber,
    labelAr: 'العنبري الدافئ',
    labelEn: 'Warm Amber',
    previewColor: Color(0xFFE65100),
    lightScaffold: Color(0xFFF8F4EE),
    lightCard: Color(0xFFF0E4D4),
    lightBorder: Color(0xFFD6BE9E),
    darkScaffold: Color(0xFF140E08),
    darkCard: Color(0xFF2A1E12),
    darkBorder: Color(0xFF523C26),
  ),
  crimsonRuby(
    scheme: FlexScheme.redWine,
    labelAr: 'الياقوتي الأنيق',
    labelEn: 'Crimson Ruby',
    previewColor: Color(0xFFC62828),
    lightScaffold: Color(0xFFF9F0F2),
    lightCard: Color(0xFFF2DCE0),
    lightBorder: Color(0xFFDEB0B8),
    darkScaffold: Color(0xFF14080A),
    darkCard: Color(0xFF2E1318),
    darkBorder: Color(0xFF592630),
  );

  const AppColorTheme({
    required this.scheme,
    required this.labelAr,
    required this.labelEn,
    required this.previewColor,
    required this.lightScaffold,
    required this.lightCard,
    required this.lightBorder,
    required this.darkScaffold,
    required this.darkCard,
    required this.darkBorder,
  });

  final FlexScheme scheme;
  final String labelAr;
  final String labelEn;
  final Color previewColor;
  final Color lightScaffold;
  final Color lightCard;
  final Color lightBorder;
  final Color darkScaffold;
  final Color darkCard;
  final Color darkBorder;

  String label(String languageCode) =>
      languageCode.startsWith('ar') ? labelAr : labelEn;
}

class AppTheme {
  // Default colors (Royal Blue)
  static const Color lightScaffoldColor = Color(0xFFF0F4F8);
  static const Color lightCardColor = Color(0xFFDCE6F2);
  static const Color lightCardBorderColor = Color(0xFFB0C4DE);

  static const Color darkScaffoldColor = Color(0xFF080C14);
  static const Color darkCardColor = Color(0xFF131E32);
  static const Color darkCardBorderColor = Color(0xFF283B5B);

  static Color cardColor(BuildContext context) => Theme.of(context).cardColor;

  static Color cardBorderColor(BuildContext context) =>
      Theme.of(context).colorScheme.outlineVariant;

  static BoxDecoration cardDecoration(
    BuildContext context, {
    double borderRadius = 16,
    Color? borderColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? theme.colorScheme.outlineVariant,
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

  static ThemeData light([AppColorTheme palette = AppColorTheme.deepBlue]) {
    final base = FlexThemeData.light(
      scheme: palette.scheme,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 12,
      subThemesData: _subThemesData,
      visualDensity: VisualDensity.standard,
      useMaterial3: true,
      fontFamily: GoogleFonts.cairo().fontFamily,
    );

    final cs = base.colorScheme.copyWith(
      surface: palette.lightScaffold,
      surfaceContainerLowest: palette.lightScaffold,
      surfaceContainerLow: palette.lightCard,
      surfaceContainer: palette.lightCard,
      surfaceContainerHigh: palette.lightCard,
      surfaceContainerHighest: palette.lightBorder.withValues(alpha: 0.45),
      onSurface: const Color(0xFF0F172A),
      onSurfaceVariant: const Color(0xFF1E293B),
      outline: const Color(0xFF334155),
      outlineVariant: palette.lightBorder,
    );

    return base.copyWith(
      scaffoldBackgroundColor: palette.lightScaffold,
      colorScheme: cs,
      cardColor: palette.lightCard,
      textTheme: _enhanceTextTheme(base.textTheme, isDark: false),
      cardTheme: base.cardTheme.copyWith(
        color: palette.lightCard,
        surfaceTintColor: Colors.transparent,
        elevation: 2.0,
        shadowColor: const Color(0xFF0F2B48).withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: palette.lightBorder,
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
        backgroundColor: palette.lightCard.withValues(alpha: 0.7),
        foregroundColor: const Color(0xFF0F172A),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: palette.lightScaffold,
        constraints: const BoxConstraints(maxWidth: 640),
      ),
    );
  }

  static ThemeData dark([AppColorTheme palette = AppColorTheme.deepBlue]) {
    final base = FlexThemeData.dark(
      scheme: palette.scheme,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 14,
      subThemesData: _subThemesData,
      visualDensity: VisualDensity.standard,
      useMaterial3: true,
      fontFamily: GoogleFonts.cairo().fontFamily,
    );

    final cs = base.colorScheme.copyWith(
      surface: palette.darkScaffold,
      surfaceContainerLowest: palette.darkScaffold,
      surfaceContainerLow: palette.darkCard,
      surfaceContainer: palette.darkCard,
      surfaceContainerHigh: palette.darkCard,
      surfaceContainerHighest: palette.darkBorder.withValues(alpha: 0.55),
      onSurface: const Color(0xFFF8FAFC),
      onSurfaceVariant: const Color(0xFFCBD5E1),
      outline: const Color(0xFF94A3B8),
      outlineVariant: palette.darkBorder,
    );

    return base.copyWith(
      scaffoldBackgroundColor: palette.darkScaffold,
      colorScheme: cs,
      cardColor: palette.darkCard,
      textTheme: _enhanceTextTheme(base.textTheme, isDark: true),
      cardTheme: base.cardTheme.copyWith(
        color: palette.darkCard,
        surfaceTintColor: Colors.transparent,
        elevation: 3.0,
        shadowColor: Colors.black.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: palette.darkBorder,
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
        backgroundColor: palette.darkCard,
        foregroundColor: const Color(0xFFF8FAFC),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: palette.darkCard,
        constraints: const BoxConstraints(maxWidth: 640),
      ),
    );
  }
}
