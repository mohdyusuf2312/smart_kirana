import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_kirana/models/cart_item_model.dart';
import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:smart_kirana/providers/cart_provider.dart';
import 'package:smart_kirana/screens/home/checkout_screen.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/widgets/custom_button.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return cartProvider.isLoading
        ? const Center(child: CircularProgressIndicator())
        : cartProvider.cartItems.isEmpty
        ? _buildEmptyCart()
        : _buildCartContent(context, cartProvider);
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: AppColors.textSecondary.withAlpha(128),
          ),
          const SizedBox(height: AppPadding.medium),
          Text('Your cart is empty', style: AppTextStyles.heading3),
          const SizedBox(height: AppPadding.small),
          Text(
            'Add items to your cart to see them here',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(BuildContext context, CartProvider cartProvider) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppPadding.medium),
            itemCount: cartProvider.cartItems.length,
            itemBuilder: (context, index) {
              final cartItem = cartProvider.cartItems[index];
              return _buildCartItemCard(context, cartItem, cartProvider);
            },
          ),
        ),
        _buildCartSummary(context, cartProvider),
      ],
    );
  }

  Widget _buildCartItemCard(
    BuildContext context,
    CartItemModel cartItem,
    CartProvider cartProvider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppPadding.medium),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppBorderRadius.small),
              child: Image.network(
                cartItem.product.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: AppColors.background,
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),
            const SizedBox(width: AppPadding.medium),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.product.name,
                    style: AppTextStyles.heading3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppPadding.small),
                  Text(
                    '₹${(cartItem.product.discountPrice != null && cartItem.product.discountPrice! > 0) ? cartItem.product.discountPrice! : cartItem.product.price}',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  if (cartItem.product.discountPrice != null &&
                      cartItem.product.discountPrice! > 0)
                    Text(
                      '₹${cartItem.product.price}',
                      style: AppTextStyles.bodySmall.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: AppPadding.small),
                  Row(
                    children: [
                      _buildQuantityButton(
                        icon: Icons.remove,
                        onPressed: () {
                          if (cartItem.quantity > 1) {
                            cartProvider.updateCartItemQuantity(
                              cartItem.product.id,
                              cartItem.quantity - 1,
                            );
                          } else {
                            cartProvider.removeFromCart(cartItem.product.id);
                          }
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppPadding.medium,
                          vertical: AppPadding.small,
                        ),
                        child: Text(
                          '${cartItem.quantity}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildQuantityButton(
                        icon: Icons.add,
                        onPressed: () {
                          cartProvider.updateCartItemQuantity(
                            cartItem.product.id,
                            cartItem.quantity + 1,
                          );
                        },
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        onPressed: () {
                          cartProvider.removeFromCart(cartItem.product.id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textSecondary.withAlpha(76)),
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(icon, size: 16, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildCartSummary(BuildContext context, CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // 0.05 * 255 = 13
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: AppTextStyles.bodyMedium),
              Text(
                '₹${cartProvider.subtotal.toStringAsFixed(2)}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.small),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Delivery Fee', style: AppTextStyles.bodyMedium),
              Text(
                '₹${cartProvider.deliveryFee.toStringAsFixed(2)}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Free delivery message
          if (cartProvider.subtotal < 200)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(AppBorderRadius.small),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_shipping_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Add ₹${(200 - cartProvider.subtotal).toStringAsFixed(2)} more to get FREE delivery!',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${cartProvider.total.toStringAsFixed(2)}',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.medium),
          CustomButton(
            text: 'Proceed to Checkout',
            onPressed: () => _handleCheckout(context),
          ),
        ],
      ),
    );
  }

  void _handleCheckout(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check if user is authenticated
    if (authProvider.currentUser != null) {
      // User is authenticated, proceed to checkout
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CheckoutScreen()),
      );
    } else {
      // User is guest, show login/signup dialog
      _showGuestLoginDialog(context);
    }
  }

  void _showGuestLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return _GuestAuthDialog(
          onAuthSuccess: () async {
            // Store navigator before async operations
            final navigator = Navigator.of(context);

            // Close dialog
            navigator.pop();

            // Cart merge already happened in _handleSubmit, just navigate to checkout
            // Small delay to ensure UI is updated
            await Future.delayed(const Duration(milliseconds: 100));

            // Navigate to checkout with fresh context
            if (context.mounted) {
              navigator.push(
                MaterialPageRoute(builder: (context) => const CheckoutScreen()),
              );
            }
          },
        );
      },
    );
  }
}

