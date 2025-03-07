import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:smart_kirana/screens/auth/login_screen.dart';
import 'package:smart_kirana/screens/auth/phone_login_screen.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/utils/validators.dart';
import 'package:smart_kirana/widgets/custom_button.dart';
import 'package:smart_kirana/widgets/custom_input_field.dart';

class PhonePasswordLoginScreen extends StatefulWidget {
  static const String routeName = '/phone-password-login';

  const PhonePasswordLoginScreen({Key? key}) : super(key: key);

  @override
  State<PhonePasswordLoginScreen> createState() =>
      _PhonePasswordLoginScreenState();
}

class _PhonePasswordLoginScreenState extends State<PhonePasswordLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isCheckingPhone = false;
  bool _phoneExists = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Check if phone number exists in the database
  Future<void> _checkPhoneNumber() async {
    if (Validators.validatePhone(_phoneController.text.trim()) != null) {
      return;
    }

    setState(() {
      _isCheckingPhone = true;
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

      // Check if phone number exists
      final exists = await authProvider.checkPhoneNumberExists(phoneNumber);

      setState(() {
        _phoneExists = exists;
        _isCheckingPhone = false;
        if (!exists) {
          _errorMessage = 'No user found with this phone number.';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isCheckingPhone = false;
      });
    }
  }

  // Login with phone number and password
  Future<void> _login() async {
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

      // Sign in with phone number and password
      bool success = await authProvider.signInWithPhoneAndPassword(
        phoneNumber: phoneNumber,
        password: _passwordController.text.trim(),
      );

      if (success && mounted) {
        // Navigate to home screen
        Navigator.pushReplacementNamed(context, '/home');
      } else if (mounted) {
        setState(() {
          _errorMessage = authProvider.error;
          _isLoading = false;
        });
      }
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
                  'Login with Phone Number',
                  style: AppTextStyles.heading1,
                ),
                const SizedBox(height: AppPadding.small),
                const Text(
                  'Enter your phone number and password to login',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppPadding.large * 2),

                // Phone number input
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter your phone number',
                    prefixText: '+91 ',
                    prefixIcon: const Icon(Icons.phone),
                    suffixIcon:
                        _isCheckingPhone
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : IconButton(
                              icon: const Icon(Icons.check_circle_outline),
                              onPressed: _checkPhoneNumber,
                            ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                  onChanged: (_) {
                    // Reset phone exists flag when phone number changes
                    if (_phoneExists) {
                      setState(() {
                        _phoneExists = false;
                      });
                    }
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: AppPadding.medium),

                // Password input (only shown if phone number exists)
                if (_phoneExists) ...[
                  CustomInputField(
                    label: 'Password',
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
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: AppPadding.medium),
                ],

                // Error message
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: AppPadding.medium),
                ],

                // Submit button
                if (_phoneExists) ...[
                  CustomButton(
                    text: 'Login',
                    onPressed: _isLoading ? null : _login,
                    isLoading: _isLoading,
                  ),
                ] else ...[
                  CustomButton(
                    text: 'Check Phone Number',
                    onPressed: _isCheckingPhone ? null : _checkPhoneNumber,
                    isLoading: _isCheckingPhone,
                  ),
                ],
                const SizedBox(height: AppPadding.large),

                // Login with OTP instead
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        PhoneLoginScreen.routeName,
                      );
                    },
                    child: const Text('Login with OTP Instead'),
                  ),
                ),

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
