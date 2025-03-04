import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:smart_kirana/screens/admin/simple_admin_dashboard.dart';
import 'package:smart_kirana/screens/home/cart_screen.dart';
import 'package:smart_kirana/screens/home/product_screen.dart';
import 'package:smart_kirana/screens/home/profile_screen.dart';
import 'package:smart_kirana/screens/home/search_screen.dart';
import 'package:smart_kirana/utils/constants.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const ProductScreen(),
    const CartScreen(),
    const ProfileScreen(),
  ];

  final List<String> _titles = ['Products', 'Cart', 'Profile'];

  // @override
  // void initState() {
  //   super.initState();
  //   _checkAuthentication();
  // }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
  }

  Future<void> _checkAuthentication() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check if user is authenticated
    if (!authProvider.isAuthenticated) {
      // Navigate to login screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    // Load user data
    await authProvider.initialize();

    // Check if user is admin - redirect to admin dashboard
    if (authProvider.user?.role == 'ADMIN') {
      if (mounted) {
        // Navigate to the simple admin dashboard directly
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SimpleAdminDashboard()),
        );
        return;
      }
    }

    // Check if email is verified (only for non-admin users)
    if (!authProvider.isEmailVerified && authProvider.user?.role != 'ADMIN') {
      // Show dialog to verify email
      if (mounted) {
        _showVerifyEmailDialog();
      }
      return;
    }
  }

  // void _showVerifyEmailDialog() {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder:
  //         (context) => AlertDialog(
  //           title: const Text('Email Verification Required'),
  //           content: const Text(
  //             'Please verify your email address before continuing. '
  //             'Check your inbox for a verification link.',
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () async {
  //                 final authProvider = Provider.of<AuthProvider>(
  //                   context,
  //                   listen: false,
  //                 );
  //                 final scaffoldMessenger = ScaffoldMessenger.of(context);
  //                 await authProvider.resendVerificationEmail();
  //                 if (mounted) {
  //                   scaffoldMessenger.showSnackBar(
  //                     const SnackBar(
  //                       content: Text('Verification email sent'),
  //                       backgroundColor: AppColors.success,
  //                     ),
  //                   );
  //                   Navigator.pop(context); // ✅ Close the dialog here
  //                 }
  //               },
  //               child: const Text('Resend Email'),
  //             ),
  //             TextButton(
  //               onPressed: () async {
  //                 final authProvider = Provider.of<AuthProvider>(
  //                   context,
  //                   listen: false,
  //                 );
  //                 final navigator = Navigator.of(context);
  //                 await authProvider.signOut();
  //                 if (mounted) {
  //                   navigator.pushReplacementNamed('/login');
  //                 }
  //               },
  //               child: const Text('Back to Login'),
  //             ),
  //           ],
  //         ),
  //   );
  // }

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
                    Navigator.pop(dialogContext); // ✅ Properly close the dialog
                  }
                },
                child: const Text('Resend Email'),
              ),
              TextButton(
                onPressed: () async {
                  final authProvider = Provider.of<AuthProvider>(
                    dialogContext, // ✅ Again, correct context
                    listen: false,
                  );
                  await authProvider.signOut();
                  if (dialogContext.mounted) {
                    Navigator.pushReplacementNamed(dialogContext, '/login');
                  }
                },
                child: const Text('Back to Login'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
            ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Products'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
