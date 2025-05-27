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

// Responsive Grid Configuration
class ResponsiveGrid {
  // Breakpoints based on specific requirements
  static const double smallBreakpoint = 320.0; // Small phones
  static const double mediumBreakpoint = 375.0; // Medium phones
  static const double largeBreakpoint = 425.0; // Large phones
  static const double tabletBreakpoint = 768.0; // Tablets
  static const double laptopBreakpoint = 1024.0; // Laptops
  static const double laptopLargeBreakpoint = 1440.0; // Large laptops
  // 4K displays: width > 1440

  // Get cross axis count based on screen width with overflow prevention
  static int getCrossAxisCount(double width) {
    // Calculate minimum card width needed (including spacing)
    const double minCardWidth =
        140.0; // Minimum width for readable product cards
    const double baseSpacing = 12.0; // Base spacing between cards

    // Calculate maximum columns that can fit without overflow
    int maxPossibleColumns =
        ((width + baseSpacing) / (minCardWidth + baseSpacing)).floor();

    // Apply our breakpoint logic but constrain by available space
    int targetColumns;
    if (width <= smallBreakpoint) {
      targetColumns = 1; // Small phones (≤ 320px) - 1 column
    } else if (width <= mediumBreakpoint) {
      targetColumns = 2; // Medium phones (≤ 375px) - 2 columns
    } else if (width <= largeBreakpoint) {
      targetColumns = 3; // Large phones (≤ 425px) - 3 columns
    } else if (width <= tabletBreakpoint) {
      targetColumns = 4; // Tablets (≤ 768px) - 4 columns
    } else if (width <= laptopBreakpoint) {
      targetColumns = 5; // Laptops (≤ 1024px) - 5 columns
    } else if (width <= laptopLargeBreakpoint) {
      targetColumns = 7; // Large laptops (≤ 1440px) - 7 columns
    } else {
      targetColumns = 8; // 4K displays (> 1440px) - 8 columns
    }

    // Return the smaller of target columns or max possible columns
    return targetColumns.clamp(1, maxPossibleColumns);
  }

  // Get child aspect ratio based on screen width and column count
  static double getChildAspectRatio(double width) {
    int columns = getCrossAxisCount(width);
    double spacing = getSpacing(width);
    double padding = getPadding(width);

    // Calculate available width per card
    double availableWidth = width - (2 * padding) - ((columns - 1) * spacing);
    double cardWidth = availableWidth / columns;

    // Define ideal card height based on content needs
    double idealCardHeight = 220.0; // Height needed for image + text + button

    // Calculate aspect ratio, but ensure it's reasonable
    double calculatedRatio = cardWidth / idealCardHeight;

    // Clamp the ratio to prevent cards that are too tall or too short
    return calculatedRatio.clamp(0.65, 1.3);
  }

  // Get spacing based on screen width
  static double getSpacing(double width) {
    if (width <= smallBreakpoint) {
      return 6.0; // Minimal spacing for small screens
    } else if (width <= mediumBreakpoint) {
      return 8.0; // Small spacing for medium phones
    } else if (width <= largeBreakpoint) {
      return 10.0; // Medium spacing for large phones
    } else if (width <= tabletBreakpoint) {
      return 12.0; // Standard spacing for tablets
    } else if (width <= laptopBreakpoint) {
      return 14.0; // Laptop spacing
    } else if (width <= laptopLargeBreakpoint) {
      return 16.0; // Large laptop spacing
    } else {
      return 20.0; // 4K display spacing
    }
  }

  // Get padding based on screen width
  static double getPadding(double width) {
    if (width <= smallBreakpoint) {
      return 8.0; // Minimal padding for small screens
    } else if (width <= mediumBreakpoint) {
      return 12.0; // Small padding for medium phones
    } else if (width <= largeBreakpoint) {
      return 16.0; // Medium padding for large phones
    } else if (width <= tabletBreakpoint) {
      return 20.0; // Standard padding for tablets
    } else if (width <= laptopBreakpoint) {
      return 24.0; // Laptop padding
    } else if (width <= laptopLargeBreakpoint) {
      return 28.0; // Large laptop padding
    } else {
      return 32.0; // 4K display padding
    }
  }

  // Get device type name for debugging (optional)
  static String getDeviceType(double width) {
    if (width <= smallBreakpoint) {
      return 'Small Phone';
    } else if (width <= mediumBreakpoint) {
      return 'Medium Phone';
    } else if (width <= largeBreakpoint) {
      return 'Large Phone';
    } else if (width <= tabletBreakpoint) {
      return 'Tablet';
    } else if (width <= laptopBreakpoint) {
      return 'Laptop';
    } else if (width <= laptopLargeBreakpoint) {
      return 'Large Laptop';
    } else {
      return '4K Display';
    }
  }
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
