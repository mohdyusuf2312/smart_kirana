import 'package:flutter/material.dart';

// App Theme Colors based on .augment-guidelines
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6C9A8B); // calm green
  static const Color secondary = Color(0xFFF4A259); // earthy orange
  static const Color accent = Color(0xFFDDA15E); // natural gold
  static const Color background = Color(0xFFF1F1E8); // light olive
  static const Color surface = Color(0xFFFFFFFF); // white

  // Text Colors
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF6B6B6B);

  // Status Colors
  static const Color success = Color(0xFFA3B18A);
  static const Color error = Color(0xFFE63946);
}

// Text Styles
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

// App Padding
class AppPadding {
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double extraLarge = 32.0;
}

// App Border Radius
class AppBorderRadius {
  static const double small = 4.0;
  static const double medium = 8.0;
  static const double large = 12.0;
  static const double extraLarge = 24.0;
}

// App Spacing
class AppSpacing {
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double extraLarge = 32.0;
}

// App Strings
class AppStrings {
  // Auth Screens
  static const String appName = "Smart Kirana";
  static const String login = "Login";
  static const String signup = "Sign Up";
  static const String email = "Email";
  static const String password = "Password";
  static const String confirmPassword = "Confirm Password";
  static const String forgotPassword = "Forgot Password?";
  static const String resetPassword = "Reset Password";
  static const String name = "Full Name";
  static const String phone = "Phone Number";
  static const String alreadyHaveAccount = "Already have an account? ";
  static const String dontHaveAccount = "Don't have an account? ";
  static const String verifyEmail = "Verify Email";
  static const String verificationSent = "Verification email sent to ";
  static const String checkEmail =
      "Please check your email and verify your account";
  static const String resendEmail = "Resend Email";
  static const String continueToLogin = "Continue to Login";
  static const String resetPasswordInstructions =
      "Enter your email and we'll send you instructions to reset your password";
  static const String backToLogin = "Back to Login";
  static const String sendResetLink = "Send Reset Link";
  static const String resetLinkSent = "Reset link sent to your email";
}
