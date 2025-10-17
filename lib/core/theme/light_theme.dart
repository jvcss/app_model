// lib/core/theme/light_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

/// Tema claro inspirado no Bitrix 24
ThemeData getLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // ============================================================================
    // COLOR SCHEME
    // ============================================================================
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.textPrimary,
      
      secondary: AppColors.info,
      onSecondary: AppColors.textOnPrimary,
      secondaryContainer: AppColors.infoLight,
      onSecondaryContainer: AppColors.textPrimary,
      
      tertiary: AppColors.success,
      onTertiary: AppColors.textOnPrimary,
      tertiaryContainer: AppColors.successLight,
      onTertiaryContainer: AppColors.textPrimary,
      
      error: AppColors.error,
      onError: AppColors.textOnPrimary,
      errorContainer: AppColors.errorLight,
      onErrorContainer: AppColors.errorDark,
      
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceVariant,
      
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
      
      shadow: AppColors.shadowMedium,
      scrim: AppColors.overlay,
      
      inverseSurface: AppColors.surfaceDark,
      onInverseSurface: AppColors.textOnPrimary,
      inversePrimary: AppColors.primaryLight,
    ),

    // ============================================================================
    // SCAFFOLD
    // ============================================================================
    scaffoldBackgroundColor: AppColors.background,
    
    // ============================================================================
    // APP BAR
    // ============================================================================
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
      ),
      iconTheme: IconThemeData(
        color: AppColors.textOnPrimary,
        size: AppSpacing.iconMD,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),

    // ============================================================================
    // CARD
    // ============================================================================
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: AppSpacing.elevationSM,
      shadowColor: AppColors.shadowLight,
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
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
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
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
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
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border, width: 1.5),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        minimumSize: const Size(64, AppSpacing.buttonHeightMD),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.buttonRadius,
        ),
        textStyle: AppTextStyles.buttonSecondary,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.buttonRadius,
        ),
        textStyle: AppTextStyles.buttonSecondary,
      ),
    ),

    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.primary,
        iconSize: AppSpacing.iconMD,
      ),
    ),

    // ============================================================================
    // FAB
    // ============================================================================
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      elevation: AppSpacing.elevationLG,
      shape: CircleBorder(),
    ),

    // ============================================================================
    // INPUT DECORATION
    // ============================================================================
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant.withAlpha(127),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      labelStyle: AppTextStyles.inputLabel,
      hintStyle: AppTextStyles.inputLabel.copyWith(
        color: AppColors.textDisabled,
      ),
      errorStyle: AppTextStyles.errorText,
      helperStyle: AppTextStyles.helperText,
      prefixIconColor: AppColors.textSecondary,
      suffixIconColor: AppColors.textSecondary,
    ),

    // ============================================================================
    // CHIP
    // ============================================================================
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceVariant,
      deleteIconColor: AppColors.textSecondary,
      disabledColor: AppColors.surfaceVariant.withAlpha(127),
      selectedColor: AppColors.primary,
      secondarySelectedColor: AppColors.primaryLight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      labelStyle: AppTextStyles.badgeText.copyWith(
        color: AppColors.textPrimary,
      ),
      secondaryLabelStyle: AppTextStyles.badgeText.copyWith(
        color: AppColors.textOnPrimary,
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
      backgroundColor: AppColors.surface,
      elevation: AppSpacing.elevationXL,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.dialogRadius,
      ),
      titleTextStyle: AppTextStyles.headlineSmall,
      contentTextStyle: AppTextStyles.bodyMedium,
    ),

    // ============================================================================
    // BOTTOM SHEET
    // ============================================================================
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      elevation: AppSpacing.elevationXL,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.bottomSheetRadius,
      ),
      modalBackgroundColor: AppColors.surface,
      modalElevation: AppSpacing.elevationXXL,
    ),

    // ============================================================================
    // SNACKBAR
    // ============================================================================
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textOnPrimary,
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
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),

    // ============================================================================
    // LIST TILE
    // ============================================================================
    listTileTheme: const ListTileThemeData(
      contentPadding: AppSpacing.listItemPadding,
      iconColor: AppColors.textSecondary,
      textColor: AppColors.textPrimary,
      tileColor: AppColors.surface,
      selectedColor: AppColors.primary,
      selectedTileColor: AppColors.primaryVeryLight,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusSM,
      ),
    ),

    // ============================================================================
    // DRAWER
    // ============================================================================
    drawerTheme: const DrawerThemeData(
      backgroundColor: AppColors.surface,
      elevation: AppSpacing.elevationXL,
      shape: RoundedRectangleBorder(),
    ),

    // ============================================================================
    // NAVIGATION BAR (Bottom)
    // ============================================================================
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      elevation: AppSpacing.elevationMD,
      indicatorColor: AppColors.primaryLight,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(
            color: AppColors.primary,
            size: AppSpacing.iconMD,
          );
        }
        return const IconThemeData(
          color: AppColors.textSecondary,
          size: AppSpacing.iconMD,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTextStyles.labelSmall.copyWith(
            color: AppColors.primary,
          );
        }
        return AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
        );
      }),
    ),

    // ============================================================================
    // SWITCH
    // ============================================================================
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.textDisabled;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryLight;
        }
        return AppColors.divider;
      }),
    ),

    // ============================================================================
    // CHECKBOX
    // ============================================================================
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(AppColors.textOnPrimary),
      side: const BorderSide(color: AppColors.border, width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusXS,
      ),
    ),

    // ============================================================================
    // RADIO
    // ============================================================================
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.border;
      }),
    ),

    // ============================================================================
    // SLIDER
    // ============================================================================
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.primary,
      inactiveTrackColor: AppColors.divider,
      thumbColor: AppColors.primary,
      overlayColor: AppColors.primaryVeryLight,
    ),

    // ============================================================================
    // PROGRESS INDICATOR
    // ============================================================================
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.divider,
      circularTrackColor: AppColors.divider,
    ),

    // ============================================================================
    // BADGE
    // ============================================================================
    badgeTheme: const BadgeThemeData(
      backgroundColor: AppColors.badgeRed,
      textColor: AppColors.textOnPrimary,
      textStyle: AppTextStyles.badgeText,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
    ),

    // ============================================================================
    // TEXT THEME
    // ============================================================================
    textTheme: const TextTheme(
      displayLarge: AppTextStyles.displayLarge,
      displayMedium: AppTextStyles.displayMedium,
      displaySmall: AppTextStyles.displaySmall,
      headlineLarge: AppTextStyles.headlineLarge,
      headlineMedium: AppTextStyles.headlineMedium,
      headlineSmall: AppTextStyles.headlineSmall,
      titleLarge: AppTextStyles.titleLarge,
      titleMedium: AppTextStyles.titleMedium,
      titleSmall: AppTextStyles.titleSmall,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.labelLarge,
      labelMedium: AppTextStyles.labelMedium,
      labelSmall: AppTextStyles.labelSmall,
    ),

    // ============================================================================
    // ICON THEME
    // ============================================================================
    iconTheme: const IconThemeData(
      color: AppColors.textSecondary,
      size: AppSpacing.iconMD,
    ),

    primaryIconTheme: const IconThemeData(
      color: AppColors.textOnPrimary,
      size: AppSpacing.iconMD,
    ),
  );
}