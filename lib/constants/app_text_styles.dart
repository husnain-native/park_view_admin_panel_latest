import 'package:flutter/material.dart';
// import 'package:park_chatapp/constants/app_colors.dart';
import 'package:park_view_admin_panel/constants/app_colors.dart';

class AppTextStyles {
  static const headlineSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w100,
  );
  static const headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w300,
  );
  static const headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
  
  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );
  static const bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );
  
  static const TextStyle bodyLarge = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.bold, // Boldness
  color: AppColors.black, // Default color
);
  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );
  
  static const linkText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryRed,
  );
  static const TextStyle bodyMediumBold = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.bold, // Boldness
  color: AppColors.black, // Default color
);
}