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
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Initialize dynamic links only once
    if (!_initialized) {
      _initDynamicLinks();
      _initialized = true;
    }
  }

  Future<void> _initDynamicLinks() async {
    // Initialize dynamic links
    await _dynamicLinkService.initDynamicLinks(context);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Initialize auth provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      authProvider.initialize();
    });

    if (authProvider.isAuthenticated) {
      if (!authProvider.isEmailVerified) {
        return EmailVerificationScreen(
          email: authProvider.currentUser?.email ?? '',
        );
      }
      return const HomeScreen();
    }
    return const LoginScreen();
  }
}
