import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:smart_kirana/screens/auth/email_verification_screen.dart';
import 'package:smart_kirana/screens/auth/login_screen.dart';
import 'package:smart_kirana/screens/home/home_screen.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({Key? key}) : super(key: key);

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize auth provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<AuthProvider>(context, listen: false).initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer with specific properties to prevent unnecessary rebuilds
    return Consumer<AuthProvider>(
      // Only listen to authentication status and email verification status changes
      builder: (context, authProvider, _) {
        // Check authentication status
        if (authProvider.isAuthenticated) {
          // Check email verification status
          if (!authProvider.isEmailVerified) {
            // Return the verification screen but don't show Firebase's dialog
            return EmailVerificationScreen(
              email: authProvider.currentUser?.email ?? '',
            );
          }
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
