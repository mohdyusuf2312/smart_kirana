import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:smart_kirana/screens/auth/login_screen.dart';
import 'package:smart_kirana/screens/home/home_screen.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/widgets/custom_button.dart';

class EmailVerificationScreen extends StatefulWidget {
  static const String routeName = '/email-verification';
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _timer;
  bool _isVerified = false;
  bool _canResendEmail = true;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  bool _isCheckingVerification = false;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerification() async {
    // Prevent multiple simultaneous checks
    if (_isCheckingVerification || !mounted) return;

    // Set checking state only once at the beginning
    setState(() {
      _isCheckingVerification = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Check immediately
      bool isVerified = await authProvider.checkEmailVerification();
      if (!mounted) return;

      if (isVerified) {
        setState(() {
          _isVerified = true;
        });
        _timer?.cancel(); // Cancel any existing timer
        return;
      }

      // Set up periodic check with a longer interval (30 seconds)
      // This reduces API calls and prevents UI flickering
      _timer?.cancel(); // Cancel existing timer if any
      _timer = Timer.periodic(const Duration(seconds: 30), (_) async {
        // Skip if already checking or component unmounted
        if (_isCheckingVerification || !mounted) return;

        try {
          // Use the silent check method to prevent UI updates during background checks
          bool isVerified = await authProvider.checkEmailVerificationSilently();
          if (!mounted) return;

          if (isVerified) {
            setState(() {
              _isVerified = true;
            });
            _timer?.cancel();
          }
        } catch (e) {
          // Silently handle errors during background checks
          // to prevent UI disruption
        }
      });
    } finally {
      // Only update state if still mounted
      if (mounted) {
        setState(() {
          _isCheckingVerification = false;
        });
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    // Prevent resending if already in cooldown or component unmounted
    if (!_canResendEmail || !mounted) return;

    setState(() {
      _canResendEmail = false;
      _resendCooldown = 60; // 1 minute cooldown
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Attempt to resend verification email
      await authProvider.resendVerificationEmail();

      if (!mounted) return;

      // If successful, show a brief message or toast here if needed

      // Start cooldown timer regardless of success to prevent spam
      // Cancel existing timer if any
      _cooldownTimer?.cancel();

      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_resendCooldown > 0) {
          setState(() {
            _resendCooldown--;
          });
        } else {
          setState(() {
            _canResendEmail = true;
          });
          timer.cancel();
        }
      });
    } catch (e) {
      // Handle any errors that weren't caught by the provider
      if (mounted) {
        setState(() {
          _canResendEmail = true; // Allow retry on error
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // We'll use a safer approach to handle dialogs
    // Instead of trying to dismiss dialogs automatically, we'll let the user handle it

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () async {
            final navigator = Navigator.of(context);
            final authProvider = Provider.of<AuthProvider>(
              context,
              listen: false,
            );
            await authProvider.signOut();
            if (mounted) {
              navigator.pushReplacementNamed(LoginScreen.routeName);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppPadding.large),
              Text(
                AppStrings.verifyEmail,
                style: AppTextStyles.heading1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppPadding.medium),
              Text(
                '${AppStrings.verificationSent}${widget.email}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppPadding.small),
              Text(
                AppStrings.checkEmail,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppPadding.extraLarge * 2),
              if (_isVerified) ...[
                _buildVerifiedContent(),
              ] else ...[
                _buildUnverifiedContent(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerifiedContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppPadding.large),
          decoration: BoxDecoration(
            color: AppColors.success.withAlpha(26),
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
                size: 64,
              ),
              const SizedBox(height: AppPadding.medium),
              Text(
                'Email Verified Successfully!',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.success,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppPadding.small),
              const Text(
                'Your email has been verified. You can now login to your account.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppPadding.large),
        CustomButton(
          text: AppStrings.continueToLogin,
          onPressed: () {
            Navigator.pushReplacementNamed(context, HomeScreen.routeName);
          },
        ),
      ],
    );
  }

  Widget _buildUnverifiedContent() {
    return Column(
      children: [
        const Icon(
          Icons.mark_email_unread_outlined,
          size: 100,
          color: AppColors.primary,
        ),
        const SizedBox(height: AppPadding.large),
        Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return Column(
              children: [
                if (authProvider.error != null)
                  Container(
                    padding: const EdgeInsets.all(AppPadding.medium),
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(26),
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.medium,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error),
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
                if (_isCheckingVerification)
                  Container(
                    padding: const EdgeInsets.all(AppPadding.medium),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.medium,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppPadding.small),
                        Expanded(
                          child: Text(
                            'Email is not verified. Please check your email.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppPadding.large),
                CustomButton(
                  text:
                      _canResendEmail
                          ? AppStrings.resendEmail
                          : 'Resend in $_resendCooldown seconds',
                  onPressed:
                      _canResendEmail
                          ? () {
                            _resendVerificationEmail();
                          }
                          : null,
                  isLoading: authProvider.isLoading,
                  type: ButtonType.outline,
                  enabled: _canResendEmail,
                ),
                const SizedBox(height: AppPadding.medium),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Check Verification Status',
                        onPressed:
                            _isCheckingVerification
                                ? null
                                : () {
                                  // Show a brief message to indicate checking is in progress
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Checking verification status...',
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  _checkEmailVerification();
                                },
                        isLoading: _isCheckingVerification,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
