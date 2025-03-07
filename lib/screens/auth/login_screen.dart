import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';
import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:smart_kirana/screens/auth/forgot_password_screen.dart';
import 'package:smart_kirana/screens/auth/phone_login_screen.dart';
import 'package:smart_kirana/screens/auth/phone_password_login_screen.dart';
import 'package:smart_kirana/screens/auth/signup_screen.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/widgets/custom_button.dart';
import 'package:smart_kirana/widgets/custom_input_field.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      bool success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (success && mounted) {
        // Navigate to home screen or check email verification
        if (!authProvider.isEmailVerified) {
          // Show dialog to verify email
          _showVerifyEmailDialog();
        } else {
          // Navigate to home screen
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    }
  }

  void _showVerifyEmailDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Email Verification Required'),
            content: const Text(
              'Please verify your email address before continuing. '
              'Check your inbox for a verification link.',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final authProvider = Provider.of<AuthProvider>(
                    dialogContext, // ✅ Use dialogContext here
                    listen: false,
                  );
                  final scaffoldMessenger = ScaffoldMessenger.of(dialogContext);

                  await authProvider.resendVerificationEmail();

                  if (dialogContext.mounted) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Verification email sent'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    Navigator.of(
                      dialogContext,
                    ).pop(); // ✅ Dismiss with correct context
                  }
                },
                child: const Text('Resend Email'),
              ),
              TextButton(
                onPressed: () async {
                  final authProvider = Provider.of<AuthProvider>(
                    dialogContext, // ✅ Again, use the correct context
                    listen: false,
                  );
                  await authProvider.signOut();
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(); // ✅ Close the dialog
                  }
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppPadding.large),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppPadding.extraLarge * 2),
                Text(AppStrings.login, style: AppTextStyles.heading1),
                const SizedBox(height: AppPadding.small),
                Text(
                  'Welcome to Smart Kirana',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppPadding.extraLarge),
                CustomInputField(
                  label: AppStrings.email,
                  hint: 'Enter your email address',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!EmailValidator.validate(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppPadding.medium),
                CustomInputField(
                  label: AppStrings.password,
                  hint: 'Enter your password',
                  controller: _passwordController,
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock_outline),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppPadding.small),
                Align(
                  alignment: Alignment.centerRight,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          ForgotPasswordScreen.routeName,
                        );
                      },
                      child: Text(
                        AppStrings.forgotPassword,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppPadding.medium),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return Column(
                      children: [
                        if (authProvider.error != null)
                          Container(
                            padding: const EdgeInsets.all(AppPadding.medium),
                            decoration: BoxDecoration(
                              color: AppColors.error.withAlpha(
                                26,
                              ), // 0.1 * 255 = 26
                              borderRadius: BorderRadius.circular(
                                AppBorderRadius.medium,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: AppPadding.small),
                                Expanded(
                                  child: Text(
                                    authProvider.error!,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: AppPadding.large),
                        CustomButton(
                          text: AppStrings.login,
                          onPressed: _login,
                          isLoading: authProvider.isLoading,
                        ),
                        const SizedBox(height: AppPadding.medium),
                        // Phone login with OTP button
                        OutlinedButton.icon(
                          icon: const Icon(Icons.sms),
                          label: const Text('Login with OTP'),
                          onPressed:
                              authProvider.isLoading
                                  ? null
                                  : () {
                                    Navigator.pushNamed(
                                      context,
                                      PhoneLoginScreen.routeName,
                                    );
                                  },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                        const SizedBox(height: AppPadding.small),
                        // Phone login with password button
                        OutlinedButton.icon(
                          icon: const Icon(Icons.phone),
                          label: const Text('Login with Phone & Password'),
                          onPressed:
                              authProvider.isLoading
                                  ? null
                                  : () {
                                    Navigator.pushNamed(
                                      context,
                                      PhonePasswordLoginScreen.routeName,
                                    );
                                  },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppPadding.medium),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.dontHaveAccount,
                      style: AppTextStyles.bodyMedium,
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(
                            context,
                            SignupScreen.routeName,
                          );
                        },
                        child: Text(
                          AppStrings.signup,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
