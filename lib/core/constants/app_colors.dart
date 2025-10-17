// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

/// Paleta de cores inspirada no Bitrix 24
/// Extraída das screenshots fornecidas
class AppColors {
  // ============================================================================
  // PRIMARY PALETTE (Azul Bitrix)
  // ============================================================================
  static const Color primary = Color(0xFF1A4F8B);
  static const Color primaryDark = Color(0xFF0F3A6F);
  static const Color primaryLight = Color(0xFF4A7FB8);
  static const Color primaryVeryLight = Color(0xFFE3F2FD);

  // ============================================================================
  // STATUS COLORS (Sistema)
  // ============================================================================
  static const Color success = Color(0xFF7ED321);
  static const Color successDark = Color(0xFF5FB800);
  static const Color successLight = Color(0xFFC8E6C9);
  
  static const Color warning = Color(0xFFF5A623);
  static const Color warningDark = Color(0xFFE65100);
  static const Color warningLight = Color(0xFFFFE082);
  
  static const Color error = Color(0xFFFF5252);
  static const Color errorDark = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFCDD2);
  
  static const Color info = Color(0xFF4A90E2);
  static const Color infoDark = Color(0xFF1976D2);
  static const Color infoLight = Color(0xFFBBDEFB);

  // ============================================================================
  // KANBAN COLORS (Status Cards)
  // ============================================================================
  static const Color kanbanYellow = Color(0xFFFFF176); // Novos
  static const Color kanbanOrange = Color(0xFFFFB74D); // Em progresso
  static const Color kanbanBlue = Color(0xFF64B5F6);   // Negociação
  static const Color kanbanRed = Color(0xFFEF5350);    // Urgente/Pagamento
  static const Color kanbanPurple = Color(0xFFBA68C8); // Fechados
  static const Color kanbanTeal = Color(0xFF4DD0E1);   // Pendentes
  static const Color kanbanGreen = Color(0xFF81C784);  // Concluídos

  // ============================================================================
  // TICKET STATUS COLORS
  // ============================================================================
  static const Color ticketOpen = Color(0xFF7ED321);
  static const Color ticketPending = Color(0xFFF5A623);
  static const Color ticketClosed = Color(0xFF9E9E9E);

  // ============================================================================
  // NEUTRAL PALETTE (Light Theme)
  // ============================================================================
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);
  
  // TEXT COLORS
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ============================================================================
  // DARK THEME
  // ============================================================================
  static const Color backgroundDark = Color(0xFF1E1E1E);
  static const Color surfaceDark = Color(0xFF2C2C2C);
  static const Color surfaceVariantDark = Color(0xFF3A3A3A);
  static const Color borderDark = Color(0xFF424242);
  static const Color dividerDark = Color(0xFF303030);
  
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color textDisabledDark = Color(0xFF616161);

  // ============================================================================
  // CHAT COLORS (WhatsApp Style)
  // ============================================================================
  static const Color chatBubbleSent = Color(0xFFDCF8C6);      // Verde claro (enviadas)
  static const Color chatBubbleReceived = Color(0xFFFFFFFF);  // Branco (recebidas)
  static const Color chatBackground = Color(0xFFECE5DD);      // Fundo bege
  static const Color chatBackgroundDark = Color(0xFF0D1418); // Fundo escuro
  
  // ============================================================================
  // SEMANTIC COLORS (Actions)
  // ============================================================================
  static const Color approve = Color(0xFF7ED321);
  static const Color reject = Color(0xFFFF5252);
  static const Color pending = Color(0xFFFFD74F);
  static const Color inProgress = Color(0xFF4A90E2);
  
  // ============================================================================
  // GRADIENT BACKGROUNDS
  // ============================================================================
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
  
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, Color(0xFF9CCC65)],
  );
  
  // ============================================================================
  // OVERLAY & SHADOW COLORS
  // ============================================================================
  static const Color overlay = Color(0x80000000);
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadowDark = Color(0x4D000000);

  // ============================================================================
  // BADGE COLORS (Notifications)
  // ============================================================================
  static const Color badgeRed = Color(0xFFFF5252);
  static const Color badgeGreen = Color(0xFF7ED321);
  static const Color badgeBlue = Color(0xFF4A90E2);
  static const Color badgeOrange = Color(0xFFF5A623);

  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  /// Retorna cor baseada no status do ticket
  static Color getTicketStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return ticketOpen;
      case 'pending':
        return ticketPending;
      case 'closed':
        return ticketClosed;
      default:
        return textSecondary;
    }
  }

  /// Retorna cor baseada no tipo de kanban stage
  static Color getKanbanColor(int index) {
    final colors = [
      kanbanYellow,
      kanbanOrange,
      kanbanBlue,
      kanbanRed,
      kanbanPurple,
      kanbanTeal,
      kanbanGreen,
    ];
    return colors[index % colors.length];
  }

  /// Retorna cor de contraste (texto) para um background
  static Color getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? textPrimary : textOnPrimary;
  }
}