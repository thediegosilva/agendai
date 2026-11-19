import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

/// Paleta "sala de cinema": preto quente, luz de projetor em âmbar
/// e bokeh alaranjado ao fundo.
abstract final class AppColors {
  static const background = Color(0xFF0A0806);
  static const surface = Color(0xFF17120D);
  static const surfaceHigh = Color(0xFF221A12);
  static const outline = Color(0x24FFE2B8);

  static const amber = Color(0xFFF5B544);
  static const ember = Color(0xFFFF7A45);
  static const glow = Color(0xFFFF9A3C);

  static const text = Color(0xFFF7F1E8);
  static const textMuted = Color(0xFFAFA393);
  static const danger = Color(0xFFFF5C6C);
  static const success = Color(0xFF3DDC97);

  static const brandGradient = LinearGradient(
    colors: [amber, ember],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

ThemeData buildTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.amber,
    onPrimary: Color(0xFF1C1205),
    secondary: AppColors.ember,
    onSecondary: Color(0xFF1C0B05),
    tertiary: AppColors.glow,
    onTertiary: Colors.white,
    error: AppColors.danger,
    onError: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.textMuted,
    surfaceContainerHighest: AppColors.surfaceHigh,
    outline: AppColors.outline,
    outlineVariant: AppColors.outline,
  );

  final body = GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
      .apply(bodyColor: AppColors.text, displayColor: AppColors.text);
  final display = GoogleFonts.outfitTextTheme(body);
  final textTheme = body.copyWith(
    displayLarge: display.displayLarge,
    displayMedium: display.displayMedium,
    displaySmall: display.displaySmall,
    headlineLarge: display.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
    headlineMedium: display.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
    ),
    headlineSmall: display.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
    titleLarge: display.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    titleMedium: display.titleMedium?.copyWith(fontWeight: FontWeight.w600),
  );

  final radius = BorderRadius.circular(16);

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0x0DFFFFFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      labelStyle: const TextStyle(color: AppColors.textMuted),
      prefixIconColor: WidgetStateColor.resolveWith(
        (s) => s.contains(WidgetState.focused)
            ? AppColors.amber
            : AppColors.textMuted,
      ),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: textTheme.titleMedium,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.outline),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.amber),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: const Color(0x0DFFFFFF),
        foregroundColor: AppColors.textMuted,
        selectedBackgroundColor: AppColors.amber.withValues(alpha: 0.16),
        selectedForegroundColor: AppColors.amber,
        side: const BorderSide(color: AppColors.outline),
        minimumSize: const Size.fromHeight(48),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: AppColors.outline),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0x0DFFFFFF),
      selectedColor: AppColors.amber.withValues(alpha: 0.18),
      side: const BorderSide(color: AppColors.outline),
      labelStyle: const TextStyle(color: AppColors.text),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceHigh,
      contentTextStyle: const TextStyle(color: AppColors.text),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.outline),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.amber,
    ),
  );
}
