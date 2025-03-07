import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:smart_kirana/screens/home/home_screen.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/widgets/custom_button.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const OTPVerificationScreen({
    Key? key,
    required this.phoneNumber,
    required this.verificationId,
  }) : super(key: key);

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  int _resendTimer = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      _resendTimer = 30;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Verify the OTP
      final success = await authProvider.verifyPhoneOTP(
        verificationId: widget.verificationId,
        otp: _otpController.text.trim(),
      );
      
      if (success && mounted) {
        // Navigate to home screen on successful verification
        Navigator.pushNamedAndRemoveUntil(
          context,
          HomeScreen.routeName,
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _resendOTP() async {
    if (_resendTimer > 0) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Resend OTP to the phone number
      await authProvider.sendPhoneVerificationCode(
        phoneNumber: widget.phoneNumber,
        onCodeSent: (verificationId, resendToken) {
          setState(() {
            _isLoading = false;
          });
          
          // Reset the timer
          _startResendTimer();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP sent successfully')),
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
      appBar: AppBar(
        title: const Text('Verify Phone Number'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppPadding.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const SizedBox(height: AppPadding.large),
              const Text(
                'Enter verification code',
                style: AppTextStyles.heading1,
              ),
              const SizedBox(height: AppPadding.small),
              Text(
                'We have sent a 6-digit code to ${widget.phoneNumber}',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppPadding.large * 2),
              
              // OTP input
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpController,
                onChanged: (value) {
                  setState(() {
                    _errorMessage = null;
                  });
                },
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(AppBorderRadius.small),
                  fieldHeight: 50,
                  fieldWidth: 40,
                  activeFillColor: AppColors.surface,
                  inactiveFillColor: AppColors.surface,
                  selectedFillColor: AppColors.surface,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.textSecondary.withAlpha(76),
                  selectedColor: AppColors.primary,
                ),
                keyboardType: TextInputType.number,
                enableActiveFill: true,
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
              
              // Verify button
              CustomButton(
                text: 'Verify',
                onPressed: _isLoading ? null : _verifyOTP,
                isLoading: _isLoading,
              ),
              const SizedBox(height: AppPadding.large),
              
              // Resend OTP
              Center(
                child: TextButton(
                  onPressed: _resendTimer > 0 || _isLoading ? null : _resendOTP,
                  child: Text(
                    _resendTimer > 0
                        ? 'Resend OTP in $_resendTimer seconds'
                        : 'Resend OTP',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
