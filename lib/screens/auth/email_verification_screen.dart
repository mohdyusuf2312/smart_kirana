import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:smart_kirana/screens/auth/login_screen.dart';
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
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check immediately
    bool isVerified = await authProvider.checkEmailVerification();
    if (isVerified && mounted) {
      setState(() {
        _isVerified = true;
      });
      _timer?.cancel();
      return;
    }

    // Check periodically
    _timer?.cancel(); // Cancel existing timer if any
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) {
        _timer?.cancel();
        return;
      }

      bool isVerified = await authProvider.checkEmailVerification();
      if (isVerified && mounted) {
        setState(() {
          _isVerified = true;
        });
        _timer?.cancel();
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResendEmail || !mounted) return;

    setState(() {
      _canResendEmail = false;
      _resendCooldown = 60;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.resendVerificationEmail();

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
  }

  @override
  Widget build(BuildContext context) {
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
            Navigator.pushReplacementNamed(context, '/home');
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
                CustomButton(
                  text: 'Check Verification Status',
                  onPressed: () => _checkEmailVerification(),
                  isLoading: authProvider.isLoading,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
