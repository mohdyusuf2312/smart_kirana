import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:smart_kirana/screens/admin/admin_dashboard_screen.dart';
import 'package:smart_kirana/screens/auth/email_verification_screen.dart';
import 'package:smart_kirana/screens/auth/login_screen.dart';
import 'package:smart_kirana/screens/home/home_screen.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  @override
  void initState() {
    super.initState();

    // Initialize auth provider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await Provider.of<AuthProvider>(context, listen: false).initialize();
        // Force a rebuild after initialization
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer with specific properties to prevent unnecessary rebuilds
    return Consumer<AuthProvider>(
      // Only listen to authentication status and email verification status changes
      builder: (context, authProvider, _) {
        // Check authentication status
        if (authProvider.isAuthenticated) {
          // Check if user is admin - admins go directly to admin dashboard
          final isAdmin = authProvider.user?.role == 'ADMIN';

          if (isAdmin) {
            // Navigate admin users to the admin dashboard
            return Navigator(
              onGenerateRoute:
                  (_) => MaterialPageRoute(
                    builder: (_) => const AdminDashboardScreen(),
                  ),
            );
          }

          // Check email verification status for non-admin users
          if (!authProvider.isEmailVerified) {
            // Return the verification screen but don't show Firebase's dialog
            return EmailVerificationScreen(
              email: authProvider.currentUser?.email ?? '',
            );
          }

          // Regular authenticated and verified users go to home screen
          return const HomeScreen();
        }

        // Handle unauthenticated users
        // For web platform, allow guest access to home screen
        // For mobile platforms, redirect to login
        if (Theme.of(context).platform == TargetPlatform.android ||
            Theme.of(context).platform == TargetPlatform.iOS) {
          // Mobile platforms require authentication
          return const LoginScreen();
        } else {
          // Web and other platforms allow guest access
          return const HomeScreen();
        }
      },
    );
  }
}
