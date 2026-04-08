import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Thème Material 3 cohérent avec la charte Esther.
abstract final class AppTheme {
  static ThemeData get lightTheme {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.brownMedium,
      brightness: Brightness.light,
    );

    final scheme = base.copyWith(
      primary: AppColors.brownMedium,
      onPrimary: AppColors.cream,
      primaryContainer: AppColors.brownLight,
      onPrimaryContainer: AppColors.brownDark,
      secondary: AppColors.brownLight,
      onSecondary: AppColors.brownDark,
      secondaryContainer: AppColors.nude,
      onSecondaryContainer: AppColors.brownDark,
      tertiary: AppColors.brownLight,
      onTertiary: AppColors.brownDark,
      surface: AppColors.nude,
      onSurface: AppColors.brownDark,
      onSurfaceVariant: AppColors.brownMedium,
      surfaceContainerLowest: AppColors.cream,
      surfaceContainerLow: AppColors.cream,
      surfaceContainer: AppColors.nude,
      surfaceContainerHigh: AppColors.nude,
      surfaceContainerHighest: Color.lerp(AppColors.nude, AppColors.brownLight, 0.15)!,
      outline: AppColors.brownLight,
      outlineVariant: Color.lerp(AppColors.nude, AppColors.cream, 0.5)!,
      shadow: AppColors.brownDark.withValues(alpha: 0.18),
      scrim: AppColors.brownDark.withValues(alpha: 0.45),
      inverseSurface: AppColors.brownDark,
      onInverseSurface: AppColors.cream,
      inversePrimary: AppColors.brownLight,
      surfaceTint: AppColors.brownMedium,
    );

    final typography = Typography.material2021(platform: TargetPlatform.iOS);
    final textTheme = typography.black.apply(
      fontFamily: 'Roboto',
      bodyColor: AppColors.brownDark,
      displayColor: AppColors.brownDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.cream,
      canvasColor: AppColors.cream,
      textTheme: textTheme.copyWith(
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(height: 1.35),
        bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.35),
        labelLarge: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0.5,
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.brownDark,
        surfaceTintColor: AppColors.brownMedium.withValues(alpha: 0.12),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: AppColors.brownDark,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: AppColors.nude,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: AppColors.cream,
          backgroundColor: AppColors.brownMedium,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brownDark,
          side: const BorderSide(color: AppColors.brownLight, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.brownDark,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cream,
        selectedColor: AppColors.brownMedium,
        disabledColor: AppColors.nude.withValues(alpha: 0.6),
        labelStyle: const TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.w500),
        secondaryLabelStyle: const TextStyle(color: AppColors.cream),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: AppColors.brownLight, width: 0.8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cream,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.brownLight.withValues(alpha: 0.85)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.brownLight.withValues(alpha: 0.85)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.brownMedium, width: 1.5),
        ),
        hintStyle: TextStyle(
          color: AppColors.brownMedium.withValues(alpha: 0.7),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.brownLight.withValues(alpha: 0.35),
        thickness: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.cream,
        indicatorColor: AppColors.nude,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle( fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
            color: selected ? AppColors.brownMedium : AppColors.brownDark,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.brownMedium : AppColors.brownDark,
            size: 26,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.brownDark,
        contentTextStyle: const TextStyle(color: AppColors.cream),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
