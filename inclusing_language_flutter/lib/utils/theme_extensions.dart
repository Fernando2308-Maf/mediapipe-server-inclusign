import 'package:flutter/material.dart';
import 'colors.dart';

extension ThemeExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get appBackground =>
      isDarkMode ? AppColors.background : AppColors.backgroundLight;

  Color get appCardBackground =>
      isDarkMode ? AppColors.cardBackground : AppColors.cardBackgroundLight;

  Color get appPrimary =>
      isDarkMode ? AppColors.primary : AppColors.primaryLight;

  Color get appSecondary =>
      isDarkMode ? AppColors.secondary : AppColors.secondaryLight;

  Color get appAccent =>
      isDarkMode ? AppColors.accent : AppColors.accentLight;

  Color get appBorder =>
      isDarkMode ? AppColors.border : AppColors.borderLight;

  Color get appBorderDark =>
      isDarkMode ? AppColors.borderDark : AppColors.borderDarkLight;

  Color get appTextPrimary =>
      isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryLight;

  Color get appTextSecondary =>
      isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryLight;

  Color get appTextTertiary =>
      isDarkMode ? AppColors.textTertiary : AppColors.textTertiaryLight;

  Color get appTextLight =>
      isDarkMode ? AppColors.textLight : AppColors.textLightLight;

  Color get appTextDim =>
      isDarkMode ? AppColors.textDim : AppColors.textDimLight;
}
