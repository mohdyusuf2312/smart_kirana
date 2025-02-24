import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:smart_kirana/screens/auth/email_verification_screen.dart';
import 'package:smart_kirana/screens/auth/login_screen.dart';
import 'package:smart_kirana/screens/home/home_screen.dart';
import 'package:smart_kirana/services/dynamic_link_service.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({Key? key}) : super(key: key);

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  final DynamicLinkService _dynamicLinkService = DynamicLinkService();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    // Initialize dynamic links
    if (!_initialized) {
      _initDynamicLinks();
      _initialized = true;
    }
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

  Future<void> _initDynamicLinks() async {
    try {
      // Initialize dynamic links
      await _dynamicLinkService.initDynamicLinks(context);
    } catch (e) {
      // Silently continue without dynamic links
      // In a production app, use a proper logging framework
    }
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
