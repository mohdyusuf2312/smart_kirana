import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_kirana/screens/auth/login_screen.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/widgets/custom_button.dart';
import 'package:smart_kirana/widgets/custom_input_field.dart';

class ResetPasswordConfirmScreen extends StatefulWidget {
  static const String routeName = '/reset-password-confirm';
  final Map<String, dynamic> arguments;

  const ResetPasswordConfirmScreen({Key? key, required this.arguments})
    : super(key: key);

  @override
  State<ResetPasswordConfirmScreen> createState() =>
      _ResetPasswordConfirmScreenState();
}

class _ResetPasswordConfirmScreenState
    extends State<ResetPasswordConfirmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _error;
  bool _isSuccess = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get the action code from arguments
      final actionCode = widget.arguments['actionCode'] as String;

      // Confirm password reset with the new password
      await _auth.confirmPasswordReset(
        code: actionCode,
        newPassword: _passwordController.text,
      );

      setState(() {
        _isSuccess = true;
      });
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'expired-action-code':
          errorMessage = 'The password reset link has expired.';
          break;
        case 'invalid-action-code':
          errorMessage = 'The password reset link is invalid.';
          break;
        case 'user-disabled':
          errorMessage = 'The user account has been disabled.';
          break;
        case 'user-not-found':
          errorMessage = 'The user account was not found.';
          break;
        case 'weak-password':
          errorMessage = 'The password is too weak.';
          break;
        default:
          errorMessage = 'An error occurred. Please try again.';
      }
      setState(() {
        _error = errorMessage;
      });
    } catch (e) {
      setState(() {
        _error = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppPadding.large),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppPadding.large),
                if (!_isSuccess) ...[
                  Text('Create New Password', style: AppTextStyles.heading1),
                  const SizedBox(height: AppPadding.small),
                  Text(
                    'Please enter your new password below.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppPadding.extraLarge),
                  CustomInputField(
                    label: 'New Password',
                    hint: 'Enter your new password',
                    controller: _passwordController,
                    isPassword: true,
                    prefixIcon: const Icon(Icons.lock_outline),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppPadding.medium),
                  CustomInputField(
                    label: 'Confirm Password',
                    hint: 'Confirm your new password',
                    controller: _confirmPasswordController,
                    isPassword: true,
                    prefixIcon: const Icon(Icons.lock_outline),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppPadding.medium),
                  if (_error != null)
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
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: AppPadding.small),
                          Expanded(
                            child: Text(
                              _error!,
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
                    text: 'Reset Password',
                    onPressed: _resetPassword,
                    isLoading: _isLoading,
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(AppPadding.large),
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(26),
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.medium,
                      ),
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
                          'Password Reset Successful',
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.success,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppPadding.small),
                        const Text(
                          'Your password has been reset successfully. You can now login with your new password.',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppPadding.large),
                  CustomButton(
                    text: 'Go to Login',
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        LoginScreen.routeName,
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