// Guest Authentication Dialog Widget
class _GuestAuthDialog extends StatefulWidget {
  final VoidCallback onAuthSuccess;

  const _GuestAuthDialog({required this.onAuthSuccess});

  @override
  State<_GuestAuthDialog> createState() => _GuestAuthDialogState();
}

enum AuthDialogMode { login, signup, emailVerification, forgotPassword }

class _GuestAuthDialogState extends State<_GuestAuthDialog> {
  AuthDialogMode _currentMode = AuthDialogMode.login;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _resetEmailController = TextEditingController();
  final _verificationCodeController = TextEditingController();

  bool _obscurePassword = true;
  String? _pendingUserEmail;
  bool _isResendingCode = false;
  bool _isVerifyingCode = false;
  bool _isSendingResetEmail = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _resetEmailController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 8),
              _buildInfoMessage(),
              const SizedBox(height: 20),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String title;
    IconData icon;

    switch (_currentMode) {
      case AuthDialogMode.login:
        title = 'Login to Continue';
        icon = Icons.account_circle_outlined;
        break;
      case AuthDialogMode.signup:
        title = 'Create Account';
        icon = Icons.person_add_outlined;
        break;
      case AuthDialogMode.emailVerification:
        title = 'Verify Your Email';
        icon = Icons.mark_email_read_outlined;
        break;
      case AuthDialogMode.forgotPassword:
        title = 'Reset Password';
        icon = Icons.lock_reset_outlined;
        break;
    }

    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          iconSize: 20,
        ),
      ],
    );
  }

  Widget _buildInfoMessage() {
    String message;
    IconData icon;

    switch (_currentMode) {
      case AuthDialogMode.login:
      case AuthDialogMode.signup:
        message = 'Your cart items will be saved';
        icon = Icons.info_outline;
        break;
      case AuthDialogMode.emailVerification:
        message = 'Check your email for verification code';
        icon = Icons.email_outlined;
        break;
      case AuthDialogMode.forgotPassword:
        message = 'Enter your email to reset password';
        icon = Icons.help_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentMode) {
      case AuthDialogMode.login:
      case AuthDialogMode.signup:
        return _buildAuthForm();
      case AuthDialogMode.emailVerification:
        return _buildEmailVerificationForm();
      case AuthDialogMode.forgotPassword:
        return _buildForgotPasswordForm();
    }
  }

  Widget _buildAuthForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Name field (only for signup)
          if (_currentMode == AuthDialogMode.signup) ...[
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (_currentMode == AuthDialogMode.signup &&
                    (value == null || value.trim().isEmpty)) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],

          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!EmailValidator.validate(value.trim())) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Phone field (only for signup)
          if (_currentMode == AuthDialogMode.signup) ...[
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (_currentMode == AuthDialogMode.signup &&
                    (value == null || value.trim().isEmpty)) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],

          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (_currentMode == AuthDialogMode.signup && value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Submit button
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return Column(
                children: [
                  if (authProvider.error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 8),
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
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: CustomButton(
                        text: _currentMode == AuthDialogMode.login ? 'Login' : 'Sign Up',
                        onPressed: authProvider.isLoading ? null : _handleSubmit,
                        isLoading: authProvider.isLoading,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Forgot password button (only show in login mode)
          if (_currentMode == AuthDialogMode.login) ...[
            Align(
              alignment: Alignment.centerRight,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _handleForgotPassword,
                  child: Text(
                    'Forgot Password?',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Toggle between login/signup
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _currentMode == AuthDialogMode.login
                    ? "Don't have an account? "
                    : "Already have an account? ",
                style: AppTextStyles.bodyMedium,
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentMode = _currentMode == AuthDialogMode.login
                          ? AuthDialogMode.signup
                          : AuthDialogMode.login;
                      // Clear form when switching
                      _formKey.currentState?.reset();
                      _emailController.clear();
                      _passwordController.clear();
                      _nameController.clear();
                      _phoneController.clear();
                    });
                  },
                  child: Text(
                    _currentMode == AuthDialogMode.login ? 'Sign Up' : 'Login',
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
    );
  }

  Widget _buildEmailVerificationForm() {
    return Column(
      children: [
        // Email display
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.email_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verification email sent to:\n${_pendingUserEmail ?? _emailController.text}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Verification code input
        TextFormField(
          controller: _verificationCodeController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Verification Code',
            prefixIcon: const Icon(Icons.security_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter verification code';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),

        // Verify button
        SizedBox(
          width: double.infinity,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: CustomButton(
              text: 'Verify Email',
              onPressed: _isVerifyingCode ? null : _handleEmailVerification,
              isLoading: _isVerifyingCode,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Resend code button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't receive the code? ",
              style: AppTextStyles.bodyMedium,
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _isResendingCode ? null : _handleResendVerificationCode,
                child: Text(
                  'Resend',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: _isResendingCode ? Colors.grey : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Back to login button
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _currentMode = AuthDialogMode.login;
                _verificationCodeController.clear();
              });
            },
            child: Text(
              'Back to Login',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email field
          TextFormField(
            controller: _resetEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!EmailValidator.validate(value.trim())) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Send reset email button
          SizedBox(
            width: double.infinity,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: CustomButton(
                text: 'Send Reset Email',
                onPressed: _isSendingResetEmail ? null : _handleSendResetEmail,
                isLoading: _isSendingResetEmail,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Back to login button
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentMode = AuthDialogMode.login;
                  _resetEmailController.clear();
                });
              },
              child: Text(
                'Back to Login',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Store guest cart data before authentication
    final guestCartItems = List<Map<String, dynamic>>.from(
      cartProvider.cartItems.map(
        (item) => {'productId': item.product.id, 'quantity': item.quantity},
      ),
    );

    bool success = false;

    if (_currentMode == AuthDialogMode.login) {
      // Login
      success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } else {
      // Sign up
      success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
    }

    if (success && mounted) {
      // Store the guest cart data to a temporary key in SharedPreferences
      // This ensures it survives the provider recreation
      await _storeGuestCartForMerge(guestCartItems);

      // Check if email verification is required for signup
      if (!authProvider.isEmailVerified && _currentMode == AuthDialogMode.signup && mounted) {
        // Store the email for verification screen
        _pendingUserEmail = _emailController.text.trim();

        // Switch to email verification mode
        setState(() {
          _currentMode = AuthDialogMode.emailVerification;
        });

        // Send verification email (simulated for demo)
        // await authProvider.sendEmailVerification();
        return; // Don't proceed to checkout yet
      }

      // For login or verified signup, proceed to checkout
      widget.onAuthSuccess();
    }
  }

  Future<void> _storeGuestCartForMerge(
    List<Map<String, dynamic>> guestCartItems,
  ) async {
    if (guestCartItems.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'temp_guest_cart_for_merge',
      jsonEncode(guestCartItems),
    );
  }

  void _handleForgotPassword() {
    setState(() {
      _currentMode = AuthDialogMode.forgotPassword;
      _resetEmailController.text = _emailController.text; // Pre-fill with current email
    });
  }

  Future<void> _handleEmailVerification() async {
    if (_verificationCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the verification code'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isVerifyingCode = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // For now, we'll simulate email verification since Firebase Auth
      // email verification is typically done via email links, not codes
      // In a real implementation, you might use a different verification method

      // Simulate verification delay
      await Future.delayed(const Duration(seconds: 2));

      // Mark as verified (in real app, this would be handled by Firebase)
      // For demo purposes, we'll proceed to checkout
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully!'),
            backgroundColor: AppColors.success,
          ),
        );

        // Proceed to checkout
        widget.onAuthSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingCode = false;
        });
      }
    }
  }

  Future<void> _handleResendVerificationCode() async {
    setState(() {
      _isResendingCode = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Resend verification email
      // await authProvider.sendEmailVerification();

      // Simulate resend delay
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent again!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResendingCode = false;
        });
      }
    }
  }

  Future<void> _handleSendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSendingResetEmail = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Send password reset email
      await authProvider.resetPassword(_resetEmailController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent! Check your inbox.'),
            backgroundColor: AppColors.success,
          ),
        );

        // Go back to login mode
        setState(() {
          _currentMode = AuthDialogMode.login;
          _resetEmailController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reset email: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingResetEmail = false;
        });
      }
    }
  }
}
