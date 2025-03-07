import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:smart_kirana/screens/auth/login_screen.dart';
import 'package:smart_kirana/screens/auth/otp_verification_screen.dart';
import 'package:smart_kirana/screens/auth/phone_password_login_screen.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/utils/validators.dart';
import 'package:smart_kirana/widgets/custom_button.dart';

class PhoneLoginScreen extends StatefulWidget {
  static const String routeName = '/phone-login';

  const PhoneLoginScreen({Key? key}) : super(key: key);

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Format phone number to include country code if not already present
      String phoneNumber = _phoneController.text.trim();
      if (!phoneNumber.startsWith('+')) {
        // Add India country code (+91) if not present
        phoneNumber = '+91$phoneNumber';
      }

      // Send OTP to the phone number
      await authProvider.sendPhoneVerificationCode(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId, resendToken) {
          // Navigate to OTP verification screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => OTPVerificationScreen(
                    phoneNumber: phoneNumber,
                    verificationId: verificationId,
                  ),
            ),
          );
        },
        onVerificationFailed: (error) {
          setState(() {
            _errorMessage = error;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login with Phone')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppPadding.large),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const SizedBox(height: AppPadding.large),
                const Text(
                  'Enter your phone number',
                  style: AppTextStyles.heading1,
                ),
                const SizedBox(height: AppPadding.small),
                const Text(
                  'We will send you a one-time password (OTP) to verify your phone number',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppPadding.large * 2),

                // Phone number input
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter your phone number',
                    prefixText: '+91 ',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: AppPadding.medium),

                // Error message
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: AppPadding.medium),
                ],

                // Submit button
                CustomButton(
                  text: 'Send OTP',
                  onPressed: _isLoading ? null : _sendOTP,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: AppPadding.large),

                // Login with phone and password
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        PhonePasswordLoginScreen.routeName,
                      );
                    },
                    child: const Text('Login with Phone & Password Instead'),
                  ),
                ),
                const SizedBox(height: AppPadding.small),

                // Back to email login
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        LoginScreen.routeName,
                      );
                    },
                    child: const Text('Login with Email Instead'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
