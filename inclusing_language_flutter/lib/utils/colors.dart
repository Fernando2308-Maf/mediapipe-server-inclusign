import 'package:flutter/material.dart';

class AppColors {
  // Helper para obtener colores según el tema actual
  static Color getBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? background
        : backgroundLight;
  }

  static Color getCardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? cardBackground
        : cardBackgroundLight;
  }

  static Color getPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? primary
        : primaryLight;
  }

  static Color getSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? secondary
        : secondaryLight;
  }

  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textPrimary
        : textPrimaryLight;
  }

  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textSecondary
        : textSecondaryLight;
  }

  static Color getBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? border
        : borderLight;
  }

  static Color getBorderDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? borderDark
        : borderDarkLight;
  }

  // TEMA OSCURO (por defecto)
  // Colores principales
  static const Color background = Color(0xFF00131F);
  static const Color cardBackground = Color(0xFF002132);
  static const Color primary = Color(0xFF13B7FF);
  static const Color secondary = Color(0xFF86CBFF);
  static const Color accent = Color(0xFF00ABE8);

  // Colores de borde y detalles
  static const Color border = Color(0xFF0073A3);
  static const Color borderDark = Color(0xFF00577D);

  // Colores de texto
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFC4E2FF);
  static const Color textTertiary = Color(0xFF86CBFF);
  static const Color textLight = Color(0xFFE5F4FF);
  static const Color textDim = Color(0xFF00577D);

  // TEMA CLARO
  // Colores principales
  static const Color backgroundLight = Color(0xFFF5F9FC);
  static const Color cardBackgroundLight = Color(0xFFFFFFFF);
  static const Color primaryLight = Color(0xFF0288D1);
  static const Color secondaryLight = Color(0xFF0277BD);
  static const Color accentLight = Color(0xFF0277BD);

  // Colores de borde y detalles
  static const Color borderLight = Color(0xFFB3E5FC);
  static const Color borderDarkLight = Color(0xFF81D4FA);

  // Colores de texto
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF424242);
  static const Color textTertiaryLight = Color(0xFF616161);
  static const Color textLightLight = Color(0xFF212121);
  static const Color textDimLight = Color(0xFF9E9E9E);

  // Colores de estado (iguales en ambos temas)
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF6B35);
  static const Color info = Color(0xFF2196F3);

  // Colores especiales (iguales en ambos temas)
  static const Color streakOrange = Color(0xFFFF6B35);
  static const Color experienceGold = Color(0xFFFFD700);
  static const Color purple = Color(0xFF9C27B0);
}
