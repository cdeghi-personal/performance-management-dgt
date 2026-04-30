import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // DGT Brand
  static const primary = Color(0xFF1A3C6E);       // Azul corporativo DGT
  static const primaryLight = Color(0xFF2A5FA8);
  static const primaryDark = Color(0xFF0D2447);
  static const accent = Color(0xFF00A896);         // Verde-teal para destaques

  // Superfícies
  static const background = Color(0xFFF5F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFEEF2F7);

  // Texto
  static const textPrimary = Color(0xFF1A1D23);
  static const textSecondary = Color(0xFF6B7280);
  static const textDisabled = Color(0xFFB0B7C3);

  // Status de metas / avaliações
  static const statusOnTrack = Color(0xFF16A34A);     // Verde — dentro do prazo
  static const statusAtRisk = Color(0xFFF59E0B);      // Âmbar — em risco
  static const statusBehind = Color(0xFFDC2626);      // Vermelho — atrasado
  static const statusCompleted = Color(0xFF0EA5E9);   // Azul — concluído
  static const statusDraft = Color(0xFF9CA3AF);       // Cinza — rascunho

  // Avaliações (score)
  static const scoreExceeds = Color(0xFF16A34A);      // Acima das expectativas
  static const scoreMeets = Color(0xFF2A5FA8);        // Atende
  static const scoreBelow = Color(0xFFF59E0B);        // Abaixo parcial
  static const scoreUnsatisfactory = Color(0xFFDC2626); // Insatisfatório

  // Cotas DGT
  static const quotaFilled = Color(0xFF16A34A);
  static const quotaPartial = Color(0xFFF59E0B);
  static const quotaEmpty = Color(0xFFDC2626);

  // Divisores e bordas
  static const border = Color(0xFFE5E7EB);
  static const borderFocus = Color(0xFF2A5FA8);

  // Dark mode
  static const darkBackground = Color(0xFF111827);
  static const darkSurface = Color(0xFF1F2937);
  static const darkSurfaceVariant = Color(0xFF374151);
}