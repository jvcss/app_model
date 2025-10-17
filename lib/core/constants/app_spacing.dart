// lib/core/constants/app_spacing.dart
import 'package:flutter/material.dart';

/// Sistema de espaçamentos baseado em grid de 8px
/// Inspirado no Material Design 3 e Bitrix 24
class AppSpacing {
  // ============================================================================
  // SPACING SCALE (8px base)
  // ============================================================================
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // ============================================================================
  // PADDING PRESETS
  // ============================================================================
  static const EdgeInsets paddingXXS = EdgeInsets.all(xxs);
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);
  static const EdgeInsets paddingXXL = EdgeInsets.all(xxl);

  // ============================================================================
  // PADDING HORIZONTAL
  // ============================================================================
  static const EdgeInsets horizontalXS = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSM = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMD = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLG = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXL = EdgeInsets.symmetric(horizontal: xl);

  // ============================================================================
  // PADDING VERTICAL
  // ============================================================================
  static const EdgeInsets verticalXS = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSM = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMD = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLG = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXL = EdgeInsets.symmetric(vertical: xl);

  // ============================================================================
  // PAGE PADDING (Responsivo)
  // ============================================================================
  static const EdgeInsets pagePaddingMobile = EdgeInsets.all(md);
  static const EdgeInsets pagePaddingTablet = EdgeInsets.all(lg);
  static const EdgeInsets pagePaddingDesktop = EdgeInsets.all(xl);

  // ============================================================================
  // CARD PADDING
  // ============================================================================
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets cardPaddingSmall = EdgeInsets.all(sm);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(lg);

  // ============================================================================
  // LIST ITEM PADDING
  // ============================================================================
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );
  static const EdgeInsets listItemPaddingLarge = EdgeInsets.symmetric(
    horizontal: md,
    vertical: md,
  );

  // ============================================================================
  // BORDER RADIUS
  // ============================================================================
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 28.0;
  static const double radiusCircular = 999.0;

  // ============================================================================
  // BORDER RADIUS PRESETS
  // ============================================================================
  static const BorderRadius borderRadiusXS = BorderRadius.all(Radius.circular(radiusXS));
  static const BorderRadius borderRadiusSM = BorderRadius.all(Radius.circular(radiusSM));
  static const BorderRadius borderRadiusMD = BorderRadius.all(Radius.circular(radiusMD));
  static const BorderRadius borderRadiusLG = BorderRadius.all(Radius.circular(radiusLG));
  static const BorderRadius borderRadiusXL = BorderRadius.all(Radius.circular(radiusXL));
  static const BorderRadius borderRadiusXXL = BorderRadius.all(Radius.circular(radiusXXL));
  static const BorderRadius borderRadiusCircular = BorderRadius.all(Radius.circular(radiusCircular));

  // Card específico (inspirado Bitrix)
  static const BorderRadius cardRadius = borderRadiusMD;
  static const BorderRadius buttonRadius = borderRadiusSM;
  static const BorderRadius inputRadius = borderRadiusSM;
  static const BorderRadius dialogRadius = borderRadiusLG;
  static const BorderRadius bottomSheetRadius = BorderRadius.only(
    topLeft: Radius.circular(radiusLG),
    topRight: Radius.circular(radiusLG),
  );

  // ============================================================================
  // ICON SIZES
  // ============================================================================
  static const double iconXS = 16.0;
  static const double iconSM = 20.0;
  static const double iconMD = 24.0;
  static const double iconLG = 32.0;
  static const double iconXL = 40.0;
  static const double iconXXL = 48.0;

  // ============================================================================
  // AVATAR SIZES
  // ============================================================================
  static const double avatarXS = 24.0;
  static const double avatarSM = 32.0;
  static const double avatarMD = 40.0;
  static const double avatarLG = 56.0;
  static const double avatarXL = 72.0;
  static const double avatarXXL = 96.0;

  // ============================================================================
  // BUTTON SIZES
  // ============================================================================
  static const double buttonHeightSM = 36.0;
  static const double buttonHeightMD = 48.0;
  static const double buttonHeightLG = 56.0;

  // ============================================================================
  // INPUT SIZES
  // ============================================================================
  static const double inputHeightSM = 40.0;
  static const double inputHeightMD = 48.0;
  static const double inputHeightLG = 56.0;

  // ============================================================================
  // ELEVATION (Shadow)
  // ============================================================================
  static const double elevationXS = 1.0;
  static const double elevationSM = 2.0;
  static const double elevationMD = 4.0;
  static const double elevationLG = 8.0;
  static const double elevationXL = 12.0;
  static const double elevationXXL = 16.0;

  // ============================================================================
  // GAPS (para Row/Column spacing)
  // ============================================================================
  static const double gapXS = xs;
  static const double gapSM = sm;
  static const double gapMD = md;
  static const double gapLG = lg;
  static const double gapXL = xl;

  // ============================================================================
  // RESPONSIVE BREAKPOINTS
  // ============================================================================
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1440.0;

  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  /// Retorna padding responsivo baseado na largura da tela
  static EdgeInsets getResponsivePadding(double screenWidth) {
    if (screenWidth < mobileBreakpoint) {
      return pagePaddingMobile;
    } else if (screenWidth < tabletBreakpoint) {
      return pagePaddingTablet;
    } else {
      return pagePaddingDesktop;
    }
  }

  /// SizedBox com altura customizada
  static SizedBox verticalSpace(double height) => SizedBox(height: height);
  
  /// SizedBox com largura customizada
  static SizedBox horizontalSpace(double width) => SizedBox(width: width);

  /// Gaps prontos
  static SizedBox get gapXSVertical => verticalSpace(xs);
  static SizedBox get gapSMVertical => verticalSpace(sm);
  static SizedBox get gapMDVertical => verticalSpace(md);
  static SizedBox get gapLGVertical => verticalSpace(lg);
  static SizedBox get gapXLVertical => verticalSpace(xl);

  static SizedBox get gapXSHorizontal => horizontalSpace(xs);
  static SizedBox get gapSMHorizontal => horizontalSpace(sm);
  static SizedBox get gapMDHorizontal => horizontalSpace(md);
  static SizedBox get gapLGHorizontal => horizontalSpace(lg);
  static SizedBox get gapXLHorizontal => horizontalSpace(xl);
}