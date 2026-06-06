import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // DGT Brand
  static const Color primary   = Color(0xFFFCB017); // amarelo principal
  static const Color secondary = Color(0xFFFED402); // amarelo secundário

  // Grays
  static const Color darkGray  = Color(0xFF3A3A3A); // headers, textos
  static const Color midGray   = Color(0xFF787878); // subtítulos
  static const Color lightGray = Color(0xFFD3D3D3); // bordas, placeholders

  // Superfícies
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface    = Color(0xFFFFFFFF);

  // Texto
  static const Color textPrimary   = Color(0xFF3A3A3A);
  static const Color textSecondary = Color(0xFF787878);
  static const Color textDisabled  = Color(0xFFBDBDBD);

  // Bordas
  static const Color border      = Color(0xFFE8E8E8);
  static const Color borderLight = Color(0xFFF0F0F0);
  static const Color borderFocus = Color(0xFFFCB017);

  // Classificação de desempenho
  static const Color classAbaixo  = Color(0xFFE57373); // Abaixo do nível
  static const Color classNoNivel = Color(0xFF90CAF9); // No nível
  static const Color classAcima   = Color(0xFFA5D6A7); // Acima do nível
  static const Color classTop     = Color(0xFFFCB017); // Top Performer

  // Background semântico das classificações
  static const Color classAbaixoBg  = Color(0xFFFFEBEE);
  static const Color classNoNivelBg = Color(0xFFE3F2FD);
  static const Color classAcimaBg   = Color(0xFFE8F5E9);
  static const Color classTopBg     = Color(0xFFFFF8E1);

  // Status de metas / etapas
  static const Color statusOnTrack   = Color(0xFF2E7D32);
  static const Color statusAtRisk    = Color(0xFFB05E00);
  static const Color statusBehind    = Color(0xFFC62828);
  static const Color statusCompleted = Color(0xFF185FA5);
  static const Color statusDraft     = Color(0xFF787878);

  // Background dos status
  static const Color statusOnTrackBg   = Color(0xFFEAFBE7);
  static const Color statusAtRiskBg    = Color(0xFFFEF3DC);
  static const Color statusBehindBg    = Color(0xFFFFEBEE);
  static const Color statusCompletedBg = Color(0xFFE3F2FD);
  static const Color statusDraftBg     = Color(0xFFF5F5F5);
}
