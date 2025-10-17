// lib/core/theme/dark_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

/// Tema escuro inspirado no Bitrix 24
ThemeData getDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    
    // ============================================================================
    // COLOR SCHEME
    // ============================================================================
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryLight,
      onPrimary: AppColors.textPrimary,
      primaryContainer: AppColors.primary,
      onPrimaryContainer: AppColors.textOnPrimary,
      
      secondary: AppColors.infoLight,
      onSecondary: AppColors.textPrimary,
      secondaryContainer: AppColors.info,
      onSecondaryContainer: AppColors.textOnPrimary,
      
      tertiary: AppColors.successLight,
      onTertiary: AppColors.textPrimary,
      tertiaryContainer: AppColors.success,
      onTertiaryContainer: AppColors.textOnPrimary,
      
      error: AppColors.errorLight,
      onError: AppColors.textPrimary,
      errorContainer: AppColors.error,
      onErrorContainer: AppColors.textOnPrimary,
      
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      surfaceContainerHighest: AppColors.surfaceVariantDark,
      
      outline: AppColors.borderDark,
      outlineVariant: AppColors.dividerDark,
      
      shadow: AppColors.shadowDark,
      scrim: AppColors.overlay,
      
      inverseSurface: AppColors.surface,
      onInverseSurface: AppColors.textPrimary,
      inversePrimary: AppColors.primary,
    ),

    // ============================================================================
    // SCAFFOLD
    // ============================================================================
    scaffoldBackgroundColor: AppColors.backgroundDark,
    
    // ============================================================================
    // APP BAR
    // ============================================================================
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: AppColors.textPrimaryDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryDark,
      ),
      iconTheme: IconThemeData(
        color: AppColors.textPrimaryDark,
        size: AppSpacing.iconMD,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),

    // ============================================================================
    // CARD
    // ============================================================================
    cardTheme: CardThemeData(
      color: AppColors.surfaceDark,
      elevation: AppSpacing.elevationSM,
      shadowColor: AppColors.shadowDark,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.cardRadius,
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
    ),

    // ============================================================================
    // BUTTON THEMES
    // ============================================================================
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.textPrimary,
        elevation: AppSpacing.elevationSM,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        minimumSize: const Size(64, AppSpacing.buttonHeightMD),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.buttonRadius,
        ),
        textStyle: AppTextStyles.buttonPrimary,
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        minimumSize: const Size(64, AppSpacing.buttonHeightMD),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.buttonRadius,
        ),
        textStyle: AppTextStyles.buttonPrimary,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        side: const BorderSide(color: AppColors.borderDark, width: 1.5),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        minimumSize: const Size(64, AppSpacing.buttonHeightMD),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.buttonRadius,
        ),
        textStyle: AppTextStyles.buttonSecondary.copyWith(
          color: AppColors.primaryLight,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.buttonRadius,
        ),
        textStyle: AppTextStyles.buttonSecondary.copyWith(
          color: AppColors.primaryLight,
        ),
      ),
    ),

    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        iconSize: AppSpacing.iconMD,
      ),
    ),

    // ============================================================================
    // FAB
    // ============================================================================
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryLight,
      foregroundColor: AppColors.textPrimary,
      elevation: AppSpacing.elevationLG,
      shape: CircleBorder(),
    ),

    // ============================================================================
    // INPUT DECORATION
    // ============================================================================
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariantDark.withAlpha(127),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: const BorderSide(color: AppColors.errorLight),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: const BorderSide(color: AppColors.errorLight, width: 2),
      ),
      labelStyle: AppTextStyles.inputLabel.copyWith(
        color: AppColors.textSecondaryDark,
      ),
      hintStyle: AppTextStyles.inputLabel.copyWith(
        color: AppColors.textDisabledDark,
      ),
      errorStyle: AppTextStyles.errorText.copyWith(
        color: AppColors.errorLight,
      ),
      helperStyle: AppTextStyles.helperText.copyWith(
        color: AppColors.textSecondaryDark,
      ),
      prefixIconColor: AppColors.textSecondaryDark,
      suffixIconColor: AppColors.textSecondaryDark,
    ),

    // ============================================================================
    // CHIP
    // ============================================================================
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceVariantDark,
      deleteIconColor: AppColors.textSecondaryDark,
      disabledColor: AppColors.surfaceVariantDark.withAlpha(127),
      selectedColor: AppColors.primaryLight,
      secondarySelectedColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      labelStyle: AppTextStyles.badgeText.copyWith(
        color: AppColors.textPrimaryDark,
      ),
      secondaryLabelStyle: AppTextStyles.badgeText.copyWith(
        color: AppColors.textPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusSM,
      ),
      side: BorderSide.none,
    ),

    // ============================================================================
    // DIALOG
    // ============================================================================
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceDark,
      elevation: AppSpacing.elevationXL,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.dialogRadius,
      ),
      titleTextStyle: AppTextStyles.headlineSmall.copyWith(
        color: AppColors.textPrimaryDark,
      ),
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textPrimaryDark,
      ),
    ),

    // ============================================================================
    // BOTTOM SHEET
    // ============================================================================
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceDark,
      elevation: AppSpacing.elevationXL,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.bottomSheetRadius,
      ),
      modalBackgroundColor: AppColors.surfaceDark,
      modalElevation: AppSpacing.elevationXXL,
    ),

    // ============================================================================
    // SNACKBAR
    // ============================================================================
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceVariantDark,
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textPrimaryDark,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusSM,
      ),
      behavior: SnackBarBehavior.floating,
      elevation: AppSpacing.elevationLG,
    ),

    // ============================================================================
    // DIVIDER
    // ============================================================================
    dividerTheme: const DividerThemeData(
      color: AppColors.dividerDark,
      thickness: 1,
      space: 1,
    ),

    // ============================================================================
    // LIST TILE
    // ============================================================================
    listTileTheme: const ListTileThemeData(
      contentPadding: AppSpacing.listItemPadding,
      iconColor: AppColors.textSecondaryDark,
      textColor: AppColors.textPrimaryDark,
      tileColor: AppColors.surfaceDark,
      selectedColor: AppColors.primaryLight,
      selectedTileColor: AppColors.surfaceVariantDark,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusSM,
      ),
    ),

    // ============================================================================
    // DRAWER
    // ============================================================================
    drawerTheme: const DrawerThemeData(
      backgroundColor: AppColors.surfaceDark,
      elevation: AppSpacing.elevationXL,
      shape: RoundedRectangleBorder(),
    ),

    // ============================================================================
    // NAVIGATION BAR (Bottom)
    // ============================================================================
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      elevation: AppSpacing.elevationMD,
      indicatorColor: AppColors.surfaceVariantDark,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(
            color: AppColors.primaryLight,
            size: AppSpacing.iconMD,
          );
        }
        return const IconThemeData(
          color: AppColors.textSecondaryDark,
          size: AppSpacing.iconMD,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTextStyles.labelSmall.copyWith(
            color: AppColors.primaryLight,
          );
        }
        return AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondaryDark,
        );
      }),
    ),

    // ============================================================================
    // TEXT THEME
    // ============================================================================
    textTheme: TextTheme(
      displayLarge: AppTextStyles.displayLarge.copyWith(color: AppColors.textPrimaryDark),
      displayMedium: AppTextStyles.displayMedium.copyWith(color: AppColors.textPrimaryDark),
      displaySmall: AppTextStyles.displaySmall.copyWith(color: AppColors.textPrimaryDark),
      headlineLarge: AppTextStyles.headlineLarge.copyWith(color: AppColors.textPrimaryDark),
      headlineMedium: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimaryDark),
      headlineSmall: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimaryDark),
      titleLarge: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimaryDark),
      titleMedium: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimaryDark),
      titleSmall: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimaryDark),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimaryDark),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimaryDark),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryDark),
      labelLarge: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimaryDark),
      labelMedium: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimaryDark),
      labelSmall: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondaryDark),
    ),

    // ============================================================================
    // ICON THEME
    // ============================================================================
    iconTheme: const IconThemeData(
      color: AppColors.textSecondaryDark,
      size: AppSpacing.iconMD,
    ),

    primaryIconTheme: const IconThemeData(
      color: AppColors.primaryLight,
      size: AppSpacing.iconMD,
    ),
  );
}